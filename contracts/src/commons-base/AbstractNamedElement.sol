pragma solidity ^0.5;

import "commons-base/NamedElement.sol";

/**
 * @title AbstractNamedElement
 * @dev Base contract to provide ID and name attributes to inheriting contracts. This contract is not meant to be used directly, only through inheritance! 
 */
contract AbstractNamedElement is NamedElement {
	
	bytes32 id;
	string name;
		
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
	function getName() external view returns (string memory) {
		return name;
	}
	
}