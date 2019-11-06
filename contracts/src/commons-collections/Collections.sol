pragma solidity ^0.5;

/**
 * @title Collections library
 * @dev Data structures and internal functions supporting address scopes
 */

library Collections {
    function ERC165_ID_Address_Scopes() internal pure returns (bytes4) {
        return bytes4(keccak256(abi.encodePacked("setAddressScope(address,bytes32,bytes32,bytes32,bytes32,address)"))) ^
               bytes4(keccak256(abi.encodePacked("resolveAddressScope(address,bytes32,address)"))) ^
               bytes4(keccak256(abi.encodePacked("getAddressScopeDetails(address,bytes32)"))) ^
               bytes4(keccak256(abi.encodePacked("getAddressScopeDetailsForKey(bytes32)"))) ^
               bytes4(keccak256(abi.encodePacked("getAddressScopeKeys()")));
    }
}
