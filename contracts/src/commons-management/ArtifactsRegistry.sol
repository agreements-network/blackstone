pragma solidity ^0.5.12;

import "commons-base/SystemOwnerTransferable.sol";

import "commons-management/ArtifactsFinder.sol";

/**
 * @title ArtifactsRegistry
 * @dev A place to store smart contract artifacts by name and version and track the active version.
 */
contract ArtifactsRegistry is ArtifactsFinder, SystemOwnerTransferable {

    event LogArtifactCreation(bytes32 indexed eventId, string artifactId, address artifactAddress, uint versionMajor, uint versionMinor, uint versionPatch, bool activeVersion);
    event LogArtifactActivation(bytes32 indexed eventId, string artifactId, address artifactAddress, bool activeVersion);

    bytes32 public constant EVENT_ID_ARTIFACTS = "AN://artifacts";

    /**
     * @dev Registers an artifact with the provided information.
     * @param _artifactId the ID of the artifact
     * @param _artifactAddress the address of the smart contract artifact
     * @param _version the semantic version of the artifact
     * @param _activeVersion whether this version of the artifact should be tracked as the active version
     */
    function registerArtifact(string calldata _artifactId, address _artifactAddress, uint8[3] calldata _version, bool _activeVersion) external;

    /**
     * @dev Sets the specified artifact and version to be tracked as the active version
     * @param _artifactId the ID of the artifact
     * @param _version the semantic version of the artifact
     */
    function setActiveVersion(string calldata _artifactId, uint8[3] calldata _version) external;

    /**
     * @dev Returns the number of artifacts registered in this ArtifactsRegistry irrespective of how many version of an artifact exist.
     * @return the number of unique artifact IDs
     */
    function getNumberOfArtifacts() external view returns (uint);

}