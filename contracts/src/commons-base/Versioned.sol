pragma solidity ^0.5;

/**
 * @title Versioned Interface
 * @dev Interface contract specifying semantic versioning and comparison functions.
 */
contract Versioned {

    /**
     * @dev Compares this contract's version to the version of the contract at the specified address.
     *
     * @param _other a Versioned contract to which this contract's version is compared
     * @return 0 (equal), -1 (the other version is lower), or 1 (the other version is higher).
     */
    function compareVersion(address _other) public view returns (int result);

    /**
     * @dev Compares this contract's version to the specified version.
     *
     * @param _version the version to which this contract's version is compared
     * @return 0 (equal), -1 (the other version is lower), or 1 (the other version is higher).
     */
    function compareVersion(uint8[3] memory _version) public view returns (int result);

	/**
	 * @dev Returns the major version number
     * @return the major version
	 */
    function getVersionMajor() external view returns (uint8);

	/**
	 * @dev returns the minor version number
     * @return the minor version
	 */
    function getVersionMinor() external view returns (uint8);
	
    /**
	 * @dev returns the patch version number
     * @return the patch version
	 */
    function getVersionPatch() external view returns (uint8);

    /**
     * @dev Returns the version as 3-digit array
     * @return the version as unit8[3]
     */
    function getVersion() external view returns (uint8[3] memory);
}