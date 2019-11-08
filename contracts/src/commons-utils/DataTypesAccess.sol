pragma solidity ^0.5;

import "commons-utils/DataTypes.sol";

/**
 * @title DataTypesAccess
 * @dev Exports the different data and parameter types in the DataTypes library as events in order to facilitate populating an external system with these values.
 */
contract DataTypesAccess {

    event LogDataType(
        bytes32 indexed eventId,
        uint dataType,
        string label
    );

    event LogParameterType(
        bytes32 indexed eventId,
        uint parameterType,
        string label
    );

    bytes32 public constant EVENT_ID_PARAMETER_TYPES = "AN://parameter-types";
    bytes32 public constant EVENT_ID_DATA_TYPES = "AN://data-types";

    constructor() public {
        // DataType events
        emit LogDataType("AN://data-types", DataTypes.BOOL(), "Boolean");
        emit LogDataType("AN://data-types", DataTypes.STRING(), "String");
        emit LogDataType("AN://data-types", DataTypes.UINT(), "Unsigned Integer");
        emit LogDataType("AN://data-types", DataTypes.UINT8(), "8-bit Unsigned Integer");
        emit LogDataType("AN://data-types", DataTypes.UINT16(), "16-bit Unsigned Integer");
        emit LogDataType("AN://data-types", DataTypes.UINT32(), "32-bit Unsigned Integer");
        emit LogDataType("AN://data-types", DataTypes.UINT64(), "64-bit Unsigned Integer");
        emit LogDataType("AN://data-types", DataTypes.UINT128(), "128-bit Unsigned Integer");
        emit LogDataType("AN://data-types", DataTypes.UINT256(), "256-bit Unsigned Integer");
        emit LogDataType("AN://data-types", DataTypes.INT(), "Signed Integer");
        emit LogDataType("AN://data-types", DataTypes.INT8(), "8-bit Signed Integer");
        emit LogDataType("AN://data-types", DataTypes.INT16(), "16-bit Signed Integer");
        emit LogDataType("AN://data-types", DataTypes.INT32(), "32-bit Signed Integer");
        emit LogDataType("AN://data-types", DataTypes.INT64(), "64-bit Signed Integer");
        emit LogDataType("AN://data-types", DataTypes.INT128(), "128-bit Signed Integer");
        emit LogDataType("AN://data-types", DataTypes.INT256(), "256-bit Signed Integer");
        emit LogDataType("AN://data-types", DataTypes.ADDRESS(), "Address");
        emit LogDataType("AN://data-types", DataTypes.BYTE(), "Byte");
        emit LogDataType("AN://data-types", DataTypes.BYTES1(), "1 Byte");
        emit LogDataType("AN://data-types", DataTypes.BYTES2(), "2 Bytes");
        emit LogDataType("AN://data-types", DataTypes.BYTES3(), "3 Bytes");
        emit LogDataType("AN://data-types", DataTypes.BYTES4(), "4 Bytes");
        emit LogDataType("AN://data-types", DataTypes.BYTES8(), "8 Bytes");
        emit LogDataType("AN://data-types", DataTypes.BYTES16(), "16 Bytes");
        emit LogDataType("AN://data-types", DataTypes.BYTES20(), "20 Bytes");
        emit LogDataType("AN://data-types", DataTypes.BYTES24(), "24 Bytes");
        emit LogDataType("AN://data-types", DataTypes.BYTES28(), "28 Bytes");
        emit LogDataType("AN://data-types", DataTypes.BYTES32(), "32 Bytes");
        emit LogDataType("AN://data-types", DataTypes.BYTES(), "Bytes");
        emit LogDataType("AN://data-types", DataTypes.BOOLARRAY(), "Array of Booleans");
        emit LogDataType("AN://data-types", DataTypes.STRINGARRAY(), "Array of Strings");
        emit LogDataType("AN://data-types", DataTypes.UINTARRAY(), "Array of Unsigned Integers");
        emit LogDataType("AN://data-types", DataTypes.UINT8ARRAY(), "Array of 8-bit Unsigned Integers");
        emit LogDataType("AN://data-types", DataTypes.UINT16ARRAY(), "Array of 16-bit Unsigned Integers");
        emit LogDataType("AN://data-types", DataTypes.UINT32ARRAY(), "Array of 32-bit Unsigned Integers");
        emit LogDataType("AN://data-types", DataTypes.UINT64ARRAY(), "Array of 64-bit Unsigned Integers");
        emit LogDataType("AN://data-types", DataTypes.UINT128ARRAY(), "Array of 128-bit Unsigned Integers");
        emit LogDataType("AN://data-types", DataTypes.UINT256ARRAY(), "Array of 256-bit Unsigned Integers");
        emit LogDataType("AN://data-types", DataTypes.INTARRAY(), "Array of Signed Integers");
        emit LogDataType("AN://data-types", DataTypes.INT8ARRAY(), "Array of 8-bit Signed Integers");
        emit LogDataType("AN://data-types", DataTypes.INT16ARRAY(), "Array of 16-bit Signed Integers");
        emit LogDataType("AN://data-types", DataTypes.INT32ARRAY(), "Array of 32-bit Signed Integers");
        emit LogDataType("AN://data-types", DataTypes.INT64ARRAY(), "Array of 64-bit Signed Integers");
        emit LogDataType("AN://data-types", DataTypes.INT128ARRAY(), "Array of 128-bit Signed Integers");
        emit LogDataType("AN://data-types", DataTypes.INT256ARRAY(), "Array of 256-bit Signed Integers");
        emit LogDataType("AN://data-types", DataTypes.ADDRESSARRAY(), "Array of Addresses");
        emit LogDataType("AN://data-types", DataTypes.BYTEARRAY(), "Array of single Bytes");
        emit LogDataType("AN://data-types", DataTypes.BYTES1ARRAY(), "Array of 1 Bytes");
        emit LogDataType("AN://data-types", DataTypes.BYTES2ARRAY(), "Array of 2 Bytes");
        emit LogDataType("AN://data-types", DataTypes.BYTES3ARRAY(), "Array of 3 Bytes");
        emit LogDataType("AN://data-types", DataTypes.BYTES4ARRAY(), "Array of 4 Bytes");
        emit LogDataType("AN://data-types", DataTypes.BYTES8ARRAY(), "Array of 8 Bytes");
        emit LogDataType("AN://data-types", DataTypes.BYTES16ARRAY(), "Array of 16 Bytes");
        emit LogDataType("AN://data-types", DataTypes.BYTES20ARRAY(), "Array of 20 Bytes");
        emit LogDataType("AN://data-types", DataTypes.BYTES24ARRAY(), "Array of 24 Bytes");
        emit LogDataType("AN://data-types", DataTypes.BYTES28ARRAY(), "Array of 28 Bytes");
        emit LogDataType("AN://data-types", DataTypes.BYTES32ARRAY(), "Array of 32 Bytes");
        emit LogDataType("AN://data-types", DataTypes.BYTESARRAY(), "Array of Bytes");
        // ParameterType events
        emit LogParameterType("AN://parameter-types", uint(DataTypes.ParameterType.BOOLEAN), "Boolean");
        emit LogParameterType("AN://parameter-types", uint(DataTypes.ParameterType.STRING), "String");
        emit LogParameterType("AN://parameter-types", uint(DataTypes.ParameterType.NUMBER), "Number");
        emit LogParameterType("AN://parameter-types", uint(DataTypes.ParameterType.DATE), "Date");
        emit LogParameterType("AN://parameter-types", uint(DataTypes.ParameterType.DATETIME), "Datetime");
        emit LogParameterType("AN://parameter-types", uint(DataTypes.ParameterType.MONETARY_AMOUNT), "Monetary Amount");
        emit LogParameterType("AN://parameter-types", uint(DataTypes.ParameterType.USER_ORGANIZATION), "User/Organization");
        emit LogParameterType("AN://parameter-types", uint(DataTypes.ParameterType.CONTRACT_ADDRESS), "Contract Address");
        emit LogParameterType("AN://parameter-types", uint(DataTypes.ParameterType.SIGNING_PARTY), "Signing Party");
        emit LogParameterType("AN://parameter-types", uint(DataTypes.ParameterType.BYTES32), "32-Byte Value");
        emit LogParameterType("AN://parameter-types", uint(DataTypes.ParameterType.DOCUMENT), "Document");
        emit LogParameterType("AN://parameter-types", uint(DataTypes.ParameterType.LARGE_TEXT), "Large Text");
        emit LogParameterType("AN://parameter-types", uint(DataTypes.ParameterType.POSITIVE_NUMBER), "Positive Number");
        emit LogParameterType("AN://parameter-types", uint(DataTypes.ParameterType.DURATION), "Time Duration");
        emit LogParameterType("AN://parameter-types", uint(DataTypes.ParameterType.CYCLE), "Time Cycle");
    }

}