pragma solidity ^0.5;

/**
 * @dev Defines the storage layout for owned contracts.
 */
contract StorageDefSystemOwner {

    address internal systemOwner;

    /**
     * @dev Internal constructor to enforce abstract contract.
     */
    constructor() internal {}
}