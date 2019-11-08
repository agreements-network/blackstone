pragma solidity ^0.5;

import "commons-base/BaseErrors.sol";

import "commons-collections/Mappings.sol";
import "commons-collections/MappingsLib.sol";

contract MappingsLibTest {

    using MappingsLib for Mappings.Bytes32AddressMap;
    using MappingsLib for Mappings.Bytes32StringMap;
    using MappingsLib for Mappings.Bytes32AddressArrayMap;
    using MappingsLib for Mappings.Bytes32Bytes32Map;
    using MappingsLib for Mappings.Bytes32UintMap;    
    using MappingsLib for Mappings.AddressBytes32Map;
    using MappingsLib for Mappings.AddressBoolMap;
    using MappingsLib for Mappings.AddressBytes32ArrayMap;
    using MappingsLib for Mappings.AddressAddressMap;
    using MappingsLib for Mappings.AddressAddressArrayMap;
    using MappingsLib for Mappings.UintAddressMap;
    using MappingsLib for Mappings.UintAddressArrayMap;
    using MappingsLib for Mappings.UintBytes32ArrayMap;
    using MappingsLib for Mappings.StringAddressMap;

    // Map structures under test
    Mappings.Bytes32AddressMap b32AddrMap;
    Mappings.Bytes32StringMap b32StringMap;
    Mappings.Bytes32AddressArrayMap b32AddrArrayMap;
    Mappings.Bytes32Bytes32Map b32b32Map;
    Mappings.Bytes32UintMap b32UintMap;    
    Mappings.AddressBytes32Map addrB32Map;
    Mappings.AddressBoolMap addrBoolMap;
    Mappings.AddressBytes32ArrayMap addrB32ArrayMap;
    Mappings.AddressAddressMap addrAddrMap;
    Mappings.AddressAddressArrayMap addrAddrArrayMap;
    Mappings.UintAddressMap uintAddrMap;
    Mappings.UintAddressArrayMap uintAddrArrayMap;
    Mappings.UintBytes32ArrayMap uintB32ArrayMap;
    Mappings.StringAddressMap strAddrMap;

    // test data
    address addr1 = 0x1040e6521541daB4E7ee57F21226dD17Ce9F0Fb7;
    address addr2 = 0x58fd1799aa32deD3F6eac096A1dC77834a446b9C;
    address addr3 = 0x68112f9380f75a13f6Ce2d5923F1dB8386EF1339;
    address addr4 = 0x776FDe59876aAB7D654D656e654Ed9876574c54c;
    address addr5 = 0x9834D45E546d56475c76Ab7656412DD123aE2345;
    bool bool_true = true;
    bool bool_false = false;
    bytes32 bytes32_1 = "Hugo";
    bytes32 bytes32_2 = "Violin";
    bytes32 bytes32_3 = "Cactus";
    bytes32 bytes32_4 = "Desk";
    bytes32 bytes32_5 = "Fox";
    bytes32 bytes32_key1 = "spider";
    bytes32 bytes32_val1 = "man";
    bytes32 bytes32_key2 = "thor";
    bytes32 bytes32_val2 = "loki";
    bytes32 bytes32_key3 = "baby";
    bytes32 bytes32_val3 = "driver";
    bytes32 bytes32_key11 = "number11";
    bytes32 bytes32_key12 = "number12";
    bytes32 bytes32_key13 = "number13";
    uint uint_val11 = 11;
    uint uint_val12 = 12;
    uint uint_val13 = 13;
    uint uint1 = 2;
    uint uint2 = 22;
    uint uint3 = 222;
    string str_1 = "Banana";
    string str_2 = "Apple";
    string str_3 = "Grape";

    address[] addresses1;
    address[] addresses2;
    address[] addresses3;
    bytes32[] bytes32Array1;
    bytes32[] bytes32Array2;
    bytes32[] bytes32Array3;
    Mappings.AddressBytes32Map addrB32Map1;
    Mappings.AddressBytes32Map addrB32Map2;
    Mappings.AddressBytes32Map addrB32Map3;


    /**
     * @dev Tests functions belonging to Bytes32AddressMap in Mappings.
     */
    function testBytes32AddressMap() external returns (string memory) {

        // reusable variables during test
        uint error;
        bytes32 key;
        address value;

        // New inserts test
        error = b32AddrMap.insert(bytes32_1, addr1);
        if (error != BaseErrors.NO_ERROR()) { return "Unexpected error for new insert."; }
        if (b32AddrMap.keys.length != 1) { return "Size expected to be 1 after insert."; }
        error = b32AddrMap.insert(bytes32_2, addr2);
        if (b32AddrMap.keys.length != 2) { return "Size expected to be 2 after insert."; }

        // Update test
        uint sizeBefore = b32AddrMap.keys.length;
        error = b32AddrMap.insert(bytes32_1, addr3);
        if (error != BaseErrors.RESOURCE_ALREADY_EXISTS()) { return "Expected RESOURCE_ALREADY_EXISTS error for overwrite insert."; }
        if (b32AddrMap.keys.length != sizeBefore) { return "Size should not have changed after failed insert."; }
        if (b32AddrMap.insertOrUpdate(bytes32_1, addr3) != sizeBefore) { return "Size should NOT have changed after update of existing entry."; }

        // Value tests
        if (!b32AddrMap.exists(bytes32_1)) { return "Key bytes32_1 should exist"; }
        if (b32AddrMap.exists("xxxTotallyFakeKey")) { return "Fake key should not exist"; }
        if (b32AddrMap.get(bytes32_1) != addr3) { return "Wrong value returned for key: bytes32_1"; }
        if (b32AddrMap.get(bytes32_2) != addr2) { return "Wrong value returned for key: bytes32_2"; }

        // add more entries
        error = b32AddrMap.insert(bytes32_3, addr3);
        if (b32AddrMap.keys.length != 3) { return "Size should be 3 after third 'insert'."; }

        // key tests
        if (b32AddrMap.keyIndex(bytes32_3) != 2) { return "Expected index 2 for bytes32_3."; }
        if (b32AddrMap.keyIndex("superBogusKey") != uint(-1)) { return "Expected index -1 for non-existing key."; }
        (error, key) = b32AddrMap.keyAtIndex(1);
        if (error != BaseErrors.NO_ERROR() && key != bytes32_2) { return "Expected no error and key bytes32_2 at index 1"; }
        (error, key) = b32AddrMap.keyAtIndex(999);
        if (error != BaseErrors.INDEX_OUT_OF_BOUNDS() || key != "") { return "Expected error and empty return value for out of range index."; }

        // Removal tests
        uint removedKeyIdx = b32AddrMap.keyIndex(bytes32_2);
        // remember the key of the last element which is about to be swapped by the remove()
        (error, key) = b32AddrMap.keyAtIndex(b32AddrMap.keys.length - 1);
        if (b32AddrMap.remove(bytes32_2) != BaseErrors.NO_ERROR()) { return "Unexpected error during removal of bytes32_2 entry."; }
        if (b32AddrMap.keys.length != 2) { return "Size expected to be 2 after removal"; }
        if (b32AddrMap.keyIndex(bytes32_2) != uint(-1)) { return "Expected index -1 for removed key."; }
        if (b32AddrMap.exists(bytes32_2) != false) { return "Name2 key should not exist anymore."; }
        if (b32AddrMap.keyIndex(bytes32_3) != removedKeyIdx) { return "The last element from key index should've been swapped into the index position of the removed element."; }

        b32AddrMap.clear();
        if (b32AddrMap.keys.length != 0) { return "Size should be 0 after clearing."; }

        // test iterator functions
        b32AddrMap.insert(bytes32_3, addr3);
        b32AddrMap.insert(bytes32_1, addr1);
        b32AddrMap.insert(bytes32_2, addr2);

        // key iteration test
        uint idx = 0;
        uint nextIdx = 1;
        // NOTE: collecting entities in a temporary array is difficult in Solidity at the moment
        // array needs to be sufficiently large to work!
        // http://solidity.readthedocs.io/en/latest/types.html#allocating-memory-arrays
        bytes32[3] memory keys;
        while( nextIdx > 0 ) {
            (error, key, nextIdx) = b32AddrMap.keyAtIndexHasNext(idx);
            if (error == BaseErrors.NO_ERROR()) {
                keys[idx] = key;
            }
            idx = nextIdx;
        }

        if (keys[0] != bytes32_3) { return "keys[0] != bytes32_3 after iteration"; }
        if (keys[1] != bytes32_1) { return "keys[1] != bytes32_1 after iteration"; }
        if (keys[2] != bytes32_2) { return "keys[2] != bytes32_2 after iteration"; }

        // value iteration test
        idx = 0;
        nextIdx = 1;
        // NOTE: collecting entities in a temporary array is difficult in Solidity at the moment
        // array needs to be sufficiently large to work!
        // http://solidity.readthedocs.io/en/latest/types.html#allocating-memory-arrays
        address[3] memory values;

        while (nextIdx > 0) {
            (error, value, nextIdx) = b32AddrMap.valueAtIndexHasNext(idx);
            if (error == BaseErrors.NO_ERROR()) {
                values[idx] = value;
            }
            idx = nextIdx;
        }

        if (values[0] != addr3) { return "values[0] != addr3 after iteration"; }
        if (values[1] != addr1) { return "values[1] != addr1 after iteration"; }
        if (values[2] != addr2) { return "values[2] != addr2 after iteration"; }

        return "success";
    }

    /**
     * @dev Tests functions belonging to Bytes32StringMap in Mappings.
     */
    function testBytes32StringMap() external returns (string memory) {

        // reusable variables during test
        uint error;
        bytes32 key;
        string memory value;

        // New inserts test
        error = b32StringMap.insert(bytes32_1, str_1);
        if (error != BaseErrors.NO_ERROR()) { return "Unexpected error for new insert."; }
        if (b32StringMap.keys.length != 1) { return "Size expected to be 1 after insert."; }
        error = b32StringMap.insert(bytes32_2, str_2);
        if (b32StringMap.keys.length != 2) { return "Size expected to be 2 after insert."; }

        // Update test
        uint sizeBefore = b32StringMap.keys.length;
        error = b32StringMap.insert(bytes32_1, str_3);
        if (error != BaseErrors.RESOURCE_ALREADY_EXISTS()) { return "Expected RESOURCE_ALREADY_EXISTS error for overwrite insert."; }
        if (b32StringMap.keys.length != sizeBefore) { return "Size should not have changed after failed insert."; }
        if (b32StringMap.insertOrUpdate(bytes32_1, str_3) != sizeBefore) { return "Size should NOT have changed after update of existing entry."; }

        // Value tests
        if (!b32StringMap.exists(bytes32_1)) { return "Key bytes32_1 should exist"; }
        if (b32StringMap.exists("xxxTotallyFakeKey")) { return "Fake key should not exist"; }
        if (keccak256(abi.encodePacked(b32StringMap.get(bytes32_1))) != keccak256(abi.encodePacked(str_3))) { return "Wrong value returned for key: bytes32_1"; }
        if (keccak256(abi.encodePacked(b32StringMap.get(bytes32_2))) != keccak256(abi.encodePacked(str_2))) { return "Wrong value returned for key: bytes32_2"; }

        // add more entries
        error = b32StringMap.insert(bytes32_3, str_3);
        if (b32StringMap.keys.length != 3) { return "Size should be 3 after third 'insert'."; }

        // key tests
        if (b32StringMap.keyIndex(bytes32_3) != 2) { return "Expected index 2 for bytes32_3."; }
        if (b32StringMap.keyIndex("superBogusKey") != uint(-1)) { return "Expected index -1 for non-existing key."; }
        (error, key) = b32StringMap.keyAtIndex(1);
        if (error != BaseErrors.NO_ERROR() && key != bytes32_2) { return "Expected no error and key bytes32_2 at index 1"; }
        (error, key) = b32StringMap.keyAtIndex(999);
        if (error != BaseErrors.INDEX_OUT_OF_BOUNDS() || key != "") { return "Expected error and empty return value for out of range index."; }

        // Removal tests
        uint removedKeyIdx = b32StringMap.keyIndex(bytes32_2);
        // remember the key of the last element which is about to be swapped by the remove()
        (error, key) = b32StringMap.keyAtIndex(b32StringMap.keys.length - 1);
        if (b32StringMap.remove(bytes32_2) != BaseErrors.NO_ERROR()) { return "Unexpected error during removal of bytes32_2 entry."; }
        if (b32StringMap.keys.length != 2) { return "Size expected to be 2 after removal"; }
        if (b32StringMap.keyIndex(bytes32_2) != uint(-1)) { return "Expected index -1 for removed key."; }
        if (b32StringMap.exists(bytes32_2) != false) { return "Name2 key should not exist anymore."; }
        if (b32StringMap.keyIndex(bytes32_3) != removedKeyIdx) { return "The last element from key index should've been swapped into the index position of the removed element."; }

        b32StringMap.clear();
        if (b32StringMap.keys.length != 0) { return "Size should be 0 after clearing."; }

        // test iterator functions
        b32StringMap.insert(bytes32_3, str_3);
        b32StringMap.insert(bytes32_1, str_1);
        b32StringMap.insert(bytes32_2, str_2);

        // key iteration test
        uint idx = 0;
        uint nextIdx = 1;
        // NOTE: collecting entities in a temporary array is difficult in Solidity at the moment
        // array needs to be sufficiently large to work!
        // http://solidity.readthedocs.io/en/latest/types.html#allocating-memory-arrays
        bytes32[3] memory keys;
        while( nextIdx > 0 ) {
            (error, key, nextIdx) = b32StringMap.keyAtIndexHasNext(idx);
            if (error == BaseErrors.NO_ERROR()) {
                keys[idx] = key;
            }
            idx = nextIdx;
        }

        if (keys[0] != bytes32_3) { return "keys[0] != bytes32_3 after iteration"; }
        if (keys[1] != bytes32_1) { return "keys[1] != bytes32_1 after iteration"; }
        if (keys[2] != bytes32_2) { return "keys[2] != bytes32_2 after iteration"; }

        // value iteration test
        idx = 0;
        nextIdx = 1;
        // NOTE: collecting entities in a temporary array is difficult in Solidity at the moment
        // array needs to be sufficiently large to work!
        // http://solidity.readthedocs.io/en/latest/types.html#allocating-memory-arrays
        string[3] memory values;

        while (nextIdx > 0) {
            (error, value, nextIdx) = b32StringMap.valueAtIndexHasNext(idx);
            if (error == BaseErrors.NO_ERROR()) {
                values[idx] = value;
            }
            idx = nextIdx;
        }

        if (keccak256(abi.encodePacked(values[0])) != keccak256(abi.encodePacked(str_3))) { return "values[0] != str_3 after iteration"; }
        if (keccak256(abi.encodePacked(values[1])) != keccak256(abi.encodePacked(str_1))) { return "values[1] != str_1 after iteration"; }
        if (keccak256(abi.encodePacked(values[2])) != keccak256(abi.encodePacked(str_2))) { return "values[2] != str_2 after iteration"; }

        return "success";
    }

    /**
     * @dev Tests functions belonging to Bytes32Bytes32Map in Mappings.
     */
    function testBytes32Bytes32Map() external returns (string memory) {

        // reusable variables during test
        uint error;
        bytes32 key;
        bytes32 value;

        // New inserts test
        error = b32b32Map.insert(bytes32_key1, bytes32_val1);
        if (error != BaseErrors.NO_ERROR()) { return "Unexpected error for new insert."; }
        if (b32b32Map.keys.length != 1) { return "Size expected to be 1 after insert."; }
        error = b32b32Map.insert(bytes32_key2, bytes32_val2);
        if (b32b32Map.keys.length != 2) { return "Size expected to be 2 after insert."; }

        // Update test
        uint sizeBefore = b32b32Map.keys.length;
        error = b32b32Map.insert(bytes32_key1, bytes32_val3);
        if (error != BaseErrors.RESOURCE_ALREADY_EXISTS()) { return "Expected RESOURCE_ALREADY_EXISTS error for overwrite insert."; }
        if (b32b32Map.keys.length != sizeBefore) { return "Size should not have changed after failed insert."; }
        if (b32b32Map.insertOrUpdate(bytes32_key1, bytes32_val3) != sizeBefore) { return "Size should NOT have changed after update of existing entry."; }

        // Value tests
        if (!b32b32Map.exists(bytes32_key1)) { return "Key bytes32_key1 should exist"; }
        if (b32b32Map.exists("xxxTotallyFakeKey")) { return "Fake key should not exist"; }
        if (b32b32Map.get(bytes32_key1) != bytes32_val3) { return "Wrong value returned for key: bytes32_key1"; }
        if (b32b32Map.get(bytes32_key2) != bytes32_val2) { return "Wrong value returned for key: bytes32_key2"; }

        // add more entries
        error = b32b32Map.insert(bytes32_key3, bytes32_val3);
        if (b32b32Map.keys.length != 3) { return "Size should be 3 after third 'insert'."; }

        // key tests
        if (b32b32Map.keyIndex(bytes32_key3) != 2) { return "Expected index 2 for bytes32_key3."; }
        if (b32b32Map.keyIndex("superBogusKey") != uint(-1)) { return "Expected index -1 for non-existing key."; }
        (error, key) = b32b32Map.keyAtIndex(1);
        if (error != BaseErrors.NO_ERROR() && key != bytes32_key2) { return "Expected no error and key bytes32_key2 at index 1"; }
        (error, key) = b32b32Map.keyAtIndex(999);
        if (error != BaseErrors.INDEX_OUT_OF_BOUNDS() || key != "") { return "Expected error and empty return value for out of range index."; }

        // Removal tests
        uint removedKeyIdx = b32b32Map.keyIndex(bytes32_key2);
        // remember the key of the last element which is about to be swapped by the remove()
        (error, key) = b32b32Map.keyAtIndex(b32b32Map.keys.length - 1);
        if (b32b32Map.remove(bytes32_key2) != BaseErrors.NO_ERROR()) { return "Unexpected error during removal of bytes32_key2 entry."; }
        if (b32b32Map.keys.length != 2) { return "Size expected to be 2 after removal"; }
        if (b32b32Map.keyIndex(bytes32_key2) != uint(-1)) { return "Expected index -1 for removed key."; }
        if (b32b32Map.exists(bytes32_key2) != false) { return "Key bytes32_key2 should not exist anymore."; }
        if (b32b32Map.keyIndex(bytes32_key3) != removedKeyIdx) { return "The last element from key index should've been swapped into the index position of the removed element."; }

        b32b32Map.clear();
        if (b32b32Map.keys.length != 0) { return "Size should be 0 after clearing."; }

        // test iterator functions
        b32b32Map.insert(bytes32_key3, bytes32_val3);
        b32b32Map.insert(bytes32_key1, bytes32_val1);
        b32b32Map.insert(bytes32_key2, bytes32_val2);

        // key iteration test
        uint idx = 0;
        uint nextIdx = 1;
        // NOTE: collecting entities in a temporary array is difficult in Solidity at the moment
        // array needs to be sufficiently large to work!
        // http://solidity.readthedocs.io/en/latest/types.html#allocating-memory-arrays
        bytes32[3] memory keys;
        while( nextIdx > 0 ) {
            (error, key, nextIdx) = b32b32Map.keyAtIndexHasNext(idx);
            if (error == BaseErrors.NO_ERROR()) {
                keys[idx] = key;
            }
            idx = nextIdx;
        }

        if (keys[0] != bytes32_key3) { return "keys[0] != bytes32_3 after iteration"; }
        if (keys[1] != bytes32_key1) { return "keys[1] != bytes32_1 after iteration"; }
        if (keys[2] != bytes32_key2) { return "keys[2] != bytes32_2 after iteration"; }

        // value iteration test
        idx = 0;
        nextIdx = 1;
        // NOTE: collecting entities in a temporary array is difficult in Solidity at the moment
        // array needs to be sufficiently large to work!
        // http://solidity.readthedocs.io/en/latest/types.html#allocating-memory-arrays
        bytes32[3] memory values;

        while (nextIdx > 0) {
            (error, value, nextIdx) = b32b32Map.valueAtIndexHasNext(idx);
            if (error == BaseErrors.NO_ERROR()) {
                values[idx] = value;
            }
            idx = nextIdx;
        }

        if (values[0] != bytes32_val3) { return "values[0] != bytes32_val3 after iteration"; }
        if (values[1] != bytes32_val1) { return "values[1] != bytes32_val1 after iteration"; }
        if (values[2] != bytes32_val2) { return "values[2] != bytes32_val2 after iteration"; }

        return "success";
    }

    /**
     * @dev Tests functions belonging to Bytes32Bytes32Map in Mappings.
     */
    function testBytes32UintMap() external returns (string memory) {

        // reusable variables during test
        uint error;
        bytes32 key;
        uint value;

        // New inserts test
        error = b32UintMap.insert(bytes32_key11, uint_val11);
        if (error != BaseErrors.NO_ERROR()) { return "Unexpected error for new insert."; }
        if (b32UintMap.keys.length != 1) { return "Size expected to be 1 after insert."; }
        error = b32UintMap.insert(bytes32_key12, uint_val12);
        if (b32UintMap.keys.length != 2) { return "Size expected to be 2 after insert."; }

        // Update test
        uint sizeBefore = b32UintMap.keys.length;
        error = b32UintMap.insert(bytes32_key11, uint_val13);
        if (error != BaseErrors.RESOURCE_ALREADY_EXISTS()) { return "Expected RESOURCE_ALREADY_EXISTS error for overwrite insert."; }
        if (b32UintMap.keys.length != sizeBefore) { return "Size should not have changed after failed insert."; }
        if (b32UintMap.insertOrUpdate(bytes32_key11, uint_val13) != sizeBefore) { return "Size should NOT have changed after update of existing entry."; }

        // Value tests
        if (!b32UintMap.exists(bytes32_key11)) { return "Key bytes32_key1 should exist"; }
        if (b32UintMap.exists("xxxTotallyFakeKey")) { return "Fake key should not exist"; }
        if (b32UintMap.get(bytes32_key11) != uint_val13) { return "Wrong value returned for key: bytes32_key11"; }
        if (b32UintMap.get(bytes32_key12) != uint_val12) { return "Wrong value returned for key: bytes32_key12"; }

        // add more entries
        error = b32UintMap.insert(bytes32_key13, uint_val13);
        if (b32UintMap.keys.length != 3) { return "Size should be 3 after third 'insert'."; }

        // key tests
        if (b32UintMap.keyIndex(bytes32_key13) != 2) { return "Expected index 2 for bytes32_key3."; }
        if (b32UintMap.keyIndex("superBogusKey") != uint(-1)) { return "Expected index -1 for non-existing key."; }
        (error, key) = b32UintMap.keyAtIndex(1);
        if (error != BaseErrors.NO_ERROR() && key != bytes32_key12) { return "Expected no error and key bytes32_key12 at index 1"; }
        (error, key) = b32UintMap.keyAtIndex(999);
        if (error != BaseErrors.INDEX_OUT_OF_BOUNDS() || key != "") { return "Expected error and empty return value for out of range index."; }

        // Removal tests
        uint removedKeyIdx = b32UintMap.keyIndex(bytes32_key12);
        // remember the key of the last element which is about to be swapped by the remove()
        (error, key) = b32UintMap.keyAtIndex(b32UintMap.keys.length - 1);
        if (b32UintMap.remove(bytes32_key12) != BaseErrors.NO_ERROR()) { return "Unexpected error during removal of bytes32_key12 entry."; }
        if (b32UintMap.keys.length != 2) { return "Size expected to be 2 after removal"; }
        if (b32UintMap.keyIndex(bytes32_key12) != uint(-1)) { return "Expected index -1 for removed key."; }
        if (b32UintMap.exists(bytes32_key12) != false) { return "Key bytes32_key2 should not exist anymore."; }
        if (b32UintMap.keyIndex(bytes32_key13) != removedKeyIdx) { return "The last element from key index should've been swapped into the index position of the removed element."; }

        b32UintMap.clear();
        if (b32UintMap.keys.length != 0) { return "Size should be 0 after clearing."; }

        // test iterator functions
        b32UintMap.insert(bytes32_key13, uint_val13);
        b32UintMap.insert(bytes32_key11, uint_val11);
        b32UintMap.insert(bytes32_key12, uint_val12);

        // key iteration test
        uint idx = 0;
        uint nextIdx = 1;
        // NOTE: collecting entities in a temporary array is difficult in Solidity at the moment
        // array needs to be sufficiently large to work!
        // http://solidity.readthedocs.io/en/latest/types.html#allocating-memory-arrays
        bytes32[3] memory keys;
        while( nextIdx > 0 ) {
            (error, key, nextIdx) = b32UintMap.keyAtIndexHasNext(idx);
            if (error == BaseErrors.NO_ERROR()) {
                keys[idx] = key;
            }
            idx = nextIdx;
        }

        if (keys[0] != bytes32_key13) { return "keys[0] != bytes32_key13 after iteration"; }
        if (keys[1] != bytes32_key11) { return "keys[1] != bytes32_key11 after iteration"; }
        if (keys[2] != bytes32_key12) { return "keys[2] != bytes32_key12 after iteration"; }

        // value iteration test
        idx = 0;
        nextIdx = 1;
        // NOTE: collecting entities in a temporary array is difficult in Solidity at the moment
        // array needs to be sufficiently large to work!
        // http://solidity.readthedocs.io/en/latest/types.html#allocating-memory-arrays
        uint[3] memory values;

        while (nextIdx > 0) {
            (error, value, nextIdx) = b32UintMap.valueAtIndexHasNext(idx);
            if (error == BaseErrors.NO_ERROR()) {
                values[idx] = value;
            }
            idx = nextIdx;
        }

        if (values[0] != uint_val13) { return "values[0] != uint_val13 after iteration"; }
        if (values[1] != uint_val11) { return "values[1] != uint_val11 after iteration"; }
        if (values[2] != uint_val12) { return "values[2] != uint_val12 after iteration"; }

        return "success";
    }

    /**
     * @dev Tests functions belonging to Bytes32AddressArrayMap in Mappings.
     * TODO: test functions that return dynamic arrays. 
     */
    function testBytes32AddressArrayMap() external returns (string memory) {

        // reusable variables during test
        uint error;
        bytes32 key;

        // clear test arrays
        clearAddressesArrays();
        addresses1.push(addr1);
        addresses2.push(addr1);
        addresses3.push(addr1);

        // New inserts test
        error = b32AddrArrayMap.insert(bytes32_1, addresses1);
        if (error != BaseErrors.NO_ERROR()) { return "Unexpected error for new insert."; }
        if (b32AddrArrayMap.keys.length != 1) { return "Size expected to be 1 after insert."; }
        error = b32AddrArrayMap.insert(bytes32_2, addresses2);
        if (b32AddrArrayMap.keys.length != 2) { return "Size expected to be 2 after insert."; }

        // Update test
        uint sizeBefore = b32AddrArrayMap.keys.length;
        error = b32AddrArrayMap.insert(bytes32_1, addresses3);
        if (error != BaseErrors.RESOURCE_ALREADY_EXISTS()) { return "Expected RESOURCE_ALREADY_EXISTS error for overwrite insert."; }
        if (b32AddrArrayMap.keys.length != sizeBefore) { return "Size should not have changed after failed insert."; }
        if (b32AddrArrayMap.insertOrUpdate(bytes32_1, addresses3) != sizeBefore) { return "Size should NOT have changed after update of existing entry."; }

        // // Value tests
        if (!b32AddrArrayMap.exists(bytes32_1)) { return "Key bytes32_1 should exist"; }
        if (b32AddrArrayMap.exists("xxxTotallyFakeKey")) { return "Fake key should not exist"; }

        // // add more entries
        error = b32AddrArrayMap.insert(bytes32_3, addresses3);
        if (b32AddrArrayMap.keys.length != 3) { return "Size should be 3 after third 'insert'."; }

        // key tests
        if (b32AddrArrayMap.keyIndex(bytes32_3) != 2) { return "Expected index 2 for key: bytes32_3."; }
        if (b32AddrArrayMap.keyIndex("superBogusKey") != uint(-1)) { return "Expected index -1 for non-existing key."; }
        (error, key) = b32AddrArrayMap.keyAtIndex(1);
        if (error != BaseErrors.NO_ERROR() && key != bytes32_2) { return "Expected no error and key bytes32_2 at index 1"; }
        (error, key) = b32AddrArrayMap.keyAtIndex(999);
        if (error != BaseErrors.INDEX_OUT_OF_BOUNDS() || key != "") { return "Expected error and empty return value for out of range index."; }

        // Removal tests
        uint removedKeyIdx = b32AddrArrayMap.keyIndex(bytes32_2);
        // remember the key of the last element which is about to be swapped by the remove()
        (error, key) = b32AddrArrayMap.keyAtIndex(b32AddrArrayMap.keys.length - 1);
        if (b32AddrArrayMap.remove(bytes32_2) != BaseErrors.NO_ERROR()) { return "Unexpected error during removal of bytes32_2 entry."; }
        if (b32AddrArrayMap.keys.length != 2) { return "Size expected to be 2 after removal"; }
        if (b32AddrArrayMap.keyIndex(bytes32_2) != uint(-1)) { return "Expected index -1 for removed key."; }
        if (b32AddrArrayMap.exists(bytes32_2)) { return "Name2 key should not exist anymore."; }
        if (b32AddrArrayMap.keyIndex(bytes32_3) != removedKeyIdx) { return "The last element from key index should've been swapped into the index position of the removed element."; }

        b32AddrArrayMap.clear();
        if (b32AddrArrayMap.keys.length != 0) { return "Size should be 0 after clearing."; }

        // test iterator functions
        b32AddrArrayMap.insert(bytes32_3, addresses3);
        b32AddrArrayMap.insert(bytes32_1, addresses1);
        b32AddrArrayMap.insert(bytes32_2, addresses2);

        // key iteration test
        uint idx = 0;
        uint nextIdx = 1;
        // NOTE: collecting entities in a temporary array is difficult in Solidity at the moment
        // array needs to be sufficiently large to work!
        // http://solidity.readthedocs.io/en/latest/types.html#allocating-memory-arrays
        bytes32[3] memory keys;
        while( nextIdx > 0 ) {
            (error, key, nextIdx) = b32AddrArrayMap.keyAtIndexHasNext(idx);
            if (error == BaseErrors.NO_ERROR()) {
                keys[idx] = key;
            }
            idx = nextIdx;
        }

        if (keys[0] != bytes32_3) { return "Key0 != bytes32_3 after iteration"; }
        if (keys[1] != bytes32_1) { return "Key1 != bytes32_1 after iteration"; }
        if (keys[2] != bytes32_2) { return "Key2 != bytes32_2 after iteration"; }

        // test internal array manipulation
        uint lenBefore = b32AddrArrayMap.rows[bytes32_2].value.length;
        uint lenAfter = b32AddrArrayMap.addToArray(bytes32_2, addr3, false);
        if (lenBefore+1 != lenAfter) { return "Size of inner array returned from addToArray function does not have expected value"; }
        if (lenBefore+1 != b32AddrArrayMap.rows[bytes32_2].value.length) { return "Adding to inner array did not increase length"; }
        if (b32AddrArrayMap.rows[bytes32_2].value[lenAfter-1] != addr3) { return "Value added to inner array not correct"; }
        // test with unknown key
        lenAfter = b32AddrArrayMap.addToArray(bytes32_4, addr1, false);
        if (1 != lenAfter) { return "Size of newly created inner array should be 1"; }
        lenAfter = b32AddrArrayMap.addToArray(bytes32_4, addr1, false);
        if (2 != lenAfter) { return "Size of newly created inner array should be 2 after adding duplicate value"; }
        lenAfter = b32AddrArrayMap.addToArray(bytes32_4, addr1, true);
        if (2 != lenAfter) { return "Size of newly created inner array should remain 2 after rejecting duplicate value"; }
        lenAfter = b32AddrArrayMap.addToArray(bytes32_4, addr2, true);
        if (3 != lenAfter) { return "Size of newly created inner array should be 3 after new unique value"; }
        lenAfter = b32AddrArrayMap.removeFromArray(bytes32_4, addr2, false);
        if (2 != lenAfter) { return "Size of newly created inner array should be 2 after removing"; }
        lenAfter = b32AddrArrayMap.removeFromArray(bytes32_4, addr1, true);
        if (0 != lenAfter) { return "Size of newly created inner array should be 0 after removing all occurences of myValue"; }

        return "success";
    }

    /**
     * @dev Tests functions belonging to AddressBytes32Map in Mappings.
     */
    function testAddressBytes32Map() external returns (string memory) {

        // reusable variables during test
        uint error;
        address key;
        bytes32 value;

        // New inserts test
        error = addrB32Map.insert(addr1, bytes32_1);
        if (error != BaseErrors.NO_ERROR()) { return "Unexpected error for new insert."; }
        if (addrB32Map.keys.length != 1) { return "Size expected to be 1 after insert."; }
        error = addrB32Map.insert(addr2, bytes32_2);
        if (addrB32Map.keys.length != 2) { return "Size expected to be 2 after insert."; }

        // Update test
        uint sizeBefore = addrB32Map.keys.length;
        error = addrB32Map.insert(addr1, bytes32_3);
        if (error != BaseErrors.RESOURCE_ALREADY_EXISTS()) { return "Expected RESOURCE_ALREADY_EXISTS error for overwrite insert."; }
        if (addrB32Map.keys.length != sizeBefore) { return "Size should not have changed after failed insert."; }
        if (addrB32Map.insertOrUpdate(addr1, bytes32_3) != sizeBefore) { return "Size should NOT have changed after update of existing entry."; }

        // Value tests
        if (!addrB32Map.exists(addr1)) { return "Key addr1 should exist"; }
        if (addrB32Map.exists(address(this))) { return "Fake key for 'this' should not exist"; }
        if (addrB32Map.get(addr1) != bytes32_3) { return "Wrong value returned for key: addr3"; }
        if (addrB32Map.get(addr2) != bytes32_2) { return "Wrong value returned for key: addr2"; }

        // add more entries
        error = addrB32Map.insert(addr3, bytes32_3);
        if (addrB32Map.keys.length != 3) { return "Size should be 3 after third 'insert'."; }

        // key tests
        if (addrB32Map.keyIndex(addr3) != 2) { return "Expected index 2 for addr3."; }
        if (addrB32Map.keyIndex(address(this)) != uint(-1)) { return "Expected index -1 for non-existing key for 'this'."; }
        (error, key) = addrB32Map.keyAtIndex(1);
        if (error != BaseErrors.NO_ERROR() && key != addr2) { return "Expected no error and key addr2 at index 1"; }
        (error, key) = addrB32Map.keyAtIndex(999);
        if (error != BaseErrors.INDEX_OUT_OF_BOUNDS() || key != address(0)) { return "Expected error and empty 0x0 return value for out of range index."; }

        // Removal tests
        uint removedKeyIdx = addrB32Map.keyIndex(addr2);
        // remember the key of the last element which is about to be swapped by the remove()
        (error, key) = addrB32Map.keyAtIndex(addrB32Map.keys.length - 1);
        if (addrB32Map.remove(addr2) != BaseErrors.NO_ERROR()) { return "Unexpected error during removal of addr2 entry."; }
        if (addrB32Map.keys.length != 2) { return "Size expected to be 2 after removal"; }
        if (addrB32Map.keyIndex(addr2) != uint(-1)) { return "Expected index -1 for removed key."; }
        if (addrB32Map.exists(addr2) != false) { return "addr2 key should not exist anymore."; }
        if (addrB32Map.keyIndex(addr3) != removedKeyIdx) { return "The last element from key index should've been swapped into the index position of the removed element."; }

        addrB32Map.clear();
        if (addrB32Map.keys.length != 0) { return "Size should be 0 after clearing."; }

        // test iterator functions
        addrB32Map.insert(addr3, bytes32_3);
        addrB32Map.insert(addr1, bytes32_1);
        addrB32Map.insert(addr2, bytes32_2);

        // key iteration test
        uint idx = 0;
        uint nextIdx = 1;
        // NOTE: collecting entities in a temporary array is difficult in Solidity at the moment
        // array needs to be sufficiently large to work!
        // http://solidity.readthedocs.io/en/latest/types.html#allocating-memory-arrays
        address[3] memory keys;
        while( nextIdx > 0 ) {
            (error, key, nextIdx) = addrB32Map.keyAtIndexHasNext(idx);
            if (error == BaseErrors.NO_ERROR()) {
                keys[idx] = key;
            }
            idx = nextIdx;
        }

        if (keys[0] != addr3) { return "keys[0] != addr3 after iteration"; }
        if (keys[1] != addr1) { return "keys[1] != addr1 after iteration"; }
        if (keys[2] != addr2) { return "keys[2] != addr2 after iteration"; }

        // value iteration test
        idx = 0;
        nextIdx = 1;
        // NOTE: collecting entities in a temporary array is difficult in Solidity at the moment
        // array needs to be sufficiently large to work!
        // http://solidity.readthedocs.io/en/latest/types.html#allocating-memory-arrays
        bytes32[3] memory values;

        while (nextIdx > 0) {
            (error, value, nextIdx) = addrB32Map.valueAtIndexHasNext(idx);
            if (error == BaseErrors.NO_ERROR()) {
                values[idx] = value;
            }
            idx = nextIdx;
        }

        if (values[0] != bytes32_3) { return "values[0] != bytes32_3 after iteration"; }
        if (values[1] != bytes32_1) { return "values[1] != bytes32_1 after iteration"; }
        if (values[2] != bytes32_2) { return "values[2] != bytes32_2 after iteration"; }

        return "success";
    }

    /**
     * @dev Tests functions belonging to AddressBoolMap in Mappings.
     */
    function testAddressBoolMap() external returns (string memory) {

        // reusable variables during test
        uint error;
        address key;
        bool value;

        // New inserts test
        error = addrBoolMap.insert(addr1, bool_true);
        if (error != BaseErrors.NO_ERROR()) { return "Unexpected error for new insert."; }
        if (addrBoolMap.keys.length != 1) { return "Size expected to be 1 after insert."; }
        error = addrBoolMap.insert(addr2, bool_true);
        if (addrBoolMap.keys.length != 2) { return "Size expected to be 2 after insert."; }

        // Update test
        uint sizeBefore = addrBoolMap.keys.length;
        error = addrBoolMap.insert(addr1, bool_true);
        if (error != BaseErrors.RESOURCE_ALREADY_EXISTS()) { return "Expected RESOURCE_ALREADY_EXISTS error for overwrite insert."; }
        if (addrBoolMap.keys.length != sizeBefore) { return "Size should not have changed after failed insert."; }
        if (addrBoolMap.insertOrUpdate(addr1, bool_true) != sizeBefore) { return "Size should NOT have changed after update of existing entry."; }

        // Value tests
        if (!addrBoolMap.exists(addr1)) { return "Key addr1 should exist"; }
        if (addrBoolMap.exists(address(this))) { return "Fake key for 'this' should not exist"; }
        if (addrBoolMap.get(addr1) != bool_true) { return "Wrong value returned for key: addr3"; }
        if (addrBoolMap.get(addr2) != bool_true) { return "Wrong value returned for key: addr2"; }

        // add more entries
        error = addrBoolMap.insert(addr3, bool_true);
        if (addrBoolMap.keys.length != 3) { return "Size should be 3 after third 'insert'."; }

        // key tests
        if (addrBoolMap.keyIndex(addr3) != 2) { return "Expected index 2 for addr3."; }
        if (addrBoolMap.keyIndex(address(this)) != uint(-1)) { return "Expected index -1 for non-existing key for 'this'."; }
        (error, key) = addrBoolMap.keyAtIndex(1);
        if (error != BaseErrors.NO_ERROR() && key != addr2) { return "Expected no error and key addr2 at index 1"; }
        (error, key) = addrBoolMap.keyAtIndex(999);
        if (error != BaseErrors.INDEX_OUT_OF_BOUNDS() || key != address(0)) { return "Expected error and empty 0x0 return value for out of range index."; }

        // Removal tests
        uint removedKeyIdx = addrBoolMap.keyIndex(addr2);
        // remember the key of the last element which is about to be swapped by the remove()
        (error, key) = addrBoolMap.keyAtIndex(addrBoolMap.keys.length - 1);
        if (addrBoolMap.remove(addr2) != BaseErrors.NO_ERROR()) { return "Unexpected error during removal of addr2 entry."; }
        if (addrBoolMap.keys.length != 2) { return "Size expected to be 2 after removal"; }
        if (addrBoolMap.keyIndex(addr2) != uint(-1)) { return "Expected index -1 for removed key."; }
        if (addrBoolMap.exists(addr2) != false) { return "addr2 key should not exist anymore."; }
        if (addrBoolMap.keyIndex(addr3) != removedKeyIdx) { return "The last element from key index should've been swapped into the index position of the removed element."; }

        addrBoolMap.clear();
        if (addrBoolMap.keys.length != 0) { return "Size should be 0 after clearing."; }

        // test iterator functions
        addrBoolMap.insert(addr3, bool_false);
        addrBoolMap.insert(addr1, bool_false);
        addrBoolMap.insert(addr2, bool_false);

        // key iteration test
        uint idx = 0;
        uint nextIdx = 1;
        // NOTE: collecting entities in a temporary array is difficult in Solidity at the moment
        // array needs to be sufficiently large to work!
        // http://solidity.readthedocs.io/en/latest/types.html#allocating-memory-arrays
        address[3] memory keys;
        while( nextIdx > 0 ) {
            (error, key, nextIdx) = addrBoolMap.keyAtIndexHasNext(idx);
            if (error == BaseErrors.NO_ERROR()) {
                keys[idx] = key;
            }
            idx = nextIdx;
        }

        if (keys[0] != addr3) { return "keys[0] != addr3 after iteration"; }
        if (keys[1] != addr1) { return "keys[1] != addr1 after iteration"; }
        if (keys[2] != addr2) { return "keys[2] != addr2 after iteration"; }

        // value iteration test
        idx = 0;
        nextIdx = 1;
        // NOTE: collecting entities in a temporary array is difficult in Solidity at the moment
        // array needs to be sufficiently large to work!
        // http://solidity.readthedocs.io/en/latest/types.html#allocating-memory-arrays
        bool[3] memory values;

        while (nextIdx > 0) {
            (error, value, nextIdx) = addrBoolMap.valueAtIndexHasNext(idx);
            if (error == BaseErrors.NO_ERROR()) {
                values[idx] = value;
            }
            idx = nextIdx;
        }

        if (values[0] != bool_false) { return "values[0] != bool_false after iteration"; }
        if (values[1] != bool_false) { return "values[1] != bool_false after iteration"; }
        if (values[2] != bool_false) { return "values[2] != bool_false after iteration"; }

        return "success";
    }

    /**
     * @dev Tests functions belonging to AddressBytes32ArrayMap in Mappings.
     * TODO: test functions that return dynamic arrays.
     */
    function testAddressBytes32ArrayMap() external returns (string memory) {

        // reusable variables during test
        uint error;
        address key;
    
        // clear test arrays
        clearBytes32Arrays();
        bytes32Array1.push(bytes32_1);
        bytes32Array2.push(bytes32_2);
        bytes32Array3.push(bytes32_3);

        // New inserts test
        error = addrB32ArrayMap.insert(addr1, bytes32Array1);
        if (error != BaseErrors.NO_ERROR()) { return "Unexpected error for new insert."; }
        if (addrB32ArrayMap.keys.length != 1) { return "Size expected to be 1 after insert."; }
        error = addrB32ArrayMap.insert(addr2, bytes32Array2);
        if (addrB32ArrayMap.keys.length != 2) { return "Size expected to be 2 after insert."; }

        // Update test
        uint sizeBefore = addrB32ArrayMap.keys.length;
        error = addrB32ArrayMap.insert(addr1, bytes32Array3);
        if (error != BaseErrors.RESOURCE_ALREADY_EXISTS()) { return "Expected RESOURCE_ALREADY_EXISTS error for overwrite insert."; }
        if (addrB32ArrayMap.keys.length != sizeBefore) { return "Size should not have changed after failed insert."; }
        if (addrB32ArrayMap.insertOrUpdate(addr1, bytes32Array3) != sizeBefore) { return "Size should NOT have changed after update of existing entry."; }

        // // Value tests
        if (!addrB32ArrayMap.exists(addr1)) { return "Key uint1 should exist"; }
        if (addrB32ArrayMap.exists(0x01234562345aAAaCDEdcdDc345678876DDdD3456)) { return "Fake key should not exist"; }

        // // add more entries
        error = addrB32ArrayMap.insert(addr3, bytes32Array3);
        if (addrB32ArrayMap.keys.length != 3) { return "Size should be 3 after third 'insert'."; }

        // key tests
        if (addrB32ArrayMap.keyIndex(addr3) != 2) { return "Expected index 2 for key: addr3."; }
        if (addrB32ArrayMap.keyIndex(0x01234562345aAAaCDEdcdDc345678876DDdD3456) != uint(-1)) { return "Expected index -1 for non-existing key."; }
        (error, key) = addrB32ArrayMap.keyAtIndex(1);
        if (error != BaseErrors.NO_ERROR() && key != addr2) { return "Expected no error and key addr2 at index 1"; }
        (error, key) = addrB32ArrayMap.keyAtIndex(999);
        if (error != BaseErrors.INDEX_OUT_OF_BOUNDS() || key != address(0)) { return "Expected error and empty return value for out of range index."; }

        // Removal tests
        uint removedKeyIdx = addrB32ArrayMap.keyIndex(addr2);
        // remember the key of the last element which is about to be swapped by the remove()
        (error, key) = addrB32ArrayMap.keyAtIndex(addrB32ArrayMap.keys.length - 1);
        if (addrB32ArrayMap.remove(addr2) != BaseErrors.NO_ERROR()) { return "Unexpected error during removal of uint2 entry."; }
        if (addrB32ArrayMap.keys.length != 2) { return "Size expected to be 2 after removal"; }
        if (addrB32ArrayMap.keyIndex(addr2) != uint(-1)) { return "Expected index -1 for removed key."; }
        if (addrB32ArrayMap.exists(addr2)) { return "Key addr2 should not exist anymore."; }
        if (addrB32ArrayMap.keyIndex(addr3) != removedKeyIdx) { return "The last element from key index should've been swapped into the index position of the removed element."; }

        addrB32ArrayMap.clear();
        if (addrB32ArrayMap.keys.length != 0) { return "Size should be 0 after clearing."; }

        // test iterator functions
        addrB32ArrayMap.insert(addr3, bytes32Array3);
        addrB32ArrayMap.insert(addr1, bytes32Array1);
        addrB32ArrayMap.insert(addr2, bytes32Array2);

        // key iteration test
        uint idx = 0;
        uint nextIdx = 1;
        // NOTE: collecting entities in a temporary array is difficult in Solidity at the moment
        // array needs to be sufficiently large to work!
        // http://solidity.readthedocs.io/en/latest/types.html#allocating-memory-arrays
        address[3] memory keys;
        while( nextIdx > 0 ) {
            (error, key, nextIdx) = addrB32ArrayMap.keyAtIndexHasNext(idx);
            if (error == BaseErrors.NO_ERROR()) {
                keys[idx] = key;
            }
            idx = nextIdx;
        }

        if (keys[0] != addr3) { return "Key0 != addr3 after iteration"; }
        if (keys[1] != addr1) { return "Key1 != addr1 after iteration"; }
        if (keys[2] != addr2) { return "Key2 != addr2 after iteration"; }

        // test internal array manipulation
        uint lenBefore = addrB32ArrayMap.rows[addr2].value.length;
        uint lenAfter = addrB32ArrayMap.addToArray(addr2, "newValue", false);
        if (lenBefore+1 != lenAfter) { return "Size of inner array returned from addToArray function does not have expected value"; }
        if (lenBefore+1 != addrB32ArrayMap.rows[addr2].value.length) { return "Adding to inner array did not increase length"; }
        if (addrB32ArrayMap.rows[addr2].value[lenAfter-1] != "newValue") { return "Value added to inner array not correct"; }
        
        // test with unknown key
        lenAfter = addrB32ArrayMap.addToArray(addr4, "myValue", false);
        if (1 != lenAfter) { return "Size of newly created inner array should be 1"; }
        lenAfter = addrB32ArrayMap.addToArray(addr4, "myValue", false);
        if (2 != lenAfter) { return "Size of newly created inner array should be 2 after adding duplicate value"; }
        lenAfter = addrB32ArrayMap.addToArray(addr4, "myValue", true);
        if (2 != lenAfter) { return "Size of newly created inner array should remain 2 after rejecting duplicate value"; }
        lenAfter = addrB32ArrayMap.addToArray(addr4, "differentValue", true);
        if (3 != lenAfter) { return "Size of newly created inner array should be 3 after new unique value"; }
        lenAfter = addrB32ArrayMap.removeFromArray(addr4, "differentValue", false);
        if (2 != lenAfter) { return "Size of newly created inner array should be 2 after removing"; }
        lenAfter = addrB32ArrayMap.removeFromArray(addr4, "myValue", true);
        if (0 != lenAfter) { return "Size of newly created inner array should be 0 after removing all occurences of myValue"; }

        return "success";
    }


    /**
     * @dev Tests functions belonging to AddressAddressMap in Mappings.
     */
    function testAddressAddressMap() external returns (string memory) {

        // reusable variables during test
        uint error;
        address key;
        address value;

        // New inserts test
        error = addrAddrMap.insert(addr1, addr1);
        if (error != BaseErrors.NO_ERROR()) { return "Unexpected error for new insert."; }
        if (addrAddrMap.keys.length != 1) { return "Size expected to be 1 after insert."; }
        error = addrAddrMap.insert(addr2, addr2);
        if (addrAddrMap.keys.length != 2) { return "Size expected to be 2 after insert."; }

        // Update test
        uint sizeBefore = addrAddrMap.keys.length;
        error = addrAddrMap.insert(addr1, addr3);
        if (error != BaseErrors.RESOURCE_ALREADY_EXISTS()) { return "Expected RESOURCE_ALREADY_EXISTS error for overwrite insert."; }
        if (addrAddrMap.keys.length != sizeBefore) { return "Size should not have changed after failed insert."; }
        if (addrAddrMap.insertOrUpdate(addr1, addr3) != sizeBefore) { return "Size should NOT have changed after update of existing entry."; }

        // Value tests
        if (!addrAddrMap.exists(addr1)) { return "Key addr1 should exist"; }
        if (addrAddrMap.exists(address(this))) { return "Fake key for 'this' should not exist"; }
        if (addrAddrMap.get(addr1) != addr3) { return "Wrong value returned for key: addr3"; }
        if (addrAddrMap.get(addr2) != addr2) { return "Wrong value returned for key: addr2"; }

        // add more entries
        error = addrAddrMap.insert(addr3, addr3);
        if (addrAddrMap.keys.length != 3) { return "Size should be 3 after third 'insert'."; }

        // key tests
        if (addrAddrMap.keyIndex(addr3) != 2) { return "Expected index 2 for addr3."; }
        if (addrAddrMap.keyIndex(address(this)) != uint(-1)) { return "Expected index -1 for non-existing key for 'this'."; }
        (error, key) = addrAddrMap.keyAtIndex(1);
        if (error != BaseErrors.NO_ERROR() && key != addr2) { return "Expected no error and key addr2 at index 1"; }
        (error, key) = addrAddrMap.keyAtIndex(999);
        if (error != BaseErrors.INDEX_OUT_OF_BOUNDS() || key != address(0)) { return "Expected error and empty 0x0 return value for out of range index."; }

        // Removal tests
        uint removedKeyIdx = addrAddrMap.keyIndex(addr2);
        // remember the key of the last element which is about to be swapped by the remove()
        (error, key) = addrAddrMap.keyAtIndex(addrAddrMap.keys.length - 1);
        if (addrAddrMap.remove(addr2) != BaseErrors.NO_ERROR()) { return "Unexpected error during removal of addr2 entry."; }
        if (addrAddrMap.keys.length != 2) { return "Size expected to be 2 after removal"; }
        if (addrAddrMap.keyIndex(addr2) != uint(-1)) { return "Expected index -1 for removed key."; }
        if (addrAddrMap.exists(addr2) != false) { return "addr2 key should not exist anymore."; }
        if (addrAddrMap.keyIndex(addr3) != removedKeyIdx) { return "The last element from key index should've been swapped into the index position of the removed element."; }

        addrAddrMap.clear();
        if (addrAddrMap.keys.length != 0) { return "Size should be 0 after clearing."; }

        // test iterator functions
        addrAddrMap.insert(addr3, addr3);
        addrAddrMap.insert(addr1, addr1);
        addrAddrMap.insert(addr2, addr2);

        // key iteration test
        uint idx = 0;
        uint nextIdx = 1;
        // NOTE: collecting entities in a temporary array is difficult in Solidity at the moment
        // array needs to be sufficiently large to work!
        // http://solidity.readthedocs.io/en/latest/types.html#allocating-memory-arrays
        address[3] memory keys;
        while( nextIdx > 0 ) {
            (error, key, nextIdx) = addrAddrMap.keyAtIndexHasNext(idx);
            if (error == BaseErrors.NO_ERROR()) {
                keys[idx] = key;
            }
            idx = nextIdx;
        }

        if (keys[0] != addr3) { return "keys[0] != addr3 after iteration"; }
        if (keys[1] != addr1) { return "keys[1] != addr1 after iteration"; }
        if (keys[2] != addr2) { return "keys[2] != addr2 after iteration"; }

        // value iteration test
        idx = 0;
        nextIdx = 1;
        // NOTE: collecting entities in a temporary array is difficult in Solidity at the moment
        // array needs to be sufficiently large to work!
        // http://solidity.readthedocs.io/en/latest/types.html#allocating-memory-arrays
        address[3] memory values;

        while (nextIdx > 0) {
            (error, value, nextIdx) = addrAddrMap.valueAtIndexHasNext(idx);
            if (error == BaseErrors.NO_ERROR()) {
                values[idx] = value;
            }
            idx = nextIdx;
        }

        if (values[0] != addr3) { return "values[0] != addr3 after iteration"; }
        if (values[1] != addr1) { return "values[1] != addr1 after iteration"; }
        if (values[2] != addr2) { return "values[2] != addr2 after iteration"; }

        return "success";
    }

    /**
     * @dev Tests functions belonging to AddressAddressArrayMap in Mappings.
     * TODO: test functions that return dynamic arrays.
     */
    function testAddressAddressArrayMap() external returns (string memory) {

        // reusable variables during test
        uint error;
        address key;

        // clear test arrays
        clearAddressesArrays();
        addresses1.push(addr1);
        addresses2.push(addr2);
        addresses3.push(addr3);

        // New inserts test
        error = addrAddrArrayMap.insert(addr1, addresses1);
        if (error != BaseErrors.NO_ERROR()) { return "Unexpected error for new insert."; }
        if (addrAddrArrayMap.keys.length != 1) { return "Size expected to be 1 after insert."; }
        error = addrAddrArrayMap.insert(addr2, addresses2);
        if (addrAddrArrayMap.keys.length != 2) { return "Size expected to be 2 after insert."; }

        // Update test
        uint sizeBefore = addrAddrArrayMap.keys.length;
        error = addrAddrArrayMap.insert(addr1, addresses3);
        if (error != BaseErrors.RESOURCE_ALREADY_EXISTS()) { return "Expected RESOURCE_ALREADY_EXISTS error for overwrite insert."; }
        if (addrAddrArrayMap.keys.length != sizeBefore) { return "Size should not have changed after failed insert."; }
        if (addrAddrArrayMap.insertOrUpdate(addr1, addresses3) != sizeBefore) { return "Size should NOT have changed after update of existing entry."; }

        // // Value tests
        if (!addrAddrArrayMap.exists(addr1)) { return "Key addr1 should exist"; }
        if (addrAddrArrayMap.exists(0x01234562345aAAaCDEdcdDc345678876DDdD3456)) { return "Fake key should not exist"; }

        // // add more entries
        error = addrAddrArrayMap.insert(addr3, addresses3);
        if (addrAddrArrayMap.keys.length != 3) { return "Size should be 3 after third 'insert'."; }

        // key tests
        if (addrAddrArrayMap.keyIndex(addr3) != 2) { return "Expected index 2 for key: addr3."; }
        if (addrAddrArrayMap.keyIndex(0x01234562345aAAaCDEdcdDc345678876DDdD3456) != uint(-1)) { return "Expected index -1 for non-existing key."; }
        (error, key) = addrAddrArrayMap.keyAtIndex(1);
        if (error != BaseErrors.NO_ERROR() && key != addr2) { return "Expected no error and key addr2 at index 1"; }
        (error, key) = addrAddrArrayMap.keyAtIndex(999);
        if (error != BaseErrors.INDEX_OUT_OF_BOUNDS() || key != address(0)) { return "Expected error and empty return value for out of range index."; }

        // Removal tests
        uint removedKeyIdx = addrAddrArrayMap.keyIndex(addr2);
        // remember the key of the last element which is about to be swapped by the remove()
        (error, key) = addrAddrArrayMap.keyAtIndex(addrAddrArrayMap.keys.length - 1);
        if (addrAddrArrayMap.remove(addr2) != BaseErrors.NO_ERROR()) { return "Unexpected error during removal of addr2 entry."; }
        if (addrAddrArrayMap.keys.length != 2) { return "Size expected to be 2 after removal"; }
        if (addrAddrArrayMap.keyIndex(addr2) != uint(-1)) { return "Expected index -1 for removed key."; }
        if (addrAddrArrayMap.exists(addr2)) { return "Name2 key should not exist anymore."; }
        if (addrAddrArrayMap.keyIndex(addr3) != removedKeyIdx) { return "The last element from key index should've been swapped into the index position of the removed element."; }

        addrAddrArrayMap.clear();
        if (addrAddrArrayMap.keys.length != 0) { return "Size should be 0 after clearing."; }

        // test iterator functions
        addrAddrArrayMap.insert(addr3, addresses3);
        addrAddrArrayMap.insert(addr1, addresses1);
        addrAddrArrayMap.insert(addr2, addresses2);

        // key iteration test
        uint idx = 0;
        uint nextIdx = 1;
        // NOTE: collecting entities in a temporary array is difficult in Solidity at the moment
        // array needs to be sufficiently large to work!
        // http://solidity.readthedocs.io/en/latest/types.html#allocating-memory-arrays
        address[3] memory keys;
        while( nextIdx > 0 ) {
            (error, key, nextIdx) = addrAddrArrayMap.keyAtIndexHasNext(idx);
            if (error == BaseErrors.NO_ERROR()) {
                keys[idx] = key;
            }
            idx = nextIdx;
        }

        if (keys[0] != addr3) { return "Key0 != addr3 after iteration"; }
        if (keys[1] != addr1) { return "Key1 != addr1 after iteration"; }
        if (keys[2] != addr2) { return "Key2 != addr2 after iteration"; }

        // test internal array manipulation
        uint lenBefore = addrAddrArrayMap.rows[addr2].value.length;
        uint lenAfter = addrAddrArrayMap.addToArray(addr2, addr3, false);
        if (lenBefore+1 != lenAfter) { return "Size of inner array returned from addToArray function does not have expected value"; }
        if (lenBefore+1 != addrAddrArrayMap.rows[addr2].value.length) { return "Adding to inner array did not increase length"; }
        if (addrAddrArrayMap.rows[addr2].value[lenAfter-1] != addr3) { return "Value added to inner array not correct"; }
        // test with unknown key
        lenAfter = addrAddrArrayMap.addToArray(addr5, addr1, false);
        if (1 != lenAfter) { return "Size of newly created inner array should be 1"; }
        lenAfter = addrAddrArrayMap.addToArray(addr5, addr1, false);
        if (2 != lenAfter) { return "Size of newly created inner array should be 2 after adding duplicate value"; }
        lenAfter = addrAddrArrayMap.addToArray(addr5, addr1, true);
        if (2 != lenAfter) { return "Size of newly created inner array should remain 2 after rejecting duplicate value"; }
        lenAfter = addrAddrArrayMap.addToArray(addr5, addr2, true);
        if (3 != lenAfter) { return "Size of newly created inner array should be 3 after new unique value"; }
        lenAfter = addrAddrArrayMap.removeFromArray(addr5, addr2, false);
        if (2 != lenAfter) { return "Size of newly created inner array should be 2 after removing"; }
        lenAfter = addrAddrArrayMap.removeFromArray(addr5, addr1, true);
        if (0 != lenAfter) { return "Size of newly created inner array should be 0 after removing all occurences of myValue"; }

        return "success";
    }

    /**
     * @dev Tests functions belonging to UintAddressMap in Mappings.
     */
    function testUintAddressMap() external returns (string memory) {

        // reusable variables during test
        uint error;
        uint key;
        address value;

        // New inserts test
        error = uintAddrMap.insert(uint1, addr1);
        if (error != BaseErrors.NO_ERROR()) { return "Unexpected error for new insert."; }
        if (uintAddrMap.keys.length != 1) { return "Size expected to be 1 after insert."; }
        error = uintAddrMap.insert(uint2, addr2);
        if (uintAddrMap.keys.length != 2) { return "Size expected to be 2 after insert."; }

        // Update test
        uint sizeBefore = uintAddrMap.keys.length;
        error = uintAddrMap.insert(uint1, addr3);
        if (error != BaseErrors.RESOURCE_ALREADY_EXISTS()) { return "Expected RESOURCE_ALREADY_EXISTS error for overwrite insert."; }
        if (uintAddrMap.keys.length != sizeBefore) { return "Size should not have changed after failed insert."; }
        if (uintAddrMap.insertOrUpdate(uint1, addr3) != sizeBefore) { return "Size should NOT have changed after update of existing entry."; }

        // Value tests
        if (!uintAddrMap.exists(uint1)) { return "Key uint1 should exist"; }
        if (uintAddrMap.exists(9999999)) { return "Fake key should not exist"; }
        if (uintAddrMap.get(uint1) != addr3) { return "Wrong value returned for key: uint1"; }
        if (uintAddrMap.get(uint2) != addr2) { return "Wrong value returned for key: uint2"; }

        // add more entries
        error = uintAddrMap.insert(uint3, addr3);
        if (uintAddrMap.keys.length != 3) { return "Size should be 3 after third 'insert'."; }

        // key tests
        if (uintAddrMap.keyIndex(uint3) != 2) { return "Expected index 2 for key: uint3."; }
        if (uintAddrMap.keyIndex(2222) != uint(-1)) { return "Expected index -1 for non-existing key."; }
        (error, key) = uintAddrMap.keyAtIndex(1);
        if (error != BaseErrors.NO_ERROR() && key != uint2) { return "Expected no error and key uint2 at index 1"; }
        (error, key) = uintAddrMap.keyAtIndex(999);
        if (error != BaseErrors.INDEX_OUT_OF_BOUNDS() || key != uint(-1)) { return "Expected error and -1 return value for out of range index."; }

        // Removal tests
        uint removedKeyIdx = uintAddrMap.keyIndex(uint2);
        // remember the key of the last element which is about to be swapped by the remove()
        (error, key) = uintAddrMap.keyAtIndex(uintAddrMap.keys.length - 1);
        if (uintAddrMap.remove(uint2) != BaseErrors.NO_ERROR()) { return "Unexpected error during removal of uint2 entry."; }
        if (uintAddrMap.keys.length != 2) { return "Size expected to be 2 after removal"; }
        if (uintAddrMap.keyIndex(uint2) != uint(-1)) { return "Expected index -1 for removed key."; }
        if (uintAddrMap.exists(uint2)) { return "Name2 key should not exist anymore."; }
        if (uintAddrMap.keyIndex(uint3) != removedKeyIdx) { return "The last element from key index should've been swapped into the index position of the removed element."; }

        uintAddrMap.clear();
        if (uintAddrMap.keys.length != 0) { return "Size should be 0 after clearing."; }

        // test iterator functions
        uintAddrMap.insert(uint3, addr3);
        uintAddrMap.insert(uint1, addr1);
        uintAddrMap.insert(uint2, addr2);

        // key iteration test
        uint idx = 0;
        uint nextIdx = 1;
        // NOTE: collecting entities in a temporary array is difficult in Solidity at the moment
        // array needs to be sufficiently large to work!
        // http://solidity.readthedocs.io/en/latest/types.html#allocating-memory-arrays
        uint[3] memory keys;
        while( nextIdx > 0 ) {
            (error, key, nextIdx) = uintAddrMap.keyAtIndexHasNext(idx);
            if (error == BaseErrors.NO_ERROR()) {
                keys[idx] = key;
            }
            idx = nextIdx;
        }

        if (keys[0] != uint3) { return "keys[0] != uint3 after iteration"; }
        if (keys[1] != uint1) { return "keys[1] != uint1 after iteration"; }
        if (keys[2] != uint2) { return "keys[2] != uint2 after iteration"; }

        // value iteration test
        idx = 0;
        nextIdx = 1;
        // NOTE: collecting entities in a temporary array is difficult in Solidity at the moment
        // array needs to be sufficiently large to work!
        // http://solidity.readthedocs.io/en/latest/types.html#allocating-memory-arrays
        address[3] memory values;

        while (nextIdx > 0) {
            (error, value, nextIdx) = uintAddrMap.valueAtIndexHasNext(idx);
            if (error == BaseErrors.NO_ERROR()) {
                values[idx] = value;
            }
            idx = nextIdx;
        }

        if (values[0] != addr3) { return "values[0] != addr3 after iteration"; }
        if (values[1] != addr1) { return "values[1] != addr1 after iteration"; }
        if (values[2] != addr2) { return "values[2] != addr2 after iteration"; }

        return "success";
    }

    /**
     * @dev Tests functions belonging to UintAddressArrayMap in Mappings.
     * TODO: test functions that return dynamic arrays.
     */
    function testUintAddressArrayMap() external returns (string memory) {

        // reusable variables during test
        uint error;
        uint key;

        // clear test arrays
        clearAddressesArrays();
        addresses1.push(addr1);
        addresses2.push(addr2);
        addresses3.push(addr3);

        // New inserts test
        error = uintAddrArrayMap.insert(uint1, addresses1);
        if (error != BaseErrors.NO_ERROR()) { return "Unexpected error for new insert."; }
        if (uintAddrArrayMap.keys.length != 1) { return "Size expected to be 1 after insert."; }
        error = uintAddrArrayMap.insert(uint2, addresses2);
        if (uintAddrArrayMap.keys.length != 2) { return "Size expected to be 2 after insert."; }

        // Update test
        uint sizeBefore = uintAddrArrayMap.keys.length;
        error = uintAddrArrayMap.insert(uint1, addresses3);
        if (error != BaseErrors.RESOURCE_ALREADY_EXISTS()) { return "Expected RESOURCE_ALREADY_EXISTS error for overwrite insert."; }
        if (uintAddrArrayMap.keys.length != sizeBefore) { return "Size should not have changed after failed insert."; }
        if (uintAddrArrayMap.insertOrUpdate(uint1, addresses3) != sizeBefore) { return "Size should NOT have changed after update of existing entry."; }

        // // Value tests
        if (!uintAddrArrayMap.exists(uint1)) { return "Key uint1 should exist"; }
        if (uintAddrArrayMap.exists(999999)) { return "Fake key should not exist"; }

        // // add more entries
        error = uintAddrArrayMap.insert(uint3, addresses3);
        if (uintAddrArrayMap.keys.length != 3) { return "Size should be 3 after third 'insert'."; }

        // key tests
        if (uintAddrArrayMap.keyIndex(uint3) != 2) { return "Expected index 2 for key: uint3."; }
        if (uintAddrArrayMap.keyIndex(975678909) != uint(-1)) { return "Expected index -1 for non-existing key."; }
        (error, key) = uintAddrArrayMap.keyAtIndex(1);
        if (error != BaseErrors.NO_ERROR() && key != uint2) { return "Expected no error and key uint2 at index 1"; }
        (error, key) = uintAddrArrayMap.keyAtIndex(999);
        if (error != BaseErrors.INDEX_OUT_OF_BOUNDS() || key != uint(-1)) { return "Expected error and empty return value for out of range index."; }

        // Removal tests
        uint removedKeyIdx = uintAddrArrayMap.keyIndex(uint2);
        // remember the key of the last element which is about to be swapped by the remove()
        (error, key) = uintAddrArrayMap.keyAtIndex(uintAddrArrayMap.keys.length - 1);
        if (uintAddrArrayMap.remove(uint2) != BaseErrors.NO_ERROR()) { return "Unexpected error during removal of uint2 entry."; }
        if (uintAddrArrayMap.keys.length != 2) { return "Size expected to be 2 after removal"; }
        if (uintAddrArrayMap.keyIndex(uint2) != uint(-1)) { return "Expected index -1 for removed key."; }
        if (uintAddrArrayMap.exists(uint2)) { return "Name2 key should not exist anymore."; }
        if (uintAddrArrayMap.keyIndex(uint3) != removedKeyIdx) { return "The last element from key index should've been swapped into the index position of the removed element."; }

        uintAddrArrayMap.clear();
        if (uintAddrArrayMap.keys.length != 0) { return "Size should be 0 after clearing."; }

        // test iterator functions
        uintAddrArrayMap.insert(uint3, addresses3);
        uintAddrArrayMap.insert(uint1, addresses1);
        uintAddrArrayMap.insert(uint2, addresses2);

        // key iteration test
        uint idx = 0;
        uint nextIdx = 1;
        // NOTE: collecting entities in a temporary array is difficult in Solidity at the moment
        // array needs to be sufficiently large to work!
        // http://solidity.readthedocs.io/en/latest/types.html#allocating-memory-arrays
        uint[3] memory keys;
        while( nextIdx > 0 ) {
            (error, key, nextIdx) = uintAddrArrayMap.keyAtIndexHasNext(idx);
            if (error == BaseErrors.NO_ERROR()) {
                keys[idx] = key;
            }
            idx = nextIdx;
        }

        if (keys[0] != uint3) { return "Key0 != uint3 after iteration"; }
        if (keys[1] != uint1) { return "Key1 != uint1 after iteration"; }
        if (keys[2] != uint2) { return "Key2 != uint2 after iteration"; }

        // test internal array manipulation
        uint lenBefore = uintAddrArrayMap.rows[uint2].value.length;
        uint lenAfter = uintAddrArrayMap.addToArray(uint2, addr3, false);
        if (lenBefore+1 != lenAfter) { return "Size of inner array returned from addToArray function does not have expected value"; }
        if (lenBefore+1 != uintAddrArrayMap.rows[uint2].value.length) { return "Adding to inner array did not increase length"; }
        if (uintAddrArrayMap.rows[uint2].value[lenAfter-1] != addr3) { return "Value added to inner array not correct"; }
        // test with unknown key
        lenAfter = uintAddrArrayMap.addToArray(777, addr1, false);
        if (1 != lenAfter) { return "Size of newly created inner array should be 1"; }
        lenAfter = uintAddrArrayMap.addToArray(777, addr1, false);
        if (2 != lenAfter) { return "Size of newly created inner array should be 2 after adding duplicate value"; }
        lenAfter = uintAddrArrayMap.addToArray(777, addr1, true);
        if (2 != lenAfter) { return "Size of newly created inner array should remain 2 after rejecting duplicate value"; }
        lenAfter = uintAddrArrayMap.addToArray(777, addr2, true);
        if (3 != lenAfter) { return "Size of newly created inner array should be 3 after new unique value"; }
        lenAfter = uintAddrArrayMap.removeFromArray(777, addr2, false);
        if (2 != lenAfter) { return "Size of newly created inner array should be 2 after removing"; }
        lenAfter = uintAddrArrayMap.removeFromArray(777, addr1, true);
        if (0 != lenAfter) { return "Size of newly created inner array should be 0 after removing all occurences of myValue"; }

        return "success";
    }

    /**
     * @dev Tests functions belonging to UintBytes32ArrayMap in Mappings.
     * TODO: test functions that return dynamic arrays.
     */
    function testUintBytes32ArrayMap() external returns (string memory) {

        // reusable variables during test
        uint error;
        uint key;

        // clear test arrays
        clearBytes32Arrays();
        bytes32Array1.push(bytes32_1);
        bytes32Array2.push(bytes32_2);
        bytes32Array3.push(bytes32_3);

        // New inserts test
        error = uintB32ArrayMap.insert(uint1, bytes32Array1);
        if (error != BaseErrors.NO_ERROR()) { return "Unexpected error for new insert."; }
        if (uintB32ArrayMap.keys.length != 1) { return "Size expected to be 1 after insert."; }
        error = uintB32ArrayMap.insert(uint2, bytes32Array2);
        if (uintB32ArrayMap.keys.length != 2) { return "Size expected to be 2 after insert."; }

        // Update test
        uint sizeBefore = uintB32ArrayMap.keys.length;
        error = uintB32ArrayMap.insert(uint1, bytes32Array3);
        if (error != BaseErrors.RESOURCE_ALREADY_EXISTS()) { return "Expected RESOURCE_ALREADY_EXISTS error for overwrite insert."; }
        if (uintB32ArrayMap.keys.length != sizeBefore) { return "Size should not have changed after failed insert."; }
        if (uintB32ArrayMap.insertOrUpdate(uint1, bytes32Array3) != sizeBefore) { return "Size should NOT have changed after update of existing entry."; }

        // // Value tests
        if (!uintB32ArrayMap.exists(uint1)) { return "Key uint1 should exist"; }
        if (uintB32ArrayMap.exists(999999)) { return "Fake key should not exist"; }

        // // add more entries
        error = uintB32ArrayMap.insert(uint3, bytes32Array3);
        if (uintB32ArrayMap.keys.length != 3) { return "Size should be 3 after third 'insert'."; }

        // key tests
        if (uintB32ArrayMap.keyIndex(uint3) != 2) { return "Expected index 2 for key: uint3."; }
        if (uintB32ArrayMap.keyIndex(876585999) != uint(-1)) { return "Expected index -1 for non-existing key."; }
        (error, key) = uintB32ArrayMap.keyAtIndex(1);
        if (error != BaseErrors.NO_ERROR() && key != uint2) { return "Expected no error and key uint2 at index 1"; }
        (error, key) = uintB32ArrayMap.keyAtIndex(999);
        if (error != BaseErrors.INDEX_OUT_OF_BOUNDS() || key != uint(-1)) { return "Expected error and empty return value for out of range index."; }

        // Removal tests
        uint removedKeyIdx = uintB32ArrayMap.keyIndex(uint2);
        // remember the key of the last element which is about to be swapped by the remove()
        (error, key) = uintB32ArrayMap.keyAtIndex(uintB32ArrayMap.keys.length - 1);
        if (uintB32ArrayMap.remove(uint2) != BaseErrors.NO_ERROR()) { return "Unexpected error during removal of uint2 entry."; }
        if (uintB32ArrayMap.keys.length != 2) { return "Size expected to be 2 after removal"; }
        if (uintB32ArrayMap.keyIndex(uint2) != uint(-1)) { return "Expected index -1 for removed key."; }
        if (uintB32ArrayMap.exists(uint2)) { return "Name2 key should not exist anymore."; }
        if (uintB32ArrayMap.keyIndex(uint3) != removedKeyIdx) { return "The last element from key index should've been swapped into the index position of the removed element."; }

        uintB32ArrayMap.clear();
        if (uintB32ArrayMap.keys.length != 0) { return "Size should be 0 after clearing."; }

        // test iterator functions
        uintB32ArrayMap.insert(uint3, bytes32Array3);
        uintB32ArrayMap.insert(uint1, bytes32Array1);
        uintB32ArrayMap.insert(uint2, bytes32Array2);

        // key iteration test
        uint idx = 0;
        uint nextIdx = 1;
        // NOTE: collecting entities in a temporary array is difficult in Solidity at the moment
        // array needs to be sufficiently large to work!
        // http://solidity.readthedocs.io/en/latest/types.html#allocating-memory-arrays
        uint[3] memory keys;
        while( nextIdx > 0 ) {
            (error, key, nextIdx) = uintB32ArrayMap.keyAtIndexHasNext(idx);
            if (error == BaseErrors.NO_ERROR()) {
                keys[idx] = key;
            }
            idx = nextIdx;
        }

        if (keys[0] != uint3) { return "Key0 != uint3 after iteration"; }
        if (keys[1] != uint1) { return "Key1 != uint1 after iteration"; }
        if (keys[2] != uint2) { return "Key2 != uint2 after iteration"; }

        // test internal array manipulation
        uint lenBefore = uintB32ArrayMap.rows[uint2].value.length;
        uint lenAfter = uintB32ArrayMap.addToArray(uint2, "newValue", false);
        if (lenBefore+1 != lenAfter) { return "Size of inner array returned from addToArray function does not have expected value"; }
        if (lenBefore+1 != uintB32ArrayMap.rows[uint2].value.length) { return "Adding to inner array did not increase length"; }
        if (uintB32ArrayMap.rows[uint2].value[lenAfter-1] != "newValue") { return "Value added to inner array not correct"; }
        // test with unknown key
        lenAfter = uintB32ArrayMap.addToArray(777, "myValue", false);
        if (1 != lenAfter) { return "Size of newly created inner array should be 1"; }
        lenAfter = uintB32ArrayMap.addToArray(777, "myValue", false);
        if (2 != lenAfter) { return "Size of newly created inner array should be 2 after adding duplicate value"; }
        lenAfter = uintB32ArrayMap.addToArray(777, "myValue", true);
        if (2 != lenAfter) { return "Size of newly created inner array should remain 2 after rejecting duplicate value"; }
        lenAfter = uintB32ArrayMap.addToArray(777, "differentValue", true);
        if (3 != lenAfter) { return "Size of newly created inner array should be 3 after new unique value"; }
        lenAfter = uintB32ArrayMap.removeFromArray(777, "differentValue", false);
        if (2 != lenAfter) { return "Size of newly created inner array should be 2 after removing"; }
        lenAfter = uintB32ArrayMap.removeFromArray(777, "myValue", true);
        if (0 != lenAfter) { return "Size of newly created inner array should be 0 after removing all occurences of myValue"; }

        return "success";
    }

    /**
     * @dev Tests functions belonging to StringAddressMap in Mappings.
     */
    function testStringAddressMap() external returns (string memory) {

        // reusable variables during test
        uint error;
        string memory key;
        address value;

        // New inserts test
        error = strAddrMap.insert(str_1, addr1);
        if (error != BaseErrors.NO_ERROR()) { return "Unexpected error for new insert."; }
        if (strAddrMap.keys.length != 1) { return "Size expected to be 1 after insert."; }
        error = strAddrMap.insert(str_2, addr2);
        if (strAddrMap.keys.length != 2) { return "Size expected to be 2 after insert."; }

        // Update test
        uint sizeBefore = strAddrMap.keys.length;
        error = strAddrMap.insert(str_1, addr3);
        if (error != BaseErrors.RESOURCE_ALREADY_EXISTS()) { return "Expected RESOURCE_ALREADY_EXISTS error for overwrite insert."; }
        if (strAddrMap.keys.length != sizeBefore) { return "Size should not have changed after failed insert."; }
        if (strAddrMap.insertOrUpdate(str_1, addr3) != sizeBefore) { return "Size should NOT have changed after update of existing entry."; }

        // Value tests
        if (!strAddrMap.exists(str_1)) { return "Key str_1 should exist"; }
        if (strAddrMap.exists("xxxTotallyFakeKey")) { return "Fake key should not exist"; }
        if (strAddrMap.get(str_1) != addr3) { return "Wrong value returned for key: str_1"; }
        if (strAddrMap.get(str_2) != addr2) { return "Wrong value returned for key: str_2"; }

        // add more entries
        error = strAddrMap.insert(str_3, addr3);
        if (strAddrMap.keys.length != 3) { return "Size should be 3 after third 'insert'."; }

        // key tests
        // NOTE: string comparison done via hashes
        if (strAddrMap.keyIndex(str_3) != 2) { return "Expected index 2 for str_3."; }
        if (strAddrMap.keyIndex("superBogusKey") != uint(-1)) { return "Expected index -1 for non-existing key."; }
        (error, key) = strAddrMap.keyAtIndex(1);
        if (error != BaseErrors.NO_ERROR() && keccak256(abi.encodePacked(key)) != keccak256(abi.encodePacked(str_2))) { return "Expected no error and key str_2 at index 1"; }
        (error, key) = strAddrMap.keyAtIndex(999);
        if (error != BaseErrors.INDEX_OUT_OF_BOUNDS() || keccak256(abi.encodePacked(key)) != keccak256(abi.encodePacked(""))) { return "Expected error and empty return value for out of range index."; }

        // Removal tests
        uint removedKeyIdx = strAddrMap.keyIndex(str_2);
        // remember the key of the last element which is about to be swapped by the remove()
        (error, key) = strAddrMap.keyAtIndex(strAddrMap.keys.length - 1);
        if (strAddrMap.remove(str_2) != BaseErrors.NO_ERROR()) { return "Unexpected error during removal of str_2 entry."; }
        if (strAddrMap.keys.length != 2) { return "Size expected to be 2 after removal"; }
        if (strAddrMap.keyIndex(str_2) != uint(-1)) { return "Expected index -1 for removed key."; }
        if (strAddrMap.exists(str_2) != false) { return "Name2 key should not exist anymore."; }
        if (strAddrMap.keyIndex(str_3) != removedKeyIdx) { return "The last element from key index should've been swapped into the index position of the removed element."; }

        strAddrMap.clear();
        if (strAddrMap.keys.length != 0) { return "Size should be 0 after clearing."; }

        // test iterator functions
        strAddrMap.insert(str_3, addr3);
        strAddrMap.insert(str_1, addr1);
        strAddrMap.insert(str_2, addr2);

        // key iteration test
        uint idx = 0;
        uint nextIdx = 1;
        // NOTE: collecting entities in a temporary array is difficult in Solidity at the moment
        // array needs to be sufficiently large to work!
        // http://solidity.readthedocs.io/en/latest/types.html#allocating-memory-arrays
        string[3] memory keys;
        while( nextIdx > 0 ) {
            (error, key, nextIdx) = strAddrMap.keyAtIndexHasNext(idx);
            if (error == BaseErrors.NO_ERROR()) {
                keys[idx] = key;
            }
            idx = nextIdx;
        }

        if (keccak256(abi.encodePacked(keys[0])) != keccak256(abi.encodePacked(str_3))) { return "keys[0] != str_3 after iteration"; }
        if (keccak256(abi.encodePacked(keys[1])) != keccak256(abi.encodePacked(str_1))) { return "keys[1] != str_1 after iteration"; }
        if (keccak256(abi.encodePacked(keys[2])) != keccak256(abi.encodePacked(str_2))) { return "keys[2] != str_2 after iteration"; }

        // value iteration test
        idx = 0;
        nextIdx = 1;
        // NOTE: collecting entities in a temporary array is difficult in Solidity at the moment
        // array needs to be sufficiently large to work!
        // http://solidity.readthedocs.io/en/latest/types.html#allocating-memory-arrays
        address[3] memory values;

        while (nextIdx > 0) {
            (error, value, nextIdx) = strAddrMap.valueAtIndexHasNext(idx);
            if (error == BaseErrors.NO_ERROR()) {
                values[idx] = value;
            }
            idx = nextIdx;
        }

        if (values[0] != addr3) { return "values[0] != addr3 after iteration"; }
        if (values[1] != addr1) { return "values[1] != addr1 after iteration"; }
        if (values[2] != addr2) { return "values[2] != addr2 after iteration"; }

        return "success";
    }

    function clearAddressesArrays() private {
        delete addresses1;
        delete addresses2;
        delete addresses3;
    }

    function clearBytes32Arrays() private {
        delete bytes32Array1;
        delete bytes32Array2;
        delete bytes32Array3;
    }

    function clearStorageMaps() private {
        addrB32Map1.clear();
        addrB32Map2.clear();
        addrB32Map3.clear();
        addrAddrMap.clear();
    }

}