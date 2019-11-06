pragma solidity ^0.5;

/**
 * @title Document Interface
 * @dev Interface describing the behavior of a versioned document.
 */
interface Document {

    /**
     * @dev Returns the document's name
     * @return the name
     */
    function getName() external view returns (string memory);

    /**
     * @dev Registers a new document version
     * @param _hash the hash representing the version being added
     * @return an error code in case of problems
     */
    function addVersion(string calldata _hash) external returns (uint);

    /**
     * @dev Returns the account of the entity that created the specified version hash
     * @param _hash the desired version
     * @return the creator's address, if the version exists
     */
    function getVersionCreator(string calldata _hash) external view returns (address);

    /**
     * @dev Returns the creation date of the specified version hash
     * @param _hash the desired version
     * @return the creation date, if the version exists
     */
    function getVersionCreated(string calldata _hash) external view returns (uint);

    /**
     * @dev Returns the number of versions of this document
     * @return the number of versions
     */
    function getNumberOfVersions() external view returns (uint);

}