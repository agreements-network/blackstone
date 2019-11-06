pragma solidity ^0.5;

import "commons-base/ErrorsLib.sol";
import "commons-management/OwnedDelegateProxy.sol";
import "commons-management/StorageDefRegistry.sol";

/**
 * @title DougProxy
 * @dev Proxy contract for Doug instances. Once deployed, this contract can be used as the singleton access point for Doug functions
 * covering future Doug upgrades.
 */
contract DougProxy is OwnedDelegateProxy, StorageDefRegistry {

    /**
     * @dev Modifier to only allow access by the owner.
     */
    modifier pre_onlyByOwner() {
        ErrorsLib.revertIf(msg.sender != owner,
            ErrorsLib.UNAUTHORIZED(), "DougProxy.pre_onlyByOwner", "The msg.sender is not the owner");
        _;
    }

    /**
     * @dev Creates a new DougProxy with the given Doug instance as the proxied contract and sets the systemOwner to msg.sender
     * @param _doug an address of a Doug instance
     */
    constructor (address _doug) public OwnedDelegateProxy(_doug) {
    }

    /**
     * @dev Allows the owner to set the DOUG contract in this proxy to the given address.
     * @param _doug the DOUG instance's address to proxy
     */
    function setProxiedDoug(address _doug) external pre_onlyByOwner {
        proxied = _doug;
    }

    /**
     * @dev Returns the owner of this DougProxy
     * @return the owner address
     */
    function getOwner() public view returns (address) {
        return owner;
    }
}