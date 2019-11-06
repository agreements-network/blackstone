pragma solidity ^0.5;

import "commons-base/StorageDefOwner.sol";

import "commons-management/DefaultDelegateProxy.sol";

/**
 * @title OwnedDelegateProxy
 * @dev A DefaultDelegateProxy implementation with an owner relying on fixed, structured data storage for the owner.
 */
contract OwnedDelegateProxy is DefaultDelegateProxy, StorageDefOwner {

    /**
     * @dev Creates a new OwnedDelegateProxy with the given proxied contract and sets the msg.sender as the owner
     * @param _proxied an address of a proxied contract
     */
    constructor(address _proxied) public DefaultDelegateProxy(_proxied) {
        owner = msg.sender;
    }
}