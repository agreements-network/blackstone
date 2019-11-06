pragma solidity ^0.5;

/**
 * @title ArrayUtils Library
 * @dev Library containing utility functions for arrays of primitive Solidity data types.
 */
library ArrayUtilsLib {

	/**
	 * @dev Returns whether the specified value is present in the given array
	 * @param _list the array
	 * @param _value the value
	 * @return true if the value is found in the array, false otherwise
	 */
    function contains(bytes32[] memory _list, bytes32 _value) public pure returns (bool) {
	    for (uint i=0; i<_list.length; i++) {
	        if (_list[i] == _value) return true;
	    }
	    return false;
    }

	/**
	 * @dev Returns whether the specified value is present in the given array
	 * @param _list the array
	 * @param _value the value
	 * @return true if the value is found in the array, false otherwise
	 */
    function contains(address[] memory _list, address _value) public pure returns (bool) {
	    for (uint i=0; i<_list.length; i++) {
	        if (_list[i] == _value) return true;
	    }
	    return false;
    }

	/**
	 * @dev Returns whether the specified value is present in the given array
	 * @param _list the array
	 * @param _value the value
	 * @return true if the value is found in the array, false otherwise
	 */
    function contains(uint[] memory _list, uint _value) public pure returns (bool) {
	    for (uint i=0; i<_list.length; i++) {
	        if (_list[i] == _value) return true;
	    }
	    return false;
    }

	/**
	 * @dev Returns whether the specified value is present in the given array
	 * @param _list the array
	 * @param _value the value
	 * @return true if the value is found in the array, false otherwise
	 */
    function contains(int[] memory _list, int _value) public pure returns (bool) {
	    for (uint i=0; i<_list.length; i++) {
	        if (_list[i] == _value) return true;
	    }
	    return false;
    }

	/**
	 * @dev Determines whether the given array contains the same value more than once.
	 * @param _list the array
	 * @return true if at least one value in the array is not unique
	 */
	function hasDuplicates(bytes32[] memory _list) public pure returns (bool) {
	    for (uint i=0; i<_list.length; i++) {
			for (uint j=i+1; j<_list.length; j++) {
		        if (_list[i] == _list[j]) return true;
			}
	    }
		return false;
	}

	/**
	 * @dev Determines whether the given array contains the same value more than once.
	 * @param _list the array
	 * @return true if at least one value in the array is not unique
	 */
	function hasDuplicates(address[] memory _list) public pure returns (bool) {
	    for (uint i=0; i<_list.length; i++) {
			for (uint j=i+1; j<_list.length; j++) {
		        if (_list[i] == _list[j]) return true;
			}
	    }
		return false;
	}

	/**
	 * @dev Determines whether the given array contains the same value more than once.
	 * @param _list the array
	 * @return true if at least one value in the array is not unique
	 */
	function hasDuplicates(uint[] memory _list) public pure returns (bool) {
	    for (uint i=0; i<_list.length; i++) {
			for (uint j=i+1; j<_list.length; j++) {
		        if (_list[i] == _list[j]) return true;
			}
	    }
		return false;
	}

	/**
	 * @dev Determines whether the given array contains the same value more than once.
	 * @param _list the array
	 * @return true if at least one value in the array is not unique
	 */
	function hasDuplicates(int[] memory _list) public pure returns (bool) {
	    for (uint i=0; i<_list.length; i++) {
			for (uint j=i+1; j<_list.length; j++) {
		        if (_list[i] == _list[j]) return true;
			}
	    }
		return false;
	}

}