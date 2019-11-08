pragma solidity ^0.5;

import "commons-base/BaseErrors.sol";
import "commons-base/Owned.sol";
import "commons-base/AbstractVersioned.sol";

/**
 * @title VersionLinked
 * @dev A Versioned contract capable of maintaining relationships with its known neighbors, i.e. predecessor and successor versions, thus forming an insert-only LinkedList.
 * There are restrictions that must be fulfilled in order to link instances together, e.g. all instances must have the same owner.
 * A new element can be inserted through any VersionLinked instance that is already connected and the new element will be passed along the versions to find its appropriate placement in the list.
 */
contract VersionLinked is AbstractVersioned, Owned {
	
	VersionLinked currentPredecessor;
	VersionLinked currentSuccessor;
	
	/**
	 * @dev Constructor - Sets the msg.sender as the owner.
	 * @param _version the version of this VersionLinked contract
	 */
	constructor(uint8[3] memory _version) public {
		owner = msg.sender;
		semanticVersion = _version;
	}
	
	/**
	 * @dev Adds the given VersionLinked contract into the linked version list or returns an error, if the operation is not possible
	 * @param _link a new VersionedLink contract.
	 * @return BaseErrors.NO_ERROR() if the given VersionLinked instance was successfully placed into the linked version list.
	 * 		   BaseErrors.NULL_PARAM_NOT_ALLOWED() if the _newPredecessor is empty (null address).
	 * 		   BaseErrors.INVALID_STATE() if the given VersionLinked instance has a different owner than this contract.
	 * 		   BaseErrors.INVALID_PARAM_VALUE() if the given VersionLinked instance has the same version or address as this contract.
	 */
	function acceptVersionLink(VersionLinked _link) external returns (uint error) {
		if (address(_link) == address(0)) return BaseErrors.NULL_PARAM_NOT_ALLOWED();
		if (_link.getOwner() != owner) return BaseErrors.INVALID_STATE();
		int comp = _link.compareVersion(address(this));
		if (comp == 0 || address(_link) == address(this)) return BaseErrors.INVALID_PARAM_VALUE(); // same version or object address. not allowed to replace itself.

		// this contract has a higher version than _link
		if (comp > 0) {
			if (address(currentPredecessor) != address(0) && _link.compareVersion(address(currentPredecessor)) >= 0) {
				// link is lower than (or equal) to existing predecessor, pass the request on
				return currentPredecessor.acceptVersionLink(_link);
			}
			return setPredecessor(_link);
		}
		// _link version is higher than this contract
		else {
			if (address(currentSuccessor) != address(0) && _link.compareVersion(address(currentSuccessor)) <= 0) {
				// link is higher than (or equal to) existing successor, pass the request on
				return currentSuccessor.acceptVersionLink(_link);
			}
			return setSuccessor(_link);
		}
	}
	
	/**
	 * @dev Attempts to set the specified version as the predecessor of this contract.
	 * If a predecessor is already set, an attempt is made to insert the _newPredecessor as a link between this contract and the existing predecessor.
	 * 
	 * @param _newPredecessor the VersionLinked instance to set as new predecessor
	 * @return BaseErrors.NO_ERROR() if the relationship between the given predecessor and this contract (and a potentially existing predecessor) is established successfully, i.e. the predecessor has been set and this contract is its successor.
	 * 		   BaseErrors.INVALID_STATE() if the given _newPredecessor does not or would not accept this contract as its successor
	 * 		   BaseErrors.INVALID_PARAM_STATE() if the msg.sender is the current predecessor (who requests to be replaced to complete an insert), but the msg.sender is not set as predecessor in the _newPredecessor, therefore risking inconsistencies.
	 */
	function setPredecessor(VersionLinked _newPredecessor) internal returns (uint error) {
		// temporarily set the new predecessor to suppress acceptVersionLink() ping pong between contracts
		VersionLinked oldPredecessor = currentPredecessor;
		currentPredecessor = _newPredecessor;
		error = BaseErrors.NO_ERROR();

		// if the new predecessor has not yet linked to this contract as a successor, attempt establishing the link first
		if (_newPredecessor.getSuccessor() != address(this)) {
			_newPredecessor.acceptVersionLink(this); // ignoring error code here since outcome is checked below
			if (_newPredecessor.getSuccessor() != address(this)) {
				error = BaseErrors.INVALID_PARAM_STATE();
			}
		}
		// deal with an existing predecessor
		if (error == BaseErrors.NO_ERROR() && address(oldPredecessor) != address(0)) {
			if (msg.sender != address(oldPredecessor)) {
				error = oldPredecessor.acceptVersionLink(_newPredecessor);
			}
			else if (_newPredecessor.getPredecessor() != address(oldPredecessor)) {
				error = BaseErrors.INVALID_PARAM_STATE();
			}
		}

		if (error != BaseErrors.NO_ERROR()) {
			currentPredecessor = oldPredecessor; // Rollback
		}
	}

	/**
	 * @dev Attempts to set the specified version as the successor of this contract.
	 * If a successor is already set, an attempt is made to insert the _newPredecessor as a link between this contract and the existing successor.
	 * 
	 * @param _newSuccessor the VersionLinked instance to set as new successor
	 * @return BaseErrors.NO_ERROR() if the relationship between the given successor and this contract (and a potentially existing successor) is established successfully, i.e. the successor has been set and this contract is its predecessor.
	 * 		   BaseErrors.INVALID_STATE() if the given _newSuccessor does not or would not accept this contract as its predecessor
	 * 		   BaseErrors.INVALID_PARAM_STATE() if the msg.sender is the current successor (who requests to be replaced to complete an insert), but the msg.sender is not set as successor in the _newSuccessor, therefore risking inconsistencies.
	 */
	function setSuccessor(VersionLinked _newSuccessor) internal returns (uint error) {
		// temporarily set the new successor to suppress acceptVersionLink() ping pong between contracts
		VersionLinked oldSuccessor = currentSuccessor;
		currentSuccessor = _newSuccessor;
		error = BaseErrors.NO_ERROR();
		
		// if the new successor has not yet linked to this contract as a predecessor, attempt establishing the link first
		if (_newSuccessor.getPredecessor() != address(this)) {
			_newSuccessor.acceptVersionLink(this); // ignoring error code here since outcome is checked below
			if (_newSuccessor.getPredecessor() != address(this)) {
				error = BaseErrors.INVALID_PARAM_STATE();
			}
		}
		// deal with an existing successor
		if (error == BaseErrors.NO_ERROR() && address(oldSuccessor) != address(0)) {
			if (msg.sender != address(oldSuccessor)) {
				error = oldSuccessor.acceptVersionLink(_newSuccessor);
			}
			else if (_newSuccessor.getSuccessor() != address(oldSuccessor)) {
				error = BaseErrors.INVALID_PARAM_STATE();
			}
		}

		if (error != BaseErrors.NO_ERROR()) {
			currentSuccessor = oldSuccessor; // Rollback
		}
	}
	
	/**
	 * @dev Returns the predecessor version
	 * @return the address of the predecessor or 0x0 if not set
	 */
	function getPredecessor() external view returns (address) {
		return address(currentPredecessor);
	}

	/**
	 * @dev Returns the successor version
	 * @return the address of the successor or 0x0 if not set
	 */
	function getSuccessor() external view returns (address) {
		return address(currentSuccessor);
	}
	
}