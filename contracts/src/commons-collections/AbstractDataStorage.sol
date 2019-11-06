pragma solidity ^0.5;

import "commons-utils/DataTypes.sol";

import "commons-collections/DataStorage.sol";
import "commons-collections/DataStorageUtils.sol";

/**
 * @title AbstractDataStorage
 * @dev DataStorage contract covering the main 6 primitive types and their arrays: address, bytes32, string, bool, uint, int
 * NOTE: This implementation currently does not emit any events for array-based values!
 */
contract AbstractDataStorage is DataStorage {

  using DataStorageUtils for DataStorageUtils.Data;
  using DataStorageUtils for DataStorageUtils.DataMap;

  DataStorageUtils.DataMap dataStorageMap;

  /**
   * @dev abstract constructor
   */
  constructor() internal {

  }

  function getDataType(bytes32 _id) external view returns (uint8) {
    return dataStorageMap.getDataType(_id);
  }
  
  /**
   * @dev Returns the number of data fields in this DataStorage
   * @return uint the size
   */
  function getNumberOfData() external view returns (uint) {
    return dataStorageMap.keys.length;
  }

  function getDataIdAtIndex(uint _index) external view returns (uint error, bytes32 id) {
    (error, id) = dataStorageMap.keyAtIndex(_index);
  }
  
  /**
   * @dev Removes the Data identified by the id from the DataMap, if it exists.
   * @param _id the id of the data
   */
  function removeData(bytes32 _id) external {
    dataStorageMap.remove(_id);
  }

  /**
   * @dev Returns the length of an array with the specified ID in this DataStorage.
   * @param _id the ID of an array-type value
   * @return the length of the array
   */
  function getArrayLength(bytes32 _id) public view returns (uint) {
    return dataStorageMap.getArrayLength(_id);
  }

  /**
   * BOOL
   */
  function getDataValueAsBool (bytes32 _id) external view returns (bool) { return dataStorageMap.get(_id).boolValue; }

  function setDataValueAsBool (bytes32 _id, bool _value) external {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.dataType = DataTypes.BOOL();
    data.boolValue = _value;
    dataStorageMap.insertOrUpdate(data);
    emit LogDataStorageUpdateBool(EVENT_ID_DATA_STORAGE, address(this), _id, _value);
  }

  function getDataValueAsBoolArray (bytes32 _id) external view returns (bool[] memory) {
    return dataStorageMap.get(_id).boolArrayValue;
  }

  function setDataValueAsBoolArray (bytes32 _id, bool[] calldata _value) external {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.dataType = DataTypes.BOOLARRAY();
    data.boolArrayValue = _value;
    dataStorageMap.insertOrUpdate(data);
    // emit LogDataStorageUpdateBoolArray(EVENT_ID_DATA_STORAGE, address(this), _id, _value);
  }

  /**
   * STRING
   */
  function getDataValueAsString (bytes32 _id) external view returns (string memory) {
    return dataStorageMap.get(_id).stringValue;
  }

  function setDataValueAsString (bytes32 _id, string calldata _value) external {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.dataType = DataTypes.STRING();
    data.stringValue = _value;
    dataStorageMap.insertOrUpdate(data);
    emit LogDataStorageUpdateString(EVENT_ID_DATA_STORAGE, address(this), _id, _value);
  }

  // TODO String[] can only be supported after upgrade to Solidity 0.5.x

  // function getDataValueAsStringArray (bytes32 _id) external view returns (string[]) { return dataStorageMap.get(_id).stringArrayValue; }

  // function setDataValueAsStringArray (bytes32 _id, string[] memory _value) external {
  //   DataStorageUtils.Data memory data;
  //   data.id = _id;
  //   data.stringArrayValue = _value;
  //   data.dataType = DataTypes.STRINGARRAY();
  //   dataStorageMap.insertOrUpdate(data);
  //   // emit LogDataStorageUpdateStringArray(EVENT_ID_DATA_STORAGE, address(this), _id, _value);
  // }

  /**
   * UINT
   */
  function getDataValueAsUint (bytes32 _id) external view returns (uint) {
    return dataStorageMap.get(_id).uintValue;
  }

  function setDataValueAsUint (bytes32 _id, uint _value) external {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.dataType = DataTypes.UINT();
    data.uintValue = _value;
    dataStorageMap.insertOrUpdate(data);
    emit LogDataStorageUpdateUint(EVENT_ID_DATA_STORAGE, address(this), _id, _value);
  }
  
  function getDataValueAsUintArray (bytes32 _id) external view returns (uint[] memory) {
    return dataStorageMap.get(_id).uint256ArrayValue;
  }

  function setDataValueAsUintArray (bytes32 _id, uint[] calldata _value) external {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.uint256ArrayValue = _value;
    data.dataType = DataTypes.UINT256ARRAY();
    dataStorageMap.insertOrUpdate(data);
    // emit LogDataStorageUpdateUintArray(EVENT_ID_DATA_STORAGE, address(this), _id, _value);
  }

  /**
   * INT
   */
  function getDataValueAsInt (bytes32 _id) external view returns (int) { return dataStorageMap.get(_id).intValue; }
 
  function setDataValueAsInt (bytes32 _id, int _value) external {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.dataType = DataTypes.INT();
    data.intValue = _value;
    dataStorageMap.insertOrUpdate(data);
    emit LogDataStorageUpdateInt(EVENT_ID_DATA_STORAGE, address(this), _id, _value);
  }

  function getDataValueAsIntArray (bytes32 _id) external view returns (int[] memory) {
    return dataStorageMap.get(_id).int256ArrayValue;
  }

  function setDataValueAsIntArray (bytes32 _id, int[] calldata _value) external {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.int256ArrayValue = _value;
    data.dataType = DataTypes.INT256ARRAY();
    dataStorageMap.insertOrUpdate(data);
    // emit LogDataStorageUpdateIntArray(EVENT_ID_DATA_STORAGE, address(this), _id, _value);
  }

  /**
   * ADDRESS
   */
  function getDataValueAsAddress (bytes32 _id) external view returns (address) {
    return dataStorageMap.get(_id).addressValue;
  }

  function setDataValueAsAddress (bytes32 _id, address _value) external {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.dataType = DataTypes.ADDRESS();
    data.addressValue = _value;
    dataStorageMap.insertOrUpdate(data);
    emit LogDataStorageUpdateAddress(EVENT_ID_DATA_STORAGE, address(this), _id, _value);
  }

  function getDataValueAsAddressArray (bytes32 _id) external view returns (address[] memory) {
    return dataStorageMap.get(_id).addressArrayValue;
  }

  function setDataValueAsAddressArray (bytes32 _id, address[] calldata _value) external {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.addressArrayValue = _value;
    data.dataType = DataTypes.ADDRESSARRAY();
    dataStorageMap.insertOrUpdate(data);
    // emit LogDataStorageUpdateAddressArray(EVENT_ID_DATA_STORAGE, address(this), _id, _value);
  }

  /**
   * BYTES32
   */
  function getDataValueAsBytes32 (bytes32 _id) external view returns (bytes32) {
    return dataStorageMap.get(_id).bytes32Value;
  }

  function setDataValueAsBytes32 (bytes32 _id, bytes32 _value) external {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.dataType = DataTypes.BYTES32();
    data.bytes32Value = _value;
    dataStorageMap.insertOrUpdate(data);
    emit LogDataStorageUpdateBytes32(EVENT_ID_DATA_STORAGE, address(this), _id, _value);
  }

  function getDataValueAsBytes32Array (bytes32 _id) external view returns (bytes32[] memory) {
    return dataStorageMap.get(_id).bytes32ArrayValue;
  }

  function setDataValueAsBytes32Array (bytes32 _id, bytes32[] calldata _value) external {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.bytes32ArrayValue = _value;
    data.dataType = DataTypes.BYTES32ARRAY();
    dataStorageMap.insertOrUpdate(data);
    // emit LogDataStorageUpdateBytes32Array(EVENT_ID_DATA_STORAGE, address(this), _id, _value);
  }

}