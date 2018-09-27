pragma solidity ^0.4.23;

/**
 * @title DataStorage Interface
 * @dev Definition of the public API for Data Storage 
 */
contract DataStorage {

  /**
   * @dev Returns the data type of the Data object identified by the given id
   * @param _id the id of the data
   * @return uint8 the DataType
   */
  function getDataType(bytes32 _id) external view returns (uint8);

  /**
   * @dev Returns the size of the DataMap
   * @return uint the size
   */
  function getSize() external view returns (uint);

  /**
   * @dev Returns the data id at the given index
   * @param _index the index of the data
   * @return error uint error code 
   * @return id bytes32 id of the data
   */
  function getDataIdAtIndex(uint _index) external view returns (uint error, bytes32 id);

  /**
   * @dev Removes the Data identified by the id from the DataMap, if it exists.
   * @param _id the id of the data
   */
  function removeData(bytes32 _id) external;

  /**
   * @dev Returns the number of non-default entries in the specified array-type DataStorage field
   * @param _key the key for the array-type value
   * @param _fullscan if false the function will return as soon as a default value (0 for int/uint, 0x0 for address, "" for bytes32, etc.) is encountered, if true the array will be scanned to its end
   * @return the number of non-default entries in the array
   */
  function getNumberOfArrayEntries(bytes32 _key, bool _fullscan) public view returns (uint);

  /**
   * @dev Creates a Data object with the given value and inserts it into the DataMap
   * @param _id the id of the data
   * @param _value the bool value of the data
   */
  function setDataValueAsBool (bytes32 _id, bool _value) external;

  /**
   * @dev Gets the value of the Data object identified by the given id
   * @param _id the id of the data
   * @return bool the bool value of the data
   */
  function getDataValueAsBool (bytes32 _id) external view returns (bool);

  /**
   * @dev Creates a Data object with the given value and inserts it into the DataMap
   * @param _id the id of the data
   * @param _value the string value of the data
   */
  function setDataValueAsString (bytes32 _id, string _value) external;

  /**
   * @dev Gets the value of the Data object identified by the given id
   * @param _id the id of the data
   * @return string the value of the data
   */
  function getDataValueAsString (bytes32 _id) external view returns (string);
  
  /**
   * @dev Creates a Data object with the given value and inserts it into the DataMap
   * @param _id the id of the data
   * @param _value the uint value of the data
   */
  function setDataValueAsUint (bytes32 _id, uint _value) external;

  /**
   * @dev Gets the value of the Data object identified by the given id
   * @param _id the id of the data
   * @return uint the value of the data
   */
  function getDataValueAsUint (bytes32 _id) external view returns (uint);

  /**
   * @dev Creates a Data object with the given value and inserts it into the DataMap
   * @param _id the id of the data
   * @param _value the int value of the data
   */
  function setDataValueAsInt (bytes32 _id, int _value) external;

  /**
   * @dev Gets the value of the Data object identified by the given id
   * @param _id the id of the data
   * @return int the value of the data
   */
  function getDataValueAsInt (bytes32 _id) external view returns (int);
  
  /**
   * @dev Creates a Data object with the given value and inserts it into the DataMap
   * @param _id the id of the data
   * @param _value the address value of the data
   */
  function setDataValueAsAddress (bytes32 _id, address _value) external;

  /**
   * @dev Gets the value of the Data object identified by the given id
   * @param _id the id of the data
   * @return address the value of the data
   */
  function getDataValueAsAddress (bytes32 _id) external view returns (address);

  /**
   * @dev Creates a Data object with the given value and inserts it into the DataMap
   * @param _id the id of the data
   * @param _value the bytes32 value of the data
   */
  function setDataValueAsBytes32 (bytes32 _id, bytes32 _value) external;

  /**
   * @dev Gets the value of the Data object identified by the given id
   * @param _id the id of the data
   * @return bytes32 the value of the data
   */
  function getDataValueAsBytes32 (bytes32 _id) external view returns (bytes32);

  /**
   * @dev Creates a Data object with the given value and inserts it into the DataMap
   * @param _id the id of the data
   * @param _value the address[100] value of the data
   */
  function setDataValueAsAddressArray (bytes32 _id, address[100] _value) external;

  /**
   * @dev Gets the value of the Data object identified by the given id
   * @param _id the id of the data
   * @return address[100] the value of the data
   */
  function getDataValueAsAddressArray (bytes32 _id) external view returns (address[100]);

  /**
   * @dev Creates a Data object with the given value and inserts it into the DataMap
   * @param _id the id of the data
   * @param _value the uint[100] value of the data
   */
  function setDataValueAsUintArray (bytes32 _id, uint[100] _value) external;

  /**
   * @dev Gets the value of the Data object identified by the given id
   * @param _id the id of the data
   * @return uint256[100] the value of the data
   */
  function getDataValueAsUintArray (bytes32 _id) external view returns (uint[100]);

  /**
   * @dev Creates a Data object with the given value and inserts it into the DataMap
   * @param _id the id of the data
   * @param _value the int256[100] value of the data
   */
  function setDataValueAsIntArray (bytes32 _id, int[100] _value) external;

  /**
   * @dev Gets the value of the Data object identified by the given id
   * @param _id the id of the data
   * @return int256[100] the value of the data
   */
  function getDataValueAsIntArray (bytes32 _id) external view returns (int[100]);

  /**
   * @dev Creates a Data object with the given value and inserts it into the DataMap
   * @param _id the id of the data
   * @param _value the bytes32[100] value of the data
   */
  function setDataValueAsBytes32Array (bytes32 _id, bytes32[100] _value) external;

  /**
   * @dev Gets the value of the Data object identified by the given id
   * @param _id the id of the data
   * @return bytes32[100] the value of the data
   */
  function getDataValueAsBytes32Array (bytes32 _id) external view returns (bytes32[100]);

}