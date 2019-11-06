pragma solidity ^0.5;

import "commons-standards/ERC165.sol";

/**
 * @title ERC165Utils
 * @dev Library to facilitate the detection of ERC165 interfaces in contracts.
 * Based on example at: https://github.com/ethereum/EIPs/pull/881
 */
library ERC165Utils {

    /**
     * @dev Returns the invalid ID 0xffffffff
     */
    function getInvalidId() internal pure returns (bytes4) {
        return 0xffffffff;
    }

    /**
     * @dev Returns the ERC165 ID 0x01ffc9a7
     */
    function getERC165Id() internal pure returns (bytes4) {
        return 0x01ffc9a7;
    }

    /**
     * @dev Detects whether the given contract implements the specified ERC165 interface signature.
     * This is a modified implementation of the example in EIP 881 to avoid the use of the "staticcall" opcode. This function
     * performs two invocations:
     * 1. A "call" to the 0x01ffc9a7 function signature to test if it can be invoked
     * 2. If step 1 returns 'true', the contract is cast to ERC165 and the supportsInterface(bytes4) function is invoked
     * @param _contract the contract to be examined
     * @param _interfaceId the signature of the interface for which to test
     * @return true if the contract implements the interface, false otherwise
     */
    function implementsInterface(address _contract, bytes4 _interfaceId) public returns (bool) {
        (bool isERC165, ) = _contract.call(abi.encodeWithSelector(getERC165Id(), getERC165Id()));
        return isERC165 && ERC165(_contract).supportsInterface(_interfaceId);
    }

    // function implementsInterface(address _contract, bytes4 _interfaceId) public view returns (bool) {

    //     bytes4 invalidId = getInvalidId();
    //     bytes4 erc165Id = getERC165Id();

    //     uint256 success;
    //     uint256 result;
        
    //     (success, result) = noThrowCall(_contract, erc165Id);
    //     if ((success==0)||(result==0)) {
    //         return false;
    //     }

    //     (success, result) = noThrowCall(_contract, invalidId);
    //     if ((success==0)||(result!=0)) {
    //         return false;
    //     }

    //     (success, result) = noThrowCall(_contract, _interfaceId);
    //     if ((success==1)&&(result==1)) {
    //         return true;
    //     }
    //     return false;
    // }

    // function noThrowCall(address _contract, bytes4 _interfaceId) internal view returns (uint256 success, uint256 result) {

    //     bytes4 erc165Id = getERC165Id();

    //     assembly {
    //             let x := mload(0x40)               // Find empty storage location using "free memory pointer"
    //             mstore(x, erc165Id)                // Place signature at begining of empty storage
    //             mstore(add(x, 0x04), _interfaceId) // Place first argument directly next to signature

    //             success := call(
    //                                 30000,         // 30k gas
    //                                 0,             // 0 value transfered
    //                                 _contract,     // To addr
    //                                 x,             // Inputs are stored at location x
    //                                 0x20,          // Inputs are 32 bytes long
    //                                 x,             // Store output over input (saves space)
    //                                 0x20)          // Outputs are 32 bytes long

    //             result := mload(x)                 // Load the result
    //     }
    // }
}