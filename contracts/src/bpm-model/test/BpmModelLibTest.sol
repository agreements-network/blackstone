pragma solidity ^0.5;

import "commons-collections/AbstractDataStorage.sol";
import "commons-collections/DataStorageUtils.sol";

import "bpm-model/BpmModel.sol";
import "bpm-model/BpmModelLib.sol";

contract BpmModelLibTest {
	
	using BpmModelLib for BpmModel.TransitionCondition;

	string constant SUCCESS = "success";
	BpmModel.TransitionCondition testCondition;
	bytes32 EMPTY = "";

	function testConditionalDataFunctions() external returns (string memory) {
	
		// this is the DataStorage used for resolving conditions
		TestData dataStorage = new TestData();
		TestData subStorage = new TestData();
		dataStorage.setDataValueAsAddress("subStorage", address(subStorage));
		TestData rightHandData = new TestData();
		
		// PRIMITIVE ADDRESS EQ
		testCondition = BpmModel.createLeftHandTransitionCondition("Buyer", EMPTY, address(0), uint8(DataStorageUtils.COMPARISON_OPERATOR.EQ));
		testCondition.rhPrimitive.addressValue = address(this);
		testCondition.rhPrimitive.exists = true;

		if (testCondition.resolve(address(dataStorage))) return "The condition for Buyer address should not be true as the data is not set";
		dataStorage.setDataValueAsAddress("Buyer", address(this));
		if (!testCondition.resolve(address(dataStorage))) return "The condition for Buyer address should be true for EQ operation";

		// PRIMITIVE STRING NEQ
		testCondition = BpmModel.createLeftHandTransitionCondition("City", EMPTY, address(0), uint8(DataStorageUtils.COMPARISON_OPERATOR.NEQ));
		testCondition.rhPrimitive.stringValue = "BadOehenhausen";
		testCondition.rhPrimitive.exists = true;

		dataStorage.setDataValueAsString("City", "Berlin");
		if (!testCondition.resolve(address(dataStorage))) return "The condition for City string should be true for NEQ operation with no match";
		dataStorage.setDataValueAsString("City", "BadOehenhausen");
		if (testCondition.resolve(address(dataStorage))) return "The condition for City string should be false for NEQ operation with matching string";

		// PRIMITIVE UINT GTE
		testCondition = BpmModel.createLeftHandTransitionCondition("Age", EMPTY, address(0), uint8(DataStorageUtils.COMPARISON_OPERATOR.GTE));
		testCondition.rhPrimitive.uintValue = 18;
		testCondition.rhPrimitive.exists = true;

		dataStorage.setDataValueAsUint("Age", 18);
		if (!testCondition.resolve(address(dataStorage))) return "The condition for Age uint 18 should be true for GTE operation";
		dataStorage.setDataValueAsUint("Age", 17);
		if (testCondition.resolve(address(dataStorage))) return "The condition for Age uint 17 should be false for GTE operation";
		dataStorage.setDataValueAsUint("Age", 56);
		if (!testCondition.resolve(address(dataStorage))) return "The condition for Age uint 56 should be true for GTE operation";

		// PRIMITIVE INT LT in substorage
		testCondition = BpmModel.createLeftHandTransitionCondition("Temperature", "subStorage", address(0), uint8(DataStorageUtils.COMPARISON_OPERATOR.LT));
		testCondition.rhPrimitive.intValue = -20;
		testCondition.rhPrimitive.exists = true;

		subStorage.setDataValueAsInt("Temperature", 6);
		if (testCondition.resolve(address(dataStorage))) return "The condition for Temperature int 6 should be false for LT operation";
		subStorage.setDataValueAsInt("Temperature", -33);
		if (!testCondition.resolve(address(dataStorage))) return "The condition for Temperature int -33 should be true for LT operation";

		// RIGHT HAND DATASTORAGE with fixed address
		testCondition = BpmModel.createLeftHandTransitionCondition("Approved", EMPTY, address(0), uint8(DataStorageUtils.COMPARISON_OPERATOR.EQ));
		testCondition.rhData = DataStorageUtils.ConditionalData({dataPath: "OtherApproval", dataStorageId: EMPTY, dataStorage: address(rightHandData), exists: true});
		testCondition.rhData.exists = true;

		dataStorage.setDataValueAsBool("Approved", true);
		if (testCondition.resolve(address(dataStorage))) return "The condition for Approved bool should be false for EQ operation with false right-hand side";
		rightHandData.setDataValueAsBool("OtherApproval", true);
		if (!testCondition.resolve(address(dataStorage))) return "The condition for Approved bool should be true for EQ operation with OtherApproval true";


		return SUCCESS;
	}

}

/**
 * Helper contract to provide a DataStorage location
 */
contract TestData is AbstractDataStorage {}
