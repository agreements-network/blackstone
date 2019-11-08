pragma solidity ^0.5;

/**
 * @dev Provides the storage layout for database-owning contracts.
 */
contract StorageDefDatabase {

    address internal database;

    /**
     * @dev Internal constructor to enforce abstract contract.
     */
    constructor() internal {}
}