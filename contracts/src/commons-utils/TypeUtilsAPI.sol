pragma solidity ^0.4.23;

/**
 * @title TypeUtils Library Interface
 * @dev Library containing various conversion and other utility functions for primitive Solidity data types.
 */
library TypeUtilsAPI {
	
    /**
     * @dev Returns the length of the alphanumeric content of the bytes32, i.e. the number of non-empty bytes
     * @param self bytes32
     * @return the length
     */
    function contentLength(bytes32 self) public pure returns (uint);

    /**
     * @dev Converts an unsigned integer to its string representation.
     * @param v The number to be converted.
     * @return the bytes32 representation
     */
    function toBytes32(uint v) public pure returns (bytes32 ret);

	/**
	 * @dev Checks if the given bytes32 is empty.
	 * @param _value the value to check
	 * @return true if empty, false otherwise
	 */	
	function isEmpty(bytes32 _value) public pure returns (bool);

    /**
     * @dev Converts bytes32 to string
     * @param x bytes32
     * @return the string representation
     */
    function toString (bytes32 x) public pure returns (string);
    
    /**
     * @dev Converts the given string to bytes32. If the string is longer than
     * 32 byte-sized characters (depends on encoding and character-set), it will be truncated.
     * @param s a string
     * @return the bytes32 representation
     */
    function toBytes32(string s) public pure returns (bytes32 result);

}