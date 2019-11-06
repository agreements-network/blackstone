pragma solidity ^0.5;

import "commons-base/ErrorsLib.sol";

import "commons-management/AbstractDelegateProxy.sol";

/**
 * @title OwnedDelegateUnstructuredProxy
 * @dev Implementation of a proxy contract that supports unstructured data storage, i.e. leaves the definition and management of data storage to the proxied contract.
 * The data fields required for proxying and delegating calls as well as ownership of the proxy are stored in reserved storage slots that are extremely unlikely to ever interfere with the structured storage space of the proxied contract.
 */
contract OwnedDelegateUnstructuredProxy is AbstractDelegateProxy {

    /**
     * Storage position for the address of the proxied contract
     */
    bytes32 private constant storagePositionDelegateTarget = keccak256("AN://contract/storage/delegate-target");
    /**
     * Storage position for the address of the owner
     */
    bytes32 private constant storagePositionOwner = keccak256("AN://contract/storage/owner");

    /**
     * @dev Creates a new OwnedDelegateUnstructuredProxy with the given address as the proxied contract.
     * The msg.sender will be registered as the owner of this proxy who has the permission to change the delegate target.
     * @param _delegateAddress the address of a contract to be proxied
     */
    constructor(address _delegateAddress) public {
        ErrorsLib.revertIf(_delegateAddress == address(0),
            ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "OwnedDelegateUnstructuredProxy.constructor", "_delegateAddress must not be empty");
        bytes32 delegatePos = storagePositionDelegateTarget;
        bytes32 ownerPos = storagePositionOwner;
        address sender = msg.sender;
        assembly {
            sstore(delegatePos, _delegateAddress)
            sstore(ownerPos, sender)
        }
    }

    /**
     * @dev Implements AbstractDelegateProxy.getDelegate()
     * Retrieves and returns the delegate address for this proxy from the fixed storage position
     * @return the address of the proxied contract
     */
    function getDelegate() public view returns (address delegate) {
        bytes32 delegatePos = storagePositionDelegateTarget;
        assembly {
            delegate := sload(delegatePos)
        }
    }

    /**
     * @dev Sets the proxied contract, i.e. the delegate target of this proxy to the specified address
     * @param _delegateAddress the new address of the proxied contract to which calls are forwarded
     * REVERTS if:
     * - the msg.sender is not the owner
     */
    function setDelegate(address _delegateAddress) external {
        ErrorsLib.revertIf(msg.sender != getOwner(),
            ErrorsLib.UNAUTHORIZED(), "OwnedDelegateUnstructuredProxy.setDelegate", "The msg.sender is not the owner");
        bytes32 delegatePos = storagePositionDelegateTarget;
        assembly {
            sstore(delegatePos, _delegateAddress)
        }
    }

    /**
     * @dev Returns the address of the proxy owner
     * @return the owner's address
     */
    function getOwner() public view returns (address owner) {
        bytes32 ownerPos = storagePositionOwner;
        assembly {
            owner := sload(ownerPos)
        }
    }

}