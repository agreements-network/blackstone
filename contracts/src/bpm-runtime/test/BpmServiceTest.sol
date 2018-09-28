pragma solidity ^0.4.23;

import "commons-base/BaseErrors.sol";
import "commons-base/SystemOwned.sol";
import "commons-utils/ArrayUtilsAPI.sol";
import "commons-utils/TypeUtilsAPI.sol";
import "commons-collections/AbstractDataStorage.sol";
import "commons-management/AbstractDbUpgradeable.sol";
import "commons-auth/ParticipantsManager.sol";
import "commons-auth/DefaultParticipantsManager.sol";
import "commons-auth/DefaultOrganization.sol";
import "bpm-model/ProcessModelRepository.sol";
import "bpm-model/ProcessModel.sol";
import "bpm-model/ProcessDefinition.sol";

import "bpm-runtime/BpmRuntime.sol";
import "bpm-runtime/BpmRuntimeLib.sol";
import "bpm-runtime/BpmServiceDb.sol";
import "bpm-runtime/DefaultBpmService.sol";
import "bpm-runtime/ProcessInstance.sol";
import "bpm-runtime/DefaultProcessInstance.sol";
import "bpm-runtime/WorkflowProxy.sol";
import "bpm-runtime/WorkflowUserAccount.sol"; 
import "bpm-runtime/ApplicationRegistry.sol";
import "bpm-runtime/ApplicationRegistryDb.sol";
import "bpm-runtime/DefaultApplicationRegistry.sol"; 
import "bpm-runtime/Application.sol";
import "bpm-runtime/TransitionConditionResolver.sol";

contract BpmServiceTest {

	using TypeUtilsAPI for bytes32;
	using ArrayUtilsAPI for bytes32[];
	using BpmRuntimeLib for BpmRuntime.ProcessGraph;
	using BpmRuntimeLib for BpmRuntime.ActivityNode;
	using BpmRuntimeLib for BpmRuntime.Transition;
	using BpmRuntimeLib for ProcessDefinition;

	// test data
	bytes32 activityId1 = "activity1";
	bytes32 activityId2 = "activity2";
	bytes32 activityId3 = "activity3";
	bytes32 activityId4 = "activity4";
	bytes32 activityId5 = "activity5";
	bytes32 activityId6 = "activity6";
	bytes32 transitionId1 = "transition1";
	bytes32 transitionId2 = "transition2";
	bytes32 transitionId3 = "transition3";
	bytes32 transitionId4 = "transition4";

	address assignee1 = 0x1040e6521541daB4E7ee57F21226dD17Ce9F0Fb7;
	address assignee2 = 0x58fd1799aa32deD3F6eac096A1dC77834a446b9C;
	address assignee3 = 0x68112f9380f75a13f6Ce2d5923F1dB8386EF1339;
	address modelAuthor = 0x76212f9380F75a13F6Ce280F75f1Db8386EF113f;

	bytes32 user1Id = "iamuser1";
	bytes32 user2Id = "iamuser2";
	bytes32 user3Id = "iamuser3";

	bytes32 serviceApp1Id = "ServiceApp1";
	bytes32 serviceApp2Id = "ServiceApp2";

	bytes32 participantId1 = "Participant1";
	bytes32 participantId2 = "Participant2";
	bytes32 participantId3 = "Participant3";
	bytes32 participantId4 = "Participant4";

	address[] parties;

	string constant SUCCESS = "success";
	bytes32 EMPTY = "";

	ProcessModelRepository repository;
	ApplicationRegistry applicationRegistry;

	// graph needs to be a storage variable to mimic behavior inside ProcessInstance
	BpmRuntime.ProcessGraph graph;

	function setApplicationRegistry(address _appRegistry) external {
		applicationRegistry = ApplicationRegistry(_appRegistry);
	}

	function setProcessModelRepository(address _repository) external {
		repository = ProcessModelRepository(_repository);
	}
	
	/**
	 * @dev Tests a process graph consisting of sequential activities.
	 */
	function testProcessGraphSequential() external returns (string) {

		// Graph: activity1 -> activity2 -> activity3
		graph.clear();

		// add places
		graph.addActivity(activityId1);
		graph.addActivity(activityId2);
		graph.addActivity(activityId3);
	
		// add connections
		graph.connect(activityId1, BpmModel.ModelElementType.ACTIVITY, activityId2, BpmModel.ModelElementType.ACTIVITY);
		graph.connect(activityId2, BpmModel.ModelElementType.ACTIVITY, activityId3, BpmModel.ModelElementType.ACTIVITY);

		// Test graph connectivity
		if (graph.activityKeys.length != 3) return "There should be 3 activities in the graph";
		if (graph.transitionKeys.length != 2) return "There should be 2 transitions in the graph";
		if (graph.activities[activityId1].node.inputs.length != 0) return "activity1 should have 0 in arcs";
		if (graph.activities[activityId1].node.outputs.length != 1) return "activity1 should have 1 out arcs";
		if (graph.transitions[graph.transitionKeys[0]].node.inputs.length != 1) return "transition1 should have 1 in arcs";
		if (graph.transitions[graph.transitionKeys[0]].node.outputs.length != 1) return "transition1 should have 1 out arcs";
		if (graph.activities[activityId2].node.inputs.length != 1) return "activity2 should have 1 in arcs";
		if (graph.activities[activityId2].node.outputs.length != 1) return "activity2 should have 1 out arcs";
		if (graph.transitions[graph.transitionKeys[1]].node.inputs.length != 1) return "transition2 should have 1 in arcs";
		if (graph.transitions[graph.transitionKeys[1]].node.outputs.length != 1) return "transition2 should have 1 out arcs";
		if (graph.activities[activityId3].node.inputs.length != 1) return "activity3 should have 1 in arcs";
		if (graph.activities[activityId3].node.outputs.length != 0) return "activity3 should have 0 out arcs";

		graph.activities[activityId1].done = true; // setting the "done" marker on the 1st activity enables the tokens to start moving through the graph

		// test helper functions
		if (graph.isTransitionEnabled(graph.transitionKeys[0]) != true) return "Transition1 should be enabled";
		if (graph.isTransitionEnabled(graph.transitionKeys[1]) != false) return "Transition2 should not be enabled";

		// Test token movement
	  	if (graph.activities[activityId1].done != true) return "State1: activity1 should have 1 completion markers";
		if (graph.activities[activityId2].done != false) return "State1: activity2 should have 0 completion markers";
		if (graph.activities[activityId3].done != false) return "State1: activity3 should have 0 completion markers";

		graph.execute();

		if (graph.activities[activityId1].done != false) return "State2: activity1 should have 0 completion markers";
		if (graph.activities[activityId2].ready != true) return "State2: activity2 should have 1 activation markers";
		if (graph.activities[activityId2].done != false) return "State2: activity2 should have 0 completion markers";
		if (graph.activities[activityId3].done != false) return "State2: activity3 should have 0 completion markers";

		// "activate and complete" on the graph level involves removing activation markers and setting completion markers
		graph.activities[activityId2].ready = false;
		graph.activities[activityId2].done = true;
		graph.execute();

	  	if (graph.activities[activityId1].done != false) return "State3: activity1 should have 0 completion markers";
		if (graph.activities[activityId2].done != false) return "State3: activity2 should have 0 completion markers";
		if (graph.activities[activityId3].ready != true) return "State3: activity3 should have 1 activation markers";

		return SUCCESS;
	}

	/**
	 * @dev Tests a process graph containing AND split and join transitions
	 */
	function testProcessGraphParallelGateway() external returns (string) {

		//                                 /-> activity2 ->\
		// Graph: activity1 -> AND SPLIT ->                 -> AND JOIN -> activity4
		//                                 \-> activity3 ->/ 

		graph.clear();

		// add places
		graph.addActivity(activityId1);
		graph.addActivity(activityId2);
		graph.addActivity(activityId3);
		graph.addActivity(activityId4);

		// add transitions
		graph.addTransition(transitionId1, BpmRuntime.TransitionType.AND);
		graph.addTransition(transitionId2, BpmRuntime.TransitionType.AND);
	
		// add connections
		graph.connect(activityId1, BpmModel.ModelElementType.ACTIVITY, transitionId1, BpmModel.ModelElementType.GATEWAY);
		graph.connect(transitionId1, BpmModel.ModelElementType.GATEWAY, activityId2, BpmModel.ModelElementType.ACTIVITY);
		graph.connect(transitionId1, BpmModel.ModelElementType.GATEWAY, activityId3, BpmModel.ModelElementType.ACTIVITY);
		graph.connect(activityId2, BpmModel.ModelElementType.ACTIVITY, transitionId2, BpmModel.ModelElementType.GATEWAY);
		graph.connect(activityId3, BpmModel.ModelElementType.ACTIVITY, transitionId2, BpmModel.ModelElementType.GATEWAY);
		graph.connect(transitionId2, BpmModel.ModelElementType.GATEWAY, activityId4, BpmModel.ModelElementType.ACTIVITY);

		// Test graph connectivity
		if (graph.activityKeys.length != 4) return "There should be 4 activities in the graph";
		if (graph.transitionKeys.length != 2) return "There should be 2 transitions in the graph";
		if (graph.activities[activityId1].node.inputs.length != 0) return "activity1 should have 0 in arcs";
		if (graph.activities[activityId1].node.outputs.length != 1) return "activity1 should have 1 out arcs";
		if (graph.transitions[transitionId1].node.inputs.length != 1) return "transition1 should have 1 in arcs";
		if (graph.transitions[transitionId1].node.outputs.length != 2) return "transition1 should have 1 out arcs";
		if (graph.activities[activityId2].node.inputs.length != 1) return "activity2 should have 1 in arcs";
		if (graph.activities[activityId2].node.outputs.length != 1) return "activity2 should have 1 out arcs";
		if (graph.activities[activityId3].node.inputs.length != 1) return "activity3 should have 1 in arcs";
		if (graph.activities[activityId3].node.outputs.length != 1) return "activity3 should have 1 out arcs";
		if (graph.transitions[transitionId2].node.inputs.length != 2) return "transition2 should have 2 in arcs";
		if (graph.transitions[transitionId2].node.outputs.length != 1) return "transition2 should have 1 out arcs";
		if (graph.activities[activityId4].node.inputs.length != 1) return "activity4 should have 1 in arcs";
		if (graph.activities[activityId4].node.outputs.length != 0) return "activity4 should have 0 out arcs";

		graph.activities[activityId1].done = true; // start execution by marking 1st activity done

		if (graph.isTransitionEnabled(graph.transitionKeys[0]) != true) return "Transition1 should be enabled";
		if (graph.isTransitionEnabled(graph.transitionKeys[1]) != false) return "Transition2 should not be enabled at graph start";

		// Before 1st iteration
		if (graph.activities[activityId2].done != false) return "State1: activity2 should have 0 completion markers";
		if (graph.activities[activityId3].done != false) return "State1: activity3 should have 0 completion markers";

		graph.execute();

		if (graph.activities[activityId1].done != false) return "State2: activity1 should have 0 completion markers";
		if (graph.activities[activityId2].ready != true) return "State2: activity2 should have 1 activation markers";
		if (graph.activities[activityId2].ready != true) return "State2: activity3 should have 1 activation markers";

		// complete activities and test transition
		graph.activities[activityId2].done = true;
		if (graph.isTransitionEnabled(graph.transitionKeys[1]) == true) return "Transition2 should NOT be enabled with only 1/2 inputs";
		graph.activities[activityId3].done = true;
		if (graph.isTransitionEnabled(graph.transitionKeys[1]) != true) return "Transition2 should be enabled now with 2/2 inputs";

		graph.execute();

		if (graph.activities[activityId2].done != false) return "State3: activity2 should have 0 completion markers";
		if (graph.activities[activityId3].done != false) return "State3: activity3 should have 0 completion markers";
		if (graph.activities[activityId4].ready != true) return "State3: activity4 should have 1 activation markers";

		return SUCCESS;
	}

	/**
	 * @dev Tests a process graph containing XOR split and join transitions
	 */
	function testProcessGraphExclusiveGateway() external returns (string) {

		//                                 /-> activity2 ->\
		// Graph: activity1 -> XOR SPLIT ----> activity3 ----> XOR JOIN -> activity5
		//                                 \-> activity4 ->/ 

		graph.clear();

		// add places
		graph.addActivity(activityId1);
		graph.addActivity(activityId2);
		graph.addActivity(activityId3);
		graph.addActivity(activityId4);
		graph.addActivity(activityId5);

		// add transitions
		graph.addTransition(transitionId1, BpmRuntime.TransitionType.XOR);
		graph.addTransition(transitionId2, BpmRuntime.TransitionType.XOR);
	
		// add connections
		graph.connect(activityId1, BpmModel.ModelElementType.ACTIVITY, transitionId1, BpmModel.ModelElementType.GATEWAY);
		graph.connect(transitionId1, BpmModel.ModelElementType.GATEWAY, activityId2, BpmModel.ModelElementType.ACTIVITY);
		graph.connect(transitionId1, BpmModel.ModelElementType.GATEWAY, activityId3, BpmModel.ModelElementType.ACTIVITY);
		graph.connect(transitionId1, BpmModel.ModelElementType.GATEWAY, activityId4, BpmModel.ModelElementType.ACTIVITY);
		graph.connect(activityId2, BpmModel.ModelElementType.ACTIVITY, transitionId2, BpmModel.ModelElementType.GATEWAY);
		graph.connect(activityId3, BpmModel.ModelElementType.ACTIVITY, transitionId2, BpmModel.ModelElementType.GATEWAY);
		graph.connect(activityId4, BpmModel.ModelElementType.ACTIVITY, transitionId2, BpmModel.ModelElementType.GATEWAY);
		graph.connect(transitionId2, BpmModel.ModelElementType.GATEWAY, activityId5, BpmModel.ModelElementType.ACTIVITY);

		// Test graph connectivity
		if (graph.activityKeys.length != 5) return "There should be 4 activities in the graph";
		if (graph.transitionKeys.length != 2) return "There should be 2 transitions in the graph";
		if (graph.activities[activityId1].node.inputs.length != 0) return "activity1 should have 0 in arcs";
		if (graph.activities[activityId1].node.outputs.length != 1) return "activity1 should have 1 out arcs";
		if (graph.transitions[transitionId1].node.inputs.length != 1) return "transition1 should have 1 in arcs";
		if (graph.transitions[transitionId1].node.outputs.length != 3) return "transition1 should have 1 out arcs";
		if (graph.activities[activityId2].node.inputs.length != 1) return "activity2 should have 1 in arcs";
		if (graph.activities[activityId2].node.outputs.length != 1) return "activity2 should have 1 out arcs";
		if (graph.activities[activityId3].node.inputs.length != 1) return "activity3 should have 1 in arcs";
		if (graph.activities[activityId3].node.outputs.length != 1) return "activity3 should have 1 out arcs";
		if (graph.activities[activityId4].node.inputs.length != 1) return "activity4 should have 1 in arcs";
		if (graph.activities[activityId4].node.outputs.length != 1) return "activity4 should have 1 out arcs";
		if (graph.transitions[transitionId2].node.inputs.length != 3) return "transition2 should have 2 in arcs";
		if (graph.transitions[transitionId2].node.outputs.length != 1) return "transition2 should have 1 out arcs";
		if (graph.activities[activityId5].node.inputs.length != 1) return "activity5 should have 1 in arcs";
		if (graph.activities[activityId5].node.outputs.length != 0) return "activity5 should have 0 out arcs";

		// add TransitionConditionResolver
		TestConditionResolver resolver = new TestConditionResolver();
		resolver.addCondition(transitionId1, activityId2, false);
		resolver.addCondition(transitionId1, activityId3, true);
		resolver.addCondition(transitionId1, activityId4, false);

		graph.processInstance = address(resolver); // the simple test implementation of a resolver is used here
		graph.activities[activityId1].done = true; // start execution by marking 1st activity done

		if (graph.isTransitionEnabled(graph.transitionKeys[0]) != true) return "Transition1 should be enabled";
		if (graph.isTransitionEnabled(graph.transitionKeys[1]) != false) return "Transition2 should not be enabled at graph start";

		// Before 1st iteration
		if (graph.activities[activityId2].done != false) return "State1: activity2 should have 0 completion markers";
		if (graph.activities[activityId3].done != false) return "State1: activity3 should have 0 completion markers";
		if (graph.activities[activityId4].done != false) return "State1: activity4 should have 0 completion markers";

		graph.execute();

		if (graph.activities[activityId1].done != false) return "State2: activity1 should have 0 completion markers";
		if (graph.activities[activityId2].ready != false) return "State2: activity2 should have 0 activation markers";
		if (graph.activities[activityId3].ready != true) return "State2: activity3 should have 1 activation markers";
		if (graph.activities[activityId4].ready != false) return "State2: activity4 should have 0 activation markers";

		// complete activities and test transition
		graph.activities[activityId3].done = true;
		if (graph.isTransitionEnabled(graph.transitionKeys[1]) != true) return "Transition2 should be enabled with only 1 inputs";

		graph.execute();

		if (graph.activities[activityId2].done != false) return "State3: activity2 should have 0 completion markers";
		if (graph.activities[activityId3].done != false) return "State3: activity3 should have 0 completion markers";
		if (graph.activities[activityId4].done != false) return "State3: activity4 should have 0 completion markers";
		if (graph.activities[activityId5].ready != true) return "State3: activity5 should have 1 activation markers";

		return SUCCESS;
	}

		/**
	 * @dev Tests a process graph containing XOR split with default transition
	 */
	function testProcessGraphExclusiveGatewayWithDefault() external returns (string) {

		//                                 /-> activity2 ->\ // default transition
		// Graph: activity1 -> XOR SPLIT --
		//                                 \-> activity3 ->/ 

		graph.clear();

		// add places
		graph.addActivity(activityId1);
		graph.addActivity(activityId2);
		graph.addActivity(activityId3);

		// add transitions
		graph.addTransition(transitionId1, BpmRuntime.TransitionType.XOR);
	
		// add connections
		graph.connect(activityId1, BpmModel.ModelElementType.ACTIVITY, transitionId1, BpmModel.ModelElementType.GATEWAY);
		graph.connect(transitionId1, BpmModel.ModelElementType.GATEWAY, activityId2, BpmModel.ModelElementType.ACTIVITY);
		graph.connect(transitionId1, BpmModel.ModelElementType.GATEWAY, activityId3, BpmModel.ModelElementType.ACTIVITY);

		// add TransitionConditionResolver with all transitions false
		TestConditionResolver resolver = new TestConditionResolver();
		resolver.addCondition(transitionId1, activityId2, false);
		resolver.addCondition(transitionId1, activityId3, false);

		graph.processInstance = address(resolver); // the simple test implementation of a resolver is used here
		graph.activities[activityId1].done = true; // start execution by marking 1st activity done

		// test REVERT for XOR gateway with no outputs to fire
		if (graph.isTransitionEnabled(graph.transitionKeys[0]) != true) return "Transition1 should be enabled";
		if (address(this).call(bytes4(keccak256(abi.encodePacked("executeGraph()")))))
			return "Executing transition1 with all outputs false and no default transition should REVERT";

		// correct setup by defining a default transition and try again
		graph.transitions[transitionId1].defaultOutput = activityId2;
		graph.execute();

		if (graph.activities[activityId1].done != false) return "State2: activity1 should have 0 completion markers";
		if (graph.activities[activityId2].ready != true) return "State2: activity2 should have 1 activation markers being the default transition";

		return SUCCESS;
	}

	/**
	 * @dev Tests a process graph containing multiple sequential gateways to ensure activation markers are passed along correctly
	 * using artificial activities between the gateways.
	 */
	function testProcessGraphMultiGateway() external returns (string) {

		//                                 /---------------> activity2 --------------->\
		// Graph: activity1 -> AND SPLIT ->                                             -> AND JOIN -> activity5
		//                                 \             /-> activity3 ->\             /
		//                                  -> OR SPLIT -                 -> OR JOIN -/ 
		//                                               \-> activity4 ->/

		graph.clear();

		// add places
		graph.addActivity(activityId1);
		graph.addActivity(activityId2);
		graph.addActivity(activityId3);
		graph.addActivity(activityId4);
		graph.addActivity(activityId5);

		// add transitions
		graph.addTransition(transitionId1, BpmRuntime.TransitionType.AND);
		graph.addTransition(transitionId2, BpmRuntime.TransitionType.XOR);
		graph.addTransition(transitionId3, BpmRuntime.TransitionType.XOR);
		graph.addTransition(transitionId4, BpmRuntime.TransitionType.AND);
	
		// add connections
		graph.connect(activityId1, BpmModel.ModelElementType.ACTIVITY, transitionId1, BpmModel.ModelElementType.GATEWAY);
		graph.connect(transitionId1, BpmModel.ModelElementType.GATEWAY, activityId2, BpmModel.ModelElementType.ACTIVITY);
		graph.connect(transitionId1, BpmModel.ModelElementType.GATEWAY, transitionId2, BpmModel.ModelElementType.GATEWAY);
		bytes32 hiddenPlace1Id = graph.activityKeys[graph.activityKeys.length-1]; // an artificial activity was added between the two transitions. Save ID for later
		graph.connect(transitionId2, BpmModel.ModelElementType.GATEWAY, activityId3, BpmModel.ModelElementType.ACTIVITY);
		graph.connect(transitionId2, BpmModel.ModelElementType.GATEWAY, activityId4, BpmModel.ModelElementType.ACTIVITY);
		graph.connect(activityId3, BpmModel.ModelElementType.ACTIVITY, transitionId3, BpmModel.ModelElementType.GATEWAY);
		graph.connect(activityId4, BpmModel.ModelElementType.ACTIVITY, transitionId3, BpmModel.ModelElementType.GATEWAY);
		graph.connect(activityId2, BpmModel.ModelElementType.ACTIVITY, transitionId4, BpmModel.ModelElementType.GATEWAY);
		graph.connect(transitionId3, BpmModel.ModelElementType.GATEWAY, transitionId4, BpmModel.ModelElementType.GATEWAY);
		bytes32 hiddenPlace2Id = graph.activityKeys[graph.activityKeys.length-1];  // an artificial activity was added between the two transitions. Save ID for later
		graph.connect(transitionId4, BpmModel.ModelElementType.GATEWAY, activityId5, BpmModel.ModelElementType.ACTIVITY);

		// Test graph connectivity
		if (graph.activityKeys.length != 7) return "There should be 7 activities in the graph, including two artificial places to connect the gateways";
		if (graph.transitionKeys.length != 4) return "There should be 4 transitions in the graph";
		if (graph.activities[activityId1].node.inputs.length != 0) return "activity1 should have 0 in arcs";
		if (graph.activities[activityId1].node.outputs.length != 1) return "activity1 should have 1 out arcs";
		if (graph.transitions[transitionId1].node.inputs.length != 1) return "transition1 should have 1 in arcs";
		if (graph.transitions[transitionId1].node.outputs.length != 2) return "transition1 should have 2 out arcs";
		if (graph.transitions[transitionId2].node.inputs.length != 1) return "transition2 should have 1 in arcs";
		if (graph.transitions[transitionId2].node.outputs.length != 2) return "transition2 should have 2 out arcs";
		if (graph.activities[activityId2].node.inputs.length != 1) return "activity2 should have 1 in arcs";
		if (graph.activities[activityId2].node.outputs.length != 1) return "activity2 should have 1 out arcs";
		if (graph.activities[activityId3].node.inputs.length != 1) return "activity3 should have 1 in arcs";
		if (graph.activities[activityId3].node.outputs.length != 1) return "activity3 should have 1 out arcs";
		if (graph.activities[activityId4].node.inputs.length != 1) return "activity4 should have 1 in arcs";
		if (graph.activities[activityId4].node.outputs.length != 1) return "activity4 should have 1 out arcs";
		if (graph.transitions[transitionId3].node.inputs.length != 2) return "transition3 should have 2 in arcs";
		if (graph.transitions[transitionId3].node.outputs.length != 1) return "transition3 should have 1 out arcs";
		if (graph.transitions[transitionId4].node.inputs.length != 2) return "transition4 should have 2 in arcs";
		if (graph.transitions[transitionId4].node.outputs.length != 1) return "transition4 should have 1 out arcs";
		if (graph.activities[activityId5].node.inputs.length != 1) return "activity5 should have 1 in arcs";
		if (graph.activities[activityId5].node.outputs.length != 0) return "activity5 should have 0 out arcs";

		TestConditionResolver resolver = new TestConditionResolver();
		resolver.addCondition(transitionId2, activityId3, true);
		resolver.addCondition(transitionId2, activityId4, false);
		graph.processInstance = address(resolver); // the simple test implementation of a resolver is used here
		graph.activities[activityId1].done = true; // start execution by marking 1st activity done

		if (graph.isTransitionEnabled(transitionId1) == false) return "Transition1 should be enabled";
		if (graph.isTransitionEnabled(transitionId2) == true) return "Transition2 should not be enabled at graph start";

		// Before 1st iteration
		if (graph.activities[activityId2].done) return "State1: activity2 should have 0 completion markers";
		if (graph.activities[activityId3].done) return "State1: activity3 should have 0 completion markers";

		graph.execute();

		if (graph.isTransitionEnabled(transitionId1) == true) return "Transition1 should have fired";
		if (graph.isTransitionEnabled(transitionId2) == true) return "Transition2 should NOT be enabled due to missing execution of hidden activity";

		// need to complete the hidden activity between the two gateways
		if (graph.activities[hiddenPlace1Id].ready == false) return "The hidden activity between transition1 and transition2 should be ready";
		graph.activities[hiddenPlace1Id].done = true;
		if (graph.isTransitionEnabled(transitionId2) == false) return "Transition2 should be enabled now";

		graph.execute();

		if (graph.activities[activityId1].done) return "State2: activity1 should have 0 completion markers";
		if (graph.activities[activityId2].ready == false) return "State2: activity2 should have 1 activation markers";
		if (graph.activities[activityId3].ready == false) return "State2: activity3 should have 1 activation markers";

		// complete activities and test transition
		graph.activities[activityId2].done = true;
		graph.activities[activityId3].done = true;
		if (graph.isTransitionEnabled(transitionId3) == false) return "Transition3 XOR should be enabled";
		if (graph.isTransitionEnabled(transitionId4) == true) return "Transition4 AND should NOT be enabled";

		graph.execute();

		if (graph.isTransitionEnabled(transitionId4) == true) return "Transition4 AND should still NOT be enabled due to missing execution of hidden activity";
		if (graph.activities[hiddenPlace2Id].ready == false) return "The hidden activity between transition3 and transition4 should be ready";
		graph.activities[hiddenPlace2Id].done = true;
		if (graph.isTransitionEnabled(transitionId4) == false) return "Transition4 AND should be enabled now";

		graph.execute();

		if (graph.activities[activityId2].done) return "State3: activity2 should have 0 completion markers";
		if (graph.activities[activityId3].done) return "State3: activity3 should have 0 completion markers";
		if (graph.activities[activityId5].ready == false) return "State3: activity4 should have 1 activation markers";

		return SUCCESS;
	}

	/**
	 * @dev Tests the creation and configuration of a process instance from a process definition, specifically the tranlation into a BpmRuntime.ProcessGraph
	 */
	function testProcessGraphCreation() external returns (string) {

		//                                              /--> activity3 -------------\
		// Graph: activity1 -> activity2 -> XOR SPLIT --                             --> XOR JOIN -> activity6
		//                                              \-> activity4 -> activity5 -/

		// re-usable variables for return values
		uint error;
		address addr;
		bool valid;
		bytes32 errorMsg;

		(error, addr) = repository.createProcessModel("testModel2", "Test Model", [1,0,0], modelAuthor, false, EMPTY, EMPTY);
		if (addr == 0x0) return "Unable to create a ProcessModel";
		ProcessModel pm = ProcessModel(addr);

		(error, addr) = pm.createProcessDefinition("ProcessDefinition1");
		if (addr == 0x0) return "Unable to create a ProcessDefinition";
		ProcessDefinition pd = ProcessDefinition(addr);

		pd.createActivityDefinition(activityId1, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createActivityDefinition(activityId2, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createActivityDefinition(activityId3, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createActivityDefinition(activityId4, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createActivityDefinition(activityId5, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createActivityDefinition(activityId6, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createGateway(transitionId1, BpmModel.GatewayType.XOR);
		pd.createGateway(transitionId2, BpmModel.GatewayType.XOR);
		pd.createTransition(activityId1, activityId2);
		pd.createTransition(activityId2, transitionId1);
		pd.createTransition(transitionId1, activityId3);
		pd.createTransition(transitionId1, activityId4);
		pd.createTransition(activityId4, activityId5);
 		pd.createTransition(activityId3, transitionId2);
		pd.createTransition(activityId5, transitionId2);
		pd.createTransition(transitionId2, activityId6);
		pd.createTransitionConditionForUint(transitionId1, activityId3, "Age", EMPTY, 0x0, uint8(DataStorageUtils.COMPARISON_OPERATOR.GTE), 18);
		pd.setDefaultTransition(transitionId1, activityId4);

		// Validate to set the start activity and enable runtime configuration
		(valid, errorMsg) = pd.validate();
		if (!valid) return errorMsg.toString();

		ProcessInstance pi = new DefaultProcessInstance(pd, this, EMPTY);
		graph.configure(pi);
		if (graph.processInstance != address(pi)) return "ProcessGraph.configure() should have set the process instance on the graph";

		if (graph.activityKeys.length != 6) return "There should be 6 activities in the ProcessGraph";
		if (graph.transitionKeys.length != 4) return "There should be 4 transitions in the ProcessGraph";
		if (!graph.activities[activityId1].exists) return "Activity1 not found in graph.";
		if (!graph.activities[activityId2].exists) return "Activity2 not found in graph.";
		if (!graph.activities[activityId3].exists) return "Activity3 not found in graph.";
		if (!graph.activities[activityId4].exists) return "Activity4 not found in graph.";
		if (!graph.activities[activityId5].exists) return "Activity5 not found in graph.";
		if (!graph.activities[activityId6].exists) return "Activity6 not found in graph.";
		if (!graph.transitions[transitionId1].exists) return "Transition1 not found in graph.";
		if (graph.transitions[transitionId1].transitionType != BpmRuntime.TransitionType.XOR) return "Transition1 should be of type XOR.";
		if (!graph.transitions[transitionId2].exists) return "Transition2 not found in graph.";
		if (graph.transitions[transitionId2].transitionType != BpmRuntime.TransitionType.XOR) return "Transition2 should be of type XOR.";

		if (graph.activities[activityId1].node.inputs.length != 0) return "Activity1 should have no inputs.";
		if (graph.activities[activityId1].node.outputs.length != 1) return "Activity1 should have 1 outputs.";
		if (graph.activities[activityId2].node.inputs.length != 1) return "Activity2 should have 1 inputs.";
		if (graph.activities[activityId2].node.outputs.length != 1) return "Activity2 should have 1 outputs.";
		if (graph.transitions[transitionId1].node.inputs.length != 1) return "Transition1 should have 1 inputs.";
		if (graph.transitions[transitionId1].node.outputs.length != 2) return "Transition1 should have 2 outputs.";
		if (graph.activities[activityId3].node.inputs.length != 1) return "Activity3 should have 1 inputs.";
		if (graph.activities[activityId3].node.outputs.length != 1) return "Activity3 should have 1 outputs.";
		if (graph.activities[activityId4].node.inputs.length != 1) return "Activity4 should have 1 inputs.";
		if (graph.activities[activityId4].node.outputs.length != 1) return "Activity4 should have 1 outputs.";
		if (graph.activities[activityId5].node.inputs.length != 1) return "Activity5 should have 1 inputs.";
		if (graph.activities[activityId5].node.outputs.length != 1) return "Activity5 should have 1 outputs.";
		if (graph.transitions[transitionId2].node.inputs.length != 2) return "Transition2 should have 2 inputs.";
		if (graph.transitions[transitionId2].node.outputs.length != 1) return "Transition2 should have 1 outputs.";
		if (graph.activities[activityId6].node.inputs.length != 1) return "Activity6 should have 1 inputs.";
		if (graph.activities[activityId6].node.outputs.length != 0) return "Activity6 should have no outputs.";

		if (graph.activities[activityId1].node.outputs[0] != graph.activities[activityId2].node.inputs[0]) return "Activity1 and Activity2 should share the same transition";
		if (graph.activities[activityId2].node.outputs[0] != graph.activities[activityId3].node.inputs[0]) return "Activity2 and Activity3 should share the same transition";
		if (graph.activities[activityId2].node.outputs[0] != graph.activities[activityId4].node.inputs[0]) return "Activity2 and Activity4 should share the same transition";
		if (graph.activities[activityId4].node.outputs[0] != graph.activities[activityId5].node.inputs[0]) return "Activity4 and Activity5 should share the same transition";
		if (graph.activities[activityId5].node.outputs[0] != graph.activities[activityId6].node.inputs[0]) return "Activity5 and Activity6 should share the same transition";
		if (graph.activities[activityId3].node.outputs[0] != graph.activities[activityId6].node.inputs[0]) return "Activity3 and Activity6 should share the same transition";

		if (graph.transitions[transitionId1].defaultOutput != activityId4) return "Transition1 should have activity4 as the default output";

		return SUCCESS;
	}

	/**
	 * @dev Uses a simple process flow in order to test BpmService-internal functions.
	 */
	function testInternalProcessExecution() external returns (string) {

		// re-usable variables for return values
		uint error;
		address addr;

		(error, addr) = repository.createProcessModel("testModel3", "Test Model 3", [1,0,0], modelAuthor, false, EMPTY, EMPTY);
		if (addr == 0x0) return "Unable to create a ProcessModel";
		ProcessModel pm = ProcessModel(addr);

		(error, addr) = pm.createProcessDefinition("ProcessDefinitionSequence");
		if (addr == 0x0) return "Unable to create a ProcessDefinition";
		ProcessDefinition pd = ProcessDefinition(addr);

		pd.createActivityDefinition(activityId1, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createActivityDefinition(activityId2, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createActivityDefinition(activityId3, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createTransition(activityId1, activityId2);
		pd.createTransition(activityId2, activityId3);
		
		// Validate to set the start activity and enable runtime configuration
		pd.validate();

		TestBpmService service = getNewTestBpmService();

		ProcessInstance pi = service.createDefaultProcessInstance(pd, this, EMPTY);

		pi.initRuntime();
		if (pi.getState() != uint(BpmRuntime.ProcessInstanceState.ACTIVE)) return "PI should be ACTIVE after runtime initiation";
		if (address(pi).call(bytes4(keccak256(abi.encodePacked("initRuntime()")))))
			return "It should not be possible to initiate an ACTIVE PI again";
		// TODO test more error conditions around pi.initRuntime(), e.g. invalid PD, etc.

		service.addProcessInstance(pi);
		error = pi.execute(service);
		if (error != BaseErrors.NO_ERROR()) return "Unexpected error executing the PI";

		// verify DB state
		if (service.getDatabase().getNumberOfProcessInstances() != 1) return "There should be 1 PI in the DB";
		if (service.getDatabase().getNumberOfActivityInstances() != 3) return "There should be 3 AIs in the DB";
		if (pi.getNumberOfActivityInstances() != 3) return "There should be 3 AIs in the ProcessInstance";

		// verify individual activity instances
		uint8 state;
		( , , , , , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(0));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity1 should be completed";
		( , , , , , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(1));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity2 should be completed";
		( , , , , , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(2));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity3 should be completed";

		// verify process state
		if (pi.getState() != uint8(BpmRuntime.ProcessInstanceState.COMPLETED)) return "The PI should be completed";

		return SUCCESS;
	}

	/**
	 * @dev Tests a straight-through process with XOR and AND gateways
	 */
	function testGatewayRouting() external returns (string) {

		//                                                 /-> activity3 -\
		//                                 /-> XOR SPLIT --                --> XOR JOIN -\
		// Graph: activity1 -> AND SPLIT --                \-> activity4 -/               \
		//                                 \                                               --> AND JOIN -> activity5
		//                                  \-> activity2 --------------------------------/

		// re-usable variables for return values
		uint error;
		address addr;
		bytes32 activityId;
		uint8 state;

		(error, addr) = repository.createProcessModel("routingModel", "Routing Model", [1,0,0], modelAuthor, false, EMPTY, EMPTY);
		if (addr == 0x0) return "Unable to create a ProcessModel";
		ProcessModel pm = ProcessModel(addr);

		(error, addr) = pm.createProcessDefinition("RoutingPD");
		if (addr == 0x0) return "Unable to create a ProcessDefinition";
		ProcessDefinition pd = ProcessDefinition(addr);

		pd.createActivityDefinition(activityId1, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createActivityDefinition(activityId2, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createActivityDefinition(activityId3, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createActivityDefinition(activityId4, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createActivityDefinition(activityId5, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createGateway(transitionId1, BpmModel.GatewayType.AND);
		pd.createGateway(transitionId2, BpmModel.GatewayType.XOR);
		pd.createGateway(transitionId3, BpmModel.GatewayType.XOR);
		pd.createGateway(transitionId4, BpmModel.GatewayType.AND);
		pd.createTransition(activityId1, transitionId1);
		pd.createTransition(transitionId1, transitionId2);
		pd.createTransition(transitionId1, activityId2);
		pd.createTransition(transitionId2, activityId3);
		pd.createTransition(transitionId2, activityId4);
 		pd.createTransition(activityId3, transitionId3);
		pd.createTransition(activityId4, transitionId3);
		pd.createTransition(transitionId3, transitionId4);
		pd.createTransition(activityId2, transitionId4);
		pd.createTransition(transitionId4, activityId5);
		pd.createTransitionConditionForUint(transitionId2, activityId3, "Age", EMPTY, 0x0, uint8(DataStorageUtils.COMPARISON_OPERATOR.GTE), 18);
		pd.setDefaultTransition(transitionId2, activityId4);
		
		// Validate to set the start activity and enable runtime configuration
		(bool valid, bytes32 errorMsg) = pd.validate();
		if (!valid) return errorMsg.toString();

		TestBpmService service = getNewTestBpmService();
		service.setProcessModelRepository(repository);
		service.setApplicationRegistry(applicationRegistry);

		// Start first process instance with Age not set (should take default transition to activity4)
		ProcessInstance pi1 = service.createDefaultProcessInstance(pd, this, EMPTY);

		// verify expected routing decisions ahead of start
		if (pi1.resolveTransitionCondition(transitionId2, activityId3)) return "TransitionCondition to activity3 should be false without a value being set in the process";

		error = service.startProcessInstance(pi1);
		if (error != BaseErrors.NO_ERROR()) return "Unexpected error during process start of p1";
		if (pi1.getState() != uint8(BpmRuntime.ProcessInstanceState.COMPLETED)) return "p1 should be completed";

		if (pi1.getNumberOfActivityInstances() != 4) return "There should be 4 AIs total in p1";
		uint i;
		bool xorPathCorrect = false;
		for (i=0; i<pi1.getNumberOfActivityInstances(); i++) {
			(activityId, , , , , state) = pi1.getActivityInstanceData(pi1.getActivityInstanceAtIndex(i));
			if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "All AIs in p1 should be completed";
			if (activityId == activityId4)
				xorPathCorrect = true;
		}
		if (!xorPathCorrect) return "The XOR split should have invoked activity4 as default transition";

		// Start second process with Age data set (should take activity3 route)
		ProcessInstance pi2 = service.createDefaultProcessInstance(pd, this, EMPTY);
		pi2.setDataValueAsUint("Age", 55);
		error = service.startProcessInstance(pi2);
		if (error != BaseErrors.NO_ERROR()) return "Unexpected error during process start of p2";

		if (pi2.getNumberOfActivityInstances() != 4) return "There should be 4 AIs total in p2";
		for (i=0; i<pi2.getNumberOfActivityInstances(); i++) {
			(activityId, , , , , state) = pi2.getActivityInstanceData(pi2.getActivityInstanceAtIndex(i));
			if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "All AIs in p2 should be completed";
			if (activityId == activityId3)
				xorPathCorrect = true;
		}
		if (!xorPathCorrect) return "The XOR split should have invoked activity3 due to a satisfied transition condition";

		return SUCCESS;
	}

	/**
	 * Tests invocation of application completion functions in general
	 */
	function testSequentialServiceApplications() external returns (string) {

		// re-usable variables for return values
		uint error;
		address addr;
		bool valid;
		bytes32 errorMsg;
		uint8 state;
		bytes32 dataPath;

		// Init BpmService
		TestBpmService service = getNewTestBpmService();
		service.setProcessModelRepository(repository);
		service.setApplicationRegistry(applicationRegistry);

		TestData dataStorage = new TestData();
		EventApplication eventApp = new EventApplication(service);
		FailureServiceApplication serviceApp = new FailureServiceApplication();

		(error, addr) = repository.createProcessModel("serviceApplicationsModel", "Service Applications", [1,0,0], modelAuthor, false, EMPTY, EMPTY);
		if (addr == 0x0) return "Unable to create a ProcessModel";
		ProcessModel pm = ProcessModel(addr);

		error = applicationRegistry.addApplication(serviceApp1Id, BpmModel.ApplicationType.EVENT, eventApp, bytes4(EMPTY), EMPTY);
		error = applicationRegistry.addApplication(serviceApp2Id, BpmModel.ApplicationType.SERVICE, serviceApp, bytes4(EMPTY), EMPTY);

		(error, addr) = pm.createProcessDefinition("ServiceApplicationProcess");
		if (addr == 0x0) return "Unable to create a ProcessDefinition";
		ProcessDefinition pd = ProcessDefinition(addr);

		// Activity1 is configured as an asynchronous invocation in order to test the IN/OUT data mappings
		error = pd.createActivityDefinition(activityId1, BpmModel.ActivityType.TASK, BpmModel.TaskType.EVENT, BpmModel.TaskBehavior.SENDRECEIVE, EMPTY, false, serviceApp1Id, EMPTY, EMPTY);
		if (error != BaseErrors.NO_ERROR()) return "$1";
		pd.createDataMapping(activityId1, BpmModel.Direction.IN, eventApp.inDataIdAge(), "Age", "storage", 0x0);
		pd.createDataMapping(activityId1, BpmModel.Direction.IN, eventApp.inDataIdGreeting(), "Message", EMPTY, 0x0);
		pd.createDataMapping(activityId1, BpmModel.Direction.OUT, eventApp.outDataIdResult(), "Response", EMPTY, 0x0);
		error = pd.createActivityDefinition(activityId2, BpmModel.ActivityType.TASK, BpmModel.TaskType.SERVICE, BpmModel.TaskBehavior.SEND, EMPTY, false, serviceApp2Id, EMPTY, EMPTY);
		if (error != BaseErrors.NO_ERROR()) return "$1";
		pd.createTransition(activityId1, activityId2);
		
		// Validate to set the start activity and enable runtime configuration
		(valid, errorMsg) = pd.validate();
		if (!valid) return errorMsg.toString();

		// create a PI and set up data content for testing
		// NOTE: must match data mapping instructions in activity definitions above!
		ProcessInstance pi = service.createDefaultProcessInstance(pd, this, EMPTY);
		dataStorage.setDataValueAsUint("Age", 78);
		pi.setDataValueAsAddress("storage", dataStorage);
		pi.setDataValueAsString("Message", "Hello World");

		error = service.startProcessInstance(pi);
		if (error != BaseErrors.NO_ERROR()) return "Unexpected error during process start";

		// verify PI and AI state
		if (pi.getState() != uint8(BpmRuntime.ProcessInstanceState.ACTIVE)) return "The PI should still be active";
		( , , , addr, , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(0));
		if (state != uint8(BpmRuntime.ActivityInstanceState.SUSPENDED)) return "$1";
		if (addr != address(eventApp)) return "$1";

		// test IN data retrieval
		(addr, dataPath) = pi.resolveInDataLocation(pi.getActivityInstanceAtIndex(0), eventApp.inDataIdAge());
		if (addr != address(dataStorage)) return "$1";
		if (dataPath != "Age") return "$1";
		(addr, dataPath) = pi.resolveInDataLocation(pi.getActivityInstanceAtIndex(0), eventApp.inDataIdGreeting());
		if (addr != address(pi)) return "$1";
		if (dataPath != "Message") return "$1";

		// test failure scenarios for IN mappings
		if (address(service).call(keccak256(abi.encodePacked("getActivityInDataAsUint(bytes32,bytes32)")), eventApp.activityInstanceId(), eventApp.inDataIdAge()))
			return "Retrieving IN data outside of the application should REVERT";
		if (address(eventApp).call(keccak256(abi.encodePacked("retrieveInDataAge()"))))
			return "$1";
		// test successful IN mappings set during completion of the event
		if (eventApp.getAgeDuringCompletion() != 78)
			return "$1";
		if (keccak256(abi.encodePacked(eventApp.getGreetingDuringCompletion())) != keccak256(abi.encodePacked("Hello World")))
			return "$1";

		// trying to set OUT data from here should fail
		if (address(service).call(keccak256(abi.encodePacked("setActivityOutDataAsBytes32(bytes32,bytes32,bytes32)")), eventApp.activityInstanceId(), eventApp.inDataIdAge(), "bla"))
			return "Retrieving IN data outside of the application should REVERT";
		// try completing activity1 from here should fail
		error = pi.completeActivity(pi.getActivityInstanceAtIndex(0), service);
		if (error != BaseErrors.INVALID_ACTOR()) return "$1";

		error = eventApp.completeExternal(pi.getActivityInstanceAtIndex(0), "Hello back");
		if (error != BaseErrors.NO_ERROR()) return "$1";

		// // verify out data correctly stored in process by the event app
		if (pi.getDataValueAsBytes32("Response") != "Hello back")
			return "$1";

		( , , , , , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(0));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "$1";
		// activity2 should be interrupted at first
		( , , , , , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(1));
		if (state != uint8(BpmRuntime.ActivityInstanceState.INTERRUPTED)) return "Activity2 should be interrupted";

		// reset the app and recover the process
		serviceApp.reset();
		// recovery should be possible from here and not via the service contract
		error = pi.completeActivity(pi.getActivityInstanceAtIndex(1), service);
		if (error != BaseErrors.NO_ERROR()) return "$1";
		( , , , , , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(1));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity2 should be completed now";

		if (pi.getState() != uint8(BpmRuntime.ProcessInstanceState.COMPLETED)) return "The PI should be completed";

		return SUCCESS;
	}

	function testParticipantResolution() external returns (string) {

		// re-usable variables for return values
		uint error;
		address addr;
		bool valid;
		bytes32 errorMsg;
	
		bytes32 dataPathOnAgreement = "buyer";
		bytes32 dataStorageId = "agreement";
		bytes32 dataPathOnProcess = "customAssignee";
	
		(error, addr) = repository.createProcessModel("conditionalPerformerModel", "Test Model CP", [1,0,0], modelAuthor, false, EMPTY, EMPTY);
		if (addr == 0x0) return "Unable to create a ProcessModel";
		ProcessModel pm = ProcessModel(addr);

		// Create participants, one conditional performer and one direct one.
		TestData dataStorage = new TestData(); // this simulates the Agreement's DataStorage
		dataStorage.setDataValueAsAddress(dataPathOnAgreement, assignee1);
		// conditional data path with direct storage address
		pm.addParticipant(participantId1, 0x0, dataPathOnAgreement, EMPTY, dataStorage);
		// specific account participant
		pm.addParticipant(participantId2, this, EMPTY, EMPTY, 0x0);
		// conditional data path with indirect storage ID
		pm.addParticipant(participantId3, 0x0, dataPathOnAgreement, dataStorageId, 0x0);
		// conditional data path on process instance
		pm.addParticipant(participantId4, 0x0, dataPathOnProcess, EMPTY, 0x0);

		(error, addr) = pm.createProcessDefinition("SingleTaskProcess");
		if (addr == 0x0) return "Unable to create a ProcessDefinition";
		ProcessDefinition pd = ProcessDefinition(addr);

		// creating a valid model with a single activity
		error = pd.createActivityDefinition(activityId1, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		if (error != BaseErrors.NO_ERROR()) return "$1";
		(valid, errorMsg) = pd.validate();
		if (!valid) return errorMsg.toString();

		TestProcessInstance pi = new TestProcessInstance(pd);
		pi.setDataValueAsAddress(dataStorageId, dataStorage); // supports indirect navigation to DataStorage via a field in the process instance
		pi.setDataValueAsAddress(dataPathOnProcess, this); // supports direct lookup of address via a field in the process instance
		pi.initRuntime();

		bytes32 dataPath;
		(addr, dataPath) = pi.resolveParticipant(participantId1);
		if (addr != address(dataStorage)) return "$1";
		if (dataPath != dataPathOnAgreement) return "$1";
		(addr, dataPath) = pi.resolveParticipant(participantId2);
		if (addr != address(this)) return "$1";
		if (dataPath != "") return "$1";
		(addr, dataPath) = pi.resolveParticipant(participantId3);
		if (addr != address(dataStorage)) return "$1";
		if (dataPath != dataPathOnAgreement) return "$1";
		(addr, dataPath) = pi.resolveParticipant(participantId4);
		if (addr != address(pi)) return "$1";
		if (dataPath != dataPathOnProcess) return "$1";

		return SUCCESS;
	}

	/**
	 * Tests a simple process flow using public BpmService API
	 */
	function testSequentialProcessWithUserTask() external returns (string) {

		// re-usable variables for return values
		uint error;
		address addr;
		bool valid;
		bytes32 errorMsg;
		address[10] memory emptyAddressArray;

		TestBpmService service = getNewTestBpmService();

		WorkflowUserAccount proxy1 = new WorkflowUserAccount("user1", this, 0x0);
		WorkflowUserAccount organizationUser = new WorkflowUserAccount("TomHanks", this, 0x0);
		DefaultOrganization org1 = new DefaultOrganization(emptyAddressArray);
		if (!org1.addUser(organizationUser)) return "Unable to add user account to organization";

		// Register a typical WEB application with only a webform
		error = applicationRegistry.addApplication("Webform1", BpmModel.ApplicationType.WEB, 0x0, bytes4(EMPTY), "MyCustomWebform");
		if (error != BaseErrors.NO_ERROR()) return "$1";

		(error, addr) = repository.createProcessModel("testModelUserTasks", "UserTask Test Model", [1,0,0], modelAuthor, false, EMPTY, EMPTY);
		if (addr == 0x0) return "Unable to create a ProcessModel";
		ProcessModel pm = ProcessModel(addr);

		// Register participants to be used for USER tasks
		pm.addParticipant(participantId1, proxy1, EMPTY, EMPTY, 0x0); // user participant
		pm.addParticipant(participantId2, org1, EMPTY, EMPTY, 0x0); // organization participant

		(error, addr) = pm.createProcessDefinition("UserTaskProcess");
		if (addr == 0x0) return "Unable to create a ProcessDefinition";
		ProcessDefinition pd = ProcessDefinition(addr);

		// Activity 1 is assigned to proxy1
		// Activity 2 is assigned to the organizationUser via the org1 organization
		error = pd.createActivityDefinition(activityId1, BpmModel.ActivityType.TASK, BpmModel.TaskType.USER, BpmModel.TaskBehavior.SENDRECEIVE, participantId1, false, "Webform1", EMPTY, EMPTY);
		if (error != BaseErrors.NO_ERROR()) return "$1";
		error = pd.createActivityDefinition(activityId2, BpmModel.ActivityType.TASK, BpmModel.TaskType.USER, BpmModel.TaskBehavior.SENDRECEIVE, participantId2, false, "Webform1", EMPTY, EMPTY);
		if (error != BaseErrors.NO_ERROR()) return "$1";
		pd.createTransition(activityId1, activityId2);

		pd.createDataMapping(activityId1, BpmModel.Direction.IN, "nameAccessPoint", "Name", "storage", 0x0);
		pd.createDataMapping(activityId1, BpmModel.Direction.OUT, "approvedAccessPoint", "Approved", EMPTY, 0x0);
		pd.createDataMapping(activityId2, BpmModel.Direction.IN, "approvedAccessPoint", "Approved", EMPTY, 0x0);
		pd.createDataMapping(activityId2, BpmModel.Direction.OUT, "ageAccessPoint", "Age", "storage", 0x0);
		// Create a DataStorage to use for IN/OUT data mappings
		TestData dataStorage = new TestData();
		dataStorage.setDataValueAsBytes32("Name", "Smith");

		// Validate to set the start activity and enable runtime configuration
		(valid, errorMsg) = pd.validate();
		if (!valid) return errorMsg.toString();

		// test error conditions for creating a process via model and pd IDs
		if (address(service).call(bytes4(keccak256(abi.encodePacked("startProcessFromRepository(bytes32,bytes32,bytes32)"))), "FakeModelIdddddd", "UserTaskProcess", EMPTY))
			return "Starting a process with invalid model ID should REVERT";
		if (address(service).call(bytes4(keccak256(abi.encodePacked("startProcessFromRepository(bytes32,bytes32,bytes32)"))), pm.getId(), "TotallyFakeProcessssId", EMPTY))
			return "$1";

		// test successful creation via model and pd IDs
		(error, addr) = service.startProcessFromRepository(pm.getId(), "UserTaskProcess", EMPTY);
		if (error != BaseErrors.NO_ERROR()) return "Unexpected error during process start";
		if (addr == 0x0) return "$1";
		ProcessInstance pi = ProcessInstance(addr);

		// some of the data mappings reference a DataStorage object that needs to be set in the PI
		pi.setDataValueAsAddress("storage", dataStorage);

		// verify DB state
		if (service.getNumberOfProcessInstances() != 1) return "There should be 1 PI after process start";
		if (service.getNumberOfActivityInstances(pi) != 1) return "There should be 1 AI after process start";
		if (pi.getNumberOfActivityInstances() != 1) return "$1";

		// verify individual activity instances
		uint8 state;
		( , , , addr, , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(0));
		if (state != uint8(BpmRuntime.ActivityInstanceState.SUSPENDED)) return "Activity1 should be suspended";
		if (addr != address(proxy1)) return "Activity1 should be assigned to proxy1";

		// test data mappings via user-assigned task
		if (address(service).call(bytes4(keccak256(abi.encodePacked("getActivityInDataAsBytes32(bytes32,bytes32)"))), pi.getActivityInstanceAtIndex(0), "nameAccessPoint"))
			 return "$1";
		if (proxy1.getActivityInDataAsBytes32(pi.getActivityInstanceAtIndex(0), "nameAccessPoint", service) != "Smith")
			return "IN data mapping Name should return correctly via user proxy1";
		proxy1.setActivityOutDataAsBool(pi.getActivityInstanceAtIndex(0), "approvedAccessPoint", true, service);

		// complete user task 1 and check outcome
		error = organizationUser.completeActivity(pi.getActivityInstanceAtIndex(0), service);
		if (error != BaseErrors.INVALID_ACTOR()) return "$1";
		error = proxy1.completeActivity(pi.getActivityInstanceAtIndex(0), service);
		if (error != BaseErrors.NO_ERROR()) return "$1";
		( , , , , addr, state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(0));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity1 should be completed";
		if (addr != address(proxy1)) return "Activity1 should be completedBy proxy1";

		// verify new world state
		if (service.getNumberOfActivityInstances(pi) != 2) return "There should be 2 AIs after task1 completion";
		if (pi.getNumberOfActivityInstances() != 2) return "$1";
		( , , , addr, , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(1));
		if (state != uint8(BpmRuntime.ActivityInstanceState.SUSPENDED)) return "Activity2 should be suspended";
		if (addr != address(org1)) return "$1";

		// test data mappings via organization-assigned task
		if (address(proxy1).call(bytes4(keccak256(abi.encodePacked("getActivityInDataAsBool(bytes32,bytes32)"))), pi.getActivityInstanceAtIndex(1), "approvedAccessPoint"))
			return "$1";
		if (organizationUser.getActivityInDataAsBool(pi.getActivityInstanceAtIndex(1), "approvedAccessPoint", service) != true)
			return "$1";
		organizationUser.setActivityOutDataAsUint(pi.getActivityInstanceAtIndex(1), "ageAccessPoint", 21, service);

		// complete user task 2 and check outcome
		error = proxy1.completeActivity(pi.getActivityInstanceAtIndex(1), service);
		if (error != BaseErrors.INVALID_ACTOR()) return "$1";
		// complete the activity here using an OUT data mapping to set the Age
		error = organizationUser.completeActivityWithUintData(pi.getActivityInstanceAtIndex(1), service, "Age", 21);
		if (error != BaseErrors.NO_ERROR()) return "$1";
		( , , , , addr, state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(1));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity2 should be completed";
		if (addr != address(organizationUser)) return "$1";
		// check the fields that were set in the PI and data storage
		if (pi.getDataValueAsBool("Approved") != true)
			return "$1";
		if (dataStorage.getDataValueAsUint("Age") != 21)
			return "$1";

		// verify process state
		if (pi.getState() != uint8(BpmRuntime.ProcessInstanceState.COMPLETED)) return "The PI should be completed";

		return SUCCESS;
	}

	/**
	 * Tests aborting a process midflight
	 */
	function testProcessAbort() external returns (string) {

		// re-usable variables for return values
		uint error;
		address addr;
		bool valid;
		bytes32 errorMsg;

		TestBpmService service = getNewTestBpmService();

		WorkflowProxy proxy1 = new WorkflowUserAccount("user1", this, 0x0);
	
		(error, addr) = repository.createProcessModel("testModelAbort", "Abort Test Model", [1,0,0], modelAuthor, false, EMPTY, EMPTY);
		if (addr == 0x0) return "Unable to create a ProcessModel";
		ProcessModel pm = ProcessModel(addr);

		// Register participants to be used for USER tasks
		pm.addParticipant(participantId1, proxy1, EMPTY, EMPTY, 0x0); // user participant

		(error, addr) = pm.createProcessDefinition("AbortProcess");
		if (addr == 0x0) return "Unable to create a ProcessDefinition";
		ProcessDefinition pd = ProcessDefinition(addr);

		// Activity 1 is a NONE
		// Activity 2 is user task
		error = pd.createActivityDefinition(activityId1, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		if (error != BaseErrors.NO_ERROR()) return "Error creating NONE task activity";
		error = pd.createActivityDefinition(activityId2, BpmModel.ActivityType.TASK, BpmModel.TaskType.USER, BpmModel.TaskBehavior.SENDRECEIVE, participantId1, false, EMPTY, EMPTY, EMPTY);
		if (error != BaseErrors.NO_ERROR()) return "$1";
		pd.createTransition(activityId1, activityId2);
		
		// Validate to set the start activity and enable runtime configuration
		(valid, errorMsg) = pd.validate();
		if (!valid) return errorMsg.toString();

		// create two process instances, one via the BpmService.startProcess function and one via direct constructor
		// to make sure they are both abortable by the ower (this contract)
		(error, addr) = service.startProcess(pd, EMPTY);
		if (error != BaseErrors.NO_ERROR()) return "Unexpected error during process start";
		if (addr == 0x0) return "$1";
		ProcessInstance pi1 = ProcessInstance(addr);
		ProcessInstance pi2 = new DefaultProcessInstance(pd, 0x0, EMPTY);
		service.startProcessInstance(pi2);

		// verify DB state
		if (service.getNumberOfProcessInstances() != 2) return "There should be 1 PI after process start";
		if (service.getNumberOfActivityInstances(pi1) != 2) return "There should be 2 AIs in pi1";
		if (service.getNumberOfActivityInstances(pi2) != 2) return "There should be 2 AIs in pi2";

		// verify individual activity instances
		uint8 state;
		( , , , addr, , state) = pi1.getActivityInstanceData(pi1.getActivityInstanceAtIndex(0));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity1 in pi1 should be completed";
		( , , , addr, , state) = pi1.getActivityInstanceData(pi1.getActivityInstanceAtIndex(1));
		if (state != uint8(BpmRuntime.ActivityInstanceState.SUSPENDED)) return "Activity2 in pi1 should be suspended";
		( , , , addr, , state) = pi2.getActivityInstanceData(pi2.getActivityInstanceAtIndex(0));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity1 in pi2 should be completed";
		( , , , addr, , state) = pi2.getActivityInstanceData(pi2.getActivityInstanceAtIndex(1));
		if (state != uint8(BpmRuntime.ActivityInstanceState.SUSPENDED)) return "Activity2 in pi2 should be suspended";

		// abort both processes, only the second one should succeed
		pi1.abort(service);
		pi2.abort(service);

		if (pi1.getState() != uint8(BpmRuntime.ProcessInstanceState.ABORTED)) return "pi1 should be aborted";
		if (pi2.getState() != uint8(BpmRuntime.ProcessInstanceState.ABORTED)) return "pi2 should be aborted";
		( , , , addr, , state) = pi1.getActivityInstanceData(pi1.getActivityInstanceAtIndex(0));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity1 in pi1 should still be completed";
		( , , , addr, , state) = pi1.getActivityInstanceData(pi1.getActivityInstanceAtIndex(1));
		if (state != uint8(BpmRuntime.ActivityInstanceState.ABORTED)) return "Activity2 in pi1 should now be aborted";
		( , , , addr, , state) = pi2.getActivityInstanceData(pi2.getActivityInstanceAtIndex(0));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity1 in pi2 should still be completed";
		( , , , addr, , state) = pi2.getActivityInstanceData(pi2.getActivityInstanceAtIndex(1));
		if (state != uint8(BpmRuntime.ActivityInstanceState.ABORTED)) return "Activity2 in pi2 should now be aborted";

		return SUCCESS;
	}

	/**
	 * Tests a multi-instance user task flow
	 */
	function testMultiInstanceUserTask() external returns (string) {

		// re-usable variables for return values
		uint error;
		address addr;
		bool valid;
		bytes32 errorMsg;
		WorkflowUserAccount proxy1 = new WorkflowUserAccount(user1Id, this, 0x0);
		WorkflowUserAccount proxy2 = new WorkflowUserAccount(user2Id, this, 0x0);

		TestBpmService service = getNewTestBpmService();

		TestData dataStorage = new TestData();
		address[100] memory signatories;
		signatories[0] = address(proxy1);
		signatories[1] = address(proxy2);
		dataStorage.setDataValueAsAddressArray("SIGNATORIES", signatories);

		(error, addr) = repository.createProcessModel("multiInstanceUserTasks", "Multi Instance User Tasks", [1,0,0], modelAuthor, false, EMPTY, EMPTY);
		if (addr == 0x0) return "Unable to create a ProcessModel";
		ProcessModel pm = ProcessModel(addr);

		// Register a participant to be used for USER tasks that replicates the AN behavior
		pm.addParticipant(participantId1, 0x0, "SIGNATORIES", "agreement", 0x0);

		(error, addr) = pm.createProcessDefinition("MultiInstanceUserTaskProcess");
		if (addr == 0x0) return "Unable to create a ProcessDefinition";
		ProcessDefinition pd = ProcessDefinition(addr);

		error = pd.createActivityDefinition(activityId1, BpmModel.ActivityType.TASK, BpmModel.TaskType.USER, BpmModel.TaskBehavior.SENDRECEIVE, participantId1, true, EMPTY, EMPTY, EMPTY);
		if (error != BaseErrors.NO_ERROR()) return "Error creating USER task activity definition";
		error = pd.createActivityDefinition(activityId2, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		if (error != BaseErrors.NO_ERROR()) return "Error creating NONE task activity definition";
		pd.createTransition(activityId1, activityId2);
		
		// Validate to set the start activity and enable runtime configuration
		(valid, errorMsg) = pd.validate();
		if (!valid) return errorMsg.toString();

		// Start process instance
		ProcessInstance pi = service.createDefaultProcessInstance(pd, this, EMPTY);
		pi.setDataValueAsAddress("agreement", dataStorage);
		error = service.startProcessInstance(pi);
		if (error != BaseErrors.NO_ERROR()) return "Unexpected error during process start";

		// verify DB state
		if (service.getNumberOfProcessInstances() != 1) return "There should be 1 PI";
		if (service.getNumberOfActivityInstances(pi) != 2) return "There should be 2 AIs";

		// verify process state
		if (pi.getState() != uint8(BpmRuntime.ProcessInstanceState.ACTIVE)) return "The PI should be active";

		// verify individual activity instances
		uint8 state;
		( , , , addr, , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(0));
		if (state != uint8(BpmRuntime.ActivityInstanceState.SUSPENDED)) return "Activity1.1 should be suspended";
		if (addr != address(proxy1)) return "Activity1.1 should be assigned to proxy1";
		( , , , addr, , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(1));
		if (state != uint8(BpmRuntime.ActivityInstanceState.SUSPENDED)) return "Activity1.2 should be suspended";
		if (addr != address(proxy2)) return "Activity1.2 should be assigned to proxy2";

		// complete first user task
		error = proxy1.completeActivity(pi.getActivityInstanceAtIndex(0), service);
		if (error != BaseErrors.NO_ERROR()) return "$1";
		( , , , , , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(0));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity1.1 should be completed";

		// verify process state
		if (pi.getState() != uint8(BpmRuntime.ProcessInstanceState.ACTIVE)) return "The PI should be completed";

		// number of AIs should still be 2 at this point
		if (service.getNumberOfActivityInstances(pi) != 2) return "$1";

		// complete remaining user task
		error = proxy2.completeActivity(pi.getActivityInstanceAtIndex(1), service);
		if (error != BaseErrors.NO_ERROR()) return "$1";
		( , , , , , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(1));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity1.2 should be completed";

		if (service.getNumberOfActivityInstances(pi) != 3) return "$1";

		// remaining activities should be completed
		( , , , , , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(1));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity2 should be completed";
		( , , , , , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(2));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity3 should be completed";

		// verify process state
		if (pi.getState() != uint8(BpmRuntime.ProcessInstanceState.COMPLETED)) return "The PI should be completed";

		return SUCCESS;
	}

	/**
	 * Tests a simple process flow using public BpmService API
	 */
	function testSubprocesses() external returns (string) {

		// re-usable variables for return values
		uint error;
		address addr;
		bool valid;
		bytes32 errorMsg;
		ProcessInstance[3] memory subProcesses;

		TestBpmService service = getNewTestBpmService();
		service.setProcessModelRepository(repository);
		service.setApplicationRegistry(applicationRegistry);

		// Two process models
		(error, addr) = repository.createProcessModel("ModelA", "Model A", [1,0,0], modelAuthor, false, EMPTY, EMPTY);
		if (addr == 0x0) return "Unable to create ProcessModel A";
		ProcessModel pmA = ProcessModel(addr);
		pmA.addParticipant(participantId1, address(this), EMPTY, EMPTY, 0x0);

		(error, addr) = repository.createProcessModel("ModelB", "Model B", [1,0,0], modelAuthor, false, EMPTY, EMPTY);
		if (addr == 0x0) return "Unable to create ProcessModel B";
		ProcessModel pmB = ProcessModel(addr);

		// One 'main' process and three sub-process definitions
		(error, addr) = pmA.createProcessDefinition("MainProcess");
		if (addr == 0x0) return "Unable to create MainProcess ProcessDefinition";
		ProcessDefinition pdMain = ProcessDefinition(addr);
		(error, addr) = pmA.createProcessDefinition("SubProcessA");
		if (addr == 0x0) return "Unable to create SubProcessA ProcessDefinition";
		ProcessDefinition pdSubA = ProcessDefinition(addr);
		(error, addr) = pmA.createProcessDefinition("SubProcessA2");
		if (addr == 0x0) return "$1";
		ProcessDefinition pdSubA2 = ProcessDefinition(addr);
		(error, addr) = pmB.createProcessDefinition("SubProcessB");
		if (addr == 0x0) return "Unable to create SubProcessB ProcessDefinition";
		ProcessDefinition pdSubB = ProcessDefinition(addr);

		// The test covers a "main" process with three subprocess activities. The first two subprocesses have activities that should be suspended.
		// The first subprocess activity is a "SEND" (asynchronous) invocation and the main process should continue despite the subprocess not being completed
		// The second subprocess activity is a "SENDRECEIVE" (synchronous) invocation and the main process should wait for its completion
		// The third subprocess is completely automated and should complete right away which should lead to the main process being completed as well
		pdMain.createActivityDefinition(activityId1, BpmModel.ActivityType.SUBPROCESS, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, "SubProcessA");
		pdMain.createActivityDefinition(activityId2, BpmModel.ActivityType.SUBPROCESS, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SENDRECEIVE, EMPTY, false, EMPTY, "ModelB", "SubProcessB");
		pdMain.createActivityDefinition(activityId3, BpmModel.ActivityType.SUBPROCESS, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, "SubProcessA2");
		pdMain.createTransition(activityId1, activityId2);
		pdMain.createTransition(activityId2, activityId3);
		pdSubA.createActivityDefinition(activityId1, BpmModel.ActivityType.TASK, BpmModel.TaskType.USER, BpmModel.TaskBehavior.SENDRECEIVE, participantId1, false, EMPTY, EMPTY, EMPTY);
		pdSubA2.createActivityDefinition(activityId1, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.RECEIVE, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pdSubB.createActivityDefinition(activityId1, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.RECEIVE, EMPTY, false, EMPTY, EMPTY, EMPTY);

		// Validate to set the start activity and enable runtime configuration
		(valid, errorMsg) = pdSubA.validate();
		if (!valid) return errorMsg.toString();
		(valid, errorMsg) = pdSubB.validate();
		if (!valid) return errorMsg.toString();
		(valid, errorMsg) = pdMain.validate();
		if (!valid) return errorMsg.toString();

		// Start process instance with data to simulate agreement reference
		ProcessInstance piMain = service.createDefaultProcessInstance(pdMain, this, EMPTY);
		piMain.setDataValueAsAddress("agreement", this);
		error = service.startProcessInstance(piMain);
		if (error != BaseErrors.NO_ERROR()) return "Unexpected error during process start";

		// verify DB state
		if (service.getBpmServiceDb().getNumberOfProcessInstances() != 3) return "There should be 3 PIs";
		if (service.getBpmServiceDb().getNumberOfActivityInstances() != 4) return "There should be 4 AIs total";
		subProcesses[0] = ProcessInstance(service.getProcessInstanceAtIndex(1));
		subProcesses[1] = ProcessInstance(service.getProcessInstanceAtIndex(2));
	
		// all processes should be active after main start
		if (piMain.getState() != uint8(BpmRuntime.ProcessInstanceState.ACTIVE)) return "The Main PI should be active";
		if (piMain.getNumberOfActivityInstances() != 2) return "$1";
		if (subProcesses[0].getState() != uint8(BpmRuntime.ProcessInstanceState.ACTIVE)) return "SubprocessA should be active";
		if (subProcesses[1].getState() != uint8(BpmRuntime.ProcessInstanceState.ACTIVE)) return "SubprocessB should be active";
		uint state;
		( , , , , , state) = piMain.getActivityInstanceData(piMain.getActivityInstanceAtIndex(0));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity1 in Main should be completed";
		( , , , , , state) = piMain.getActivityInstanceData(piMain.getActivityInstanceAtIndex(1));
		if (state != uint8(BpmRuntime.ActivityInstanceState.SUSPENDED)) return "Activity2 in Main should be suspended";

		// verify that data was propagated to the subprocess
		if (subProcesses[0].getDataValueAsAddress("agreement") != address(this)) return "$1";
		if (subProcesses[1].getDataValueAsAddress("agreement") != address(this)) return "$1";

		// completing the SubprocessB activity should trigger completion of the subprocess and creation of the third subprocess
		error = subProcesses[1].completeActivity(subProcesses[1].getActivityInstanceAtIndex(0), service);
		if (error != BaseErrors.NO_ERROR()) return "$1";
		( , , , , , state) = subProcesses[1].getActivityInstanceData(subProcesses[1].getActivityInstanceAtIndex(0));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity1 in SubprocessB should be completed";
		( , , , , , state) = piMain.getActivityInstanceData(piMain.getActivityInstanceAtIndex(1));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity2 in Main should be completed now";
		// after completing SubprocessB, the third subprocess A2 is synchronous and has no wait activity, so its completion should complete the main process
		if (piMain.getNumberOfActivityInstances() != 3) return "$1";
		if (service.getNumberOfProcessInstances() != 4) return "$1";
		( , , , , , state) = piMain.getActivityInstanceData(piMain.getActivityInstanceAtIndex(2));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity3 in Main should be completed";
		subProcesses[2] = ProcessInstance(service.getProcessInstanceAtIndex(3));

		( , , , , , state) = piMain.getActivityInstanceData(piMain.getActivityInstanceAtIndex(1));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity2 in Main should be completed";
		( , , , , , state) = piMain.getActivityInstanceData(piMain.getActivityInstanceAtIndex(2));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity2 in Main should be completed";
		if (subProcesses[0].getState() != uint8(BpmRuntime.ProcessInstanceState.ACTIVE)) return "$1";
		if (subProcesses[1].getState() != uint8(BpmRuntime.ProcessInstanceState.COMPLETED)) return "SubprocessB should be completed";		
		if (subProcesses[2].getState() != uint8(BpmRuntime.ProcessInstanceState.COMPLETED)) return "SubprocessA2 should be completed";		
		if (piMain.getState() != uint8(BpmRuntime.ProcessInstanceState.COMPLETED)) return "The Main PI should be completed";

		return SUCCESS;
	}

	function getNewTestBpmService() internal returns (TestBpmService) {
		TestBpmService service = new TestBpmService();
		BpmServiceDb serviceDb = new BpmServiceDb();
		SystemOwned(serviceDb).transferSystemOwnership(service);
		AbstractDbUpgradeable(service).acceptDatabase(serviceDb);
		service.setProcessModelRepository(repository);
		service.setApplicationRegistry(applicationRegistry);
		return service;
	}

	// public function to call the BpmRuntimeLib.execute() function via this contract
	function executeGraph() public {
		graph.execute();
	}

}

/**
 * Allows invoking functions and variables that are otherwise unreachable
 */
contract TestBpmService is DefaultBpmService {

	function setProcessModelRepository(ProcessModelRepository _repo) external {
		modelRepository = _repo;
	}

	function setApplicationRegistry(ApplicationRegistry _registry) external {
		applicationRegistry = _registry;
	}

	function addProcessInstance(ProcessInstance _pi) external {
		BpmServiceDb(database).addProcessInstance(_pi);
	}

	function getDatabase() external view returns (BpmServiceDb) {
		return BpmServiceDb(database);
	}
}

/**
 * Helper contract to provide a DataStorage location
 */
contract TestData is AbstractDataStorage {}

/**
 * Helper contract extending DefaultProcessInstance to test internal functions
 */
contract TestProcessInstance is DefaultProcessInstance {

	bytes32 constant EMPTY = "";

	constructor(ProcessDefinition _pd) DefaultProcessInstance(_pd, 0x0, EMPTY) public {}

	function resolveParticipant(bytes32 _assignee) public view returns (address, bytes32) {
		return BpmRuntimeLib.resolveParticipant(self.processDefinition.getModel(), DataStorage(this), _assignee);
	}
}

/**
 * Application that produces a REVERT until it's reset.
 */
contract FailureServiceApplication is Application {

	bool public fail = true;

	// completion function that cannot be invoked two times in the same process without resetting the app
	function complete(bytes32, bytes32, address) public {
		require(!fail);
		// TODO get/set IN/OUT data to test performer access
	}

	function reset() external {
		fail = false;
	}
}

/**
 * Test application which uses IN/OUT data mappings to communicate with the process.
 * 
 */
contract EventApplication is Application {

	BpmService bpmService;
	bytes32 public inDataIdGreeting = "Greeting";
	bytes32 public inDataIdAge = "ClientAge";
	bytes32 public outDataIdResult = "Result";
	bytes32 public activityInstanceId;
	uint ageDuringCompletion;
	string greetingDuringCompletion;

	constructor(BpmService _bpmService) public {
		bpmService = _bpmService;
	}

	// the completion function should have access to the IN data mappings, so we're saving the age field here for later verification
	function complete(bytes32 _aiId, bytes32, address) public {
		activityInstanceId = _aiId;
		ageDuringCompletion = retrieveInDataAge();
		greetingDuringCompletion = retrieveInDataGreeting();
	}

	/// writes the bytes32 to the outDataIdResult mapping and completes the activity
	function completeExternal(bytes32 _aiId, bytes32 _value) external returns (uint error) {
		bpmService.setActivityOutDataAsBytes32(_aiId, outDataIdResult, _value);
		address pi = bpmService.getProcessInstanceForActivity(_aiId);
		error = ProcessInstance(pi).completeActivity(_aiId, bpmService);
	}

	/// returns the age IN data saved in the completion function
	function getAgeDuringCompletion() external view returns (uint) {
		return ageDuringCompletion;
	}

	/// returns the greeting IN data saved in the completion function
	function getGreetingDuringCompletion() external view returns (string) {
		return greetingDuringCompletion;
	}

	/// allows invoking the inDataIdAge mapping via the application
	function retrieveInDataAge() public view returns (uint) {
		return bpmService.getActivityInDataAsUint(activityInstanceId, inDataIdAge);
	}

	/// allows invoking the inDataIdGreeting mapping via the application
	function retrieveInDataGreeting() public view returns (string) {
		return bpmService.getActivityInDataAsString(activityInstanceId, inDataIdGreeting);
	}
}

/**
 * TransitionConditionResolver which can be configured easily for testing the graph
 */
contract TestConditionResolver is TransitionConditionResolver {

	mapping(bytes32 => bool) conditions;
	mapping(bytes32 => bool) transitions;

	function addCondition(bytes32 _sourceId, bytes32 _targetId, bool _value) public {
		bytes32 id = keccak256(abi.encodePacked(_sourceId, _targetId));
		transitions[id] = true;
		conditions[id] = _value;
	}

    function resolveTransitionCondition(bytes32 _sourceId, bytes32 _targetId) external view returns (bool) {
		bytes32 id = keccak256(abi.encodePacked(_sourceId, _targetId));
		if (transitions[id])
			return conditions[keccak256(abi.encodePacked(_sourceId, _targetId))];
		else
			return true;
	}
}
