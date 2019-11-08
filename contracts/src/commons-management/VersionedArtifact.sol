pragma solidity ^0.5;

import "commons-standards/ERC165.sol";

/**
 * @title VersionedArtifact Interface
 * @dev Interface contract specifying semantic versioning and comparison functions for a smart contract artifact.
 * This contract replicates the functionality of the commons-base/Versioned contract in order to be able to mix the two versioning characteristics.
 */
contract VersionedArtifact {

    bytes4 public constant ERC165_ID_VERSIONED_ARTIFACT = bytes4(keccak256(abi.encodePacked("getArtifactVersion()")));

    /**
     * @dev Compares this contract's version to the version of the contract at the specified address.
     *
     * @param _other a VersionedArtifact contract to which this contract's version is compared
     * @return 0 (equal), -1 (the other version is lower), or 1 (the other version is higher).
     */
    function compareArtifactVersion(address _other) public view returns (int result);

    /**
     * @dev Compares this contract's version to the specified version.
     *
     * @param _version the version to which this contract's version is compared
     * @return 0 (equal), -1 (the other version is lower), or 1 (the other version is higher).
     */
    function compareArtifactVersion(uint8[3] memory _version) public view returns (int result);

	/**
	 * @dev Returns the major version number
     * @return the major version
	 */
    function getArtifactVersionMajor() external view returns (uint8);

	/**
	 * @dev returns the minor version number
     * @return the minor version
	 */
    function getArtifactVersionMinor() external view returns (uint8);
	
    /**
	 * @dev returns the patch version number
     * @return the patch version
	 */
    function getArtifactVersionPatch() external view returns (uint8);

    /**
     * @dev Returns the version as 3-digit array
     * @return the version as unit8[3]
     */
    function getArtifactVersion() external view returns (uint8[3] memory);
}