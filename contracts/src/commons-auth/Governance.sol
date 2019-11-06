pragma solidity ^0.5;

import "commons-collections/Mappings.sol";
import "commons-collections/MappingsLib.sol";

/**
 * @title Governance library
 * @dev Data structures and internal functions supporting organizations, users, and their governance
 */

library Governance {

    struct Organization {
        bytes20 lei;
        bytes3 countryCode;
        bytes32 defaultDepartmentId;
        mapping(bytes32 => Department) departments;
        bytes32[] departmentKeys;
        bool exists;
    }

    struct Department {
        bytes32 id;
        Mappings.AddressBoolMap users;
        bool exists;
        uint keyIdx;
    }

    struct UserAccount {
        Mappings.AddressBoolMap ecosystems;
        bool exists;
    }

    function ERC165_ID_Organization() internal pure returns (bytes4) {
        return bytes4(keccak256(abi.encodePacked("addUser(address)"))) ^
               bytes4(keccak256(abi.encodePacked("removeUser(address)"))) ^
               bytes4(keccak256(abi.encodePacked("authorizeUser(address,bytes32)")));
    }

}