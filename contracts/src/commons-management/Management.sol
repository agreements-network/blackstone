pragma solidity ^0.5;

/**
 * @title Management Library
 * @dev Library to define data structures used across the management package.
 */
library Management {

    struct Artifact {
        address activeVersion;
        bool exists;
        mapping (address => uint8[3]) versions; //version by location
        mapping (bytes32 => address) locations; //location by version
    }

}