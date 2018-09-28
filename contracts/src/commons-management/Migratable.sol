pragma solidity ^0.4.23;

/**
 * @title Migratable
 * @dev Interface to be implemented by contracts to support the capability of 'migrating' their state to
 * a successor contract.
 */
contract Migratable {

    /**
     * @dev Performs the PULL migration of state from the specified predecessor to this contract.
     * @param predecessor the address from which the state is migrated
     * @return true if the operation succeeded, false otherwise
     */
    function migrateFrom(address predecessor) public returns (bool success);

    /**
     * @dev Performs the PUSH migration of state from this contract to the specified contract.
     * @param successor the address to which the state is migrated
     * @return true if the operation succeeded, false otherwise
     */
    function migrateTo(address successor) public returns (bool success);
}