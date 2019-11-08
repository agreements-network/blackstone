pragma solidity ^0.5;

import "commons-utils/TypeUtilsLib.sol";

import "commons-auth/UserAccount.sol";
import "commons-auth/DefaultUserAccount.sol";

contract UserAccountTest {

	using TypeUtilsLib for bytes;

	string constant SUCCESS = "success";
	string constant functionSigForwardCall = "forwardCall(address,bytes)";
	string constant functionSigServiceInvocation = "serviceInvocation(address,uint256,bytes32)";

	string longString = "longString";
    bytes1[] tempByteArray;

	/**
	 * @dev Tests the UserAccount call forwarding logic
	 */
	function testCallForwarding() external returns (string memory) {

        bool success;
		uint testState = 42;
		bytes32 testKey = "myKey";
		TestService testService = new TestService();

		UserAccount account = new DefaultUserAccount();
		account.initialize(address(this), address(0));
		UserAccount externalAccount = new DefaultUserAccount();
		externalAccount.initialize(msg.sender, address(0));

		bytes memory payload;
		payload = abi.encodeWithSignature("fakeFunction(bytes32)", testState);
		(success, ) = address(account).call(abi.encodeWithSignature(functionSigForwardCall, address(testService), payload));
		if (success)
			return "Forwarding a call to a non-existent function should revert";

		payload = abi.encodeWithSignature(functionSigServiceInvocation, address(this), testState, testKey);
		// first test that the correct signature is working
		(success, ) = address(account).call(abi.encodeWithSignature(functionSigForwardCall, address(testService), payload));
		if (!success)
			return "Forwarding a call to the valid function signature should not revert";

		// test failures
		(success, ) = address(account).call(abi.encodeWithSignature(functionSigForwardCall, address(0), payload));
		if (success)
			return "Forwarding a call to an empty address should revert";
		// unauthorized accounts (not owner)
		(success, ) = address(externalAccount).call(abi.encodeWithSignature(functionSigForwardCall, address(testService), payload));
		if (success)
			return "Forwarding a call from an unauthorized address should fail";

		// test successful invocation
		bytes memory returnData;
		returnData = account.forwardCall(address(testService), payload);
		if (testService.currentEntity() != address(this)) return "The testService should show this address as the current entity";
		if (testService.currentState() != testState) return "The testService should have the testState set";
		if (testService.currentKey() != testKey) return "The testService should have the testKey set";
		if (testService.lastCaller() != address(account)) return "The testService should show the UserAccount as the last caller";
		if (returnData.length != 32) return "ReturnData should be of size 32";
		// TODO ability to decode return data via abi requires 0.5.0.
		// (bytes32 returnMessage) = abi.decode(returnData,(bytes32));
		if (returnData.toBytes32() != testService.getSuccessMessage()) return "The function return data should match the service success message";

		// test different input/return data
		payload = abi.encodeWithSignature("isStringLonger5(string)", longString);
		returnData = account.forwardCall(address(testService), payload);
		if (uint8(returnData[31]) != uint8(1)) return "isStringLonger5 should return true for longString"; // boolean is left-padded, so the value is at the end of the bytes

		// test revert reason return
		payload = abi.encodeWithSignature("invokeRevert()");
		(success, ) = address(account).call(abi.encodeWithSignature(functionSigForwardCall, address(testService), payload));
		if (success)
			return "A revert from a forwarded function call should propagate as revert";

        uint returnSize;
		address target = address(account);
		bytes memory data = abi.encodeWithSignature(functionSigForwardCall, address(testService), payload);
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
        bytes memory expectedReason = "UserAccountTest::error";
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
            return "The return data from invoking the revert function via forwardCall should contain the error reason from the TestService";

		return SUCCESS;
	}

}

/**
 * @dev Contract providing a typical service function to use as target for call forwarding.
 */
contract TestService {

	address public currentEntity;
	uint public currentState;
	bytes32 public currentKey;
	address public lastCaller;

	function serviceInvocation(address _entity, uint _newState, bytes32 _key) public returns (bytes32) {

		currentEntity = _entity;
		currentState = _newState;
		currentKey = _key;
		lastCaller = msg.sender;
		return "congrats";
	}

	function isStringLonger5(string memory _string) public pure returns (bool) {
		if (bytes(_string).length > 5)
			return true;
		else
			return false;
	} 

	function getSuccessMessage() public pure returns (bytes32) {
		return "congrats";	
	}

	function invokeRevert() public pure {
		revert("UserAccountTest::error");
	}
}