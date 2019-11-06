pragma solidity ^0.5;

import "commons-utils/TypeUtilsLib.sol";
import "commons-management/AbstractDelegateProxy.sol";

contract DelegateProxyTest {

    using TypeUtilsLib for uint;
    using TypeUtilsLib for bytes32;

    string constant SUCCESS = "success";
    bytes1[] tempByteArray;

    function testDelegateCallReturns() external returns (string memory) {

        TestDelegate delegate = new TestDelegate();
        TestProxy proxy = new TestProxy(address(delegate));
        
        if (proxy.getDelegate() != address(delegate)) return "The delegate should be set in the proxy";
        string memory result = TestDelegate(address(proxy)).regularFunction();
        if (keccak256(abi.encodePacked(result)) != keccak256(abi.encodePacked("message"))) return "Proxy invocation of regularFunction should have returned the message";
        
        // check that the revert reason from the inner delegate function is returned as the proxy's revert reason
        bytes memory data = abi.encodeWithSignature("revertFunction()");
        address target = address(proxy);
        bytes memory returnData;
        bool success;
        uint returnSize;
        assembly {
            let freeMemSlot := mload(0x40)
            success := call(gas, target, 0, add(data, 0x20), mload(data), freeMemSlot, 0)
            returnSize := returndatasize
        }
        returnData = new bytes(returnSize);
        assembly {
            returndatacopy(add(returnData, 0x20), 0, returnSize)
        }

        if (returnData.length < 32) return "The data returned from invoking the revert function should be at least 32 bytes long";
        bytes memory expectedReason = "TestDelegate::error";
        delete tempByteArray;

        // There currently is no elegant way to decode the returned bytes of a revert. The bytes being received have the following structure:
        // 0x08c379a0                                                         // Function selector for Error(string)
        // 0x0000000000000000000000000000000000000000000000000000000000000020 // Data offset
        // 0x000000000000000000000000000000000000000000000000000000000000001a // String length
        // 0x4e6f7420656e6f7567682045746865722070726f76696465642e000000000000 // String data

        // Since we know that the expected revert reason fits into 32 bytes, we can simply grab those last 32 bytes
        uint i;
        for (i=returnData.length-32; i<returnData.length; i++) {
            if (uint256(uint8(returnData[i])) != 0) {
                tempByteArray.push(returnData[i]);
            }
        }
        bytes memory trimmedBytes = new bytes(tempByteArray.length);
        for (i=0; i<tempByteArray.length; i++) {
            trimmedBytes[i] = tempByteArray[i];
        }

        if (keccak256(abi.encodePacked(trimmedBytes)) != keccak256(abi.encodePacked(expectedReason)))
            return "The return data from invoking the revert function should contain the error reason from the TargetDelegate";

        return SUCCESS;
    }

}

contract TestProxy is AbstractDelegateProxy {

    address delegate;

    constructor(address _delegate) public {
        delegate = _delegate;
    }

    function getDelegate() public view returns (address) {
        return delegate;
    }
}

contract TestDelegate {

    function regularFunction() public pure returns (string memory) {
        return "message";
    }

    function revertFunction() public pure {
        revert("TestDelegate::error");
    }
}


