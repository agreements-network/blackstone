pragma solidity ^0.5;

import "commons-utils/ArrayUtilsLib.sol";

contract ArrayUtilsTest {

	using ArrayUtilsLib for bytes32[];
	using ArrayUtilsLib for address[];
	using ArrayUtilsLib for uint[];
	using ArrayUtilsLib for int[];

	string constant SUCCESS = "success";

	bytes32[] b32Values;
	address[] addrValues;
	uint[] uintValues;
	int[] intValues;

	/**
	 * @dev Tests the contains() functions
	 */
	function testContains() external returns (string memory) {

		delete b32Values;
		b32Values.push("1");
		b32Values.push("2");
		b32Values.push("3");
		if (!b32Values.contains("2")) { return "Contains b32 failed for value 2"; }
		if (b32Values.contains("987sdf")) { return "Contains b32 wrongly detected non-existing value"; }

		delete addrValues;
		addrValues.push(msg.sender);
		addrValues.push(address(this));
		addrValues.push(0xD97E471695f73d8186dEABc1AB5B8765e667Cd96);
		if (!addrValues.contains(address(this))) { return "Contains addr failed for value 2"; }
		if (addrValues.contains(0xC1F1E51bf3d02021247dEbFfc191c67aA27058c1)) { return "Contains addr wrongly detected non-existing value"; }

		delete uintValues;
		uintValues.push(99);
		uintValues.push(2934);
		uintValues.push(7878773);
		if (!uintValues.contains(7878773)) { return "Contains uint failed for value 3"; }
		if (uintValues.contains(99999)) { return "Contains uint wrongly detected non-existing value"; }

		delete intValues;
		intValues.push(23);
		intValues.push(-2388393);
		intValues.push(-1287);
		if (!intValues.contains(-1287)) { return "Contains uint failed for value 3"; }
		if (intValues.contains(-99999)) { return "Contains uint wrongly detected non-existing value"; }

		return SUCCESS;
	}

	/**
	 * @dev Tests the hasDuplicates() functions
	 */
	function testHasDuplicates() external returns (string memory) {

		delete b32Values;
		b32Values.push("bla");
		b32Values.push("blubb");
		b32Values.push("nosejob");
		if (b32Values.hasDuplicates()) { return "hasDuplicates b32 should not have duplicates"; }
		b32Values[1] = b32Values[0];
		if (!b32Values.hasDuplicates()) { return "hasDuplicates b32 should detect duplicate value"; }

		delete addrValues;
		addrValues.push(msg.sender);
		addrValues.push(address(this));
		addrValues.push(0xD97E471695f73d8186dEABc1AB5B8765e667Cd96);
		if (addrValues.hasDuplicates()) { return "hasDuplicates addr should not have duplicates"; }
		addrValues[1] = addrValues[2];
		if (!addrValues.hasDuplicates()) { return "hasDuplicates addr should detect duplicate value"; }

		delete uintValues;
		uintValues.push(99);
		uintValues.push(2934);
		uintValues.push(7878773);
		if (uintValues.hasDuplicates()) { return "hasDuplicates uint should not have duplicates"; }
		uintValues.push(2934);
		if (!uintValues.hasDuplicates()) { return "hasDuplicates uint should detect duplicate value"; }

		delete intValues;
		intValues.push(23);
		intValues.push(-2388393);
		intValues.push(-1287);
		if (intValues.hasDuplicates()) { return "hasDuplicates int should not have duplicates"; }
		intValues.push(2983472);
		intValues.push(-1287);
		if (!intValues.hasDuplicates()) { return "hasDuplicates int should detect duplicate value"; }

		return SUCCESS;
	}
}