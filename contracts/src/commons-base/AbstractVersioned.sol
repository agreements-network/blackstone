pragma solidity ^0.5;

import "commons-base/Versioned.sol";

/**
 * @title AbstractVersioned
 * @dev Abstract implementation of the Versioned interface
 */
contract AbstractVersioned is Versioned {

    uint8[3] semanticVersion;

    /**
     * @dev Compares this contract's version to the version of the contract at the specified address.
     *
     * @param _other the address to which this contract is compared
     * @return 0 (equal), -1 (the other version is lower), or 1 (the other version is higher).
     */
    function compareVersion(address _other) public view returns (int result) {
        result = compareVersions(semanticVersion, Versioned(_other).getVersion());
    }

    /**
     * @dev Compares this contract's version to the specified version.
     *
     * @param _version the version to which this contract's version is compared
     * @return 0 (equal), -1 (the other version is lower), or 1 (the other version is higher).
     */
    function compareVersion(uint8[3] memory _version) public view returns (int result) {
		result = compareVersions(semanticVersion, _version);
    }

    /**
     * @dev Compares the two specified versions.
     *
     * @param _a version A
     * @param _b version B
     * @return 0 (equal), -1 (B version is lower), or 1 (B version is higher).
     * //TODO move to a math library
     */
	function compareVersions(uint8[3] memory _a, uint8[3] memory _b) private pure returns (int result) {
        result = compareUint8Values(_a[0], _b[0]);
        if (result != 0) { return result; }
        result = compareUint8Values(_a[1], _b[1]);
        if (result != 0) { return result; }
        result = compareUint8Values(_a[2], _b[2]);
	}
	
    /**
     * @dev returns 0 (equal), -1 (b is lower), or 1 (b is higher).
     * //TODO move to a math library
     */
    function compareUint8Values(uint8 _a, uint8 _b) private pure returns (int) {
        if (_b == _a) { return 0; }
        else if (_b < _a) { return -1; }
        else { return 1; }
    }

	/**
	 * @dev Returns the major version number
     * @return the major version
	 */
    function getVersionMajor() external view returns (uint8) { return semanticVersion[0]; }

	/**
	 * @dev returns the minor version number
     * @return the minor version
	 */
    function getVersionMinor() external view returns (uint8) { return semanticVersion[1]; }
	/**
	 * @dev returns the patch version number
     * @return the patch version
	 */
    function getVersionPatch() external view returns (uint8) { return semanticVersion[2]; }

    /**
     * @dev Returns the version as 3-digit array
     * @return the version as unit8[3]
     */
    function getVersion() external view returns (uint8[3] memory) {
    	return semanticVersion;
    }
}
