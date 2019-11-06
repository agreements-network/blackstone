pragma solidity ^0.5;

import "commons-base/BaseErrors.sol";
import "commons-utils/DataTypes.sol";

import "commons-collections/DataStorage.sol";
import "commons-collections/FullDataStorage.sol";
import "commons-collections/AbstractAddressScopes.sol";
import "commons-collections/DataStorageUtils.sol";

contract DataStorageTest {
	
	string SUCCESS = "success";
	bytes32 EMPTY = "";
	
	// Storage contracts used in tests
	FullDataStorage myStorage;
	FullDataStorage mySubDataStorage;

	// storage arrays used in tests
	address[] addressArr;
	uint[] u256Arr;
	int[] i256Arr;
	bytes32[] dcSuperheroes;

	uint8 num = 200;
	address addr = 0x64A6b18404251B0C8E88b0D8FbDE7145C72aFC75;

	bool myCoolBool = true;
	bytes32 boolId = "myCoolBool";
	bytes32 numId = "twoHundred";
	bytes32 addrId = "myAddr";
	bytes32 myValId = "letter1";
	bytes32 my16bValId = "someId";
	bytes32 addressArrId = "addressArrId";
	bytes32 u256ArrId = "uint256ArrId";
	bytes32 i256ArrId = "int256ArrId";
	bytes32 bytesArrayId = "DCSuperheroes";
	
	bytes1 myVal = "a";
	bytes16 my16bVal = "abcd1234";
	bytes32 batman = "batman";
	bytes32 superman = "superman";
	bytes32 wonderwoman = "wonderwoman";

	bytes32 num10 = "num10";
	uint tenVal = 10;
	bytes32 trueVal = "trueVal";
	bool truthy = true;
	bytes32 marmot = "marmot";
	string marmotName = "toby";
	string antman = "antman";
	bytes32 subStorageId = "substorage";
	bytes32 compAddrId = "comparableAddr";
	address compAddr = 0x94EcB18404251B0C8E88B0D8fbde7145c72AEC22;
	
	uint error;

	function testPrimitivesDataStorageAndRetrieval() external returns (string memory) {
		
		myStorage = new TestDataStorage();

		// bool
		myStorage.setDataValueAsBool(boolId, myCoolBool);
		if (myStorage.getDataType(boolId) != DataTypes.BOOL()) return "bool Data object dataType is not DataTypes.BOOL()";
		if (!myStorage.getDataValueAsBool(boolId)) return "bool value should have been true";

		// uint8
		myStorage.setDataValueAsUintType(numId, num, DataTypes.UINT8());
		if (myStorage.getDataType(numId) != DataTypes.UINT8()) return "uint8 Data object dataType is not DataTypes.UINT8()";
		if (myStorage.getDataValueAsUint(numId) != num) return "uint8 value should have been 200";

		// uint
		numId = "twoHundred2";
		myStorage.setDataValueAsUint(numId, num);
		if (myStorage.getDataType(numId) != DataTypes.UINT256()) return "unspecified uint size should be saved as DataTypes.UINT256()";
		if (myStorage.getDataValueAsUint(numId) != num) return "uint8 value should have been 200";

		// address
		myStorage.setDataValueAsAddress(addrId, addr);
		if (myStorage.getDataType(addrId) != DataTypes.ADDRESS()) return "address Data object dataType is not DataTypes.ADDRESS()";
		if (myStorage.getDataValueAsAddress(addrId) != addr) return "address value does not match saved address";

		// bytes32
		myStorage.setDataValueAsBytes32(myValId, myVal);
		if (myStorage.getDataType(myValId) != DataTypes.BYTES32()) return "bytes1 Data object with unspecifiec dataType should be of type DataTypes.BYTES32()";
		if (myStorage.getDataValueAsBytes32(myValId) != myVal) return "output value does not match saved bytes1";

		// bytes16
		myStorage.setDataValueAsBytes32Type(my16bValId, my16bVal, DataTypes.BYTES16());
		if (myStorage.getDataType(my16bValId) != DataTypes.BYTES16()) return "bytes16 Data object should have type DataTypes.BYTES16()";
		if (myStorage.getDataValueAsBytes32(my16bValId) != my16bVal) return "output value does not match saved bytes16";
		
		return SUCCESS;
	}

	function testArraysDataStorageAndRetrieval() external returns (string memory) {

		myStorage = new TestDataStorage();

		// address[]
		delete addressArr;
		addressArr.push(0xd23B9DC1f8DFc5C722243b19dA46F9174e9409Ab);
		addressArr.push(0x34266B66E9D8627213a2129Bb7c305DfC1Db8e04);
		addressArr.push(0xdFcf0C7a89BF918F388F2D00f7D45f8C5aFB80f9);

		myStorage.setDataValueAsAddressArray(addressArrId, addressArr);
		address[] memory retAddressArr = myStorage.getDataValueAsAddressArray(addressArrId);
		if (myStorage.getDataType(addressArrId) != DataTypes.ADDRESSARRAY()) return "address[] datatype is not DataTypes.ADDRESSARRAY()";
		if (retAddressArr.length != addressArr.length) return "Returned address array length should match input array length";
		if (retAddressArr[2] != addressArr[2]) return "address[] value at index 2 does not match original";

		// uint256[]
		delete u256Arr;
		u256Arr.push(16);
		u256Arr.push(64);
		u256Arr.push(255);
		myStorage.setDataValueAsUintArray(u256ArrId, u256Arr);
		uint[] memory retU256Arr = myStorage.getDataValueAsUintArray(u256ArrId);
		if (myStorage.getDataType(u256ArrId) != DataTypes.UINT256ARRAY()) return "uint256[] datatype is not DataTypes.UINT256ARRAY()";
		if (retU256Arr.length != u256Arr.length) return "Returned uint256 array length should match input array length";
		if (retU256Arr[2] != u256Arr[2]) return "uint256[] value at index 2 does not match original";

		// int256[]
		delete i256Arr;
		i256Arr.push(16);
		i256Arr.push(64);
		i256Arr.push(255);
		myStorage.setDataValueAsIntArray(i256ArrId, i256Arr);
		int[] memory retI256Arr = myStorage.getDataValueAsIntArray(i256ArrId);
		if (myStorage.getDataType(i256ArrId) != DataTypes.INT256ARRAY()) return "int256[] datatype is not DataTypes.INT256ARRAY()";
		if (retI256Arr.length != i256Arr.length) return "Returned int256 array length should match input array length";
		if (retI256Arr[2] != i256Arr[2]) return "int256[] value at index 2 does not match original";

		// bytes32[]
		delete dcSuperheroes;
		dcSuperheroes.push(batman);
		dcSuperheroes.push(superman);
		dcSuperheroes.push(wonderwoman);
		myStorage.setDataValueAsBytes32Array(bytesArrayId, dcSuperheroes);
		bytes32[] memory heroes = myStorage.getDataValueAsBytes32Array(bytesArrayId);
		if (myStorage.getDataType(bytesArrayId) != DataTypes.BYTES32ARRAY()) return "bytes32[] datatype is not DataTypes.BYTES32ARRAY()";
		if (heroes.length != dcSuperheroes.length) return "Returned bytes32 array length should match input array length";
		if (heroes[2] != dcSuperheroes[2]) return "bytes32[] value at index 2 does not match original";

		return SUCCESS;
	}

	function testDataRemoval () external returns (string memory) {

		myStorage = new TestDataStorage();
		delete u256Arr;
		u256Arr.push(3);
		u256Arr.push(55);
		u256Arr.push(237);
		u256Arr.push(88);
	
		myStorage.setDataValueAsAddress("key1", address(this));
		myStorage.setDataValueAsBool("key2", true);
		myStorage.setDataValueAsBytes32("key3", "bla");
		myStorage.setDataValueAsUintArray(i256ArrId, u256Arr);

		if (myStorage.getNumberOfData() != 4) return "pre-removal storage size should be 4";
		
		myStorage.removeData(i256ArrId);
		uint[] memory retUintArray = myStorage.getDataValueAsUintArray(i256ArrId);
		if (retUintArray.length > 0) return "Returned array should be empty due to entry having been deleted";
		
		if (myStorage.getNumberOfData() != 3) return "post-removal storage size should be 9";
		
		myStorage.removeData("fakeKeyTTTT");
		if (myStorage.getNumberOfData() != 3) return "Storage size should not have changed when deleting non-existent entry";

		return SUCCESS;
	}

	function testDataComparison() external returns (string memory) {

		myStorage = new TestDataStorage();
		mySubDataStorage = new TestDataStorage();
		bool result;

		myStorage.setDataValueAsAddress(subStorageId, address(mySubDataStorage));
		
		// compare uints
		myStorage.setDataValueAsUint(num10, tenVal);
		mySubDataStorage.setDataValueAsUint("num2000", uint(2000));
		result = DataStorageUtils.resolveExpression(myStorage, EMPTY, num10, DataStorageUtils.COMPARISON_OPERATOR.EQ, tenVal);
		if (result != true) return "Expected 10 == 10 to be true";

		result = DataStorageUtils.resolveExpression(myStorage, EMPTY, num10, DataStorageUtils.COMPARISON_OPERATOR.NEQ, uint(12));
		if (result != true) return "Expected 10 != 12 to be true";

		result = DataStorageUtils.resolveExpression(myStorage, EMPTY, num10, DataStorageUtils.COMPARISON_OPERATOR.LT, uint(12));
		if (result != true) return "Expected 10 < 12 to be true";

		result = DataStorageUtils.resolveExpression(myStorage, EMPTY, num10, DataStorageUtils.COMPARISON_OPERATOR.GT, uint(12));
		if (result != false) return "Expected 10 > 12 to be false";

		// uint in substorage
		result = DataStorageUtils.resolveExpression(myStorage, subStorageId, "num2000", DataStorageUtils.COMPARISON_OPERATOR.GTE, uint(2000));
		if (result != true) return "Expected 2000 >= 2000 to be true";

		result = DataStorageUtils.resolveExpression(myStorage, subStorageId, "num2000", DataStorageUtils.COMPARISON_OPERATOR.GTE, uint(2001));
		if (result != false) return "Expected 2000 >= 2001 to be false";

		// compare bools
		myStorage.setDataValueAsBool(trueVal, truthy);
		result = DataStorageUtils.resolveExpression(myStorage, EMPTY, trueVal, DataStorageUtils.COMPARISON_OPERATOR.EQ, true);
		if (result != true) return "Expected truthy to be true";

		// compare bytes32
		myStorage.setDataValueAsBytes32(batman, batman);
		result = DataStorageUtils.resolveExpression(myStorage, EMPTY, batman, DataStorageUtils.COMPARISON_OPERATOR.EQ, superman);
		if (result != false) return "Expected batman == superman to be false";

		result = DataStorageUtils.resolveExpression(myStorage, EMPTY, batman, DataStorageUtils.COMPARISON_OPERATOR.EQ, bytes32("batman"));
		if (result != true) return "Expected batman == batman to be true";

		// compare string
		myStorage.setDataValueAsString(marmot, marmotName);
		result = DataStorageUtils.resolveExpression(myStorage, EMPTY, marmot, DataStorageUtils.COMPARISON_OPERATOR.EQ, antman);
		if (result != false) return "Expected toby == antman to be false";

		result = DataStorageUtils.resolveExpression(myStorage, EMPTY, marmot, DataStorageUtils.COMPARISON_OPERATOR.NEQ, marmotName);
		if (result != false) return "Expected toby != toby to be false";

		// compare address
		myStorage.setDataValueAsAddress(compAddrId, compAddr);
		result = DataStorageUtils.resolveExpression(myStorage, EMPTY, compAddrId, DataStorageUtils.COMPARISON_OPERATOR.EQ, addr);
		if (result != false) return "Expected compAddr == addr to be false";

		result = DataStorageUtils.resolveExpression(myStorage, EMPTY, compAddrId, DataStorageUtils.COMPARISON_OPERATOR.NEQ, compAddr);
		if (result != false) return "Expected compAddr != compAddr to be false";

		// compare uint in substorage
		mySubDataStorage.setDataValueAsUintType(num10, 10, DataTypes.UINT256());
		result = DataStorageUtils.resolveExpression(myStorage, subStorageId, num10, DataStorageUtils.COMPARISON_OPERATOR.EQ, tenVal);
		if (result != true) return "Expected 10 == 10 to be true in substorage";

		return SUCCESS;
	}

	/**
	 * @dev Tests functions specific to AddressScopes
	 */
	function testAddressScopedDataStorage() external returns (string memory) {

		ScopedStorage testStorage = new ScopedStorage();

		testStorage.setDataValueAsAddress("Buyer", address(this));
		testStorage.setDataValueAsAddress("Seller", msg.sender);
		bool success;
		(success, ) = address(testStorage).call(abi.encodeWithSignature("setAddressScope(address,bytes32,bytes32,bytes32,bytes32,address)", address(0), "context1", "Scope1", EMPTY, EMPTY, address(0)));
		if (success)
			return "Setting a scope on an empty address should revert";
		(success, ) = address(testStorage).call(abi.encodeWithSignature("setAddressScope(address,bytes32,bytes32,bytes32,bytes32,address)", address(this), EMPTY, EMPTY, EMPTY, EMPTY, address(0)));
		if (success)
			return "Setting a scope with no fixed or conditional scope information should revert";

		testStorage.setAddressScope(address(this), EMPTY, "testScope", EMPTY, EMPTY, address(0));
		testStorage.setDataValueAsBytes32("ConditionalScope", "senderScope");
		// set the second scope twice to test overwriting and length expectations
		testStorage.setAddressScope(msg.sender, "context1", EMPTY, "fakeCondition", EMPTY, address(0));
		testStorage.setAddressScope(msg.sender, "context1", EMPTY, "ConditionalScope", EMPTY, address(0));

		if (testStorage.resolveAddressScope(address(this), EMPTY, DataStorage(address(0))) != "testScope") return "Scope for address(this)/EMPTY not resolved correctly";
		(success, ) = address(testStorage).call(abi.encodeWithSignature("resolveAddressScope(address,bytes32,DataStorage)", msg.sender, "context1", DataStorage(address(0))));
		if (success)
			return "Retrieving a scope defined by ConditionalData should revert if no DataStorage is passed";
		if (testStorage.resolveAddressScope(msg.sender, "context1", testStorage) != "senderScope") return "Scope for msg.sender/context1 not resolved correctly";
		bytes32 fixedScope;
		bytes32 dataPath;
		bytes32 dataStorageId;
		address dataStorage;
		(fixedScope, dataPath, dataStorageId, dataStorage) = testStorage.getAddressScopeDetails(address(this), EMPTY);
		if (fixedScope != "testScope") return "fixedScope via scope details for address(this)/EMPTY not returned correctly";
		(fixedScope, dataPath, dataStorageId, dataStorage) = testStorage.getAddressScopeDetails(msg.sender, "context1");
		if (fixedScope != "") return "fixedScope via scope details for msg.sender/context1 not returned correctly";
		if (dataPath != "ConditionalScope") return "dataPath via scope details for msg.sender/context1 not returned correctly";
		if (dataStorageId != "") return "dataStorageId via scope details for msg.sender/context1 not returned correctly";
		if (dataStorage != address(0)) return "dataStorage via scope details for msg.sender/context1 not returned correctly";

		return SUCCESS;
	}

}


contract TestDataStorage is FullDataStorage {

}

contract ScopedStorage is AbstractDataStorage, AbstractAddressScopes {

}