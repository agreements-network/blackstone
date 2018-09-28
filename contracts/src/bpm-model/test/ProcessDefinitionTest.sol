pragma solidity ^0.4.23;

import "commons-base/BaseErrors.sol";
import "commons-utils/TypeUtilsAPI.sol";
import "commons-collections/AbstractDataStorage.sol";

import "bpm-model/ProcessDefinition.sol";
import "bpm-model/DefaultProcessModel.sol";

contract ProcessDefinitionTest {
	
	using TypeUtilsAPI for bytes32;

	string constant SUCCESS = "success";

	// test data
	bytes32 activity1Id = "activity1";
	bytes32 activity2Id = "activity2";
	bytes32 activity3Id = "activity3";
	bytes32 activity4Id = "activity4";
	bytes32 activity5Id = "activity5";
	bytes32 transition1Id = "transition1";
	address assignee1 = 0x1040e6521541daB4E7ee57F21226dD17Ce9F0Fb7;
	address assignee2 = 0x58fd1799aa32deD3F6eac096A1dC77834a446b9C;
	address assignee3 = 0x68112f9380f75a13f6Ce2d5923F1dB8386EF1339;
	address assignee4 = 0x776FDe59876aAB7D654D656e654Ed9876574c54c;
	address author = 0x9d7fDE63776AaB9E234d656E654ED9876574C54C;
	bytes32 participantId1 = "Participant1";

	bytes32 pId;
	bytes32 pInterface;
	bytes32 modelId;

	bytes32 EMPTY = "";

	/**
	 * @dev 
	 */
	function testProcessDefinition() external returns (string) {
	
		// re-usable test variables
		uint error;
		address newAddress;

		ProcessModel pm = new DefaultProcessModel("testModel", "Test Model", [1,0,0], author, false, EMPTY, EMPTY);
		(error, newAddress) = pm.createProcessDefinition("p1");
		ProcessDefinition pd = ProcessDefinition(newAddress);
		
		// setup
		if (pm.getProcessDefinition("p1") != address(pd)) return "$1";

		// test process interface handling
		error = pd.addProcessInterfaceImplementation(pm, "AgreementFormation");
		if (error != BaseErrors.RESOURCE_NOT_FOUND()) return "$1";
		error = pm.addProcessInterface("AgreementFormation");
		if (error != BaseErrors.NO_ERROR()) return "$1";
		error = pm.addProcessInterface("AgreementExecution");
		if (error != BaseErrors.NO_ERROR()) return "$1";
		error = pd.addProcessInterfaceImplementation(pm, "AgreementFormation");
		if (error != BaseErrors.NO_ERROR()) return "$1";
		error = pd.addProcessInterfaceImplementation(pm, "AgreementExecution");
		if (error != BaseErrors.NO_ERROR()) return "$1";
		if (pd.getNumberOfImplementedProcessInterfaces() != 2) return "Number of implemented interfaces should be 2";
		(pId, pInterface, modelId) = pm.getProcessDefinitionData(pd);
		if (pId != "p1") return "Expected process definition id to equal p1";
		if (pInterface != "AgreementFormation") return "$1";

		bool valid;
		bytes32 errorMsg;

		// test activity creation

		// Invalid participant
		error = pd.createActivityDefinition("activity999", BpmModel.ActivityType.TASK, BpmModel.TaskType.USER, BpmModel.TaskBehavior.SENDRECEIVE, "fakeParticipantXYZ", false, EMPTY, EMPTY, EMPTY);
		if (error != BaseErrors.RESOURCE_NOT_FOUND()) return "$1";

		error = pm.addParticipant(participantId1, assignee1, EMPTY, EMPTY, 0x0);
		if (error != BaseErrors.NO_ERROR()) return "Unable to add a valid participant";

		error = pd.createActivityDefinition("activity999", BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, participantId1, false, EMPTY, EMPTY, EMPTY);
		if (error != BaseErrors.INVALID_PARAM_VALUE()) return "$1";
		error = pd.createActivityDefinition("activity999", BpmModel.ActivityType.TASK, BpmModel.TaskType.USER, BpmModel.TaskBehavior.SENDRECEIVE, EMPTY, false, EMPTY, EMPTY, EMPTY);
		if (error != BaseErrors.NULL_PARAM_NOT_ALLOWED()) return "$1";

		// Activity 1
		error = pd.createActivityDefinition(activity1Id, BpmModel.ActivityType.TASK, BpmModel.TaskType.USER, BpmModel.TaskBehavior.SENDRECEIVE, participantId1, true, "app1", EMPTY, EMPTY);
		if (error != BaseErrors.NO_ERROR()) return "Creating activity1 failed";

		(valid, errorMsg) = pd.validate();
		if (!valid) return "$1";
		if (pd.getStartActivity() != activity1Id) return "$1";
		error = pd.createActivityDefinition(activity1Id, BpmModel.ActivityType.TASK, BpmModel.TaskType.USER, BpmModel.TaskBehavior.SENDRECEIVE, participantId1, false, "app1", EMPTY, EMPTY);
		if (error != BaseErrors.RESOURCE_ALREADY_EXISTS()) return "$1";

		// Activity 2
		error = pd.createActivityDefinition(activity2Id, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, "app1", EMPTY, EMPTY);
		if (error != BaseErrors.NO_ERROR()) return "Creating activity2 failed";
		if (pd.getNumberOfActivities() != 2) return "$1";

		(valid, errorMsg) = pd.validate();
		if (valid) return "$1";
		
		// Scenario 1: Sequential Process
		if (address(pd).call(bytes4(keccak256(abi.encodePacked("createTransition(bytes32,bytes32)"))), "blablaActivity", activity2Id))
			return "$1";
		if (address(pd).call(bytes4(keccak256(abi.encodePacked("createTransition(bytes32,bytes32)"))), activity1Id, "blablaActivity"))
			return "$1";
		error = pd.createTransition(activity1Id, activity2Id);
		if (error != BaseErrors.NO_ERROR()) return "$1";

		(valid, errorMsg) = pd.validate();
		if (!valid) return errorMsg.toString(); // should be valid at this point
		if (pd.getStartActivity() != activity1Id) return "Start activity should still be activity1";

		// Scenario 2: XOR Split
		// create gateway to allow valid setup
		pd.createGateway("gateway1", BpmModel.GatewayType.XOR);
		(valid, errorMsg) = pd.validate();
		if (valid) return "$1";

		// Activity 3
		error = pd.createActivityDefinition(activity3Id, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		if (error != BaseErrors.NO_ERROR()) return "Creating activity3 failed";
		if (address(pd).call(bytes4(keccak256(abi.encodePacked("createTransition(bytes32,bytes32)"))), activity1Id, activity3Id))
			return "$1";
		// Activity 4
		error = pd.createActivityDefinition(activity4Id, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		if (error != BaseErrors.NO_ERROR()) return "Creating activity4 failed";

		// check transition condition failure
		if (address(pd).call(bytes4(keccak256(abi.encodePacked("createTransitionConditionForAddress(bytes32,bytes32,bytes32,bytes32,address,uint8,address)"))), "fakeXX", activity3Id, EMPTY, EMPTY, 0x0, 0, 0x0))
			return "Adding condition for non-existent gateway should fail";
		if (address(pd).call(bytes4(keccak256(abi.encodePacked("createTransitionConditionForAddress(bytes32,bytes32,bytes32,bytes32,address,uint8,address)"))), "gateway1", "fakeXX", EMPTY, EMPTY, 0x0, 0, 0x0))
			return "Adding condition for non-existent activity should fail";
		if (address(pd).call(bytes4(keccak256(abi.encodePacked("createTransitionConditionForAddress(bytes32,bytes32,bytes32,bytes32,address,uint8,address)"))), "gateway1", activity3Id, EMPTY, EMPTY, 0x0, 0, 0x0))
			return "$1";

		pd.createTransition(activity2Id, "gateway1");
		pd.createTransition("gateway1", activity3Id);
		pd.createTransition("gateway1", activity4Id);

		// test transition condition failure when adding condition on default transition
		pd.setDefaultTransition("gateway1", activity3Id);
		if (address(pd).call(bytes4(keccak256(abi.encodePacked("createTransitionConditionForAddress(bytes32,bytes32,bytes32,bytes32,address,uint8,address)"))), "gateway1", activity3Id, EMPTY, EMPTY, 0x0, 0, 0x0))
			return "Adding condition for the default transition shoudl fail";

		// test transition condition success with activity4
		if (!address(pd).call(bytes4(keccak256(abi.encodePacked("createTransitionConditionForAddress(bytes32,bytes32,bytes32,bytes32,address,uint8,address)"))), "gateway1", activity4Id, EMPTY, EMPTY, 0x0, 0, 0x0))
			return "Adding condition on valid transition should succeed";

		//TODO missing test if condition gets deleted when setting activity4 as the default transition

		// check transitions on gateways
		bytes32[] memory inputs;
		bytes32[] memory outputs;
		bytes32 defaultOutput;
		(inputs, outputs, , defaultOutput) = pd.getGatewayGraphDetails("gateway1");
		if (inputs.length != 1) return "$1";
		if (outputs.length != 2) return "$1";
		if (defaultOutput != activity3Id) return "activity3 should be set as default transition";

		(valid, errorMsg) = pd.validate();
		if (!valid) return errorMsg.toString(); // process definition should be valid at this point

		// Scenario 3: XOR Join
		pd.createGateway("gateway2", BpmModel.GatewayType.XOR);
		// Activity 5
		error = pd.createActivityDefinition(activity5Id, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		if (error != BaseErrors.NO_ERROR()) return "Creating activity5 failed";
		pd.createTransition(activity3Id, "gateway2");
		pd.createTransition(activity4Id, "gateway2");
		pd.createTransition("gateway2", activity5Id);

		(valid, errorMsg) = pd.validate();
		if (!valid) return errorMsg.toString(); // should be valid at this point

		bytes32[] memory activityIds = pd.getActivitiesForParticipant(participantId1);
		if (activityIds.length != 1)
			return "There should be 1 activity using participant1 as assignee";
		if (pd.getActivitiesForParticipant(participantId1)[0] != activity1Id)
			return "$1";

		return SUCCESS;
	}

	/**
	 * @dev Tests the setup and resolution of transition conditions via the ProcessDefinition
	 */
	function testTransitionConditionResolution() external returns (string) {

		// re-usable variables for return values
		uint error;
		address addr;

		ProcessModel pm = new DefaultProcessModel("conditionsModel", "Conditions Model", [1,0,0], author, false, EMPTY, EMPTY);
		(error, addr) = pm.createProcessDefinition("p1");
		ProcessDefinition pd = ProcessDefinition(addr);

		pd.createActivityDefinition(activity1Id, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createActivityDefinition(activity2Id, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createActivityDefinition(activity3Id, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createGateway(transition1Id, BpmModel.GatewayType.XOR);
		pd.createTransition(activity1Id, transition1Id);
		pd.createTransition(transition1Id, activity2Id);
		pd.createTransition(transition1Id, activity3Id);

		pd.createTransitionConditionForAddress(transition1Id, activity2Id, "buyer", EMPTY, 0x0, uint8(DataStorageUtils.COMPARISON_OPERATOR.EQ), this);
		pd.createTransitionConditionForUint(transition1Id, activity3Id, "elevation", EMPTY, 0x0, uint8(DataStorageUtils.COMPARISON_OPERATOR.LTE), 500);

		// this is the DataStorage used for resolving conditions
		TestData dataStorage = new TestData();
		
		if (pd.resolveTransitionCondition(transition1Id, activity2Id, dataStorage)) return "The condition for transition1/activity2 should be false as the data is not set";
		dataStorage.setDataValueAsAddress("buyer", this);
		if (!pd.resolveTransitionCondition(transition1Id, activity2Id, dataStorage)) return "The condition for transition1/activity2 should be true after data is set";
		dataStorage.setDataValueAsUint("elevation", 2200);
		if (pd.resolveTransitionCondition(transition1Id, activity3Id, dataStorage)) return "The condition for transition1/activity3 should be false";

		return SUCCESS;
	}

}

contract TestApplication {
	
	bool public success;
	
	function doSomething() external {
		success = true;
	}
}

/**
 * Helper contract to provide a DataStorage location
 */
contract TestData is AbstractDataStorage {}
