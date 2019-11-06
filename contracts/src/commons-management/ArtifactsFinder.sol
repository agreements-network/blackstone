pragma solidity ^0.5;

/**
 * @title ArtifactsFinder
 * @dev A simple interface for the lookup of smart contract artifacts by ID and version.
 */
interface ArtifactsFinder {

    /**
     * @dev Returns the location and semantic version of the active version of artifact with the given ID.
     * @param _artifactId the ID of the artifact
     * @return location - the address of the smart contract artifact, if it exists
     * @return version - the semantic version of the artifact
     */
    function getArtifact(string calldata _artifactId) external view returns (address location, uint8[3] memory version);

    /**
     * @dev Returns the location of the artifact with the given ID and version.
     * @param _artifactId the ID of the artifact
     * @param _version the semantic version of the artifact
     * @return location - the address of the smart contract artifact, if it exists
     */
    function getArtifactByVersion(string calldata _artifactId, uint8[3] calldata _version) external view returns (address location);

}