pragma solidity ^0.5;

/**
 * @title DbInterchangeable
 * @dev Interface for a contract to signal that its database contract can be swapped out.
 */
interface DbInterchangeable {

  /**
   * @dev Allows the implementing contract to accept a database contract as its backend.
   * @param _db the address of a contract to use as database
   * @return true if the database was successfully set, false otherwise
   */
  function acceptDatabase(address _db) external returns (bool);

}