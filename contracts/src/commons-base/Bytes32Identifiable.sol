pragma solidity ^0.5;

/**
 * @title Identifiable Interface
 * @dev Interface definition for contracts providing a bytes32 ID.
 */
interface Bytes32Identifiable {
	
	/**
	 * @dev Returns the identifier of this contract.
	 * @return the bytes32 ID
	 */
	function getId() external view returns (bytes32);
}