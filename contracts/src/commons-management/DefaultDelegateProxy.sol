pragma solidity ^0.5;

import "commons-management/StorageDefProxied.sol";
import "commons-management/AbstractDelegateProxy.sol";

/**
 * @title DefaultDelegateProxy
 * @dev Default implementation of a proxy contract that delegates all calls to a "proxied" contract and returns the results to the caller.
 * This implementation relies on fixed, structured data storage for the proxied address.
 */
contract DefaultDelegateProxy is StorageDefProxied, AbstractDelegateProxy {

    /**
     * @dev Creates a new DefaultDelegateProxy with the given address as the proxied contract
     * @param _proxied the address of the proxied contract
     */
    constructor(address _proxied) public {
        proxied = _proxied;
    }

    /**
     * @dev Implements AbstractDelegateProxy.getDelegate()
     * @return the address of the proxied contract
     */
    function getDelegate() public view returns (address) {
        return proxied;
    }
}