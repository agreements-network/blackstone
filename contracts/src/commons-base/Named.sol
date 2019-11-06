pragma solidity ^0.5;

/**
 * @title Named Interface
 * @dev Interface definition for contracts providing a bytes32 name.
 */
interface Named {
	
	/**
	 * @dev Returns the name of this contract.
	 * @return the bytes32 name
	 */
	function getName() external view returns (string memory);
}