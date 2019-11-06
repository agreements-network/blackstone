pragma solidity ^0.5;

// Libraries
import "commons-base/BaseErrors.sol";
import "commons-utils/ArrayUtilsLib.sol";
import "commons-utils/TypeUtilsLib.sol";

import "commons-collections/Mappings.sol";

/**
 * @title Mappings API Library
 * @dev Public API to offer convenience around collections based on Mappings by supporting
 * easier key and value access as well as iteration capabilities.
 * 
 * The following Mapping combinations are currently available:
 * - Bytes32AddressMap:      bytes32 -> address
 * - Bytes32StringMap:       bytes32 -> string
 * - Bytes32UintMap:         bytes32 -> uint
 * - Bytes32AddressArrayMap: bytes32 -> address[]
 * - Bytes32Bytes32Map:      bytes32 -> bytes32 
 * - AddressBytes32Map:      address -> bytes32
 * - AddressStringMap:       address -> string
 * - AddressBoolMap:         address -> bool
 * - AddressBytes32ArrayMap: address -> bytes32[]
 * - AddressAddressMap:      address -> address
 * - AddressAddressArrayMap: address -> address[]
 * - UintAddressMap:         uint    -> address
 * - UintBytes32ArrayMap:    uint    -> bytes32[]
 * - UintAddressArrayMap:    uint    -> address[]
 *
 * Mappings that contain arrays as values possess additional access functions to add/remove values from the inner arrays.
 */
library MappingsLib {

	using TypeUtilsLib for bytes32;
    using ArrayUtilsLib for bytes32[];
    using ArrayUtilsLib for address[];
    
    /**
     * ---------> Bytes32AddressMap <---------
     */

    /**
     * @dev Inserts the given value at the specified key in the provided map, but only
     * if the key does not exist, yet. The `insert` function essentially behaves like a database insert
     * in that it avoids entering duplicate keys. In most cases you'd want to use `insertOrUpdate(...)`
     *
     * @param _map the AddressMap
     * @param _key the key
     * @param _value the value
     * @return BaseErrors.NO_ERROR or BaseErrors.RESOURCE_ALREADY_EXISTS
     */
    function insert(Mappings.Bytes32AddressMap storage _map, bytes32 _key, address _value) public returns (uint)
    {
        if (_map.rows[_key].exists) { return BaseErrors.RESOURCE_ALREADY_EXISTS(); }
        insertOrUpdate(_map, _key, _value);
        return BaseErrors.NO_ERROR();
    }

    /**
     * @dev Inserts or updates the given value at the specified key in the provided map.
     *
     * @param _map the AddressMap
     * @param _key the key
     * @param _value the value
     * @return the size of the map after the operation
     */
    function insertOrUpdate(Mappings.Bytes32AddressMap storage _map, bytes32 _key, address _value) public returns (uint)
    {
        if (_map.rows[_key].exists) {
            _map.rows[_key].value = _value;
        } else {
            _map.rows[_key].keyIdx = (_map.keys.push(_key)-1);
            _map.rows[_key].value = _value;
            _map.rows[_key].exists = true;
        }
        return _map.keys.length;
    }

    /**
     * @dev Removes the entry registered at the specified key in the provided map.
     * @dev the _map.keys array may get re-ordered by this operation: unless the removed entry was
     * the last element in the map's keys, the last key will be moved into the void position created
     * by the removal.
     *
     * @param _map the AddressMap
     * @param _key the key
     * @return BaseErrors.NO_ERROR or BaseErrors.RESOURCE_NOT_FOUND.
     */
    function remove(Mappings.Bytes32AddressMap storage _map, bytes32 _key) public returns (uint) {
        if (!_map.rows[_key].exists) { return BaseErrors.RESOURCE_NOT_FOUND(); }
        bytes32 swapKey = Mappings.deleteInKeys(_map.keys, _map.rows[_key].keyIdx);
        if (swapKey.contentLength() > 0) {
            _map.rows[swapKey].keyIdx = _map.rows[_key].keyIdx;
        }
        delete _map.rows[_key];
        return BaseErrors.NO_ERROR();
     }

    /**
     * @dev Removes all entries stored in the map.
     * @param _map the map
     * @return the number of removed entries
     */
    function clear(Mappings.Bytes32AddressMap storage _map) public returns (uint) {
        uint l = _map.keys.length;
        for(uint i = 0; i < l; i++) {
            delete _map.rows[_map.keys[i]];
        }
        _map.keys.length = 0;
        return l;
    }

    /**
     * @dev Convenience function to return the row[_key].exists value.
     * @return true if the map contains valid values at the specified key, false otherwise.
     */
    function exists(Mappings.Bytes32AddressMap storage _map, bytes32 _key) public view returns (bool) {
        return _map.rows[_key].exists;
    }

    /**
     * @return the value registered at the specified key, or 0x0 if it doesn't exist
     */
    function get(Mappings.Bytes32AddressMap storage _map, bytes32 _key) public view returns (address) {
        return _map.rows[_key].value;
    }

    /**
     * @return the index of the given key or int_constant uint(-1) if the key does not exist
     */
    function keyIndex(Mappings.Bytes32AddressMap storage _map, bytes32 _key) public view returns (uint) {
        if (!_map.rows[_key].exists) { return uint(-1); }
        return _map.rows[_key].keyIdx;
    }

    /**
     * @dev Retrieves the key at the given index, if it exists.
     *
     * @param _map the map
     * @param _index the index
     * @return (BaseErrors.NO_ERROR(), key) or (BaseErrors.INDEX_OUT_OF_BOUNDS(), "")
     */
    function keyAtIndex(Mappings.Bytes32AddressMap storage _map, uint _index) public view returns (uint, bytes32) {
        return Mappings.keyAtIndex(_map.keys, _index);
    }

    /**
     * @dev Retrieves the key at the given index position and the index of the next artifact.
     *
     * @param _map the map
     * @param _index the index
     * @return error BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS()
     * @return key the key or ""
     * @return nextindex the next index if there is one or 0
     */
    function keyAtIndexHasNext(Mappings.Bytes32AddressMap storage _map, uint _index) public view returns (uint error, bytes32 key, uint nextIndex) {
        (error, key) = keyAtIndex(_map, _index);
        if (++_index < _map.keys.length) {
            nextIndex = _index;
        }
    }

    /**
     * @dev Retrieves the value at the given index position and the index of the next address.
     *
     * @param _map the map
     * @param _index the index
     * @return BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS(), value, and nextIndex
     */
    function valueAtIndexHasNext(Mappings.Bytes32AddressMap storage _map, uint _index) public view returns (uint error, address value, uint nextIndex) {
        bytes32 key;
        (error, key, nextIndex) = keyAtIndexHasNext(_map, _index);
        if (error == BaseErrors.NO_ERROR()) {
            value = get(_map, key);
        }
    }


    /**
     * ---------> Bytes32StringMap <---------
     */

    /**
     * @dev Inserts the given value at the specified key in the provided map, but only
     * if the key does not exist, yet. The `insert` function essentially behaves like a database insert
     * in that it avoids entering duplicate keys. In most cases you'd want to use `insertOrUpdate(...)`
     *
     * @param _map the AddressMap
     * @param _key the key
     * @param _value the value
     * @return BaseErrors.NO_ERROR or BaseErrors.RESOURCE_ALREADY_EXISTS
     */
    function insert(Mappings.Bytes32StringMap storage _map, bytes32 _key, string memory _value) public returns (uint)
    {
        if (_map.rows[_key].exists) { return BaseErrors.RESOURCE_ALREADY_EXISTS(); }
        insertOrUpdate(_map, _key, _value);
        return BaseErrors.NO_ERROR();
    }

    /**
     * @dev Inserts or updates the given value at the specified key in the provided map.
     *
     * @param _map the AddressMap
     * @param _key the key
     * @param _value the value
     * @return the size of the map after the operation
     */
    function insertOrUpdate(Mappings.Bytes32StringMap storage _map, bytes32 _key, string memory _value) public returns (uint)
    {
        if (_map.rows[_key].exists) {
            _map.rows[_key].value = _value;
        } else {
            _map.rows[_key].keyIdx = (_map.keys.push(_key)-1);
            _map.rows[_key].value = _value;
            _map.rows[_key].exists = true;
        }
        return _map.keys.length;
    }

    /**
     * @dev Removes the entry registered at the specified key in the provided map.
     * @dev the _map.keys array may get re-ordered by this operation: unless the removed entry was
     * the last element in the map's keys, the last key will be moved into the void position created
     * by the removal.
     *
     * @param _map the AddressMap
     * @param _key the key
     * @return BaseErrors.NO_ERROR or BaseErrors.RESOURCE_NOT_FOUND.
     */
    function remove(Mappings.Bytes32StringMap storage _map, bytes32 _key) public returns (uint) {
        if (!_map.rows[_key].exists) { return BaseErrors.RESOURCE_NOT_FOUND(); }
        bytes32 swapKey = Mappings.deleteInKeys(_map.keys, _map.rows[_key].keyIdx);
        if (swapKey.contentLength() > 0) {
            _map.rows[swapKey].keyIdx = _map.rows[_key].keyIdx;
        }
        delete _map.rows[_key];
        return BaseErrors.NO_ERROR();
     }

    /**
     * @dev Removes all entries stored in the map.
     * @param _map the map
     * @return the number of removed entries
     */
    function clear(Mappings.Bytes32StringMap storage _map) public returns (uint) {
        uint l = _map.keys.length;
        for(uint i = 0; i < l; i++) {
            delete _map.rows[_map.keys[i]];
        }
        _map.keys.length = 0;
        return l;
    }

    /**
     * @dev Convenience function to return the row[_key].exists value.
     * @return true if the map contains valid values at the specified key, false otherwise.
     */
    function exists(Mappings.Bytes32StringMap storage _map, bytes32 _key) public view returns (bool) {
        return _map.rows[_key].exists;
    }

    /**
     * @return the value registered at the specified key, or an empty string if it doesn't exist
     */
    function get(Mappings.Bytes32StringMap storage _map, bytes32 _key) public view returns (string memory) {
        return _map.rows[_key].value;
    }

    /**
     * @return the index of the given key or int_constant uint(-1) if the key does not exist
     */
    function keyIndex(Mappings.Bytes32StringMap storage _map, bytes32 _key) public view returns (uint) {
        if (!_map.rows[_key].exists) { return uint(-1); }
        return _map.rows[_key].keyIdx;
    }

    /**
     * @dev Retrieves the key at the given index, if it exists.
     *
     * @param _map the map
     * @param _index the index
     * @return (BaseErrors.NO_ERROR(), key) or (BaseErrors.INDEX_OUT_OF_BOUNDS(), "")
     */
    function keyAtIndex(Mappings.Bytes32StringMap storage _map, uint _index) public view returns (uint, bytes32) {
        return Mappings.keyAtIndex(_map.keys, _index);
    }

    /**
     * @dev Retrieves the key at the given index position and the index of the next artifact.
     *
     * @param _map the map
     * @param _index the index
     * @return error BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS()
     * @return key the key or ""
     * @return nextindex the next index if there is one or 0
     */
    function keyAtIndexHasNext(Mappings.Bytes32StringMap storage _map, uint _index) public view returns (uint error, bytes32 key, uint nextIndex) {
        (error, key) = keyAtIndex(_map, _index);
        if (++_index < _map.keys.length) {
            nextIndex = _index;
        }
    }

    /**
     * @dev Retrieves the value at the given index position and the index of the next address.
     *
     * @param _map the map
     * @param _index the index
     * @return BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS(), value, and nextIndex
     */
    function valueAtIndexHasNext(Mappings.Bytes32StringMap storage _map, uint _index) public view returns (uint error, string memory value, uint nextIndex) {
        bytes32 key;
        (error, key, nextIndex) = keyAtIndexHasNext(_map, _index);
        if (error == BaseErrors.NO_ERROR()) {
            value = get(_map, key);
        }
    }


    /**
     * ---------> Bytes32UintMap <---------
     */

    /**
     * @dev Inserts the given value at the specified key in the provided map, but only
     * if the key does not exist, yet. The `insert` function essentially behaves like a database insert
     * in that it avoids entering duplicate keys. In most cases you'd want to use `insertOrUpdate(...)`
     *
     * @param _map the Uint Map
     * @param _key the key
     * @param _value the value
     * @return BaseErrors.NO_ERROR or BaseErrors.RESOURCE_ALREADY_EXISTS
     */
    function insert(Mappings.Bytes32UintMap storage _map, bytes32 _key, uint _value) public returns (uint)
    {
        if (_map.rows[_key].exists) { return BaseErrors.RESOURCE_ALREADY_EXISTS(); }
        insertOrUpdate(_map, _key, _value);
        return BaseErrors.NO_ERROR();
    }

    /**
     * @dev Inserts or updates the given value at the specified key in the provided map.
     *
     * @param _map the Uint Map
     * @param _key the key
     * @param _value the value
     * @return the size of the map after the operation
     */
    function insertOrUpdate(Mappings.Bytes32UintMap storage _map, bytes32 _key, uint _value) public returns (uint)
    {
        if (_map.rows[_key].exists) {
            _map.rows[_key].value = _value;
        } else {
            _map.rows[_key].keyIdx = (_map.keys.push(_key)-1);
            _map.rows[_key].value = _value;
            _map.rows[_key].exists = true;
        }
        return _map.keys.length;
    }

    /**
     * @dev Removes the entry registered at the specified key in the provided map.
     * @dev the _map.keys array may get re-ordered by this operation: unless the removed entry was
     * the last element in the map's keys, the last key will be moved into the void position created
     * by the removal.
     *
     * @param _map the Uint Map
     * @param _key the key
     * @return BaseErrors.NO_ERROR or BaseErrors.RESOURCE_NOT_FOUND.
     */
    function remove(Mappings.Bytes32UintMap storage _map, bytes32 _key) public returns (uint) {
         if (!_map.rows[_key].exists) { return BaseErrors.RESOURCE_NOT_FOUND(); }
         bytes32 swapKey = Mappings.deleteInKeys(_map.keys, _map.rows[_key].keyIdx);
         if (swapKey.contentLength() > 0) { _map.rows[swapKey].keyIdx = _map.rows[_key].keyIdx; }
         delete _map.rows[_key];
         return BaseErrors.NO_ERROR();
     }

    /**
     * @dev Removes all entries stored in the map.
     * @param _map the map
     * @return the number of removed entries
     */
    function clear(Mappings.Bytes32UintMap storage _map) public returns (uint) {
        uint l = _map.keys.length;
        for(uint i = 0; i < l; i++) {
            delete _map.rows[_map.keys[i]];
        }
        _map.keys.length = 0;
        return l;
    }

    /**
     * @dev Convenience function to return the row[_key].exists value.
     * @return true if the map contains valid values at the specified key, false otherwise.
     */
    function exists(Mappings.Bytes32UintMap storage _map, bytes32 _key) public view returns (bool) {
        return _map.rows[_key].exists;
    }

    /**
     * @return the value registered at the specified key
     */
    function get(Mappings.Bytes32UintMap storage _map, bytes32 _key) public view returns (uint) {
        return _map.rows[_key].value;
    }

    /**
     * @return the index of the given key or int_constant uint(-1) if the key does not exist
     */
    function keyIndex(Mappings.Bytes32UintMap storage _map, bytes32 _key) public view returns (uint) {
        if (!_map.rows[_key].exists) { return uint(-1); }
        return _map.rows[_key].keyIdx;
    }

    /**
     * @dev Retrieves the key at the given index, if it exists.
     *
     * @param _map the map
     * @param _index the index
     * @return (BaseErrors.NO_ERROR(), key) or (BaseErrors.INDEX_OUT_OF_BOUNDS(), "")
     */
    function keyAtIndex(Mappings.Bytes32UintMap storage _map, uint _index) public view returns (uint, bytes32) {
        return Mappings.keyAtIndex(_map.keys, _index);
    }

    /**
     * @dev Retrieves the key at the given index position and the index of the next artifact.
     *
     * @param _map the map
     * @param _index the index
     * @return error BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS()
     * @return key the key or ""
     * @return nextindex the next index if there is one or 0
     */
    function keyAtIndexHasNext(Mappings.Bytes32UintMap storage _map, uint _index) public view returns (uint error, bytes32 key, uint nextIndex) {
        (error, key) = keyAtIndex(_map, _index);
        if (++_index < _map.keys.length) {
            nextIndex = _index;
        }
    }

    /**
     * @dev Retrieves the value at the given index position and the index of the next value.
     *
     * @param _map the map
     * @param _index the index
     * @return BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS(), value, and nextIndex
     */
    function valueAtIndexHasNext(Mappings.Bytes32UintMap storage _map, uint _index) public view returns (uint error, uint value, uint nextIndex) {
        bytes32 key;
        (error, key, nextIndex) = keyAtIndexHasNext(_map, _index);
        if (error == BaseErrors.NO_ERROR()) {
            value = get(_map, key);
        }
    }


    /**
     * ---------> Bytes32Bytes32Map <---------
     */

    /**
     * @dev Inserts the given value at the specified key in the provided map, but only
     * if the key does not exist, yet. The `insert` function essentially behaves like a database insert
     * in that it avoids entering duplicate keys. In most cases you'd want to use `insertOrUpdate(...)`
     *
     * @param _map the Bytes32Bytes32Map
     * @param _key the key
     * @param _value the value
     * @return BaseErrors.NO_ERROR or BaseErrors.RESOURCE_ALREADY_EXISTS
     */
    function insert(Mappings.Bytes32Bytes32Map storage _map, bytes32 _key, bytes32 _value) public returns (uint) {
        if (_map.rows[_key].exists) { return BaseErrors.RESOURCE_ALREADY_EXISTS(); }
        insertOrUpdate(_map, _key, _value);
        return BaseErrors.NO_ERROR();
    }

    /**
     * @dev Inserts or updates the given value at the specified key in the provided map.
     *
     * @param _map the Bytes32Bytes32Map
     * @param _key the key
     * @param _value the value
     * @return the size of the map after the operation
     */
    function insertOrUpdate(Mappings.Bytes32Bytes32Map storage _map, bytes32 _key, bytes32 _value) public returns (uint) {
        if (_map.rows[_key].exists) {
            _map.rows[_key].value = _value; 
        } else {
            _map.rows[_key].keyIdx = (_map.keys.push(_key)-1);
            _map.rows[_key].value = _value;
            _map.rows[_key].exists = true;
        }
        return _map.keys.length;
    }

    /**
     * @dev Removes the entry registered at the specified key in the provided map.
     * @dev the _map.keys array may get re-ordered by this operation: unless the removed entry was
     * the last element in the map's keys, the last key will be moved into the void position created
     * by the removal.
     *
     * @param _map the Bytes32Bytes32Map
     * @param _key the key
     * @return BaseErrors.NO_ERROR or BaseErrors.RESOURCE_NOT_FOUND.
     */
    function remove(Mappings.Bytes32Bytes32Map storage _map, bytes32 _key) public returns (uint) {
         if (!_map.rows[_key].exists) { return BaseErrors.RESOURCE_NOT_FOUND(); }
         bytes32 swapKey = Mappings.deleteInKeys(_map.keys, _map.rows[_key].keyIdx);
         if (swapKey.contentLength() > 0) { _map.rows[swapKey].keyIdx = _map.rows[_key].keyIdx; }
         delete _map.rows[_key];
         return BaseErrors.NO_ERROR();
     }

    /**
     * @dev Removes all entries stored in the map.
     * @param _map the Bytes32Bytes32Map
     * @return the number of removed entries
     */
    function clear(Mappings.Bytes32Bytes32Map storage _map) public returns (uint) {
        uint l = _map.keys.length;
        for (uint i = 0; i < l; i++) {
            delete _map.rows[_map.keys[i]];
        }
        _map.keys.length = 0;
        return l;
    }

    /**
     * @dev Convenience function to return the row[_key].exists value.
     * @return true if the map contains valid values at the specified key, false otherwise.
     */
    function exists(Mappings.Bytes32Bytes32Map storage _map, bytes32 _key) public view returns (bool) {
        return _map.rows[_key].exists;
    }

    /**
     * @return the value registered at the specified key, or 0x0 if it doesn't exist
     */
    function get(Mappings.Bytes32Bytes32Map storage _map, bytes32 _key) public view returns (bytes32) {
        return _map.rows[_key].value;
    }

    /**
     * @return the index of the given key or int_constant uint(-1) if the key does not exist
     */
    function keyIndex(Mappings.Bytes32Bytes32Map storage _map, bytes32 _key) public view returns (uint) {
        if (!_map.rows[_key].exists) { return uint(-1); }
        return _map.rows[_key].keyIdx;
    }

    /**
     * @dev Retrieves the key at the given index, if it exists.
     *
     * @param _map the Bytes32Bytes32Map
     * @param _index the index
     * @return (BaseErrors.NO_ERROR(), key) or (BaseErrors.INDEX_OUT_OF_BOUNDS(), "")
     */
    function keyAtIndex(Mappings.Bytes32Bytes32Map storage _map, uint _index) public view returns (uint, bytes32) {
        return Mappings.keyAtIndex(_map.keys, _index);
    }

    /**
     * @dev Retrieves the key at the given index position and the index of the next artifact.
     *
     * @param _map the Bytes32Bytes32Map
     * @param _index the index
     * @return error BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS()
     * @return key the key or ""
     * @return nextindex the next index if there is one or 0
     */
    function keyAtIndexHasNext(Mappings.Bytes32Bytes32Map storage _map, uint _index) public view returns (uint error, bytes32 key, uint nextIndex) {
        (error, key) = keyAtIndex(_map, _index);
        if (++_index < _map.keys.length) {
            nextIndex = _index;
        }
    }

    /**
     * @dev Retrieves the value at the given index position and the index of the next address.
     *
     * @param _map the Bytes32Bytes32Map
     * @param _index the index
     * @return BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS(), value, and nextIndex
     */
    function valueAtIndexHasNext(Mappings.Bytes32Bytes32Map storage _map, uint _index) public view returns (uint error, bytes32 value, uint nextIndex) {
        bytes32 key;
        (error, key, nextIndex) = keyAtIndexHasNext(_map, _index);
        if (error == BaseErrors.NO_ERROR()) {
            value = get(_map, key);
        }
    }

    /**
     * ---------> Bytes32AddressArrayMap <---------
     */

    /**
     * @dev Inserts the given address array value at the specified key in the provided map, but only
     * if the key does not exist, yet. The `insert` function essentially behaves like a database insert
     * in that it avoids entering duplicate keys. In most cases you'd want to use `insertOrUpdate(...)`
     *
     * @param _map the AddressArrayMap
     * @param _key the key
     * @param _value the value
     * @return BaseErrors.NO_ERROR() or BaseErrors.RESOURCE_ALREADY_EXISTS()
     */
    function insert(Mappings.Bytes32AddressArrayMap storage _map, bytes32 _key, address[] memory _value) public returns (uint)
    {
        if (_map.rows[_key].exists) { return BaseErrors.RESOURCE_ALREADY_EXISTS(); }
        insertOrUpdate(_map, _key, _value);
        return BaseErrors.NO_ERROR();
    }

    /**
     * @dev Inserts or updates the given address array value at the specified key in the provided map.
     *
     * @param _map the AddressArrayMap
     * @param _key the key
     * @param _value the value
     * @return the size of the map after the operation
     */
    function insertOrUpdate(Mappings.Bytes32AddressArrayMap storage _map, bytes32 _key, address[] memory _value) public returns (uint)
    {
        if (_map.rows[_key].exists) {
            _map.rows[_key].value = _value;
        } else {
            _map.rows[_key].keyIdx = (_map.keys.push(_key)-1);
            _map.rows[_key].value = _value;
            _map.rows[_key].exists = true;
        }
        return _map.keys.length;
    }

    /**
     * @dev Adds the specified value to the array that is stored in the map under the given key. The boolean parameter can be used to avoid duplicate values in the array.
     * @dev Note that the array will be automatically initiated even if there was no prior entry at the specified key. If you want to make sure the key is valid, use exists(key).
     * @param _map the map
     * @param _key the key for the array
     * @param _value the value to store in the array
     * @param _unique set to true if the value should only be added if it does not already exist in the array
     * @return the length of the array after the operation
     */
    function addToArray(Mappings.Bytes32AddressArrayMap storage _map, bytes32 _key, address _value, bool _unique) public returns (uint) {
        if (!_unique || (_unique && !_map.rows[_key].value.contains(_value))) {
            _map.rows[_key].value.push(_value);
        }
        return _map.rows[_key].value.length;
    }

    /**
     * @dev Removes the given value from the inner array in the given map structure. The bool parameter controls if 'all' occurences of the value should be deleted.
     * @dev Searching for the value to be deleted starts at the end of the array, but LIFO is not guaranteed, because entries can be moved around as part of this function,
     * i.e. when the deletion does not happen to be at the end of the array, the last entry is swapped into position of the deleted item and the array is truncated at the end.
     * @param _map the map
     * @param _key the key for the array
     * @param _value the value to be deleted in the array
     * @param _all if true, the entire array will be traversed and all occurences deleted, if false only the first encountered one
     * @return the resulting array length
     */
    function removeFromArray(Mappings.Bytes32AddressArrayMap storage _map, bytes32 _key, address _value, bool _all) public returns (uint) {
        if (_map.rows[_key].value.length == 0) { return 0; }
        // Note that due to uint 0 - 1 rolling over, a non-zero-based index is used in the loop
        for (uint i = _map.rows[_key].value.length; i > 0; i--) {
            if (_map.rows[_key].value[i-1] == _value) {
                if (i != _map.rows[_key].value.length) {
                    // copy the last element into the to be deleted position
                    _map.rows[_key].value[i-1] = _map.rows[_key].value[_map.rows[_key].value.length-1];
                }
                // truncate from the end
                _map.rows[_key].value.length--;
                if (!_all) { break; }
            }
        }
        return _map.rows[_key].value.length;
    }

    /**
     * @dev Removes the address array registered at the specified key in the provided map.
     * @dev the _map.keys array might get re-ordered by this operation: if the removed entry was not
     * the last element in the map's keys, the last element will be moved into the void position created
     * by the removal.
     *
     * @param _map the AddressArrayMap
     * @param _key the key
     * @return BaseErrors.NO_ERROR() or BaseErrors.RESOURCE_NOT_FOUND().
     */
    function remove(Mappings.Bytes32AddressArrayMap storage _map, bytes32 _key) public returns (uint) {
         if (!_map.rows[_key].exists) { return BaseErrors.RESOURCE_NOT_FOUND(); }
         bytes32 swapKey = Mappings.deleteInKeys(_map.keys, _map.rows[_key].keyIdx);
         if (swapKey.contentLength() > 0) { _map.rows[swapKey].keyIdx = _map.rows[_key].keyIdx; }
         delete _map.rows[_key];
         return BaseErrors.NO_ERROR();
     }

    /**
     * @dev Removes all entries stored in the mapping.
     *
     * @param _map the AddressArrayMap
     * @return the number of removed entries
     */
    function clear(Mappings.Bytes32AddressArrayMap storage _map) public returns (uint) {
        uint l = _map.keys.length;
        for(uint i = 0; i < l; i++) {
            delete _map.rows[_map.keys[i]];
        }
        _map.keys.length = 0;
        return l;
    }

    /**
     * Convenience function to return the row[_key].exists value.
     * @return true if the map contains valid values at the specified key, false otherwise.
     */
    function exists(Mappings.Bytes32AddressArrayMap storage _map, bytes32 _key) public view returns (bool) {
        return _map.rows[_key].exists;
    }

    /**
     * @dev Retrieves the address array in the map at the specified key.
     *
     * @param _map the AddressArrayMap
     * @param _key the key
     * @return the addresses array value registered at the specified key, or empty address[] if it doesn't exist
     */
   function get(Mappings.Bytes32AddressArrayMap storage _map, bytes32 _key) public view returns (address[] memory) {
        return _map.rows[_key].value;
    }

    /**
     * @dev Retrieves the index of the specified key.
     *
     * @param _map the AddressArrayMap
     * @param _key the key
     * @return the index of the given key or int_constant uint(-1) if the key does not exist
     */
    function keyIndex(Mappings.Bytes32AddressArrayMap storage _map, bytes32 _key) public view returns (uint) {
        if (!_map.rows[_key].exists) { return uint(-1); }
        return _map.rows[_key].keyIdx;
    }

    /**
     * @dev Retrieves the key at the given index, if it exists.
     *
     * @param _map the AddressArrayMap
     * @param _index the index
     * @return (BaseErrors.NO_ERROR(), key) or (BaseErrors.INDEX_OUT_OF_BOUNDS(), "")
     */
    function keyAtIndex(Mappings.Bytes32AddressArrayMap storage _map, uint _index) public view returns (uint, bytes32) {
        return Mappings.keyAtIndex(_map.keys, _index);
    }

    /**
     * @dev Retrieves the key at the given index position and the index of the next artifact.
     *
     * @param _map the map
     * @param _index the index
     * @return error BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS()
     * @return key the key or ""
     * @return nextindex the next index if there is one or 0
     */
    function keyAtIndexHasNext(Mappings.Bytes32AddressArrayMap storage _map, uint _index) public view returns (uint error, bytes32 key, uint nextIndex) {
        (error, key) = keyAtIndex(_map, _index);
        if (++_index < _map.keys.length) {
            nextIndex = _index;
        }
    }

    /**
     * @dev Retrieves the array at the given index position and the index of the next array.
     *
     * @dev Internal function to retrieve the value and nextIndex from a given Map
     * @param _map the AddressArrayMap
     * @param _index the index
     * @return BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS(), value or address[], and nextIndex
     */
    function valueAtIndexHasNext(Mappings.Bytes32AddressArrayMap storage _map, uint _index) public view returns (uint error, address[] memory value, uint nextIndex) {
        bytes32 key;
        (error, key, nextIndex) = keyAtIndexHasNext(_map, _index);
        if (error == BaseErrors.NO_ERROR()) {
            value = get(_map, key);
        }
    }

    /**
     * ---------> AddressBytes32Map <---------
     */

    /**
     * @dev Inserts the given value at the specified key in the provided map, but only
     * if the key does not exist, yet. The `insert` function essentially behaves like a database insert
     * in that it avoids entering duplicate keys. In most cases you'd want to use `insertOrUpdate(...)`
     *
     * @param _map the map
     * @param _key the key
     * @param _value the value
     * @return BaseErrors.NO_ERROR or BaseErrors.RESOURCE_ALREADY_EXISTS
     */
    function insert(Mappings.AddressBytes32Map storage _map, address _key, bytes32 _value) public returns (uint)
    {
        if (_map.rows[_key].exists) { return BaseErrors.RESOURCE_ALREADY_EXISTS(); }
        insertOrUpdate(_map, _key, _value);
        return BaseErrors.NO_ERROR();
    }

    /**
     * @dev Inserts or updates the given value at the specified key in the provided map.
     *
     * @param _map the map
     * @param _key the key
     * @param _value the value
     * @return the size of the map after the operation
     */
    function insertOrUpdate(Mappings.AddressBytes32Map storage _map, address _key, bytes32 _value) public returns (uint)
    {
        if (_map.rows[_key].exists) {
            _map.rows[_key].value = _value;
        } else {
            _map.rows[_key].keyIdx = (_map.keys.push(_key)-1);
            _map.rows[_key].value = _value;
            _map.rows[_key].exists = true;
        }
        return _map.keys.length;
    }

    /**
     * @dev Removes the entry registered at the specified key in the provided map.
     * @dev the _map.keys array may get re-ordered by this operation: unless the removed entry was
     * the last element in the map's keys, the last key will be moved into the void position created
     * by the removal.
     *
     * @param _map the map
     * @param _key the key
     * @return BaseErrors.NO_ERROR or BaseErrors.RESOURCE_NOT_FOUND.
     */
    function remove(Mappings.AddressBytes32Map storage _map, address _key) public returns (uint) {
         if (!_map.rows[_key].exists) { return BaseErrors.RESOURCE_NOT_FOUND(); }
         address swapKey = Mappings.deleteInKeys(_map.keys, _map.rows[_key].keyIdx);
         if (swapKey != address(0)) { _map.rows[swapKey].keyIdx = _map.rows[_key].keyIdx; }
         delete _map.rows[_key];
         return BaseErrors.NO_ERROR();
     }

    /**
     * @dev Removes all entries stored in the mapping.
     *
     * @param _map the map
     * @return the number of removed entries
     */
    function clear(Mappings.AddressBytes32Map storage _map) public returns (uint) {
        uint l = _map.keys.length;
        for(uint i = 0; i < l; i++) {
            delete _map.rows[_map.keys[i]];
        }
        _map.keys.length = 0;
        return l;
    }

    /**
     * Convenience function to return the row[_key].exists value.
     * @return true if the map contains valid values at the specified key, false otherwise.
     */
    function exists(Mappings.AddressBytes32Map storage _map, address _key) public view returns (bool) {
        return _map.rows[_key].exists;
    }

    /**
    * @return the value registered at the specified key, or an empty bytes32 if it doesn't exist
    */
    function get(Mappings.AddressBytes32Map storage _map, address _key) public view returns (bytes32) {
        return _map.rows[_key].value;
    }

    /**
     * @return the index of the given key or int_constant uint(-1) if the key does not exist
     */
    function keyIndex(Mappings.AddressBytes32Map storage _map, address _key) public view returns (uint) {
        if (!_map.rows[_key].exists) { return uint(-1); }
        return _map.rows[_key].keyIdx;
    }

    /**
     * @dev Retrieves the key at the given index, if it exists.
     *
     * @param _map the map
     * @param _index the index
     * @return (BaseErrors.NO_ERROR(), key) or (BaseErrors.INDEX_OUT_OF_BOUNDS(), 0x0)
     */
    function keyAtIndex(Mappings.AddressBytes32Map storage _map, uint _index) public view returns (uint, address) {
        return Mappings.keyAtIndex(_map.keys, _index);
    }

    /**
     * @dev Retrieves the key at the given index position and the index of the next artifact.
     *
     * @param _map the map
     * @param _index the index
     * @return error BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS()
     * @return key the key or 0x0
     * @return nextindex the next index if there is one or 0
     */
    function keyAtIndexHasNext(Mappings.AddressBytes32Map storage _map, uint _index) public view returns (uint error, address key, uint nextIndex) {
        (error, key) = keyAtIndex(_map, _index);
        if (++_index < _map.keys.length) {
            nextIndex = _index;
        }
    }

    /**
     * @dev Retrieves the value at the given index position and the index of the next address.
     *
     * @param _map the map
     * @param _index the index
     * @return BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS(), value, and nextIndex
     */
    function valueAtIndexHasNext(Mappings.AddressBytes32Map storage _map, uint _index) public view returns (uint error, bytes32 value, uint nextIndex) {
        address key;
        (error, key, nextIndex) = keyAtIndexHasNext(_map, _index);
        if (error == BaseErrors.NO_ERROR()) {
            value = get(_map, key);
        }
    }

    /**
     * ---------> AddressStringMap <---------
     */

    /**
     * @dev Inserts the given value at the specified key in the provided map, but only
     * if the key does not exist, yet. The `insert` function essentially behaves like a database insert
     * in that it avoids entering duplicate keys. In most cases you'd want to use `insertOrUpdate(...)`
     *
     * @param _map the AddressMap
     * @param _key the key
     * @param _value the value
     * @return BaseErrors.NO_ERROR or BaseErrors.RESOURCE_ALREADY_EXISTS
     */
    function insert(Mappings.AddressStringMap storage _map, address _key, string memory _value) public returns (uint)
    {
        if (_map.rows[_key].exists) { return BaseErrors.RESOURCE_ALREADY_EXISTS(); }
        insertOrUpdate(_map, _key, _value);
        return BaseErrors.NO_ERROR();
    }

    /**
     * @dev Inserts or updates the given value at the specified key in the provided map.
     *
     * @param _map the AddressMap
     * @param _key the key
     * @param _value the value
     * @return the size of the map after the operation
     */
    function insertOrUpdate(Mappings.AddressStringMap storage _map, address _key, string memory _value) public returns (uint)
    {
        if (_map.rows[_key].exists) {
            _map.rows[_key].value = _value;
        } else {
            _map.rows[_key].keyIdx = (_map.keys.push(_key)-1);
            _map.rows[_key].value = _value;
            _map.rows[_key].exists = true;
        }
        return _map.keys.length;
    }

    /**
     * @dev Removes the entry registered at the specified key in the provided map.
     * @dev the _map.keys array may get re-ordered by this operation: unless the removed entry was
     * the last element in the map's keys, the last key will be moved into the void position created
     * by the removal.
     *
     * @param _map the AddressMap
     * @param _key the key
     * @return BaseErrors.NO_ERROR or BaseErrors.RESOURCE_NOT_FOUND.
     */
    function remove(Mappings.AddressStringMap storage _map, address _key) public returns (uint) {
        if (!_map.rows[_key].exists) { return BaseErrors.RESOURCE_NOT_FOUND(); }
        address swapKey = Mappings.deleteInKeys(_map.keys, _map.rows[_key].keyIdx);
        if (swapKey != address(0)) {
            _map.rows[swapKey].keyIdx = _map.rows[_key].keyIdx;
        }
        delete _map.rows[_key];
        return BaseErrors.NO_ERROR();
     }

    /**
     * @dev Removes all entries stored in the map.
     * @param _map the map
     * @return the number of removed entries
     */
    function clear(Mappings.AddressStringMap storage _map) public returns (uint) {
        uint l = _map.keys.length;
        for(uint i = 0; i < l; i++) {
            delete _map.rows[_map.keys[i]];
        }
        _map.keys.length = 0;
        return l;
    }

    /**
     * @dev Convenience function to return the row[_key].exists value.
     * @return true if the map contains valid values at the specified key, false otherwise.
     */
    function exists(Mappings.AddressStringMap storage _map, address _key) public view returns (bool) {
        return _map.rows[_key].exists;
    }

    /**
     * @return the value registered at the specified key, or an empty string if it doesn't exist
     */
    function get(Mappings.AddressStringMap storage _map, address _key) public view returns (string memory) {
        return _map.rows[_key].value;
    }

    /**
     * @return the index of the given key or int_constant uint(-1) if the key does not exist
     */
    function keyIndex(Mappings.AddressStringMap storage _map, address _key) public view returns (uint) {
        if (!_map.rows[_key].exists) { return uint(-1); }
        return _map.rows[_key].keyIdx;
    }

    /**
     * @dev Retrieves the key at the given index, if it exists.
     *
     * @param _map the map
     * @param _index the index
     * @return (BaseErrors.NO_ERROR(), key) or (BaseErrors.INDEX_OUT_OF_BOUNDS(), "")
     */
    function keyAtIndex(Mappings.AddressStringMap storage _map, uint _index) public view returns (uint, address) {
        return Mappings.keyAtIndex(_map.keys, _index);
    }

    /**
     * @dev Retrieves the key at the given index position and the index of the next artifact.
     *
     * @param _map the map
     * @param _index the index
     * @return error BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS()
     * @return key the key or ""
     * @return nextindex the next index if there is one or 0
     */
    function keyAtIndexHasNext(Mappings.AddressStringMap storage _map, uint _index) public view returns (uint error, address key, uint nextIndex) {
        (error, key) = keyAtIndex(_map, _index);
        if (++_index < _map.keys.length) {
            nextIndex = _index;
        }
    }

    /**
     * @dev Retrieves the value at the given index position and the index of the next address.
     *
     * @param _map the map
     * @param _index the index
     * @return BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS(), value, and nextIndex
     */
    function valueAtIndexHasNext(Mappings.AddressStringMap storage _map, uint _index) public view returns (uint error, string memory value, uint nextIndex) {
        address key;
        (error, key, nextIndex) = keyAtIndexHasNext(_map, _index);
        if (error == BaseErrors.NO_ERROR()) {
            value = get(_map, key);
        }
    }


    /**
     * ---------> AddressBoolMap <---------
     */

    /**
     * @dev Inserts the given value at the specified key in the provided map, but only
     * if the key does not exist, yet. The `insert` function essentially behaves like a database insert
     * in that it avoids entering duplicate keys. In most cases you'd want to use `insertOrUpdate(...)`
     *
     * @param _map the map
     * @param _key the key
     * @param _value the value
     * @return BaseErrors.NO_ERROR or BaseErrors.RESOURCE_ALREADY_EXISTS
     */
    function insert(Mappings.AddressBoolMap storage _map, address _key, bool _value) public returns (uint)
    {
        if (_map.rows[_key].exists) { return BaseErrors.RESOURCE_ALREADY_EXISTS(); }
        insertOrUpdate(_map, _key, _value);
        return BaseErrors.NO_ERROR();
    }

    /**
     * @dev Inserts or updates the given value at the specified key in the provided map.
     *
     * @param _map the map
     * @param _key the key
     * @param _value the value
     * @return the size of the map after the operation
     */
    function insertOrUpdate(Mappings.AddressBoolMap storage _map, address _key, bool _value) public returns (uint)
    {
        if (_map.rows[_key].exists) {
            _map.rows[_key].value = _value;
        } else {
            _map.rows[_key].keyIdx = (_map.keys.push(_key)-1);
            _map.rows[_key].value = _value;
            _map.rows[_key].exists = true;
        }
        return _map.keys.length;
    }

    /**
     * @dev Removes the entry registered at the specified key in the provided map.
     * @dev the _map.keys array may get re-ordered by this operation: unless the removed entry was
     * the last element in the map's keys, the last key will be moved into the void position created
     * by the removal.
     *
     * @param _map the map
     * @param _key the key
     * @return BaseErrors.NO_ERROR or BaseErrors.RESOURCE_NOT_FOUND.
     */
    function remove(Mappings.AddressBoolMap storage _map, address _key) public returns (uint) {
         if (!_map.rows[_key].exists) { return BaseErrors.RESOURCE_NOT_FOUND(); }
         address swapKey = Mappings.deleteInKeys(_map.keys, _map.rows[_key].keyIdx);
         if (swapKey != address(0)) { _map.rows[swapKey].keyIdx = _map.rows[_key].keyIdx; }
         delete _map.rows[_key];
         return BaseErrors.NO_ERROR();
     }

    /**
     * @dev Removes all entries stored in the mapping.
     *
     * @param _map the map
     * @return the number of removed entries
     */
    function clear(Mappings.AddressBoolMap storage _map) public returns (uint) {
        uint l = _map.keys.length;
        for(uint i = 0; i < l; i++) {
            delete _map.rows[_map.keys[i]];
        }
        _map.keys.length = 0;
        return l;
    }

    /**
     * Convenience function to return the row[_key].exists value.
     * @return true if the map contains valid values at the specified key, false otherwise.
     */
    function exists(Mappings.AddressBoolMap storage _map, address _key) public view returns (bool) {
        return _map.rows[_key].exists;
    }

    /**
    * @return the value registered at the specified key, or an empty bool if it doesn't exist
    */
    function get(Mappings.AddressBoolMap storage _map, address _key) public view returns (bool) {
        return _map.rows[_key].value;
    }

    /**
     * @return the index of the given key or int_constant uint(-1) if the key does not exist
     */
    function keyIndex(Mappings.AddressBoolMap storage _map, address _key) public view returns (uint) {
        if (!_map.rows[_key].exists) { return uint(-1); }
        return _map.rows[_key].keyIdx;
    }

    /**
     * @dev Retrieves the key at the given index, if it exists.
     *
     * @param _map the map
     * @param _index the index
     * @return (BaseErrors.NO_ERROR(), key) or (BaseErrors.INDEX_OUT_OF_BOUNDS(), 0x0)
     */
    function keyAtIndex(Mappings.AddressBoolMap storage _map, uint _index) public view returns (uint, address) {
        return Mappings.keyAtIndex(_map.keys, _index);
    }

    /**
     * @dev Retrieves the key at the given index position and the index of the next artifact.
     *
     * @param _map the map
     * @param _index the index
     * @return error BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS()
     * @return key the key or 0x0
     * @return nextindex the next index if there is one or 0
     */
    function keyAtIndexHasNext(Mappings.AddressBoolMap storage _map, uint _index) public view returns (uint error, address key, uint nextIndex) {
        (error, key) = keyAtIndex(_map, _index);
        if (++_index < _map.keys.length) {
            nextIndex = _index;
        }
    }

    /**
     * @dev Retrieves the value at the given index position and the index of the next address.
     *
     * @param _map the map
     * @param _index the index
     * @return BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS(), value, and nextIndex
     */
    function valueAtIndexHasNext(Mappings.AddressBoolMap storage _map, uint _index) public view returns (uint error, bool value, uint nextIndex) {
        address key;
        (error, key, nextIndex) = keyAtIndexHasNext(_map, _index);
        if (error == BaseErrors.NO_ERROR()) {
            value = get(_map, key);
        }
    }

    /**
     * ---------> AddressBytes32ArrayMap <---------
     */

    /**
     * @dev Inserts the given bytes32 array value at the specified key in the provided map, but only
     * if the key does not exist, yet. The `insert` function essentially behaves like a database insert
     * in that it avoids entering duplicate keys. In most cases you'd want to use `insertOrUpdate(...)`
     *
     * @param _map the map
     * @param _key the key
     * @param _value the value
     * @return BaseErrors.NO_ERROR() or BaseErrors.RESOURCE_ALREADY_EXISTS()
     */
    function insert(Mappings.AddressBytes32ArrayMap storage _map, address _key, bytes32[] memory _value) public returns (uint) {
        if (_map.rows[_key].exists) { return BaseErrors.RESOURCE_ALREADY_EXISTS(); }
        insertOrUpdate(_map, _key, _value);
        return BaseErrors.NO_ERROR();
    }

    /**
     * @dev Inserts or updates the given address array value at the specified key in the provided map.
     *
     * @param _map the map
     * @param _key the key
     * @param _value the value
     * @return the size of the map after the operation
     */
    function insertOrUpdate(Mappings.AddressBytes32ArrayMap storage _map, address _key, bytes32[] memory _value) public returns (uint) {
        if (_map.rows[_key].exists) {
            _map.rows[_key].value = _value;
        } else {
            _map.rows[_key].keyIdx = (_map.keys.push(_key)-1);
            _map.rows[_key].value = _value;
            _map.rows[_key].exists = true;
        }
        return _map.keys.length;
    }

    /**
     * @dev Adds the specified value to the array that is stored in the map under the given key. The boolean parameter can be used to avoid duplicate values in the array.
     * @dev Note that the array will be automatically initiated even if there was no prior entry at the specified key. If you want to make sure the key is valid, use exists(key).
     * @param _map the map
     * @param _key the key for the array
     * @param _value the value to store in the array
     * @param _unique set to true if the value should only be added if it does not already exist in the array
     * @return the length of the array after the operation
     */
    function addToArray(Mappings.AddressBytes32ArrayMap storage _map, address _key, bytes32 _value, bool _unique) public returns (uint) {
        if (!_unique || (_unique && !_map.rows[_key].value.contains(_value))) {
            _map.rows[_key].value.push(_value);
        }
        return _map.rows[_key].value.length;
    }

    /**
     * @dev Removes the given value from the inner array in the given map structure. The bool parameter controls if 'all' occurences of the value should be deleted.
     * @dev Searching for the value to be deleted starts at the end of the array, but LIFO is not guaranteed, because entries can be moved around as part of this function,
     * i.e. when the deletion does not happen to be at the end of the array, the last entry is swapped into position of the deleted item and the array is truncated at the end.
     * @param _map the map
     * @param _key the key for the array
     * @param _value the value to be deleted in the array
     * @param _all if true, the entire array will be traversed and all occurences deleted, if false only the first encountered one
     * @return the resulting array length
     */
    function removeFromArray(Mappings.AddressBytes32ArrayMap storage _map, address _key, bytes32 _value, bool _all) public returns (uint) {
        if (_map.rows[_key].value.length == 0) { return 0; }
        // Note that due to uint 0 - 1 rolling over, a non-zero-based index is used in the loop
        for (uint i = _map.rows[_key].value.length; i > 0; i--) {
            if (_map.rows[_key].value[i-1] == _value) { // there's a match
                if (i != _map.rows[_key].value.length) { // it's NOT the last item
                    // copy the last element into the to be deleted position
                    _map.rows[_key].value[i-1] = _map.rows[_key].value[_map.rows[_key].value.length-1];
                }
                // truncate from the end
                _map.rows[_key].value.length--;
                if (!_all) { break; }
            }
        }
        return _map.rows[_key].value.length;
    }

    /**
     * @dev Removes the bytes32 array registered at the specified key in the provided map.
     * @dev the _map.keys array might get re-ordered by this operation: if the removed entry was not
     * the last element in the map's keys, the last element will be moved into the void position created
     * by the removal.
     *
     * @param _map the map
     * @param _key the key
     * @return BaseErrors.NO_ERROR() or BaseErrors.RESOURCE_NOT_FOUND().
     */
    function remove(Mappings.AddressBytes32ArrayMap storage _map, address _key) public returns (uint) {
        if (!_map.rows[_key].exists) { return BaseErrors.RESOURCE_NOT_FOUND(); }
        address swapKey = Mappings.deleteInKeys(_map.keys, _map.rows[_key].keyIdx);
        if (swapKey != address(0)) { _map.rows[swapKey].keyIdx = _map.rows[_key].keyIdx; }
        delete _map.rows[_key];
        return BaseErrors.NO_ERROR();
    }

    /**
     * @dev Removes all entries stored in the mapping.
     *
     * @param _map the AddressBytes32ArrayMap
     * @return the number of removed entries
     */
    function clear(Mappings.AddressBytes32ArrayMap storage _map) public returns (uint) {
        uint l = _map.keys.length;
        for(uint i = 0; i < l; i++) {
            delete _map.rows[_map.keys[i]];
        }
        _map.keys.length = 0;
        return l;
    }

    /**
     * Convenience function to return the row[_key].exists value.
     * @return true if the map contains valid values at the specified key, false otherwise.
     */
    function exists(Mappings.AddressBytes32ArrayMap storage _map, address _key) public view returns (bool) {
        return _map.rows[_key].exists;
    }

    /**
     * @dev Retrieves the bytes32 array in the map at the specified key.
     *
     * @param _map the AddressBytes32ArrayMap
     * @param _key the key
     * @return the addresses array value registered at the specified key, or empty bytes32[] if it doesn't exist
     */
   function get(Mappings.AddressBytes32ArrayMap storage _map, address _key) public view returns (bytes32[] memory) {
        return _map.rows[_key].value;
    }

    /**
     * @dev Retrieves the index of the specified key.
     *
     * @param _map the AddressBytes32ArrayMap
     * @param _key the key
     * @return the index of the given key or int_constant uint(-1) if the key does not exist
     */
    function keyIndex(Mappings.AddressBytes32ArrayMap storage _map, address _key) public view returns (uint) {
        if (!_map.rows[_key].exists) { return uint(-1); }
        return _map.rows[_key].keyIdx;
    }

    /**
     * @dev Retrieves the key at the given index, if it exists.
     *
     * @param _map the AddressBytes32ArrayMap
     * @param _index the index
     * @return (BaseErrors.NO_ERROR(), key) or (BaseErrors.INDEX_OUT_OF_BOUNDS(), "")
     */
    function keyAtIndex(Mappings.AddressBytes32ArrayMap storage _map, uint _index) public view returns (uint, address) {
        return Mappings.keyAtIndex(_map.keys, _index);
    }

    /**
     * @dev Retrieves the key at the given index position and the index of the next artifact.
     *
     * @param _map the map
     * @param _index the index
     * @return error BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS()
     * @return key the key or uint(-1)
     * @return nextIndex the next index if there is one or 0
     */
    function keyAtIndexHasNext(Mappings.AddressBytes32ArrayMap storage _map, uint _index) public view returns (uint error, address key, uint nextIndex) {
        (error, key) = keyAtIndex(_map, _index);
        if (++_index < _map.keys.length) {
            nextIndex = _index;
        }
    }

    /**
     * @dev Retrieves the array at the given index position and the index of the next array.
     *
     * @dev Internal function to retrieve the value and nextIndex from a given Map
     * @param _map the AddressArrayMap
     * @param _index the index
     * @return BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS(), value or bytes32[], and nextIndex
     */
    function valueAtIndexHasNext(Mappings.AddressBytes32ArrayMap storage _map, uint _index) public view returns (uint error, bytes32[] memory value, uint nextIndex) {
        address key;
        (error, key, nextIndex) = keyAtIndexHasNext(_map, _index);
        if (error == BaseErrors.NO_ERROR()) {
            value = get(_map, key);
        }
    }


    /**
     * ---------> AddressAddressMap <---------
     */

    /**
     * @dev Inserts the given value at the specified key in the provided map, but only
     * if the key does not exist, yet. The `insert` function essentially behaves like a database insert
     * in that it avoids entering duplicate keys. In most cases you'd want to use `insertOrUpdate(...)`
     *
     * @param _map the map
     * @param _key the key
     * @param _value the value
     * @return BaseErrors.NO_ERROR or BaseErrors.RESOURCE_ALREADY_EXISTS
     */
    function insert(Mappings.AddressAddressMap storage _map, address _key, address _value) public returns (uint)
    {
        if (_map.rows[_key].exists) { return BaseErrors.RESOURCE_ALREADY_EXISTS(); }
        insertOrUpdate(_map, _key, _value);
        return BaseErrors.NO_ERROR();
    }

    /**
     * @dev Inserts or updates the given value at the specified key in the provided map.
     *
     * @param _map the map
     * @param _key the key
     * @param _value the value
     * @return the size of the map after the operation
     */
    function insertOrUpdate(Mappings.AddressAddressMap storage _map, address _key, address _value) public returns (uint)
    {
        if (_map.rows[_key].exists) {
            _map.rows[_key].value = _value;
        } else {
            _map.rows[_key].keyIdx = (_map.keys.push(_key)-1);
            _map.rows[_key].value = _value;
            _map.rows[_key].exists = true;
        }
        return _map.keys.length;
    }

    /**
     * @dev Removes the entry registered at the specified key in the provided map.
     * @dev the _map.keys array may get re-ordered by this operation: unless the removed entry was
     * the last element in the map's keys, the last key will be moved into the void position created
     * by the removal.
     *
     * @param _map the map
     * @param _key the key
     * @return BaseErrors.NO_ERROR or BaseErrors.RESOURCE_NOT_FOUND.
     */
    function remove(Mappings.AddressAddressMap storage _map, address _key) public returns (uint) {
         if (!_map.rows[_key].exists) { return BaseErrors.RESOURCE_NOT_FOUND(); }
         address swapKey = Mappings.deleteInKeys(_map.keys, _map.rows[_key].keyIdx);
         if (swapKey != address(0)) { _map.rows[swapKey].keyIdx = _map.rows[_key].keyIdx; }
         delete _map.rows[_key];
         return BaseErrors.NO_ERROR();
     }

    /**
     * @dev Removes all entries stored in the mapping.
     *
     * @param _map the map
     * @return the number of removed entries
     */
    function clear(Mappings.AddressAddressMap storage _map) public returns (uint) {
        uint l = _map.keys.length;
        for(uint i = 0; i < l; i++) {
            delete _map.rows[_map.keys[i]];
        }
        _map.keys.length = 0;
        return l;
    }

    /**
     * Convenience function to return the row[_key].exists value.
     * @return true if the map contains valid values at the specified key, false otherwise.
     */
    function exists(Mappings.AddressAddressMap storage _map, address _key) public view returns (bool) {
        return _map.rows[_key].exists;
    }

    /**
    * @return the value registered at the specified key, or 0x0 if it doesn't exist
    */
    function get(Mappings.AddressAddressMap storage _map, address _key) public view returns (address) {
        return _map.rows[_key].value;
    }

    /**
     * @return the index of the given key or int_constant uint(-1) if the key does not exist
     */
    function keyIndex(Mappings.AddressAddressMap storage _map, address _key) public view returns (uint) {
        if (!_map.rows[_key].exists) { return uint(-1); }
        return _map.rows[_key].keyIdx;
    }

    /**
     * @dev Retrieves the key at the given index, if it exists.
     *
     * @param _map the map
     * @param _index the index
     * @return (BaseErrors.NO_ERROR(), key) or (BaseErrors.INDEX_OUT_OF_BOUNDS(), 0x0)
     */
    function keyAtIndex(Mappings.AddressAddressMap storage _map, uint _index) public view returns (uint, address) {
        return Mappings.keyAtIndex(_map.keys, _index);
    }

    /**
     * @dev Retrieves the key at the given index position and the index of the next artifact.
     *
     * @param _map the map
     * @param _index the index
     * @return error BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS()
     * @return key the key or 0x0
     * @return nextindex the next index if there is one or 0
     */
    function keyAtIndexHasNext(Mappings.AddressAddressMap storage _map, uint _index) public view returns (uint error, address key, uint nextIndex) {
        (error, key) = keyAtIndex(_map, _index);
        if (++_index < _map.keys.length) {
            nextIndex = _index;
        }
    }

    /**
     * @dev Retrieves the value at the given index position and the index of the next address.
     *
     * @param _map the map
     * @param _index the index
     * @return BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS(), value, and nextIndex
     */
    function valueAtIndexHasNext(Mappings.AddressAddressMap storage _map, uint _index) public view returns (uint error, address value, uint nextIndex) {
        address key;
        (error, key, nextIndex) = keyAtIndexHasNext(_map, _index);
        if (error == BaseErrors.NO_ERROR()) {
            value = get(_map, key);
        }
    }

    /**
     * ---------> AddressAddressArrayMap <---------
     */

    /**
     * @dev Inserts the given address array value at the specified key in the provided map, but only
     * if the key does not exist, yet. The `insert` function essentially behaves like a database insert
     * in that it avoids entering duplicate keys. In most cases you'd want to use `insertOrUpdate(...)`
     *
     * @param _map the map
     * @param _key the key
     * @param _value the value
     * @return BaseErrors.NO_ERROR() or BaseErrors.RESOURCE_ALREADY_EXISTS()
     */
    function insert(Mappings.AddressAddressArrayMap storage _map, address _key, address[] memory _value) public returns (uint)
    {
        if (_map.rows[_key].exists) { return BaseErrors.RESOURCE_ALREADY_EXISTS(); }
        insertOrUpdate(_map, _key, _value);
        return BaseErrors.NO_ERROR();
    }

    /**
     * @dev Inserts or updates the given address array value at the specified key in the provided map.
     *
     * @param _map the map
     * @param _key the key
     * @param _value the value
     * @return the size of the map after the operation
     */
    function insertOrUpdate(Mappings.AddressAddressArrayMap storage _map, address _key, address[] memory _value) public returns (uint)
    {
        if (_map.rows[_key].exists) {
            _map.rows[_key].value = _value;
        } else {
            _map.rows[_key].keyIdx = (_map.keys.push(_key)-1);
            _map.rows[_key].value = _value;
            _map.rows[_key].exists = true;
        }
        return _map.keys.length;
    }

    /**
     * @dev Adds the specified value to the array that is stored in the map under the given key. The boolean parameter can be used to avoid duplicate values in the array.
     * @dev Note that the array will be automatically initiated even if there was no prior entry at the specified key. If you want to make sure the key is valid, use exists(key).
     * @param _map the map
     * @param _key the key for the array
     * @param _value the value to store in the array
     * @param _unique set to true if the value should only be added if it does not already exist in the array
     * @return the length of the array after the operation
     */
    function addToArray(Mappings.AddressAddressArrayMap storage _map, address _key, address _value, bool _unique) public returns (uint) {
        if (!_unique || (_unique && !_map.rows[_key].value.contains(_value))) {
            _map.rows[_key].value.push(_value);
        }
        return _map.rows[_key].value.length;
    }

    /**
     * @dev Removes the given value from the inner array in the given map structure. The bool parameter controls if 'all' occurences of the value should be deleted.
     * @dev Searching for the value to be deleted starts at the end of the array, but LIFO is not guaranteed, because entries can be moved around as part of this function,
     * i.e. when the deletion does not happen to be at the end of the array, the last entry is swapped into position of the deleted item and the array is truncated at the end.
     * @param _map the map
     * @param _key the key for the array
     * @param _value the value to be deleted in the array
     * @param _all if true, the entire array will be traversed and all occurences deleted, if false only the first encountered one
     * @return the resulting array length
     */
    function removeFromArray(Mappings.AddressAddressArrayMap storage _map, address _key, address _value, bool _all) public returns (uint) {
        if (_map.rows[_key].value.length == 0) { return 0; }
        // Note that due to uint 0 - 1 rolling over, a non-zero-based index is used in the loop
        for (uint i = _map.rows[_key].value.length; i > 0; i--) {
            if (_map.rows[_key].value[i-1] == _value) {
                if (i != _map.rows[_key].value.length) {
                    // copy the last element into the to be deleted position
                    _map.rows[_key].value[i-1] = _map.rows[_key].value[_map.rows[_key].value.length-1];
                }
                // truncate from the end
                _map.rows[_key].value.length--;
                if (!_all) { break; }
            }
        }
        return _map.rows[_key].value.length;
    }

    /**
     * @dev Removes the address array registered at the specified key in the provided map.
     * @dev the _map.keys array might get re-ordered by this operation: if the removed entry was not
     * the last element in the map's keys, the last element will be moved into the void position created
     * by the removal.
     *
     * @param _map the AddressArrayMap
     * @param _key the key
     * @return BaseErrors.NO_ERROR() or BaseErrors.RESOURCE_NOT_FOUND().
     */
    function remove(Mappings.AddressAddressArrayMap storage _map, address _key) public returns (uint) {
         if (!_map.rows[_key].exists) { return BaseErrors.RESOURCE_NOT_FOUND(); }
         address swapKey = Mappings.deleteInKeys(_map.keys, _map.rows[_key].keyIdx);
         if (swapKey != address(0)) { _map.rows[swapKey].keyIdx = _map.rows[_key].keyIdx; }
         delete _map.rows[_key];
         return BaseErrors.NO_ERROR();
     }

    /**
     * @dev Removes all entries stored in the mapping.
     *
     * @param _map the AddressArrayMap
     * @return the number of removed entries
     */
    function clear(Mappings.AddressAddressArrayMap storage _map) public returns (uint) {
        uint l = _map.keys.length;
        for(uint i = 0; i < l; i++) {
            delete _map.rows[_map.keys[i]];
        }
        _map.keys.length = 0;
        return l;
    }

    /**
     * Convenience function to return the row[_key].exists value.
     * @return true if the map contains valid values at the specified key, false otherwise.
     */
    function exists(Mappings.AddressAddressArrayMap storage _map, address _key) public view returns (bool) {
        return _map.rows[_key].exists;
    }

    /**
     * @dev Retrieves the address array in the map at the specified key.
     *
     * @param _map the AddressArrayMap
     * @param _key the key
     * @return the addresses array value registered at the specified key, or empty address[] if it doesn't exist
     */
   function get(Mappings.AddressAddressArrayMap storage _map, address _key) public view returns (address[] memory) {
        return _map.rows[_key].value;
    }

    /**
     * @dev Retrieves the index of the specified key.
     *
     * @param _map the AddressArrayMap
     * @param _key the key
     * @return the index of the given key or int_constant uint(-1) if the key does not exist
     */
    function keyIndex(Mappings.AddressAddressArrayMap storage _map, address _key) public view returns (uint) {
        if (!_map.rows[_key].exists) { return uint(-1); }
        return _map.rows[_key].keyIdx;
    }

    /**
     * @dev Retrieves the key at the given index, if it exists.
     *
     * @param _map the AddressArrayMap
     * @param _index the index
     * @return (BaseErrors.NO_ERROR(), key) or (BaseErrors.INDEX_OUT_OF_BOUNDS(), "")
     */
    function keyAtIndex(Mappings.AddressAddressArrayMap storage _map, uint _index) public view returns (uint, address) {
        return Mappings.keyAtIndex(_map.keys, _index);
    }

    /**
     * @dev Retrieves the key at the given index position and the index of the next artifact.
     *
     * @param _map the map
     * @param _index the index
     * @return error BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS()
     * @return key the key or 0x0
     * @return nextindex the next index if there is one or 0
     */
    function keyAtIndexHasNext(Mappings.AddressAddressArrayMap storage _map, uint _index) public view returns(uint error, address key, uint nextIndex) {
        (error, key) = keyAtIndex(_map, _index);
        if (++_index < _map.keys.length) {
            nextIndex = _index;
        }
    }

    /**
     * @dev Retrieves the array at the given index position and the index of the next array.
     *
     * @dev Internal function to retrieve the value and nextIndex from a given Map
     * @param _map the AddressArrayMap
     * @param _index the index
     * @return BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS(), value or address[], and nextIndex
     */
    function valueAtIndexHasNext(Mappings.AddressAddressArrayMap storage _map, uint _index) public view returns (uint error, address[] memory value, uint nextIndex) {
        address key;
        (error, key, nextIndex) = keyAtIndexHasNext(_map, _index);
        if (error == BaseErrors.NO_ERROR()) {
            value = get(_map, key);
        }
    }

    /**
     * ---------> UintAddressMap <---------
     */

    /**
     * @dev Inserts the given value at the specified key in the provided map, but only
     * if the key does not exist, yet. The `insert` function essentially behaves like a database insert
     * in that it avoids entering duplicate keys. In most cases you'd want to use `insertOrUpdate(...)`
     *
     * @param _map the map
     * @param _key the key
     * @param _value the value
     * @return BaseErrors.NO_ERROR or BaseErrors.RESOURCE_ALREADY_EXISTS
     */
    function insert(Mappings.UintAddressMap storage _map, uint _key, address _value) public returns (uint)
    {
        if (_map.rows[_key].exists) { return BaseErrors.RESOURCE_ALREADY_EXISTS(); }
        insertOrUpdate(_map, _key, _value);
        return BaseErrors.NO_ERROR();
    }

    /**
     * @dev Inserts or updates the given value at the specified key in the provided map.
     *
     * @param _map the map
     * @param _key the key
     * @param _value the value
     * @return the size of the map after the operation
     */
    function insertOrUpdate(Mappings.UintAddressMap storage _map, uint _key, address _value) public returns (uint)
    {
        if (_map.rows[_key].exists) {
            _map.rows[_key].value = _value;
        } else {
            _map.rows[_key].keyIdx = (_map.keys.push(_key)-1);
            _map.rows[_key].value = _value;
            _map.rows[_key].exists = true;
        }
        return _map.keys.length;
    }

    /**
     * @dev Removes the entry registered at the specified key in the provided map.
     * @dev the _map.keys array might get re-ordered by this operation: if the removed entry was not
     * the last element in the map's keys, the last element will be moved into the void position created
     * by the removal.
     *
     * @param _map the map
     * @param _key the key
     * @return BaseErrors.NO_ERROR or BaseErrors.RESOURCE_NOT_FOUND.
     */
    function remove(Mappings.UintAddressMap storage _map, uint _key) public returns (uint) {
         if (!_map.rows[_key].exists) { return BaseErrors.RESOURCE_NOT_FOUND(); }
         uint swapKey = Mappings.deleteInKeys(_map.keys, _map.rows[_key].keyIdx);
         if (swapKey != uint(-1)) { _map.rows[swapKey].keyIdx = _map.rows[_key].keyIdx; }
         delete _map.rows[_key];
         return BaseErrors.NO_ERROR();
     }

    /**
     * @dev Removes all entries stored in the mapping.
     *
     * @param _map the map
     * @return the number of removed entries
     */
    function clear(Mappings.UintAddressMap storage _map) public returns (uint) {
        uint l = _map.keys.length;
        for(uint i = 0; i < l; i++) {
            delete _map.rows[_map.keys[i]];
        }
        _map.keys.length = 0;
        return l;
    }

    /**
     * Convenience function to return the row[_key].exists value.
     * @return true if the map contains valid values at the specified key, false otherwise.
     */
    function exists(Mappings.UintAddressMap storage _map, uint _key) public view returns (bool) {
        return _map.rows[_key].exists;
    }

    /**
    * @return the value registered at the specified key, or 0x0 if it doesn't exist
    */
   function get(Mappings.UintAddressMap storage _map, uint _key) public view returns (address) {
        return _map.rows[_key].value;
    }

    /**
     * @dev Retrieves the index of the specified key.
     *
     * @param _map the map
     * @param _key the key
     * @return the index of the given key or int_constant uint(-1) if the key does not exist
     */
    function keyIndex(Mappings.UintAddressMap storage _map, uint _key) public view returns (uint) {
        if (!_map.rows[_key].exists) { return uint(-1); }
        return _map.rows[_key].keyIdx;
    }

    /**
     * @dev Retrieves the key at the given index, if it exists.
     *
     * @param _map the map
     * @param _index the index
     * @return (BaseErrors.NO_ERROR(), key) or (BaseErrors.INDEX_OUT_OF_BOUNDS(), uint(-1))
     */
    function keyAtIndex(Mappings.UintAddressMap storage _map, uint _index) public view returns (uint, uint) {
        return Mappings.keyAtIndex(_map.keys, _index);
    }

    /**
     * @dev Retrieves the key at the given index position and the index of the next artifact.
     *
     * @param _map the map
     * @param _index the index
     * @return error BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS()
     * @return key the key or uint(-1)
     * @return nextindex the next index if there is one or 0
     */
    function keyAtIndexHasNext(Mappings.UintAddressMap storage _map, uint _index) public view returns (uint error, uint key, uint nextIndex) {
        (error, key) = keyAtIndex(_map, _index);
        if (++_index < _map.keys.length) {
            nextIndex = _index;
        }
    }

    /**
     * @dev Retrieves the value at the given index position and the index of the next address.
     *
     * @dev Internal function to retrieve the value and nextIndex from a given Map
     * @param _map the map
     * @param _index the index
     * @return BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS(), value, and nextIndex
     */
    function valueAtIndexHasNext(Mappings.UintAddressMap storage _map, uint _index) public view returns (uint error, address value, uint nextIndex) {
        uint key;
        (error, key, nextIndex) = keyAtIndexHasNext(_map, _index);
        if (error == BaseErrors.NO_ERROR()) {
            value = get(_map, key);
        }
    }

    /**
     * ---------> UintAddressArrayMap <---------
     */

    /**
     * @dev Inserts the given address array value at the specified key in the provided map, but only
     * if the key does not exist, yet. The `insert` function essentially behaves like a database insert
     * in that it avoids entering duplicate keys. In most cases you'd want to use `insertOrUpdate(...)`
     *
     * @param _map the map
     * @param _key the key
     * @param _value the value
     * @return BaseErrors.NO_ERROR() or BaseErrors.RESOURCE_ALREADY_EXISTS()
     */
    function insert(Mappings.UintAddressArrayMap storage _map, uint _key, address[] memory _value) public returns (uint)
    {
        if (_map.rows[_key].exists) { return BaseErrors.RESOURCE_ALREADY_EXISTS(); }
        insertOrUpdate(_map, _key, _value);
        return BaseErrors.NO_ERROR();
    }

    /**
     * @dev Inserts or updates the given address array value at the specified key in the provided map.
     *
     * @param _map the map
     * @param _key the key
     * @param _value the value
     * @return the size of the map after the operation
     */
    function insertOrUpdate(Mappings.UintAddressArrayMap storage _map, uint _key, address[] memory _value) public returns (uint)
    {
        if (_map.rows[_key].exists) {
            _map.rows[_key].value = _value;
        } else {
            _map.rows[_key].keyIdx = (_map.keys.push(_key)-1);
            _map.rows[_key].value = _value;
            _map.rows[_key].exists = true;
        }
        return _map.keys.length;
    }

    /**
     * @dev Adds the specified value to the array that is stored in the map under the given key. The boolean parameter can be used to avoid duplicate values in the array.
     * @dev Note that the array will be automatically initiated even if there was no prior entry at the specified key. If you want to make sure the key is valid, use exists(key).
     * @param _map the map
     * @param _key the key for the array
     * @param _value the value to store in the array
     * @param _unique set to true if the value should only be added if it does not already exist in the array
     * @return the length of the array after the operation
     */
    function addToArray(Mappings.UintAddressArrayMap storage _map, uint _key, address _value, bool _unique) public returns (uint) {
        if (!_unique || (_unique && !_map.rows[_key].value.contains(_value))) {
            _map.rows[_key].value.push(_value);
        }
        return _map.rows[_key].value.length;
    }

    /**
     * @dev Removes the given value from the inner array in the given map structure. The bool parameter controls if 'all' occurences of the value should be deleted.
     * @dev Searching for the value to be deleted starts at the end of the array, but LIFO is not guaranteed, because entries can be moved around as part of this function,
     * i.e. when the deletion does not happen to be at the end of the array, the last entry is swapped into position of the deleted item and the array is truncated at the end.
     * @param _map the map
     * @param _key the key for the array
     * @param _value the value to be deleted in the array
     * @param _all if true, the entire array will be traversed and all occurences deleted, if false only the first encountered one
     * @return the resulting array length
     */
    function removeFromArray(Mappings.UintAddressArrayMap storage _map, uint _key, address _value, bool _all) public returns (uint) {
        if (_map.rows[_key].value.length == 0) { return 0; }
        // Note that due to uint 0 - 1 rolling over, a non-zero-based index is used in the loop
        for (uint i = _map.rows[_key].value.length; i > 0; i--) {
            if (_map.rows[_key].value[i-1] == _value) {
                if (i != _map.rows[_key].value.length) {
                    // copy the last element into the to be deleted position
                    _map.rows[_key].value[i-1] = _map.rows[_key].value[_map.rows[_key].value.length-1];
                }
                // truncate from the end
                _map.rows[_key].value.length--;
                if (!_all) { break; }
            }
        }
        return _map.rows[_key].value.length;
    }

    /**
     * @dev Removes the address array registered at the specified key in the provided map.
     * @dev the _map.keys array might get re-ordered by this operation: if the removed entry was not
     * the last element in the map's keys, the last element will be moved into the void position created
     * by the removal.
     *
     * @param _map the AddressArrayMap
     * @param _key the key
     * @return BaseErrors.NO_ERROR() or BaseErrors.RESOURCE_NOT_FOUND().
     */
    function remove(Mappings.UintAddressArrayMap storage _map, uint _key) public returns (uint) {
         if (!_map.rows[_key].exists) { return BaseErrors.RESOURCE_NOT_FOUND(); }
         uint swapKey = Mappings.deleteInKeys(_map.keys, _map.rows[_key].keyIdx);
         if (swapKey != uint(-1)) { _map.rows[swapKey].keyIdx = _map.rows[_key].keyIdx; }
         delete _map.rows[_key];
         return BaseErrors.NO_ERROR();
     }

    /**
     * @dev Removes all entries stored in the mapping.
     *
     * @param _map the AddressArrayMap
     * @return the number of removed entries
     */
    function clear(Mappings.UintAddressArrayMap storage _map) public returns (uint) {
        uint l = _map.keys.length;
        for(uint i = 0; i < l; i++) {
            delete _map.rows[_map.keys[i]];
        }
        _map.keys.length = 0;
        return l;
    }

    /**
     * Convenience function to return the row[_key].exists value.
     * @return true if the map contains valid values at the specified key, false otherwise.
     */
    function exists(Mappings.UintAddressArrayMap storage _map, uint _key) public view returns (bool) {
        return _map.rows[_key].exists;
    }

    /**
     * @dev Retrieves the address array in the map at the specified key.
     *
     * @param _map the AddressArrayMap
     * @param _key the key
     * @return the addresses array value registered at the specified key, or empty address[] if it doesn't exist
     */
   function get(Mappings.UintAddressArrayMap storage _map, uint _key) public view returns (address[] memory) {
        return _map.rows[_key].value;
    }

    /**
     * @dev Retrieves the index of the specified key.
     *
     * @param _map the AddressArrayMap
     * @param _key the key
     * @return the index of the given key or int_constant uint(-1) if the key does not exist
     */
    function keyIndex(Mappings.UintAddressArrayMap storage _map, uint _key) public view returns (uint) {
        if (!_map.rows[_key].exists) { return uint(-1); }
        return _map.rows[_key].keyIdx;
    }

    /**
     * @dev Retrieves the key at the given index, if it exists.
     *
     * @param _map the AddressArrayMap
     * @param _index the index
     * @return (BaseErrors.NO_ERROR(), key) or (BaseErrors.INDEX_OUT_OF_BOUNDS(), "")
     */
    function keyAtIndex(Mappings.UintAddressArrayMap storage _map, uint _index) public view returns (uint, uint) {
        return Mappings.keyAtIndex(_map.keys, _index);
    }

    /**
     * @dev Retrieves the key at the given index position and the index of the next artifact.
     *
     * @param _map the map
     * @param _index the index
     * @return error BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS()
     * @return key the key or uint(-1)
     * @return nextindex the next index if there is one or 0
     */
    function keyAtIndexHasNext(Mappings.UintAddressArrayMap storage _map, uint _index) public view returns (uint error, uint key, uint nextIndex) {
        (error, key) = keyAtIndex(_map, _index);
        if (++_index < _map.keys.length) {
            nextIndex = _index;
        }
    }

    /**
     * @dev Retrieves the array at the given index position and the index of the next array.
     *
     * @dev Internal function to retrieve the value and nextIndex from a given Map
     * @param _map the AddressArrayMap
     * @param _index the index
     * @return BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS(), value or address[], and nextIndex
     */
    function valueAtIndexHasNext(Mappings.UintAddressArrayMap storage _map, uint _index) public view returns (uint error, address[] memory value, uint nextIndex) {
        uint key;
        (error, key, nextIndex) = keyAtIndexHasNext(_map, _index);
        if (error == BaseErrors.NO_ERROR()) {
            value = get(_map, key);
        }
    }

    /**
     * ---------> UintBytes32ArrayMap <---------
     */

    /**
     * @dev Inserts the given bytes32 array value at the specified key in the provided map, but only
     * if the key does not exist, yet. The `insert` function essentially behaves like a database insert
     * in that it avoids entering duplicate keys. In most cases you'd want to use `insertOrUpdate(...)`
     *
     * @param _map the map
     * @param _key the key
     * @param _value the value
     * @return BaseErrors.NO_ERROR() or BaseErrors.RESOURCE_ALREADY_EXISTS()
     */
    function insert(Mappings.UintBytes32ArrayMap storage _map, uint _key, bytes32[] memory _value) public returns (uint) {
        if (_map.rows[_key].exists) { return BaseErrors.RESOURCE_ALREADY_EXISTS(); }
        insertOrUpdate(_map, _key, _value);
        return BaseErrors.NO_ERROR();
    }

    /**
     * @dev Inserts or updates the given address array value at the specified key in the provided map.
     *
     * @param _map the map
     * @param _key the key
     * @param _value the value
     * @return the size of the map after the operation
     */
    function insertOrUpdate(Mappings.UintBytes32ArrayMap storage _map, uint _key, bytes32[] memory _value) public returns (uint) {
        if (_map.rows[_key].exists) {
            _map.rows[_key].value = _value;
        } else {
            _map.rows[_key].keyIdx = (_map.keys.push(_key)-1);
            _map.rows[_key].value = _value;
            _map.rows[_key].exists = true;
        }
        return _map.keys.length;
    }

    /**
     * @dev Adds the specified value to the array that is stored in the map under the given key. The boolean parameter can be used to avoid duplicate values in the array.
     * @dev Note that the array will be automatically initiated even if there was no prior entry at the specified key. If you want to make sure the key is valid, use exists(key).
     * @param _map the map
     * @param _key the key for the array
     * @param _value the value to store in the array
     * @param _unique set to true if the value should only be added if it does not already exist in the array
     * @return the length of the array after the operation
     */
    function addToArray(Mappings.UintBytes32ArrayMap storage _map, uint _key, bytes32 _value, bool _unique) public returns (uint) {
        if (!_unique || (_unique && !_map.rows[_key].value.contains(_value))) {
            _map.rows[_key].value.push(_value);
        }
        return _map.rows[_key].value.length;
    }

    /**
     * @dev Removes the given value from the inner array in the given map structure. The bool parameter controls if 'all' occurences of the value should be deleted.
     * @dev Searching for the value to be deleted starts at the end of the array, but LIFO is not guaranteed, because entries can be moved around as part of this function,
     * i.e. when the deletion does not happen to be at the end of the array, the last entry is swapped into position of the deleted item and the array is truncated at the end.
     * @param _map the map
     * @param _key the key for the array
     * @param _value the value to be deleted in the array
     * @param _all if true, the entire array will be traversed and all occurences deleted, if false only the first encountered one
     * @return the resulting array length
     */
    function removeFromArray(Mappings.UintBytes32ArrayMap storage _map, uint _key, bytes32 _value, bool _all) public returns (uint) {
        if (_map.rows[_key].value.length == 0) { return 0; }
        // Note that due to uint 0 - 1 rolling over, a non-zero-based index is used in the loop
        for (uint i = _map.rows[_key].value.length; i > 0; i--) {
            if (_map.rows[_key].value[i-1] == _value) {
                if (i != _map.rows[_key].value.length) {
                    // copy the last element into the to be deleted position
                    _map.rows[_key].value[i-1] = _map.rows[_key].value[_map.rows[_key].value.length-1];
                }
                // truncate from the end
                _map.rows[_key].value.length--;
                if (!_all) { break; }
            }
        }
        return _map.rows[_key].value.length;
    }

    /**
     * @dev Removes the address array registered at the specified key in the provided map.
     * @dev the _map.keys array might get re-ordered by this operation: if the removed entry was not
     * the last element in the map's keys, the last element will be moved into the void position created
     * by the removal.
     *
     * @param _map the map
     * @param _key the key
     * @return BaseErrors.NO_ERROR() or BaseErrors.RESOURCE_NOT_FOUND().
     */
    function remove(Mappings.UintBytes32ArrayMap storage _map, uint _key) public returns (uint) {
         if (!_map.rows[_key].exists) { return BaseErrors.RESOURCE_NOT_FOUND(); }
         uint swapKey = Mappings.deleteInKeys(_map.keys, _map.rows[_key].keyIdx);
         if (swapKey != uint(-1)) { _map.rows[swapKey].keyIdx = _map.rows[_key].keyIdx; }
         delete _map.rows[_key];
         return BaseErrors.NO_ERROR();
     }

    /**
     * @dev Removes all entries stored in the mapping.
     *
     * @param _map the AddressArrayMap
     * @return the number of removed entries
     */
    function clear(Mappings.UintBytes32ArrayMap storage _map) public returns (uint) {
        uint l = _map.keys.length;
        for(uint i = 0; i < l; i++) {
            delete _map.rows[_map.keys[i]];
        }
        _map.keys.length = 0;
        return l;
    }

    /**
     * Convenience function to return the row[_key].exists value.
     * @return true if the map contains valid values at the specified key, false otherwise.
     */
    function exists(Mappings.UintBytes32ArrayMap storage _map, uint _key) public view returns (bool) {
        return _map.rows[_key].exists;
    }

    /**
     * @dev Retrieves the address array in the map at the specified key.
     *
     * @param _map the AddressArrayMap
     * @param _key the key
     * @return the addresses array value registered at the specified key, or empty bytes32[] if it doesn't exist
     */
   function get(Mappings.UintBytes32ArrayMap storage _map, uint _key) public view returns (bytes32[] memory) {
        return _map.rows[_key].value;
    }

    /**
     * @dev Retrieves the index of the specified key.
     *
     * @param _map the AddressArrayMap
     * @param _key the key
     * @return the index of the given key or int_constant uint(-1) if the key does not exist
     */
    function keyIndex(Mappings.UintBytes32ArrayMap storage _map, uint _key) public view returns (uint) {
        if (!_map.rows[_key].exists) { return uint(-1); }
        return _map.rows[_key].keyIdx;
    }

    /**
     * @dev Retrieves the key at the given index, if it exists.
     *
     * @param _map the AddressArrayMap
     * @param _index the index
     * @return (BaseErrors.NO_ERROR(), key) or (BaseErrors.INDEX_OUT_OF_BOUNDS(), "")
     */
    function keyAtIndex(Mappings.UintBytes32ArrayMap storage _map, uint _index) public view returns (uint, uint) {
        return Mappings.keyAtIndex(_map.keys, _index);
    }

    /**
     * @dev Retrieves the key at the given index position and the index of the next artifact.
     *
     * @param _map the map
     * @param _index the index
     * @return error BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS()
     * @return key the key or uint(-1)
     * @return nextindex the next index if there is one or 0
     */
    function keyAtIndexHasNext(Mappings.UintBytes32ArrayMap storage _map, uint _index) public view returns (uint error, uint key, uint nextIndex) {
        (error, key) = keyAtIndex(_map, _index);
        if (++_index < _map.keys.length) {
            nextIndex = _index;
        }
    }

    /**
     * @dev Retrieves the array at the given index position and the index of the next array.
     *
     * @dev Internal function to retrieve the value and nextIndex from a given Map
     * @param _map the AddressArrayMap
     * @param _index the index
     * @return BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS(), value or bytes32[], and nextIndex
     */
    function valueAtIndexHasNext(Mappings.UintBytes32ArrayMap storage _map, uint _index) public view returns (uint error, bytes32[] memory value, uint nextIndex) {
        uint key;
        (error, key, nextIndex) = keyAtIndexHasNext(_map, _index);
        if (error == BaseErrors.NO_ERROR()) {
            value = get(_map, key);
        }
    }

    /**
     * ---------> StringAddressMap <---------
     */

    /**
     * @dev Inserts the given value at the specified key in the provided map, but only
     * if the key does not exist, yet. The `insert` function essentially behaves like a database insert
     * in that it avoids entering duplicate keys. In most cases you'd want to use `insertOrUpdate(...)`
     *
     * @param _map the AddressMap
     * @param _key the key
     * @param _value the value
     * @return BaseErrors.NO_ERROR or BaseErrors.RESOURCE_ALREADY_EXISTS
     */
    function insert(Mappings.StringAddressMap storage _map, string memory _key, address _value) public returns (uint)
    {
        if (_map.rows[_key].exists) { return BaseErrors.RESOURCE_ALREADY_EXISTS(); }
        insertOrUpdate(_map, _key, _value);
        return BaseErrors.NO_ERROR();
    }

    /**
     * @dev Inserts or updates the given value at the specified key in the provided map.
     *
     * @param _map the AddressMap
     * @param _key the key
     * @param _value the value
     * @return the size of the map after the operation
     */
    function insertOrUpdate(Mappings.StringAddressMap storage _map, string memory _key, address _value) public returns (uint)
    {
        if (_map.rows[_key].exists) {
            _map.rows[_key].value = _value;
        } else {
            _map.rows[_key].keyIdx = (_map.keys.push(_key)-1);
            _map.rows[_key].value = _value;
            _map.rows[_key].exists = true;
        }
        return _map.keys.length;
    }

    /**
     * @dev Removes the entry registered at the specified key in the provided map.
     * @dev the _map.keys array may get re-ordered by this operation: unless the removed entry was
     * the last element in the map's keys, the last key will be moved into the void position created
     * by the removal.
     *
     * @param _map the AddressMap
     * @param _key the key
     * @return BaseErrors.NO_ERROR or BaseErrors.RESOURCE_NOT_FOUND.
     */
    function remove(Mappings.StringAddressMap storage _map, string memory _key) public returns (uint) {
        if (!_map.rows[_key].exists) { return BaseErrors.RESOURCE_NOT_FOUND(); }
        string memory swapKey = Mappings.deleteInKeys(_map.keys, _map.rows[_key].keyIdx);
        if (bytes(swapKey).length > 0) {
            _map.rows[swapKey].keyIdx = _map.rows[_key].keyIdx;
        }
        delete _map.rows[_key];
        return BaseErrors.NO_ERROR();
     }

    /**
     * @dev Removes all entries stored in the map.
     * @param _map the map
     * @return the number of removed entries
     */
    function clear(Mappings.StringAddressMap storage _map) public returns (uint) {
        uint l = _map.keys.length;
        for(uint i = 0; i < l; i++) {
            delete _map.rows[_map.keys[i]];
        }
        _map.keys.length = 0;
        return l;
    }

    /**
     * @dev Convenience function to return the row[_key].exists value.
     * @return true if the map contains valid values at the specified key, false otherwise.
     */
    function exists(Mappings.StringAddressMap storage _map, string memory _key) public view returns (bool) {
        return _map.rows[_key].exists;
    }

    /**
     * @return the value registered at the specified key, or 0x0 if it doesn't exist
     */
    function get(Mappings.StringAddressMap storage _map, string memory _key) public view returns (address) {
        return _map.rows[_key].value;
    }

    /**
     * @return the index of the given key or int_constant uint(-1) if the key does not exist
     */
    function keyIndex(Mappings.StringAddressMap storage _map, string memory _key) public view returns (uint) {
        if (!_map.rows[_key].exists) { return uint(-1); }
        return _map.rows[_key].keyIdx;
    }

    /**
     * @dev Retrieves the key at the given index, if it exists.
     *
     * @param _map the map
     * @param _index the index
     * @return (BaseErrors.NO_ERROR(), key) or (BaseErrors.INDEX_OUT_OF_BOUNDS(), "")
     */
    function keyAtIndex(Mappings.StringAddressMap storage _map, uint _index) public view returns (uint, string memory) {
        return Mappings.keyAtIndex(_map.keys, _index);
    }

    /**
     * @dev Retrieves the key at the given index position and the index of the next artifact.
     *
     * @param _map the map
     * @param _index the index
     * @return error BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS()
     * @return key the key or ""
     * @return nextindex the next index if there is one or 0
     */
    function keyAtIndexHasNext(Mappings.StringAddressMap storage _map, uint _index) public view returns (uint error, string memory key, uint nextIndex) {
        (error, key) = keyAtIndex(_map, _index);
        if (++_index < _map.keys.length) {
            nextIndex = _index;
        }
    }

    /**
     * @dev Retrieves the value at the given index position and the index of the next address.
     *
     * @param _map the map
     * @param _index the index
     * @return BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS(), value, and nextIndex
     */
    function valueAtIndexHasNext(Mappings.StringAddressMap storage _map, uint _index) public view returns (uint error, address value, uint nextIndex) {
        string memory key;
        (error, key, nextIndex) = keyAtIndexHasNext(_map, _index);
        if (error == BaseErrors.NO_ERROR()) {
            value = get(_map, key);
        }
    }

}