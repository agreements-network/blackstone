pragma solidity ^0.4.23;

import "commons-base/NamedElement.sol";

/**
 * @title AbstractNamedElement
 * @dev Base contract to provide ID and name attributes to inheriting contracts. This contract is not meant to be used directly, only through inheritance! 
 */
contract AbstractNamedElement is NamedElement {
	
	bytes32 id;
	bytes32 name;
	
	/**
	 * @dev Creates a new AbstractNamedElement with the specified ID and name
	 * @param _id the ID
	 * @param _name the name 
	 */
	constructor(bytes32 _id, bytes32 _name) public {
		id = _id;
		name = _name;
	}
	
	/**
	 * @dev Returns the ID of this contract.
	 * @return the bytes32 ID
	 */
	function getId() public view returns (bytes32) {
		return id;
	}
	
	/**
	 * @dev Returns the name of this contract.
	 * @return the bytes32 name
	 */
	function getName() external view returns (bytes32) {
		return name;
	}
	
}