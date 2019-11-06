pragma solidity ^0.5;

import "commons-base/ErrorsLib.sol";
import "commons-base/SystemOwned.sol";

import "commons-management/Management.sol";
import "commons-management/AbstractDelegateTarget.sol";
import "commons-management/ArtifactsRegistry.sol";

/**
 * @title DefaultArtifactRegistry
 * @dev Default implementation of the ArtifactRegistry interface
 */
contract DefaultArtifactsRegistry is ArtifactsRegistry, AbstractDelegateTarget, SystemOwned {

    mapping (string => Management.Artifact) artifacts;
    string[] artifactIds;

	/**
	 * @dev Initializes this DefaultArtifactsRegistry by setting the systemOwner to the msg.sender
     * This function replaces the constructor as a means to set storage variables.
	 * REVERTS if:
	 * - the contract had already been initialized before
	 */
	function initialize()
		external
		pre_post_initialize
	{
        systemOwner = msg.sender;
    }

    /**
     * @dev Registers an artifact with the provided information.
     * REVERTS if:
     * - the artifact ID or location are empty
     * - the artifact ID and version are already registered with a different address location
     * @param _artifactId the ID of the artifact
     * @param _artifactAddress the address of the smart contract artifact
     * @param _version the semantic version of the artifact
     * @param _activeVersion whether this version of the artifact should be tracked as the active version
     */
    function registerArtifact(string calldata _artifactId, address _artifactAddress, uint8[3] calldata _version, bool _activeVersion)
        external
        pre_onlyBySystemOwner
    {
        ErrorsLib.revertIf(bytes(_artifactId).length == 0 || _artifactAddress == address(0),
            ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultArtifactsRegistry.registerArtifact", "_artifactId and _artifactAddress must not be empty");
        address existingLocationForVersion = artifacts[_artifactId].locations[keccak256(abi.encodePacked(_version))];
        ErrorsLib.revertIf(existingLocationForVersion != address(0) && existingLocationForVersion != _artifactAddress,
            ErrorsLib.OVERWRITE_NOT_ALLOWED(), "DefaultArtifactsRegistry.registerArtifact", "An artifact with the same ID and version, but a different address is already registered");
        // if this artifact is a previously unknown entry, we need to register its existence
        if (!artifacts[_artifactId].exists) {
            artifactIds.push(_artifactId);
            artifacts[_artifactId].exists = true;
        }
        // if existingLocationForVersion is not empty, that means this exact same ID/location/version combination is already registered and we don't need to do anything
        if (existingLocationForVersion == address(0)) {
            artifacts[_artifactId].locations[keccak256(abi.encodePacked(_version))] = _artifactAddress;
            artifacts[_artifactId].versions[_artifactAddress] = _version;
            if (_activeVersion) {
                address existingActiveLocation = artifacts[_artifactId].activeVersion;
                if (existingActiveLocation != address(0) && existingActiveLocation != _artifactAddress) {
                    // emit change event for other active version that is being replaced
                    emit LogArtifactActivation(EVENT_ID_ARTIFACTS, _artifactId, existingActiveLocation, false);
                }
                artifacts[_artifactId].activeVersion = _artifactAddress;
            }
            emit LogArtifactCreation(EVENT_ID_ARTIFACTS, _artifactId, _artifactAddress, _version[0], _version[1], _version[2], _activeVersion);
        }
    }

    /**
     * @dev Sets the specified artifact and version to be tracked as the active version.
     * REVERTS if:
     * - the specified artifact ID and version don't exist in this ArtifactsRegistry
     * @param _artifactId the ID of the artifact
     * @param _version the semantic version of the artifact
     */
    function setActiveVersion(string calldata _artifactId, uint8[3] calldata _version)
        external
        pre_onlyBySystemOwner
    {
        address current = artifacts[_artifactId].locations[keccak256(abi.encodePacked(_version))];
        ErrorsLib.revertIf(current == address(0),
            ErrorsLib.RESOURCE_NOT_FOUND(), "DefaultArtifactsRegistry.setActiveVersion", "The specified ID and version is not registered");
        address existingActiveLocation = artifacts[_artifactId].activeVersion;
        if (existingActiveLocation != address(0) && existingActiveLocation != current) {
            emit LogArtifactActivation(EVENT_ID_ARTIFACTS, _artifactId, existingActiveLocation, false);
        }
        artifacts[_artifactId].activeVersion = current;
        emit LogArtifactActivation(EVENT_ID_ARTIFACTS, _artifactId, existingActiveLocation, true);
    }

    /**
     * @dev Returns the number of artifacts registered in this ArtifactsRegistry irrespective of how many version of an artifact exist.
     * @return the number of unique artifact IDs
     */
    function getNumberOfArtifacts() external view returns (uint) {
        return artifactIds.length;
    }

    /**
     * @dev Implements ArtifactsFinder.getArtifact(string)
     */
    function getArtifact(string calldata _artifactId) external view returns (address location, uint8[3] memory version) {
        location = artifacts[_artifactId].activeVersion;
        version = artifacts[_artifactId].versions[location];
    }

    /**
     * @dev Implements ArtifactsFinder.getArtifactByVersion(string,uint8[3])
     */
    function getArtifactByVersion(string calldata _artifactId, uint8[3] calldata _version) external view returns (address location) {
        location = artifacts[_artifactId].locations[keccak256(abi.encodePacked(_version))];
    }
}
