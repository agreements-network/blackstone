pragma solidity ^0.5;

import "commons-base/ErrorsLib.sol";
import "commons-base/BaseErrors.sol";
import "commons-utils/DataTypes.sol";
import "commons-utils/TypeUtilsLib.sol";

import "commons-collections/DataStorage.sol";
import "commons-collections/Mappings.sol";
import "commons-collections/MappingsLib.sol";

/**
 * @title DataStorageUtils Library
 * @dev A library containing storage utility structs functions
 */
library DataStorageUtils {

  enum COMPARISON_OPERATOR {EQ, LT, GT, LTE, GTE, NEQ}

  struct DataMap {
    mapping(bytes32 => DataElement) rows;
    bytes32[] keys;
  }

  struct DataElement {
    bool exists;
    uint keyIdx;
    Data value;
  }

  /**
   * a struct to describe the scope of an element in the form of two bytes32 values: context and scope.
   * The context gives an optional 2nd dimension to the scope.
   * The actual scope can either be a fixed value or something that resolves to bytes32 at via a ConditionalData.
   */
  struct DataScope {
    bytes32 context;
    bytes32 fixedScope;
    ConditionalData conditionalScope;
  }

  struct Data {
    bytes32 id;
    uint8 dataType;

    bool boolValue;
    string stringValue;
    uint uintValue;
    int intValue;
    address addressValue;
    bytes32 bytes32Value;
    
    string[] stringArrayValue;
    address[] addressArrayValue;
    bool[] boolArrayValue;

    uint8[] uint8ArrayValue;
    uint16[] uint16ArrayValue;
    uint32[] uint32ArrayValue;
    uint64[] uint64ArrayValue;
    uint128[] uint128ArrayValue;
    uint256[] uint256ArrayValue;

    int8[] int8ArrayValue;
    int16[] int16ArrayValue;
    int32[] int32ArrayValue;
    int64[] int64ArrayValue;
    int128[] int128ArrayValue;
    int256[] int256ArrayValue;

    // bytes bytesArrayValue;
    bytes1[] bytes1ArrayValue;
    bytes2[] bytes2ArrayValue;
    bytes3[] bytes3ArrayValue;
    bytes4[] bytes4ArrayValue;
    bytes8[] bytes8ArrayValue;
    bytes16[] bytes16ArrayValue;
    bytes20[] bytes20ArrayValue;
    bytes24[] bytes24ArrayValue;
    bytes28[] bytes28ArrayValue;
    bytes32[] bytes32ArrayValue;
  }

  /**
    * @dev Struct to store information about how to access a data field from a DataStorage contract.
    * Fields:
    * dataStorage: the address of a DataStorage contract
    * dataStorageId: a field key in a known DataStorage that resolves to an address of another DataStorage
    * dataPath: the field key in the target DataStorage with which the value can be extracted
    */
  struct ConditionalData {
      bytes32 dataPath;
      bytes32 dataStorageId;
      address dataStorage;
      bool exists;
  }

  /**
   * @dev Modifier to restrict function access to using only equality comparison operators.
   * REVERTS if:
   * - the operator is not EQ or NEQ
   */
  modifier pre_onlySupportsEqualityOperations(COMPARISON_OPERATOR _current) {
    ErrorsLib.revertIf(_current != COMPARISON_OPERATOR.EQ && _current != COMPARISON_OPERATOR.NEQ,
      ErrorsLib.INVALID_INPUT(), "DataStorageUtils.pre_onlySupportsEqualityOperations", "Operator must be EQ or NEQ");
    _;
  }

  /**
   * @dev Modifier to prevent function access if the parameters required to resolve a comparison expression are empty.
   * REVERTS if:
   * - _dataStorage is a zero address
   * - _dataPath is an empty bytes32
   */
  modifier pre_verifyExpressionParametersExist(DataStorage _dataStorage, bytes32 _dataPath) {
    ErrorsLib.revertIf(address(_dataStorage) == address(0),
      ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DataStorageUtils.pre_verifyExpressionParametersExist", "dataStorage is NULL");
    ErrorsLib.revertIf(_dataPath == "",
      ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DataStorageUtils.pre_verifyExpressionParametersExist", "dataPath is NULL");
    _;
  }

  /**
    * @dev Inserts the given Data structure under its data ID in the provided map. 
    * If the ID already exists, an update is performed.
    * //TODO because this is an internal function, it gets inlined and due to its heavy usage in AbstractDataStorage it blows up the binary footprint of that contract. Better: Provide insertOrUpdate(DataMap storage _map, bytes32 _key, <valuetype> _value) functions here
    *
    * @param _map the map
    * @param _value the value
    * @return the number of data objects in the map after the operation
    */
  function insertOrUpdate(DataMap storage _map, Data memory _value) internal returns (uint) {
    if (_map.rows[_value.id].exists) {
        _map.rows[_value.id].value = _value;
    } else {
        _map.rows[_value.id].keyIdx = (_map.keys.push(_value.id)-1);
        _map.rows[_value.id].value = _value;
        _map.rows[_value.id].exists = true;
    }
    return _map.keys.length;
  }

  /**
    * @dev Returns the Data registered at the specified ID in the given map.
    */
  function get(DataMap storage _map, bytes32 _id) internal view returns (Data memory) {
    return _map.rows[_id].value;
  }

  /**
    * @dev Removes the Data registered at the specified key in the provided map.
    * The _map.keys array may get re-ordered by this operation: unless the removed entry was
    * the last element in the map's keys, the last key will be moved into the void position created
    * by the removal.
    *
    * @param _map the map
    * @param _key the key
    * @return BaseErrors.NO_ERROR or BaseErrors.RESOURCE_NOT_FOUND.
    */
  function remove(DataMap storage _map, bytes32 _key) public returns (uint) {
    
    if (!_map.rows[_key].exists) { return BaseErrors.RESOURCE_NOT_FOUND(); }
    DataElement memory elem = _map.rows[_key];
    
    bytes32 swapKey = Mappings.deleteInKeys(_map.keys, _map.rows[_key].keyIdx);
    if (TypeUtilsLib.contentLength(swapKey) > 0) {
      _map.rows[swapKey].keyIdx = elem.keyIdx;
    }
    
    delete _map.rows[_key];
    return BaseErrors.NO_ERROR();
  }

  /**
   * @dev Returns the DataTypes value for the specified field key from the given map.
   * @param _map a DataMap
   * @param _key the field key
   * @return the uint8 value of the data type
   */
  function getDataType(DataMap storage _map, bytes32 _key) public view returns (uint8) {
    return get(_map, _key).dataType;
  }

  /**
   * @dev Returns the length of an array with the specified ID in the given DataMap.
   * It is expected that the data value at the given ID is an array type, otherwise length 0 is returned.
   * @param _map the DataMap
   * @param _key a key pointing to a supported array-type field
   * @return the length of the array
   */
  function getArrayLength(DataMap storage _map, bytes32 _key) public view returns (uint) {
    if (getDataType(_map, _key) == DataTypes.BOOLARRAY()) {
      return _map.rows[_key].value.boolArrayValue.length;
    }
    else if (getDataType(_map, _key) == DataTypes.STRINGARRAY()) {
      return _map.rows[_key].value.stringArrayValue.length;
    }
    else if (getDataType(_map, _key) == DataTypes.ADDRESSARRAY()) {
      return _map.rows[_key].value.addressArrayValue.length;
    }
    else if (getDataType(_map, _key) == DataTypes.UINTARRAY() ||
             getDataType(_map, _key) == DataTypes.UINT256ARRAY()) {
      return _map.rows[_key].value.uint256ArrayValue.length;
    }
    else if (getDataType(_map, _key) == DataTypes.UINT8ARRAY()) {
      return _map.rows[_key].value.uint8ArrayValue.length;
    }
    else if (getDataType(_map, _key) == DataTypes.UINT16ARRAY()) {
      return _map.rows[_key].value.uint16ArrayValue.length;
    }
    else if (getDataType(_map, _key) == DataTypes.UINT32ARRAY()) {
      return _map.rows[_key].value.uint32ArrayValue.length;
    }
    else if (getDataType(_map, _key) == DataTypes.UINT64ARRAY()) {
      return _map.rows[_key].value.uint64ArrayValue.length;
    }
    else if (getDataType(_map, _key) == DataTypes.UINT128ARRAY()) {
      return _map.rows[_key].value.uint128ArrayValue.length;
    }
    else if (getDataType(_map, _key) == DataTypes.INTARRAY() ||
             getDataType(_map, _key) == DataTypes.INT256ARRAY()) {
      return _map.rows[_key].value.int256ArrayValue.length;
    }
    else if (getDataType(_map, _key) == DataTypes.INT8ARRAY()) {
      return _map.rows[_key].value.int8ArrayValue.length;
    }
    else if (getDataType(_map, _key) == DataTypes.INT16ARRAY()) {
      return _map.rows[_key].value.int16ArrayValue.length;
    }
    else if (getDataType(_map, _key) == DataTypes.INT32ARRAY()) {
      return _map.rows[_key].value.int32ArrayValue.length;
    }
    else if (getDataType(_map, _key) == DataTypes.INT64ARRAY()) {
      return _map.rows[_key].value.int64ArrayValue.length;
    }
    else if (getDataType(_map, _key) == DataTypes.INT128ARRAY()) {
      return _map.rows[_key].value.int128ArrayValue.length;
    }
    else if (getDataType(_map, _key) == DataTypes.BYTES1ARRAY() ||
             getDataType(_map, _key) == DataTypes.BYTEARRAY()) {
      return _map.rows[_key].value.bytes1ArrayValue.length;
    }
    else if (getDataType(_map, _key) == DataTypes.BYTES2ARRAY()) {
      return _map.rows[_key].value.bytes2ArrayValue.length;
    }
    else if (getDataType(_map, _key) == DataTypes.BYTES3ARRAY()) {
      return _map.rows[_key].value.bytes3ArrayValue.length;
    }
    else if (getDataType(_map, _key) == DataTypes.BYTES4ARRAY()) {
      return _map.rows[_key].value.bytes4ArrayValue.length;
    }
    else if (getDataType(_map, _key) == DataTypes.BYTES8ARRAY()) {
      return _map.rows[_key].value.bytes8ArrayValue.length;
    }
    else if (getDataType(_map, _key) == DataTypes.BYTES16ARRAY()) {
      return _map.rows[_key].value.bytes16ArrayValue.length;
    }
    else if (getDataType(_map, _key) == DataTypes.BYTES20ARRAY()) {
      return _map.rows[_key].value.bytes20ArrayValue.length;
    }
    else if (getDataType(_map, _key) == DataTypes.BYTES24ARRAY()) {
      return _map.rows[_key].value.bytes24ArrayValue.length;
    }
    else if (getDataType(_map, _key) == DataTypes.BYTES28ARRAY()) {
      return _map.rows[_key].value.bytes28ArrayValue.length;
    }
    else if (getDataType(_map, _key) == DataTypes.BYTES32ARRAY()) {
      return _map.rows[_key].value.bytes32ArrayValue.length;
    }
  }

  /**
    * @dev Returns the ID of the Data at the specified index in the given map
    */
  function keyAtIndex(DataMap storage _map, uint _index) public view returns (uint, bytes32) {
    return Mappings.keyAtIndex(_map.keys, _index);
  }

  /**
   * @dev Resolves the location of a ConditionalData against the provided DataStorage. This function is guaranteed to return a data location
   * consisting of an address/path combination. If that is not possible, the functions reverts.
   * REVERTS if: 
   * - the DataStorage address cannot be determined and is empty
   * @param _conditionalData a ConditionalData with instructions how to find the desired data
   * @param _dataStorage a DataStorage contract to use as a basis for the resolution
   * @return dataStorage - the address of a DataStorage that contains the requested data or 0x0 if a dataStorageId was provided that has no value in the 
   * @return dataPath - the ID with which the data can be retrieved from the DataStorage
   */
  function resolveDataLocation(ConditionalData storage _conditionalData, DataStorage _dataStorage)
    public view
    returns (address dataStorage, bytes32 dataPath)
  {
    dataPath = _conditionalData.dataPath;
    dataStorage = resolveDataStorageAddress(_conditionalData.dataStorageId, _conditionalData.dataStorage, _dataStorage);
    ErrorsLib.revertIf(dataStorage == address(0),
      ErrorsLib.INVALID_STATE(), "DataStorageUtils.resolveDataLocation", "Unable to determine a DataStorage address from the given ConditionalData");
  }

  /**
   * @dev Returns the address location of a DataStorage contract using the provided information.
   * This is the most basic routine to determine from where to retrieve a data value. It uses the same attributes
   * that are encoded in a ConditionalData struct, therefore supporting the handling of ConditionalData structs.
   * The rules of resolving the location are as follows:
   * 1. If an absolute location in the form of a dataStorage address is available, this address is returned
   * 2. If a dataStorageId is provided, it's used as a dataPath to retrieve and return an address from the DataStorage parameter.
   * 3. In all other cases, the optional DataStorage parameter is returned.
   * REVERTS if:
   * - for step 2 the DataStorage parameter is empty
   * @param _dataStorageId a path by which an address can be retrieved from a DataStorage
   * @param _dataStorage the absolute address of a DataStorage
   * @param _refDataStorage an optional DataStorge required to determine an address, if no absolute address was provided
   * @return the address of a DataStorage
   */
  function resolveDataStorageAddress(bytes32 _dataStorageId, address _dataStorage, DataStorage _refDataStorage)
    public view
    returns (address)
  {
    if (_dataStorage != address(0)) {
      return _dataStorage;
    }
    else if (_dataStorageId != "") {
      // All resolutions henceforth require the DataStorage parameter
      ErrorsLib.revertIf(address(_refDataStorage) == address(0),
        ErrorsLib.INVALID_INPUT(), "DataStorageUtils.resolveDataStorageAddress", "The DataStorage parameter is required for resolving an address referenced as dataStorageId.");
      return DataStorage(_refDataStorage).getDataValueAsAddress(_dataStorageId);
    }
    else {
      return address(_refDataStorage);
    }
  }

  /**
   * @dev Resolves an expression where all the relevant parts of the expression are provided as parameters.
   * @param _dataStorage a DataStorage contract where the target data is located
   * @param _dataId an optional dataId which if supplied is then used to find a different DataStorage where the target data is located
   * @param _dataPath a dataPath where the target data is located
   * @param _op a valid comparison operator 
   * @param _value a string value to use as right-hand value to compare against the target data
   * @return boolean result of the comparison
   */
  function resolveExpression(DataStorage _dataStorage, bytes32 _dataId, bytes32 _dataPath, COMPARISON_OPERATOR _op, string calldata _value)
    external view
    pre_onlySupportsEqualityOperations(_op)
    pre_verifyExpressionParametersExist(_dataStorage, _dataPath)
    returns (bool)
  {
    string memory target;
    if (_dataId == "") {
      target = _dataStorage.getDataValueAsString(_dataPath);
    } else {
      address subDataStorage = _dataStorage.getDataValueAsAddress(_dataId);
      ErrorsLib.revertIf(subDataStorage == address(0),
        ErrorsLib.INVALID_STATE(), "DataStorageUtils.resolveExpression", "Unable to locate DataStorage based on dataId parameter");
      target = DataStorage(subDataStorage).getDataValueAsString(_dataPath);
    }
    if (_op == COMPARISON_OPERATOR.EQ) {
      return keccak256(abi.encodePacked(_value)) == keccak256(abi.encodePacked(target));
    } else if (_op == COMPARISON_OPERATOR.NEQ) {
      return keccak256(abi.encodePacked(_value)) != keccak256(abi.encodePacked(target));
    }
  }

  /**
   * @dev Resolves an expression where all the relevant parts of the expression are provided as parameters.
   * @param _dataStorage a DataStorage contract where the target data is located
   * @param _dataId an optional dataId which if supplied is then used to find a different DataStorage where the target data is located
   * @param _dataPath a dataPath where the target data is located
   * @param _op a valid comparison operator 
   * @param _value a bytes32 value to use as right-hand value to compare against the target data
   * @return boolean result of the comparison
   */
  function resolveExpression(DataStorage _dataStorage, bytes32 _dataId, bytes32 _dataPath, COMPARISON_OPERATOR _op, bytes32 _value)
    external view
    pre_onlySupportsEqualityOperations(_op)
    pre_verifyExpressionParametersExist(_dataStorage, _dataPath)
    returns (bool)
  {
    bytes32 target;
    if (_dataId == "") {
      target = _dataStorage.getDataValueAsBytes32(_dataPath);
    } else {
      address subDataStorage = _dataStorage.getDataValueAsAddress(_dataId);
      ErrorsLib.revertIf(subDataStorage == address(0),
        ErrorsLib.INVALID_STATE(), "DataStorageUtils.resolveExpression", "Unable to locate DataStorage based on dataId parameter");
      target = DataStorage(subDataStorage).getDataValueAsBytes32(_dataPath);
    }
    if (_op == COMPARISON_OPERATOR.EQ) {
      return _value == target;
    } else if (_op == COMPARISON_OPERATOR.NEQ) {
      return _value != target;
    }
  }

  /**
   * @dev Resolves an expression where all the relevant parts of the expression are provided as parameters.
   * @param _dataStorage a DataStorage contract where the target data is located
   * @param _dataId an optional dataId which if supplied is then used to find a different DataStorage where the target data is located
   * @param _dataPath a dataPath where the target data is located
   * @param _op a valid comparison operator 
   * @param _value a address value to use as right-hand value to compare against the target data
   * @return boolean result of the comparison
   */
  function resolveExpression(DataStorage _dataStorage, bytes32 _dataId, bytes32 _dataPath, COMPARISON_OPERATOR _op, address _value)
    external view
    pre_onlySupportsEqualityOperations(_op)
    pre_verifyExpressionParametersExist(_dataStorage, _dataPath)
    returns (bool)
  {
    address target;
    if (_dataId == "") {
      target = _dataStorage.getDataValueAsAddress(_dataPath);
    } else {
      address subDataStorage = _dataStorage.getDataValueAsAddress(_dataId);
      ErrorsLib.revertIf(subDataStorage == address(0),
        ErrorsLib.INVALID_STATE(), "DataStorageUtils.resolveExpression", "Unable to locate DataStorage based on dataId parameter");
      target = DataStorage(subDataStorage).getDataValueAsAddress(_dataPath);
    }
    if (_op == COMPARISON_OPERATOR.EQ) {
      return _value == target;
    } else if (_op == COMPARISON_OPERATOR.NEQ) {
      return _value != target;
    }
  }

  /**
   * @dev Resolves an expression where all the relevant parts of the expression are provided as parameters.
   * @param _dataStorage a DataStorage contract where the target data is located
   * @param _dataId an optional dataId which if supplied is then used to find a different DataStorage where the target data is located
   * @param _dataPath a dataPath where the target data is located
   * @param _op a valid comparison operator 
   * @param _value a uint value to use as right-hand value to compare against the target data
   * @return boolean result of the comparison
   */
  function resolveExpression(DataStorage _dataStorage, bytes32 _dataId, bytes32 _dataPath, COMPARISON_OPERATOR _op, uint _value)
    external view
    pre_verifyExpressionParametersExist(_dataStorage, _dataPath)
    returns (bool)
  {
    uint target;
    if (_dataId == "") {
      target = _dataStorage.getDataValueAsUint(_dataPath);
    } else {
      address subDataStorage = _dataStorage.getDataValueAsAddress(_dataId);
      ErrorsLib.revertIf(subDataStorage == address(0),
        ErrorsLib.INVALID_STATE(), "DataStorageUtils.resolveExpression", "Unable to locate DataStorage based on dataId parameter");
      target = DataStorage(subDataStorage).getDataValueAsUint(_dataPath);
    }
    if (_op == COMPARISON_OPERATOR.EQ) {
      return target == _value;
    } else if (_op == COMPARISON_OPERATOR.LT) {
      return target < _value;
    } else if (_op == COMPARISON_OPERATOR.GT) {
      return target > _value;
    } else if (_op == COMPARISON_OPERATOR.LTE) {
      return target <= _value;
    } else if (_op == COMPARISON_OPERATOR.GTE) {
      return target >= _value;
    } else if (_op == COMPARISON_OPERATOR.NEQ) {
      return target != _value;
    }
  }

  /**
   * @dev Resolves an expression where all the relevant parts of the expression are provided as parameters.
   * @param _dataStorage a DataStorage contract where the target data is located
   * @param _dataId an optional dataId which if supplied is then used to find a different DataStorage where the target data is located
   * @param _dataPath a dataPath where the target data is located
   * @param _op a valid comparison operator 
   * @param _value a uint value to use as right-hand value to compare against the target data
   * @return boolean result of the comparison
   */
  function resolveExpression(DataStorage _dataStorage, bytes32 _dataId, bytes32 _dataPath, COMPARISON_OPERATOR _op, int _value)
    external view
    pre_verifyExpressionParametersExist(_dataStorage, _dataPath)
    returns (bool)
  {
    int target;
    if (_dataId == "") {
      target = _dataStorage.getDataValueAsInt(_dataPath);
    } else {
      address subDataStorage = _dataStorage.getDataValueAsAddress(_dataId);
      ErrorsLib.revertIf(subDataStorage == address(0),
        ErrorsLib.INVALID_STATE(), "DataStorageUtils.resolveExpression", "Unable to locate DataStorage based on dataId parameter");
      target = DataStorage(subDataStorage).getDataValueAsInt(_dataPath);
    }
    if (_op == COMPARISON_OPERATOR.EQ) {
      return target == _value;
    } else if (_op == COMPARISON_OPERATOR.LT) {
      return target < _value;
    } else if (_op == COMPARISON_OPERATOR.GT) {
      return target > _value;
    } else if (_op == COMPARISON_OPERATOR.LTE) {
      return target <= _value;
    } else if (_op == COMPARISON_OPERATOR.GTE) {
      return target >= _value;
    } else if (_op == COMPARISON_OPERATOR.NEQ) {
      return target != _value;
    }
  }

  /**
   * @dev Resolves an expression where all the relevant parts of the expression are provided as parameters.
   * @param _dataStorage a DataStorage contract where the target data is located
   * @param _dataId an optional dataId which if supplied is then used to find a different DataStorage where the target data is located
   * @param _dataPath a dataPath where the target data is located
   * @param _op a valid comparison operator 
   * @param _value a bool value to use as right-hand value to compare against the target data
   * @return boolean result of the comparison
   */
  function resolveExpression(DataStorage _dataStorage, bytes32 _dataId, bytes32 _dataPath, COMPARISON_OPERATOR _op, bool _value)
    external view
    pre_onlySupportsEqualityOperations(_op)
    pre_verifyExpressionParametersExist(_dataStorage, _dataPath)
    returns (bool)
  {
    bool target;
    if (_dataId == "") {
      target = _dataStorage.getDataValueAsBool(_dataPath);
    } else {
      address subDataStorage = _dataStorage.getDataValueAsAddress(_dataId);
      ErrorsLib.revertIf(subDataStorage == address(0),
        ErrorsLib.INVALID_STATE(), "DataStorageUtils.resolveExpression", "Unable to locate DataStorage based on dataId parameter");
      target = DataStorage(subDataStorage).getDataValueAsBool(_dataPath);
    }
    if (_op == COMPARISON_OPERATOR.EQ) {
      return _value == target;
    } else if (_op == COMPARISON_OPERATOR.NEQ) {
      return _value != target;
    }
  }

}
