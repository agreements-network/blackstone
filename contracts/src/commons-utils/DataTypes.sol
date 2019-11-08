pragma solidity ^0.5;

/**
 * @title DataTypes Library
 * @dev A library distinguishing all available Solidity data types and providing an enumeration of human-readable parameter types.
 */
library DataTypes {

  enum ParameterType {BOOLEAN, STRING, NUMBER, DATE, DATETIME, MONETARY_AMOUNT, USER_ORGANIZATION, CONTRACT_ADDRESS, SIGNING_PARTY, BYTES32, DOCUMENT, LARGE_TEXT, POSITIVE_NUMBER, DURATION, CYCLE}
  
  // ************************* BOOL ********************************
  // Values: 1
  function BOOL() internal pure returns (uint8) { return 1; }


  // ************************ STRING ********************************
  // Values: 2
  function STRING() internal pure returns (uint8) { return 2; }

  
  // ************************* UINT *********************************
  // Values: 3 - 8
  function UINT() internal pure returns (uint8) { return UINT256(); }
  function UINT8() internal pure returns (uint8) { return 3; }
  function UINT16() internal pure returns (uint8) { return 4; }
  function UINT32() internal pure returns (uint8) { return 5; }
  function UINT64() internal pure returns (uint8) { return 6; }
  function UINT128() internal pure returns (uint8) { return 7; }
  function UINT256() internal pure returns (uint8) { return 8; }


  // *************************** INT *********************************
  // Values: 13 - 18
  function INT() internal pure returns (uint8) { return INT256(); }
  function INT8() internal pure returns (uint8) { return 13; }
  function INT16() internal pure returns (uint8) { return 14; }
  function INT32() internal pure returns (uint8) { return 15; }
  function INT64() internal pure returns (uint8) { return 16; }
  function INT128() internal pure returns (uint8) { return 17; }
  function INT256() internal pure returns (uint8) { return 18; }

  
  // ************************ ADDRESS *******************************
  // Values: 40
  function ADDRESS() internal pure returns (uint8) { return 40; }


  // ************************* BYTES ********************************
  // Values: 50 - 60
  function BYTE() internal pure returns (uint8) { return BYTES1(); }
  function BYTES1() internal pure returns (uint8) { return 50; }
  function BYTES2() internal pure returns (uint8) { return 51; }
  function BYTES3() internal pure returns (uint8) { return 52; }
  function BYTES4() internal pure returns (uint8) { return 53; }
  function BYTES8() internal pure returns (uint8) { return 54; }
  function BYTES16() internal pure returns (uint8) { return 55; }
  function BYTES20() internal pure returns (uint8) { return 56; }
  function BYTES24() internal pure returns (uint8) { return 57; }
  function BYTES28() internal pure returns (uint8) { return 58; }
  function BYTES32() internal pure returns (uint8) { return 59; }
  function BYTES() internal pure returns (uint8) { return 60; }

  // ************************* ARRAYS ********************************
  
  // Values: 101 - 102
  function BOOLARRAY() internal pure returns (uint8) { return 101; }
  function STRINGARRAY() internal pure returns (uint8) { return 102; }

  // Values 103 - 108 
  function UINTARRAY() internal pure returns (uint8) { return UINT256ARRAY(); }
  function UINT8ARRAY() internal pure returns (uint8) { return 103; }
  function UINT16ARRAY() internal pure returns (uint8) { return 104; }
  function UINT32ARRAY() internal pure returns (uint8) { return 105; }
  function UINT64ARRAY() internal pure returns (uint8) { return 106; }
  function UINT128ARRAY() internal pure returns (uint8) { return 107; }
  function UINT256ARRAY() internal pure returns (uint8) { return 108; }

  // Values: 113 - 118
  function INTARRAY() internal pure returns (uint8) { return INT256ARRAY(); }
  function INT8ARRAY() internal pure returns (uint8) { return 113; }
  function INT16ARRAY() internal pure returns (uint8) { return 114; }
  function INT32ARRAY() internal pure returns (uint8) { return 115; }
  function INT64ARRAY() internal pure returns (uint8) { return 116; }
  function INT128ARRAY() internal pure returns (uint8) { return 117; }
  function INT256ARRAY() internal pure returns (uint8) { return 118; }
  
  // Values: 140
  function ADDRESSARRAY() internal pure returns (uint8) { return 140; }
  
  // Values: 150 - 160
  function BYTEARRAY() internal pure returns (uint8) { return BYTES1ARRAY(); }
  function BYTES1ARRAY() internal pure returns (uint8) { return 150; }
  function BYTES2ARRAY() internal pure returns (uint8) { return 151; }
  function BYTES3ARRAY() internal pure returns (uint8) { return 152; }
  function BYTES4ARRAY() internal pure returns (uint8) { return 153; }
  function BYTES8ARRAY() internal pure returns (uint8) { return 154; }
  function BYTES16ARRAY() internal pure returns (uint8) { return 155; }
  function BYTES20ARRAY() internal pure returns (uint8) { return 156; }
  function BYTES24ARRAY() internal pure returns (uint8) { return 157; }
  function BYTES28ARRAY() internal pure returns (uint8) { return 158; }
  function BYTES32ARRAY() internal pure returns (uint8) { return 159; }
  function BYTESARRAY() internal pure returns (uint8) { return 160; }
  

  /**
    * @dev Checks if given dataType is valid
    * @param _dataType uint8 dataType
    * @return bool representing validity
    */
  function isValid(uint8 _dataType) internal pure returns (bool) {
    if ((_dataType < 1) ||
        (_dataType >= 9 && _dataType <= 12) ||
        (_dataType >= 19 && _dataType <= 39) ||
        (_dataType >= 41 && _dataType <= 49) ||
        (_dataType >= 61 && _dataType <= 100) ||
        (_dataType >= 109 && _dataType <= 112) ||
        (_dataType >= 119 && _dataType <= 139) ||
        (_dataType >= 141 && _dataType <= 149) ||
        (_dataType >= 161)) {
          return false;
        }
     return true;
  }

}
