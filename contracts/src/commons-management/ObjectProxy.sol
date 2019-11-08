pragma solidity ^0.5;

import "commons-base/ErrorsLib.sol";

import "commons-management/ArtifactsFinder.sol";
import "commons-management/AbstractDelegateProxy.sol";

/**
 * @title ObjectProxy
 * @dev Implementation of a proxy contract that supports unstructured data storage, i.e. leaves the definition and management of data storage to the proxied contract.
 * The data fields required for proxying and delegating calls are stored in reserved storage slots that are extremely unlikely to ever interfere with the structured storage space of the proxied contract.
 */
contract ObjectProxy is AbstractDelegateProxy {

    /**
     * Storage position of the address for the ArtifactsFinder
     */
    bytes32 private constant storagePositionArtifactsFinder = keccak256("AN://contract/storage/artifacts-finder");
    /**
     * Storage position of the object class identifier's length
     */
    bytes32 private constant storagePositionObjectClassLength = keccak256("AN://contract/storage/object-class/length");
    /**
     * Storage position of the object class identifier's value
     */
    bytes32 private constant storagePositionObjectClassValue = keccak256("AN://contract/storage/object-class/value");

    /**
     * @dev Creates a new ObjectProxy with the given address as the proxied contract
     * @param _artifactsFinder the address of a DOUG contract
     * @param _objectClass the identifier for the proxied implementation
     */
    constructor(address _artifactsFinder, string memory _objectClass) public {
        ErrorsLib.revertIf(_artifactsFinder == address(0),
            ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "ObjectProxy.constructor", "_artifactsFinder address must not be empty");
        ErrorsLib.revertIf(bytes(_objectClass).length == 0,
            ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "ObjectProxy.constructor", "_objectClass string must not be empty");
        bytes32 finderPos = storagePositionArtifactsFinder;
        bytes32 classLengthPos = storagePositionObjectClassLength;
        bytes32 classValuePos = storagePositionObjectClassValue;
        assembly {
            sstore(finderPos, _artifactsFinder)
            sstore(classLengthPos, mload(_objectClass)) // size of the string
            sstore(classValuePos, mload(add(_objectClass, 0x20))) // string value
        }
    }

    /**
     * @dev Implements AbstractDelegateProxy.getDelegate()
     * Retrieves and returns the delegate address for this proxy by querying DOUG using the obect class identifier.
     * @return the address of the proxied contract
     */
    function getDelegate() public view returns (address delegate) {
        // Note: we don't check if the ArtifactsFinder address exists, because the constructor guarantees its presence
        (delegate, ) = ArtifactsFinder(getArtifactsFinder()).getArtifact(getObjectClass());
    }

    function getArtifactsFinder() internal view returns (address finderAddress) {
        bytes32 finderPos = storagePositionArtifactsFinder;
        assembly {
            finderAddress := sload(finderPos)
        }
    }

    function getObjectClass() internal view returns (string memory objectClass) {
        bytes32 classLengthPos = storagePositionObjectClassLength;
        bytes32 classValuePos = storagePositionObjectClassValue;
        assembly {
            objectClass := mload(0x40) // free mem storage pointer
            mstore(objectClass, sload(classLengthPos))
            mstore(add(objectClass, 0x20), sload(classValuePos))
            mstore(0x40, add(objectClass, 0x40)) // set the pointer to free memory
        }
    }

}