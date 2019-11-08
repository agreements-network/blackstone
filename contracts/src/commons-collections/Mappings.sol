pragma solidity ^0.5;

import "commons-base/BaseErrors.sol";

/**
 * @title Mappings Library Data Model
 * @dev This library defines the data structures and internal functions to be used in conjunction with the MappingsLib library.
 * This library is not intended to be deployed, but only serves a compile-time dependency.
 */
library Mappings {

    /**
     * ---------> Map Types <---------
     */

    /// @dev Bytes32 to Address
    struct Bytes32AddressMap {
        mapping (bytes32 => AddressElement) rows;
        bytes32[] keys;
    }

    /// @dev Bytes32 to Address
    struct Bytes32StringMap {
        mapping (bytes32 => StringElement) rows;
        bytes32[] keys;
    }

    /// @dev Bytes32 to Address[]
    struct Bytes32AddressArrayMap {
        mapping (bytes32 => AddressArrayElement) rows;
        bytes32[] keys;
    }

    /// @dev Bytes32 to Bytes32
    struct Bytes32Bytes32Map {
        mapping (bytes32 => Bytes32Element) rows;
        bytes32[] keys;
    }

    /// @dev Bytes32 to Uint
    struct Bytes32UintMap {
        mapping (bytes32 => UintElement) rows;
        bytes32[] keys;
    }

    /// @dev Address to Bytes32
    struct AddressBytes32Map {
        mapping (address => Bytes32Element) rows;
        address[] keys;
    }

    /// @dev Address to String
    struct AddressStringMap {
        mapping (address => StringElement) rows;
        address[] keys;
    }

    /// @dev Address to Bool
    struct AddressBoolMap {
        mapping (address => BoolElement) rows;
        address[] keys;
    }

    /// @dev Address to Bytes32
    struct AddressBytes32ArrayMap {
        mapping (address => Bytes32ArrayElement) rows;
        address[] keys;
    }

    /// @dev Address to Address
    struct AddressAddressMap {
        mapping (address => AddressElement) rows;
        address[] keys;
    }

    /// @dev Address to Address[]
    struct AddressAddressArrayMap {
        mapping (address => AddressArrayElement) rows;
        address[] keys;
    }

    /// @dev Uint to Address
    struct UintAddressMap {
        mapping (uint => AddressElement) rows;
        uint[] keys;
    }

    /// @dev Uint to Bytes32[]
    struct UintBytes32ArrayMap {
        mapping (uint => Bytes32ArrayElement) rows;
        uint[] keys;
    }

    /// @dev Uint to Address[]
    struct UintAddressArrayMap {
        mapping (uint => AddressArrayElement) rows;
        uint[] keys;
    }

    /// @dev String to Address
    struct StringAddressMap {
        mapping (string => AddressElement) rows;
        string[] keys;
    }

    /**
     * ---------> Value Element Types <---------
     */

    /// @dev A value element for address
    struct AddressElement {
        uint keyIdx;
        address value;
        bool exists;
    }

    /// @dev A value element for string
    struct StringElement {
        uint keyIdx;
        string value;
        bool exists;
    }

    /// @dev A value element for bytes32
    struct Bytes32Element {
        uint keyIdx;
        bytes32 value;
        bool exists;
    }

    /// @dev A value element for bool
    struct BoolElement {
        uint keyIdx;
        bool value;
        bool exists;
    }

    /// @dev A value element for uint
    struct UintElement {
        uint keyIdx;
        uint value;
        bool exists;
    }

    /// @dev A value element for address[]
    struct AddressArrayElement {
        uint keyIdx;
        address[] value;
        bool exists;
    }

    /// @dev A value element for bytes32[]
    struct Bytes32ArrayElement {
        uint keyIdx;
        bytes32[] value;
        bool exists;
    }

    /**
     * ---------> Internal Type Functions <---------
     * These functions operate on generic data types from the data model that are passed. Structs and dynamic arrays are passed as references,
     * thus can be modified (https://solidity.readthedocs.io/en/develop/contracts.html#libraries).
     */

    /**
     * @dev Returns the key from the given keys array at the specified index.
     * @param _keys the keys
     * @param _index the index
     * @return (BaseErrors.NO_ERROR(), key) or (BaseErrors.INDEX_OUT_OF_BOUNDS(), "")
     */
    function keyAtIndex(bytes32[] memory _keys, uint _index) internal pure returns (uint, bytes32) {
        if(_keys.length > 0 && _index < _keys.length) {
            return (BaseErrors.NO_ERROR(), _keys[_index]);
        }
        return (BaseErrors.INDEX_OUT_OF_BOUNDS(), "");
    }

    /**
     * @dev Returns the key from the given keys struct at the specified index.
     * @param _keys the keys
     * @param _index the index
     * @return (BaseErrors.NO_ERROR(), key) or (BaseErrors.INDEX_OUT_OF_BOUNDS(), 0x0)
     */
    function keyAtIndex(address[] memory _keys, uint _index) internal pure returns (uint, address) {
        if(_keys.length > 0 && _index < _keys.length) {
            return (BaseErrors.NO_ERROR(), _keys[_index]);
        }
        return (BaseErrors.INDEX_OUT_OF_BOUNDS(), address(0));
    }

    /**
     * @dev Returns the key from the given keys struct at the specified index.
     * @param _keys the keys struct internal type
     * @param _index the index
     * @return (BaseErrors.NO_ERROR(), key) or (BaseErrors.INDEX_OUT_OF_BOUNDS(), uint(-1))
     */
    function keyAtIndex(uint[] memory _keys, uint _index) internal pure returns (uint, uint) {
        if(_keys.length > 0 && _index < _keys.length) {
            return (BaseErrors.NO_ERROR(), _keys[_index]);
        }
        return (BaseErrors.INDEX_OUT_OF_BOUNDS(), uint(-1));
    }

    /**
     * @dev Returns the key from the given keys array at the specified index.
     * @param _keys the keys
     * @param _index the index
     * @return (BaseErrors.NO_ERROR(), key) or (BaseErrors.INDEX_OUT_OF_BOUNDS(), "")
     */
    function keyAtIndex(string[] memory _keys, uint _index) internal pure returns (uint, string memory) {
        if(_keys.length > 0 && _index < _keys.length) {
            return (BaseErrors.NO_ERROR(), _keys[_index]);
        }
        return (BaseErrors.INDEX_OUT_OF_BOUNDS(), "");
    }

    /**
     * @dev Deletes the element from the specified array at the given index.
     * @dev if the removed element was NOT the last entry in the array, the created void spot is filled by
     * moving the last element of the array into the position. In that case the key of that element is returned.
     * @param _array the keys
     * @param _index the index position to delete
     * @return an empty bytes32 or the key of the element that was shuffled.
     */
    function deleteInKeys(bytes32[] storage _array, uint _index) internal returns (bytes32 swapKey) {
        uint lastPos = _array.length - 1;
        if (_index != lastPos) {
         swapKey = _array[lastPos];
         _array[_index] = swapKey;
        }
        _array.length--;
    }

    /**
     * @dev Deletes the element from the specified array at the given index.
     * @dev if the removed element was NOT the last entry in the array, the created void spot is filled by
     * moving the last element into the position. In that case the key of that element is returned.
     * @param _array the keys
     * @param _index the index position to delete
     * @return an empty address or the key of the element that was shuffled.
     */
    function deleteInKeys(address[] storage _array, uint _index) internal returns (address swapKey) {
        uint lastPos = _array.length - 1;
        if (_index != lastPos) {
         swapKey = _array[lastPos];
         _array[_index] = swapKey;
        }
        _array.length--;
    }

    /**
     * @dev Deletes the element from the specified array at the given index.
     * @dev if the removed element was NOT the last entry in the array, the created void spot is filled by
     * moving the last element into the position. In that case the key of that element is returned.
     * @param _array the keys
     * @param _index the index position to delete
     * @return a uint(-1) or the key of the element that was shuffled.
     */
    function deleteInKeys(uint[] storage _array, uint _index) internal returns (uint swapKey) {
        swapKey = uint(-1);
        uint lastPos = _array.length - 1;
        if (_index != lastPos) {
         swapKey = _array[lastPos];
         _array[_index] = swapKey;
        }
        _array.length--;
    }

    /**
     * @dev Deletes the element from the specified array at the given index.
     * @dev if the removed element was NOT the last entry in the array, the created void spot is filled by
     * moving the last element of the array into the position. In that case the key of that element is returned.
     * @param _array the keys
     * @param _index the index position to delete
     * @return an empty bytes32 or the key of the element that was shuffled.
     */
    function deleteInKeys(string[] storage _array, uint _index) internal returns (string memory swapKey) {
        uint lastPos = _array.length - 1;
        if (_index != lastPos) {
         swapKey = _array[lastPos];
         _array[_index] = swapKey;
        }
        _array.length--;
    }

}