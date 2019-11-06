pragma solidity ^0.5;

import "commons-base/ErrorsLib.sol";
import "commons-base/SystemOwned.sol";

import "commons-management/StorageDefDatabase.sol";
import "commons-management/DbInterchangeable.sol";
import "commons-management/AbstractUpgradeable.sol";

/**
 * @title AbstractDbUpgradeable
 * @dev Provides the ability to hold the contracts state in a database contract and upgrade by migrating the database. 
 */
contract AbstractDbUpgradeable is StorageDefDatabase, AbstractUpgradeable, DbInterchangeable {

  /**
   * @dev Creates a new AbstractDbUpgradeable. Internal to enforce abstract contract.
   */
  constructor() internal {}

  /**
   * @dev Implementation of DbInterchangeable.acceptDatabase(address). Sets the provided database
   * as this contract's database, if this contract has been granted system ownership of the database.
   * This function can only be called from the upgradeOwner or from another contract that shares the same upgradeOwner
   * (the second scenario applies when the database is migrated from a previous version as part of an upgrade).
   * REVERTS if:
   * - the msg.sender is neither the uprade owner nor another UpgradeOwned contract with the same upgrade owner
   * @param _db the database contract
   * @return true if it was accepted, false otherwise
   */
  function acceptDatabase(address _db) external returns (bool accepted) {
    ErrorsLib.revertIf(msg.sender != upgradeOwner && UpgradeOwned(msg.sender).getUpgradeOwner() != upgradeOwner,
      ErrorsLib.UNAUTHORIZED(), "AbstractDbUpgradeable.acceptDatabase", "The msg.sender must either be the upgradeOwner or a contract with the same upgradeOwner");
    // verify that this contract has been set as the system owner of the database
    if (SystemOwned(_db).getSystemOwner() == address(this)) {
      database = _db;
      accepted = true;
    }
  }

  /**
   * @dev Empty implementation of Migratable.migrateFrom(address).
   * @return always true
   */
  function migrateFrom(address) public returns (bool success) {
    success = true;
  }

  /**
   * @dev Implementation of Migratable.migrateTo(address) that transfers system ownership of the
   * database in this contract to the successor and calls DbInterchangeable.acceptDatabase(address) on the successor.
   * REVERTS if:
   * - the database contract was not accepted by the successor
   * @param _successor the successor contract to which to migrate the database
   * @return true if the database was successfully accepted by the successor, otherwise a REVERT is triggered to rollback the change of system ownership.
   */
  function migrateTo(address _successor) public returns (bool success) {
    SystemOwned(database).transferSystemOwnership(_successor);
    success = DbInterchangeable(_successor).acceptDatabase(database);
    ErrorsLib.revertIf(!success,
      ErrorsLib.INVALID_STATE(), "AbstractDbUpgradeable.migrateTo", "The DB contract was not accepted by the new owner");
  }
}