pragma solidity ^0.4.23;

/**
 * @title TypeUtils Library Implementation
 * @dev Library containing various conversion and other utility functions for primitive Solidity data types.
 * Note: functions with dynamic types (e.g. string, bytes) MUST be 'internal', so the current situation creates non-uniformity. 
 */
library TypeUtilsImpl {
	
    /**
     * 3RD PARTY - https://github.com/Arachnid/solidity-stringutils
     * LICENSE: Apache 2.0 - https://github.com/Arachnid/solidity-stringutils/blob/master/LICENSE
     * @dev Returns the length of the alphanumeric content of the bytes32, i.e. the number of non-empty bytes
     * @param self bytes32
     * @return the length
     */
    function contentLength(bytes32 self) public pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (self & 0xffffffffffffffffffffffffffffffff == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (self & 0xffffffffffffffff == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (self & 0xffffffff == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (self & 0xffff == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (self & 0xff == 0) {
            ret += 1;
        }
        return 32 - ret;
    }
    
   	/**
	 * @dev Checks if the given bytes32 is empty, i.e. does not have any content.
	 * @param _value the value to check
	 * @return true if empty, false otherwise
	 */	
    function isEmpty(bytes32 _value) public pure returns (bool) {
    	return contentLength(_value) == 0;
    }

    /**
     * 3RD PARTY - https://github.com/pipermerriam/ethereum-string-utils
     * LICENSE: MIT - https://github.com/pipermerriam/ethereum-string-utils/blob/master/LICENSE
     * @dev Converts an unsigned integer to its string representation.
     * @param v The number to be converted.
     * @return the bytes32 representation
     */
    function toBytes32(uint v) public pure returns (bytes32 ret) {
        if (v == 0) {
            ret = '0';
        }
        else {
            while (v > 0) {
                ret = bytes32(uint(ret) / (2 ** 8));
                ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                v /= 10;
            }
        }
        return ret;
    }

    /**
     * @dev Converts bytes32 to string
     * @param x bytes32
     * @return the string representation
     */
    function toString (bytes32 x) public pure returns (string) {
	    bytes memory bytesString = new bytes(32);
	    uint charCount = 0;
	    for (uint j = 0; j < 32; j++) {
	        byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
	        if (char != 0) {
	            bytesString[charCount] = char;
	            charCount++;
	        }
	    }
	    bytes memory bytesStringTrimmed = new bytes(charCount);
	    for (j = 0; j < charCount; j++) {
	        bytesStringTrimmed[j] = bytesString[j];
	    }
	    return string(bytesStringTrimmed);
    }

    /**
     * @dev Converts the given string to bytes32. If the string is longer than
     * 32 byte-sized characters (depends on encoding and character-set), it will be truncated.
     * @param s a string
     * @return the bytes32 representation
     */
    function toBytes32(string s) public pure returns (bytes32 result) {
	    assembly {
    	    result := mload(add(s, 32))
    	}
    }

}