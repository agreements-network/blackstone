pragma solidity ^0.5;

import "commons-utils/DataTypes.sol";

import "commons-collections/AbstractDataStorage.sol";
import "commons-collections/DataStorageUtils.sol";

/**
 * @title FullDataStorage
 * @dev DataStorage with more functions to manage various types not covered in AbstractDataStorage.
 */
contract FullDataStorage is AbstractDataStorage {

  using DataStorageUtils for DataStorageUtils.Data;
  using DataStorageUtils for DataStorageUtils.DataMap;

  function setDataValueAsUintType (bytes32 _id, uint _value, uint8 _dataType) public {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.uintValue = _value;
    DataTypes.isValid(_dataType) ? data.dataType = _dataType : data.dataType = DataTypes.UINT256();
    dataStorageMap.insertOrUpdate(data);
  }

  function setDataValueAsIntType (bytes32 _id, int _value, uint8 _dataType) public {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.intValue = _value;
    DataTypes.isValid(_dataType) ? data.dataType = _dataType : data.dataType = DataTypes.INT256();
    dataStorageMap.insertOrUpdate(data);
  }

  function setDataValueAsBytes32Type (bytes32 _id, bytes32 _value, uint8 _dataType) public {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.bytes32Value = _value;
    DataTypes.isValid(_dataType) ? data.dataType = _dataType : data.dataType = DataTypes.BYTES32();
    dataStorageMap.insertOrUpdate(data);
  }

  /*****************************************************************
   *                          UINTARRAY
   *****************************************************************/
  
  function setDataValueAsUint8Array (bytes32 _id, uint8[] memory _value) public {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.uint8ArrayValue = _value;
    data.dataType = DataTypes.UINT8ARRAY();
    dataStorageMap.insertOrUpdate(data);
  }

  function setDataValueAsUint16Array (bytes32 _id, uint16[] memory _value) public {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.uint16ArrayValue = _value;
    data.dataType = DataTypes.UINT16ARRAY();
    dataStorageMap.insertOrUpdate(data);
  }

  function setDataValueAsUint32Array (bytes32 _id, uint32[] memory _value) public {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.uint32ArrayValue = _value;
    data.dataType = DataTypes.UINT32ARRAY();
    dataStorageMap.insertOrUpdate(data);
  }

  function setDataValueAsUint64Array (bytes32 _id, uint64[] memory _value) public {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.uint64ArrayValue = _value;
    data.dataType = DataTypes.UINT64ARRAY();
    dataStorageMap.insertOrUpdate(data);
  }

  function setDataValueAsUint128Array (bytes32 _id, uint128[] memory _value) public {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.uint128ArrayValue = _value;
    data.dataType = DataTypes.UINT128ARRAY();
    dataStorageMap.insertOrUpdate(data);
  }

  function getDataValueAsUint8Array (bytes32 _id) external view returns (uint8[] memory) { return dataStorageMap.get(_id).uint8ArrayValue; }
  function getDataValueAsUint16Array (bytes32 _id) external view returns (uint16[] memory) { return dataStorageMap.get(_id).uint16ArrayValue; }
  function getDataValueAsUint32Array (bytes32 _id) external view returns (uint32[] memory) { return dataStorageMap.get(_id).uint32ArrayValue; }
  function getDataValueAsUint64Array (bytes32 _id) external view returns (uint64[] memory) { return dataStorageMap.get(_id).uint64ArrayValue; }
  function getDataValueAsUint128Array (bytes32 _id) external view returns (uint128[] memory) { return dataStorageMap.get(_id).uint128ArrayValue; }

  /*****************************************************************
   *                          INTARRAY
   *****************************************************************/
  
  function setDataValueAsInt8Array (bytes32 _id, int8[] memory _value) public {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.int8ArrayValue = _value;
    data.dataType = DataTypes.INT8ARRAY();
    dataStorageMap.insertOrUpdate(data);
  }

  function setDataValueAsInt16Array (bytes32 _id, int16[] memory _value) public {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.int16ArrayValue = _value;
    data.dataType = DataTypes.INT16ARRAY();
    dataStorageMap.insertOrUpdate(data);
  }

  function setDataValueAsInt32Array (bytes32 _id, int32[] memory _value) public {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.int32ArrayValue = _value;
    data.dataType = DataTypes.INT32ARRAY();
    dataStorageMap.insertOrUpdate(data);
  }

  function setDataValueAsInt64Array (bytes32 _id, int64[] memory _value) public {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.int64ArrayValue = _value;
    data.dataType = DataTypes.INT64ARRAY();
    dataStorageMap.insertOrUpdate(data);
  }

  function setDataValueAsInt128Array (bytes32 _id, int128[] memory _value) public {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.int128ArrayValue = _value;
    data.dataType = DataTypes.INT128ARRAY();
    dataStorageMap.insertOrUpdate(data);
  }

  function getDataValueAsInt8Array (bytes32 _id) external view returns (int8[] memory) { return dataStorageMap.get(_id).int8ArrayValue; }
  function getDataValueAsInt16Array (bytes32 _id) external view returns (int16[] memory) { return dataStorageMap.get(_id).int16ArrayValue; }
  function getDataValueAsInt32Array (bytes32 _id) external view returns (int32[] memory) { return dataStorageMap.get(_id).int32ArrayValue; }
  function getDataValueAsInt64Array (bytes32 _id) external view returns (int64[] memory) { return dataStorageMap.get(_id).int64ArrayValue; }
  function getDataValueAsInt128Array (bytes32 _id) external view returns (int128[] memory) { return dataStorageMap.get(_id).int128ArrayValue; }

  /*****************************************************************
   *                          BYTESARRAY
   *****************************************************************/

  function setDataValueAsBytes1Array (bytes32 _id, bytes1[] memory _value) public {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.bytes1ArrayValue = _value;
    data.dataType = DataTypes.BYTES1ARRAY();
    dataStorageMap.insertOrUpdate(data);
  }

  function setDataValueAsBytes2Array (bytes32 _id, bytes2[] memory _value) public {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.bytes2ArrayValue = _value;
    data.dataType = DataTypes.BYTES2ARRAY();
    dataStorageMap.insertOrUpdate(data);
  }

  function setDataValueAsBytes3Array (bytes32 _id, bytes3[] memory _value) public {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.bytes3ArrayValue = _value;
    data.dataType = DataTypes.BYTES3ARRAY();
    dataStorageMap.insertOrUpdate(data);
  }

  function setDataValueAsBytes4Array (bytes32 _id, bytes4[] memory _value) public {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.bytes4ArrayValue = _value;
    data.dataType = DataTypes.BYTES4ARRAY();
    dataStorageMap.insertOrUpdate(data);
  }

  function setDataValueAsBytes8Array (bytes32 _id, bytes8[] memory _value) public {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.bytes8ArrayValue = _value;
    data.dataType = DataTypes.BYTES8ARRAY();
    dataStorageMap.insertOrUpdate(data);
  }

  function setDataValueAsBytes16Array (bytes32 _id, bytes16[] memory _value) public {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.bytes16ArrayValue = _value;
    data.dataType = DataTypes.BYTES16ARRAY();
    dataStorageMap.insertOrUpdate(data);
  }

  function setDataValueAsBytes20Array (bytes32 _id, bytes20[] memory _value) public {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.bytes20ArrayValue = _value;
    data.dataType = DataTypes.BYTES20ARRAY();
    dataStorageMap.insertOrUpdate(data);
  }

  function setDataValueAsBytes24Array (bytes32 _id, bytes24[] memory _value) public {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.bytes24ArrayValue = _value;
    data.dataType = DataTypes.BYTES24ARRAY();
    dataStorageMap.insertOrUpdate(data);
  }

  function setDataValueAsBytes28Array (bytes32 _id, bytes28[] memory _value) public {
    DataStorageUtils.Data memory data;
    data.id = _id;
    data.bytes28ArrayValue = _value;
    data.dataType = DataTypes.BYTES28ARRAY();
    dataStorageMap.insertOrUpdate(data);
  }

  function getDataValueAsBytes1Array (bytes32 _id) external view returns (bytes1[] memory) { return dataStorageMap.get(_id).bytes1ArrayValue; }
  function getDataValueAsBytes2Array (bytes32 _id) external view returns (bytes2[] memory) { return dataStorageMap.get(_id).bytes2ArrayValue; }
  function getDataValueAsBytes3Array (bytes32 _id) external view returns (bytes3[] memory) { return dataStorageMap.get(_id).bytes3ArrayValue; }
  function getDataValueAsBytes4Array (bytes32 _id) external view returns (bytes4[] memory) { return dataStorageMap.get(_id).bytes4ArrayValue; }
  function getDataValueAsBytes8Array (bytes32 _id) external view returns (bytes8[] memory) { return dataStorageMap.get(_id).bytes8ArrayValue; }
  function getDataValueAsBytes16Array (bytes32 _id) external view returns (bytes16[] memory) { return dataStorageMap.get(_id).bytes16ArrayValue; }
  function getDataValueAsBytes20Array (bytes32 _id) external view returns (bytes20[] memory) { return dataStorageMap.get(_id).bytes20ArrayValue; }
  function getDataValueAsBytes24Array (bytes32 _id) external view returns (bytes24[] memory) { return dataStorageMap.get(_id).bytes24ArrayValue; }
  function getDataValueAsBytes28Array (bytes32 _id) external view returns (bytes28[] memory) { return dataStorageMap.get(_id).bytes28ArrayValue; }
  
}
