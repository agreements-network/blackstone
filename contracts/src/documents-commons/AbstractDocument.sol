pragma solidity ^0.5;

import "commons-base/BaseErrors.sol";
import "commons-base/Owned.sol";

import "documents-commons/Document.sol";
import "documents-commons/Documents.sol";

/**
 * @title AbstractDocument
 * @dev Abstract implementation of the Document interface.
 * It contains default implementations of the interface's functions and
 * adds an owner concept as well as an abstract authentication function that
 * allows inheriting contracts to control who is allowed to add versions.
 */
contract AbstractDocument is Document, Owned {

    string name;
    mapping (bytes32 => Documents.DocumentVersion) versions;
    bytes32[] versionKeys;

    /**
     * @dev Creates a new document with the given name
     */
    constructor(string memory _name) public {
        owner = msg.sender;
        name = _name;
    }

    /**
     * @dev Returns the document's name
     */
    function getName() external view returns (string memory) {
        return name;
    }

    /**
     * @dev Adds the specified hash as a new version of the document. The msg.sender is
     * registered as owner and the version creation date is set to now.
     * @param _hash the version hash
     * @return BaseErrors.NO_ERROR, BaseErrors.INSUFFICIENT_PRIVILEGES (as determined by calling canAddVersion(),
     * or BaseErrors.RESOURCE_ALREADY_EXISTS if the version has been added before.
     */
    function addVersion(string calldata _hash) external returns (uint) {
        if (!canAddVersion()) return BaseErrors.INSUFFICIENT_PRIVILEGES();
        if (versions[keccak256(abi.encodePacked(_hash))].creator != address(0)) {
            return BaseErrors.RESOURCE_ALREADY_EXISTS();
        }
        bytes32 key = keccak256(abi.encodePacked(_hash));
        versions[key] = Documents.DocumentVersion(_hash, now, msg.sender);
        versionKeys.push(key);
        return BaseErrors.NO_ERROR();
    }

    /**
     * @dev Returns the address registered as the creator of the specified version hash.
     * @param _hash the desired version hash
     * @return the creator address, or 0x0 if the version does not exist
     */
    function getVersionCreator(string calldata _hash) external view returns (address) {
        return versions[keccak256(abi.encodePacked(_hash))].creator;
    }

    /**
     * @dev Returns the creation date of the specified version hash.
     * @param _hash the desired version hash
     * @return the creation date, or 0 if the version does not exist
     */
    function getVersionCreated(string calldata _hash) external view returns (uint) {
        return versions[keccak256(abi.encodePacked(_hash))].created;
    }

    /**
     * @dev Returns the number of versions of this document
     * @return the number of versions
     */
    function getNumberOfVersions() external view returns (uint) {
        return versionKeys.length;
    }

    /**
     * @dev This function is used within addVersion(string) to verify if the caller is allowed access.
     * This function can be implemented by inheriting contracts to customize the logic underlying that decision.
     * @return true if the caller transaction should be allowed to add a new version, false otherwise
     */
    function canAddVersion() internal view returns (bool);

}