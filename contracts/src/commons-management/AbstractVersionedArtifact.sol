pragma solidity ^0.5;

import "commons-standards/AbstractERC165.sol";
import "commons-management/VersionedArtifact.sol";

/**
 * @title AbstractVersionedArtifact
 * @dev Abstract implementation of the VersionedArtifact interface
 */
contract AbstractVersionedArtifact is AbstractERC165, VersionedArtifact {

    uint8[3] artifactVersion;

    /**
     * @dev Constructor
     */
    constructor(uint8 _major, uint8 _minor, uint8 _patch) internal {
        artifactVersion[0] = _major;
        artifactVersion[1] = _minor;
        artifactVersion[2] = _patch;
        addInterfaceSupport(ERC165_ID_VERSIONED_ARTIFACT);
    }

    /**
     * @dev Compares this contract's version to the version of the contract at the specified address.
     *
     * @param _other the address to which this contract is compared
     * @return 0 (equal), -1 (the other version is lower), or 1 (the other version is higher).
     */
    function compareArtifactVersion(address _other) public view returns (int result) {
        result = compareArtifactVersions(artifactVersion, VersionedArtifact(_other).getArtifactVersion());
    }

    /**
     * @dev Compares this contract's version to the specified version.
     *
     * @param _version the version to which this contract's version is compared
     * @return 0 (equal), -1 (the other version is lower), or 1 (the other version is higher).
     */
    function compareArtifactVersion(uint8[3] memory _version) public view returns (int result) {
		result = compareArtifactVersions(artifactVersion, _version);
    }

    /**
     * @dev Compares the two specified versions.
     *
     * @param _a version A
     * @param _b version B
     * @return 0 (equal), -1 (B version is lower), or 1 (B version is higher).
     * //TODO move to a math library
     */
	function compareArtifactVersions(uint8[3] memory _a, uint8[3] memory _b) private pure returns (int result) {
        result = compareUint8ArtifactValues(_a[0], _b[0]);
        if (result != 0) { return result; }
        result = compareUint8ArtifactValues(_a[1], _b[1]);
        if (result != 0) { return result; }
        result = compareUint8ArtifactValues(_a[2], _b[2]);
	}
	
    /**
     * @dev returns 0 (equal), -1 (b is lower), or 1 (b is higher).
     * //TODO move to a math library
     */
    function compareUint8ArtifactValues(uint8 _a, uint8 _b) private pure returns (int) {
        if (_b == _a) { return 0; }
        else if (_b < _a) { return -1; }
        else { return 1; }
    }

	/**
	 * @dev Returns the major version number
     * @return the major version
	 */
    function getArtifactVersionMajor() external view returns (uint8) { return artifactVersion[0]; }

	/**
	 * @dev returns the minor version number
     * @return the minor version
	 */
    function getArtifactVersionMinor() external view returns (uint8) { return artifactVersion[1]; }
	/**
	 * @dev returns the patch version number
     * @return the patch version
	 */
    function getArtifactVersionPatch() external view returns (uint8) { return artifactVersion[2]; }

    /**
     * @dev Returns the version as 3-digit array
     * @return the version as unit8[3]
     */
    function getArtifactVersion() external view returns (uint8[3] memory) {
    	return artifactVersion;
    }
}
