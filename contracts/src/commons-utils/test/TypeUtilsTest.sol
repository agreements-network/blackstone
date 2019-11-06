pragma solidity ^0.5;

import "commons-utils/TypeUtilsLib.sol";

contract TypeUtilsTest {

	using TypeUtilsLib for uint;
	using TypeUtilsLib for int;
	using TypeUtilsLib for bytes32;
	using TypeUtilsLib for string;
	using TypeUtilsLib for address;
	using TypeUtilsLib for bytes;

	function testLengthBytes32() external pure returns (string memory) {
		bytes32 b = "Hello World";
		if (b.contentLength() != 11) { return "Length of 'Hello World' bytes32 should be 11"; }
		b = "  apple!";
		if (b.contentLength() != 8) { return "Length of '  apple!' bytes32 should be 8"; }
		b = "000one000";
		if (b.contentLength() != 9) { return "Length of '000one000' bytes32 should be 9"; }
		b = "";
		if (b.contentLength() != 0) { return "Length of empty bytes32 variable should be 0"; }
		if (TypeUtilsLib.contentLength("") != 0) { return "Length of empty bytes32 literal should be 0"; }

		return "success";
	}

    function testUintToBytes32() external pure returns (string memory) {
    	uint v = 99;
        if (v.toBytes32() != "99") { return "Converting uint 99 to bytes32 failed."; }
    	v = 0;
        if (v.toBytes32() != "0") { return "Converting uint 0 to bytes32 failed."; }
    	v = 69238422394;
        if (v.toBytes32() != "69238422394") { return "Converting uint 69238422394 to bytes32 failed."; }
        
        return "success";
    }
    
    function testIsEmpty() external pure returns (string memory) {
    	
    	bytes32 b32val1 = "";
    	bytes32 b32val2 = "bla";
    	bytes32 b32val3 = "0";
    	
    	if (b32val1.isEmpty() == false) return "Empty bytes32 val1 not detected.";
    	if (b32val2.isEmpty() == true) return "bytes32 val2 has content.";
    	if (b32val3.isEmpty() == true) return "bytes32 val3 has content.";
    	
    	return "success";
    }

	function testBytes32ToString() external pure returns (string memory) {
		bytes32 input = "Rumpelstiltskin";
		string memory expectedResult = "Rumpelstiltskin";
		if (keccak256(abi.encodePacked(input.toString())) != keccak256(abi.encodePacked(expectedResult)))
			return "The converted input bytes32 should match the expected result string";
		return "success";
	}

	function testStringToBytes32() external pure returns (string memory) {
		string memory s = "blabla";
		if (s.toBytes32() != "blabla") { return "Converting string 'blabla' to bytes32 failed."; }
		s = "123 Pelham 100%";
		if (s.toBytes32() != "123 Pelham 100%") { return "Converting string '123 Pelham 100%' to bytes32 failed."; }
		s = "  blanks and underscores __";
		if (s.toBytes32() != "  blanks and underscores __") { return "Converting string '  blanks and underscores __' to bytes32 failed."; }
		s = "This text is longer then 32 ASCII characters and should be cut off.";
		if (s.toBytes32() != "This text is longer then 32 ASCI") { return "Converting string longer then 32 chars to bytes32 failed."; }
		
		return "success";
	}

	function testBytesToBytes32() external pure returns (string memory) {
		bytes memory b = "blabla";
		if (b.toBytes32() != "blabla") { return "Converting bytes 'blabla' to bytes32 failed."; }
		b = "123 Pelham 100%";
		if (b.toBytes32() != "123 Pelham 100%") { return "Converting bytes '123 Pelham 100%' to bytes32 failed."; }
		b = "  blanks and underscores __";
		if (b.toBytes32() != "  blanks and underscores __") { return "Converting bytes '  blanks and underscores __' to bytes32 failed."; }
		b = "This text is longer then 32 ASCII characters and should be cut off.";
		if (b.toBytes32() != "This text is longer then 32 ASCI") { return "Converting bytes longer then 32 chars to bytes32 failed."; }
		
		return "success";
	}

	function testBytesToUint() external pure returns (string memory) {
		uint number = 928349;
		bytes memory b = abi.encode(number);
		if (b.toUint() != number) { return "Converting bytes to number should return same value"; }
		
		return "success";
	}
}