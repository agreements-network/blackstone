pragma solidity ^0.5.12;

import "commons-base/BaseErrors.sol";
import "commons-base/SystemOwned.sol";
import "commons-utils/ArrayUtilsLib.sol";
import "commons-utils/TypeUtilsLib.sol";
import "commons-collections/AbstractDataStorage.sol";
import "commons-management/AbstractDbUpgradeable.sol";
import "commons-management/DefaultArtifactsRegistry.sol";
import "commons-auth/DefaultOrganization.sol";
import "commons-auth/DefaultUserAccount.sol";
import "bpm-model/ProcessModelRepository.sol";
// import "bpm-model/ProcessModelRepositoryDb.sol";
// import "bpm-model/DefaultProcessModelRepository.sol";
import "bpm-model/DefaultProcessModel.sol";
import "bpm-model/DefaultProcessDefinition.sol";

import "bpm-runtime/BpmRuntime.sol";
import "bpm-runtime/BpmRuntimeLib.sol";
import "bpm-runtime/BpmServiceDb.sol";
import "bpm-runtime/DefaultBpmService.sol";
import "bpm-runtime/DefaultProcessInstance.sol";
import "bpm-runtime/ApplicationRegistry.sol";
// import "bpm-runtime/ApplicationRegistryDb.sol";
// import "bpm-runtime/DefaultApplicationRegistry.sol"; 
import "bpm-runtime/Application.sol";
import "bpm-runtime/TransitionConditionResolver.sol";

contract BpmServiceTest {

	using TypeUtilsLib for bytes32;
	using TypeUtilsLib for bytes;
	using ArrayUtilsLib for bytes32[];
	using BpmRuntimeLib for BpmRuntime.ProcessGraph;
	using BpmRuntimeLib for BpmRuntime.ActivityNode;
	using BpmRuntimeLib for BpmRuntime.Transition;
	using BpmRuntimeLib for ProcessDefinition;

	string constant EMPTY_STRING = "";
	string constant functionSigSetActivityOutDataAsBytes32 = "setActivityOutDataAsBytes32(bytes32,bytes32,bytes32)";
	string constant functionSigGetActivityInDataAsUint = "getActivityInDataAsUint(bytes32,bytes32)";
	string constant functionSigRetrieveInDataAge = "retrieveInDataAge()";
	string constant functionSigExecuteGraph = "executeGraph()";
	string constant functionSigInitRuntime = "initRuntime()";
	string constant functionSigStartProcessFromRepository = "startProcessFromRepository(bytes32,bytes32,bytes32)";
	string constant functionSigGetActivityInDataAsBytes32 = "getActivityInDataAsBytes32(bytes32,bytes32)";
	string constant functionSigResolveTransitionCondition = "resolveTransitionCondition(bytes32,bytes32)";
	string constant functionSigSetActivityOutDataAsBool = "setActivityOutDataAsBool(bytes32,bytes32,bool)";
	string constant functionSigCompleteActivity = "completeActivity(bytes32,address)";
	string constant functionSigForwardCall = "forwardCall(address,bytes)";
	string constant functionSigGetActivityInDataAsBool = "getActivityInDataAsBool(bytes32,bytes32)";
	string constant functionSigSetActivityOutDataAsUint = "setActivityOutDataAsUint(bytes32,bytes32,uint256)";
	string constant functionSigCompleteActivityWithUintData = "completeActivityWithUintData(bytes32,address,bytes32,uint256)";

	// re-usable variables for return values
	uint error;
	address addr;
	bool success;

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
	bytes32 eventId1 = "event1";
	bytes32 marker1 = "marker1";
	bytes32 marker2 = "marker2";

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
	string constant dummyModelFileReference = "{json grant}";
	bytes32 EMPTY = "";

	ProcessModelRepository processModelRepository;
	ApplicationRegistry applicationRegistry;
	ArtifactsRegistry artifactsRegistry;
	ProcessModel defaultProcessModelImpl = new DefaultProcessModel();
	ProcessDefinition defaultProcessDefinitionImpl = new DefaultProcessDefinition();
	ProcessInstance defaultProcessInstanceImpl = new DefaultProcessInstance();
	string constant serviceIdModelRepository = "agreements-network/services/ProcessModelRepository";
	string constant serviceIdApplicationRegistry = "agreements-network/services/ApplicationRegistry";

	// graph needs to be a storage variable to mimic behavior inside ProcessInstance
	BpmRuntime.ProcessGraph graph;

	/**
	 * @dev Constructor for the test creates the dependencies that the BpmService needs
	 */
	constructor (ProcessModelRepository _processModelRepository, ApplicationRegistry _applicationRegistry) public {
		// // ProcessModelRegistry
		// ProcessModelRepositoryDb modelDb = new ProcessModelRepositoryDb();
		// processModelRepository = new DefaultProcessModelRepository();
		// modelDb.transferSystemOwnership(processModelRepository);
		// require(AbstractDbUpgradeable(processModelRepository).acceptDatabase(modelDb), "ProcessModelRepositoryDb not set");
		processModelRepository = _processModelRepository;

		// // ApplicatonRegistry
		// ApplicationRegistryDb appDb = new ApplicationRegistryDb();
		// applicationRegistry = new DefaultApplicationRegistry();
		// appDb.transferSystemOwnership(applicationRegistry);
		// require(AbstractDbUpgradeable(applicationRegistry).acceptDatabase(appDb), "ApplicationRegistryDb not set");
		applicationRegistry = _applicationRegistry;

		// ArtifactsRegistry
		artifactsRegistry = new DefaultArtifactsRegistry();
        DefaultArtifactsRegistry(address(artifactsRegistry)).initialize();
		artifactsRegistry.registerArtifact(serviceIdModelRepository, address(processModelRepository), processModelRepository.getArtifactVersion(), true);
		artifactsRegistry.registerArtifact(serviceIdApplicationRegistry, address(applicationRegistry), applicationRegistry.getArtifactVersion(), true);
        artifactsRegistry.registerArtifact(processModelRepository.OBJECT_CLASS_PROCESS_MODEL(), address(defaultProcessModelImpl), defaultProcessModelImpl.getArtifactVersion(), true);
        artifactsRegistry.registerArtifact(processModelRepository.OBJECT_CLASS_PROCESS_DEFINITION(), address(defaultProcessDefinitionImpl), defaultProcessDefinitionImpl.getArtifactVersion(), true);
		ArtifactsFinderEnabled(address(processModelRepository)).setArtifactsFinder(address(artifactsRegistry));
	}

	/**
	 * @dev Creates and returns a new TestBpmService using an existing ProcessModelRepository and ApplicationRegistry.
	 * This function can be used in the beginning of a test to have a fresh BpmService instance.
	 */
	function createNewTestBpmService() internal returns (TestBpmService) {
		TestBpmService service = new TestBpmService(serviceIdModelRepository, serviceIdApplicationRegistry);
		BpmServiceDb serviceDb = new BpmServiceDb();
		SystemOwned(serviceDb).transferSystemOwnership(address(service));
		AbstractDbUpgradeable(service).acceptDatabase(address(serviceDb));
		service.setArtifactsFinder(address(artifactsRegistry));
        artifactsRegistry.registerArtifact(service.OBJECT_CLASS_PROCESS_INSTANCE(), address(defaultProcessInstanceImpl), defaultProcessInstanceImpl.getArtifactVersion(), true);
		// check that dependencies are wired correctly
		require (address(service.getApplicationRegistry()) != address(0), "ApplicationRegistry in new BpmService not found");
		require (address(service.getProcessModelRepository()) != address(0), "ProcessModelRepository in new BpmService not found");
		require (address(service.getApplicationRegistry()) == address(applicationRegistry), "ApplicationRegistry in BpmService address mismatch");
		require (address(service.getProcessModelRepository()) == address(processModelRepository), "ProcessModelRepository in BpmService address mismatch");
		return service;
	}

	/**
	 * @dev Tests a process graph consisting of sequential activities.
	 */
	function testProcessGraphSequential() external returns (string memory) {

		// Graph: activity1 -> activity2 -> activity3
		graph.clear();

		// add places
		graph.addActivity(activityId1);
		graph.addActivity(activityId2);
		graph.addActivity(activityId3);
	
		// add connections
		graph.connect(activityId1, BpmModel.ModelElementType.ACTIVITY, activityId2, BpmModel.ModelElementType.ACTIVITY, "");
		graph.connect(activityId2, BpmModel.ModelElementType.ACTIVITY, activityId3, BpmModel.ModelElementType.ACTIVITY, "");

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
	 * @dev Tests a process graph consisting of sequential activities.
	 */
	function testProcessGraphColoredPaths() external returns (string) {

		//              coloredPath -> activity3
		//             /  
		// Graph: activity1 -> activity2
		//                          \
		//                           coloredPath -> activity4
		graph.clear();

		// add places
		graph.addActivity(activityId1);
		graph.addActivity(activityId2);
		graph.addActivity(activityId3);
		graph.addActivity(activityId4);
	
		// add connections
		graph.connect(activityId1, BpmModel.ModelElementType.ACTIVITY, activityId2, BpmModel.ModelElementType.ACTIVITY, EMPTY);
		bytes32 coloredTransition1Id = graph.connect(activityId1, BpmModel.ModelElementType.ACTIVITY, activityId3, BpmModel.ModelElementType.ACTIVITY, marker1);
		bytes32 coloredTransition2Id = graph.connect(activityId2, BpmModel.ModelElementType.ACTIVITY, activityId4, BpmModel.ModelElementType.ACTIVITY, marker2);

		// Test graph connectivity
		if (graph.activityKeys.length != 4) return "There should be 4 activities in the graph";
		if (graph.transitionKeys.length != 3) return "There should be 3 transitions in the graph";

		if (graph.activities[activityId1].node.inputs.length != 0) return "activity1 should have 0 in arcs";
		if (graph.activities[activityId1].node.outputs.length != 2) return "activity1 should have 2 out arcs with index 1 being colored";
		if (graph.transitions[graph.transitionKeys[0]].node.inputs.length != 1) return "transition1 should have 1 in arcs";
		if (graph.transitions[graph.transitionKeys[0]].node.outputs.length != 1) return "transition1 should have 1 out arcs";
		if (graph.activities[activityId2].node.inputs.length != 1) return "activity2 should have 1 in arcs";
		if (graph.activities[activityId2].node.outputs.length != 1) return "activity2 should have 1 out arc for the colored transition";
		if (graph.transitions[graph.transitionKeys[1]].node.inputs.length != 1) return "transition2 should have 1 in arcs";
		if (graph.transitions[graph.transitionKeys[1]].node.outputs.length != 1) return "transition2 should have 1 out arcs";
		if (graph.activities[activityId3].node.inputs.length != 1) return "activity3 should have 1 in arcs";
		if (graph.activities[activityId3].node.outputs.length != 0) return "activity3 should have 0 out arcs";
		if (graph.transitions[graph.transitionKeys[2]].node.inputs.length != 1) return "transition3 should have 1 in arcs";
		if (graph.transitions[graph.transitionKeys[2]].node.outputs.length != 1) return "transition3 should have 1 out arcs";
		if (graph.activities[activityId4].node.inputs.length != 1) return "activity4 should have 1 in arcs";
		if (graph.activities[activityId4].node.outputs.length != 0) return "activity4 should have 0 out arcs";
		// check correct colored indexing
		if (graph.activities[activityId1].node.outputs[0] != graph.activities[activityId2].node.inputs[0]) return "ouputs[0] of activity1 should be the transition to activity2";
		if (graph.activities[activityId1].node.outputs[1] != graph.activities[activityId3].node.inputs[0]) return "ouputs[1] of activity1 should be the transition to activity3";
		if (graph.activities[activityId2].node.outputs[0] != graph.activities[activityId4].node.inputs[0]) return "ouputs[0] of activity2 should be the transition to activity4";
		if (graph.transitions[coloredTransition1Id].marker != marker1) return "ColoredTransition1 should have marker1";
		if (graph.transitions[coloredTransition2Id].marker != marker2) return "ColoredTransition2 should have marker2";

		// on the first activity, the done marker as well as the colored path are activited
		graph.activities[activityId1].done = true;
		// test helper functions
		if (graph.isTransitionEnabled(graph.transitionKeys[0]) != true) return "Transition1 should be enabled";
		if (graph.isTransitionEnabled(coloredTransition1Id) != false) return "ColoredTransition1 should not be enabled";
		if (graph.isTransitionEnabled(coloredTransition2Id) != false) return "ColoredTransition2 should not be enabled";
		graph.activities[activityId1].markers[marker1] = true;
		if (graph.isTransitionEnabled(coloredTransition1Id) != true) return "ColoredTransition1 should now be enabled after marker was set";

		// Test token movement
	  	if (graph.activities[activityId1].done != true) return "State1: activity1 should have 1 completion markers";
		if (graph.activities[activityId2].done != false) return "State1: activity2 should have 0 completion markers";
		if (graph.activities[activityId3].done != false) return "State1: activity3 should have 0 completion markers";
		if (graph.activities[activityId4].done != false) return "State1: activity3 should have 0 completion markers";

		graph.execute();

		if (graph.activities[activityId1].done != false) return "State2: activity1 should have 0 completion markers";
	  	if (graph.activities[activityId1].markers[marker1] != false) return "State1: activity1 should have no colored marker1 after transition fired";
		if (graph.activities[activityId2].ready != true) return "State2: activity2 should have 1 activation markers";
		if (graph.activities[activityId3].ready != true) return "State2: activity3 should have 1 activation markers";
		if (graph.activities[activityId4].ready != false) return "State2: activity4 should have 0 activation markers";

		graph.activities[activityId2].markers[marker2] = true;
		if (graph.isTransitionEnabled(coloredTransition2Id) != true) return "Transition3 should be enabled now after marker was set";

		graph.execute();

	  	if (graph.activities[activityId2].markers[marker2] != false) return "State4: activity2 should have no colored marker2 after transition fired";
		if (graph.activities[activityId4].ready != true) return "State3: activity4 should have 1 activation markers";

		return SUCCESS;
	}

	/**
	 * @dev Tests a process graph containing AND split and join transitions
	 */
	function testProcessGraphParallelGateway() external returns (string memory) {

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
		graph.connect(activityId1, BpmModel.ModelElementType.ACTIVITY, transitionId1, BpmModel.ModelElementType.GATEWAY, "");
		graph.connect(transitionId1, BpmModel.ModelElementType.GATEWAY, activityId2, BpmModel.ModelElementType.ACTIVITY, "");
		graph.connect(transitionId1, BpmModel.ModelElementType.GATEWAY, activityId3, BpmModel.ModelElementType.ACTIVITY, "");
		graph.connect(activityId2, BpmModel.ModelElementType.ACTIVITY, transitionId2, BpmModel.ModelElementType.GATEWAY, "");
		graph.connect(activityId3, BpmModel.ModelElementType.ACTIVITY, transitionId2, BpmModel.ModelElementType.GATEWAY, "");
		graph.connect(transitionId2, BpmModel.ModelElementType.GATEWAY, activityId4, BpmModel.ModelElementType.ACTIVITY, "");

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
	function testProcessGraphExclusiveGateway() external returns (string memory) {

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
		graph.connect(activityId1, BpmModel.ModelElementType.ACTIVITY, transitionId1, BpmModel.ModelElementType.GATEWAY, "");
		graph.connect(transitionId1, BpmModel.ModelElementType.GATEWAY, activityId2, BpmModel.ModelElementType.ACTIVITY, "");
		graph.connect(transitionId1, BpmModel.ModelElementType.GATEWAY, activityId3, BpmModel.ModelElementType.ACTIVITY, "");
		graph.connect(transitionId1, BpmModel.ModelElementType.GATEWAY, activityId4, BpmModel.ModelElementType.ACTIVITY, "");
		graph.connect(activityId2, BpmModel.ModelElementType.ACTIVITY, transitionId2, BpmModel.ModelElementType.GATEWAY, "");
		graph.connect(activityId3, BpmModel.ModelElementType.ACTIVITY, transitionId2, BpmModel.ModelElementType.GATEWAY, "");
		graph.connect(activityId4, BpmModel.ModelElementType.ACTIVITY, transitionId2, BpmModel.ModelElementType.GATEWAY, "");
		graph.connect(transitionId2, BpmModel.ModelElementType.GATEWAY, activityId5, BpmModel.ModelElementType.ACTIVITY, "");

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
	function testProcessGraphExclusiveGatewayWithDefault() external returns (string memory) {

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
		graph.connect(activityId1, BpmModel.ModelElementType.ACTIVITY, transitionId1, BpmModel.ModelElementType.GATEWAY, "");
		graph.connect(transitionId1, BpmModel.ModelElementType.GATEWAY, activityId2, BpmModel.ModelElementType.ACTIVITY, "");
		graph.connect(transitionId1, BpmModel.ModelElementType.GATEWAY, activityId3, BpmModel.ModelElementType.ACTIVITY, "");

		// add TransitionConditionResolver with all transitions false
		TestConditionResolver resolver = new TestConditionResolver();
		resolver.addCondition(transitionId1, activityId2, false);
		resolver.addCondition(transitionId1, activityId3, false);

		graph.processInstance = address(resolver); // the simple test implementation of a resolver is used here
		graph.activities[activityId1].done = true; // start execution by marking 1st activity done

		// test REVERT for XOR gateway with no outputs to fire
		if (graph.isTransitionEnabled(graph.transitionKeys[0]) != true) return "Transition1 should be enabled";
		(success, ) = address(this).call(abi.encodeWithSignature(functionSigExecuteGraph));
		if (success)
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
	function testProcessGraphMultiGateway() external returns (string memory) {

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
		graph.connect(activityId1, BpmModel.ModelElementType.ACTIVITY, transitionId1, BpmModel.ModelElementType.GATEWAY, "");
		graph.connect(transitionId1, BpmModel.ModelElementType.GATEWAY, activityId2, BpmModel.ModelElementType.ACTIVITY, "");
		graph.connect(transitionId1, BpmModel.ModelElementType.GATEWAY, transitionId2, BpmModel.ModelElementType.GATEWAY, "");
		bytes32 hiddenPlace1Id = graph.activityKeys[graph.activityKeys.length-1]; // an artificial activity was added between the two transitions. Save ID for later
		graph.connect(transitionId2, BpmModel.ModelElementType.GATEWAY, activityId3, BpmModel.ModelElementType.ACTIVITY, "");
		graph.connect(transitionId2, BpmModel.ModelElementType.GATEWAY, activityId4, BpmModel.ModelElementType.ACTIVITY, "");
		graph.connect(activityId3, BpmModel.ModelElementType.ACTIVITY, transitionId3, BpmModel.ModelElementType.GATEWAY, "");
		graph.connect(activityId4, BpmModel.ModelElementType.ACTIVITY, transitionId3, BpmModel.ModelElementType.GATEWAY, "");
		graph.connect(activityId2, BpmModel.ModelElementType.ACTIVITY, transitionId4, BpmModel.ModelElementType.GATEWAY, "");
		graph.connect(transitionId3, BpmModel.ModelElementType.GATEWAY, transitionId4, BpmModel.ModelElementType.GATEWAY, "");
		bytes32 hiddenPlace2Id = graph.activityKeys[graph.activityKeys.length-1];  // an artificial activity was added between the two transitions. Save ID for later
		graph.connect(transitionId4, BpmModel.ModelElementType.GATEWAY, activityId5, BpmModel.ModelElementType.ACTIVITY, "");

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
	 * @dev Tests a process graph containing a looping pattern based on a condition
	 * using artificial activities between the gateways.
	 */
	function testProcessGraphConditionalLoop() external returns (string memory) {

		//                               
		// Graph: activity1 -> XOR JOIN ->  -------- activity2 -------> activity3 ------> XOR SPLIT -> activity5
		//                        |                                                          |
		//                         \<---------------------- activity4 <---------------------/
		

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
		graph.connect(activityId1, BpmModel.ModelElementType.ACTIVITY, transitionId1, BpmModel.ModelElementType.GATEWAY, "");
		graph.connect(transitionId1, BpmModel.ModelElementType.GATEWAY, activityId2, BpmModel.ModelElementType.ACTIVITY, "");
		graph.connect(activityId2, BpmModel.ModelElementType.ACTIVITY, activityId3, BpmModel.ModelElementType.ACTIVITY, "");
		graph.connect(activityId3, BpmModel.ModelElementType.ACTIVITY, transitionId2, BpmModel.ModelElementType.GATEWAY, "");
		graph.connect(transitionId2, BpmModel.ModelElementType.GATEWAY, activityId5, BpmModel.ModelElementType.ACTIVITY, "");
		graph.connect(transitionId2, BpmModel.ModelElementType.GATEWAY, activityId4, BpmModel.ModelElementType.ACTIVITY, "");
		graph.connect(activityId4, BpmModel.ModelElementType.ACTIVITY, transitionId1, BpmModel.ModelElementType.GATEWAY, "");

		// Test graph connectivity
		if (graph.activityKeys.length != 5) return "There should be 5 activities in the graph";
		if (graph.transitionKeys.length != 3) return "There should be 3 transitions in the graph including one artificial transition to connect two activities ";
		if (graph.activities[activityId1].node.inputs.length != 0) return "activity1 should have 0 in arcs";
		if (graph.activities[activityId1].node.outputs.length != 1) return "activity1 should have 1 out arcs";
		if (graph.transitions[transitionId1].node.inputs.length != 2) return "transition1 should have 2 in arcs";
		if (graph.transitions[transitionId1].node.outputs.length != 1) return "transition1 should have 1 out arcs";
		if (graph.activities[activityId2].node.inputs.length != 1) return "activity2 should have 1 in arcs";
		if (graph.activities[activityId2].node.outputs.length != 1) return "activity2 should have 1 out arcs";
		if (graph.activities[activityId3].node.inputs.length != 1) return "activity3 should have 1 in arcs";
		if (graph.activities[activityId3].node.outputs.length != 1) return "activity3 should have 1 out arcs";
		if (graph.activities[activityId4].node.inputs.length != 1) return "activity4 should have 1 in arcs";
		if (graph.activities[activityId4].node.outputs.length != 1) return "activity4 should have 1 out arcs";
		if (graph.transitions[transitionId2].node.inputs.length != 1) return "transition3 should have 1 in arcs";
		if (graph.transitions[transitionId2].node.outputs.length != 2) return "transition3 should have 2 out arcs";
		if (graph.activities[activityId5].node.inputs.length != 1) return "activity5 should have 1 in arcs";
		if (graph.activities[activityId5].node.outputs.length != 0) return "activity5 should have 0 out arcs";

		TestConditionResolver resolver = new TestConditionResolver();
		resolver.addCondition(transitionId2, activityId4, true);
		resolver.addCondition(transitionId2, activityId5, false);
		graph.processInstance = address(resolver); // the simple test implementation of a resolver is used here
		graph.activities[activityId1].done = true; // start execution by marking 1st activity done

		if (graph.isTransitionEnabled(transitionId1) == false) return "Transition1 should be enabled";
		if (graph.isTransitionEnabled(transitionId2) == true) return "Transition2 should not be enabled at graph start";

		// Before 1st iteration
		if (graph.activities[activityId2].done) return "State1: activity2 should have 0 completion markers";
		if (graph.activities[activityId3].done) return "State1: activity3 should have 0 completion markers";

		graph.execute();

		if (graph.isTransitionEnabled(transitionId1) == true) return "Transition1 should have fired and not be enabled anymore";
		if (graph.activities[activityId1].done) return "State2: activity1 should have 0 completion markers";
		if (graph.activities[activityId2].ready == false) return "State2: activity2 should have 1 activation markers";
		if (graph.activities[activityId3].ready == true) return "State2: activity3 should have 0 activation markers";

		// execute twice to move to activity4
		graph.activities[activityId2].ready = false;
		graph.activities[activityId2].done = true;
		graph.execute();
		graph.activities[activityId3].ready = false;
		graph.activities[activityId3].done = true;
		graph.execute();

		if (graph.activities[activityId4].ready == false) return "State3: activity4 should have 1 activation markers";
		if (graph.activities[activityId2].ready == true) return "State3: activity2 should have 0 activation markers before second activation";
		if (graph.activities[activityId2].done == true) return "State3: activity2 should have 0 completion markers before second activation";
		if (graph.activities[activityId3].ready == true) return "State3: activity3 should have 0 activation markers before second activation";
		if (graph.activities[activityId3].done == true) return "State3: activity3 should have 0 completion markers before second activation";

		graph.activities[activityId4].ready = false;
		graph.activities[activityId4].done = true;
		graph.execute();

		if (graph.activities[activityId4].done == true) return "State4: activity4 should have 0 completion markers after initiating second turn";
		if (graph.activities[activityId2].ready == false) return "State4: activity2 should have 1 activation markers on second activation";
		if (graph.activities[activityId2].done == true) return "State3: activity2 should have 0 completion markers on second activation";
		if (graph.activities[activityId3].ready == true) return "State3: activity3 should have 0 activation markers before second activation";
		if (graph.activities[activityId3].done == true) return "State3: activity3 should have 0 completion markers before second activation";

		return SUCCESS;
	}

	/**
	 * @dev Tests the creation and configuration of a process instance from a process definition,
	 * specifically the conversion into a BpmRuntime.ProcessGraph. The test covers regular activities, intermediate events,
	 * and XOR gateways.
	 */
	function testProcessGraphCreation() external returns (string memory) {

		//                                              /--> activity3 -------------\
		// Graph: activity1 -> event1 -> XOR SPLIT --                             --> XOR JOIN -> activity6
		//                                              \-> activity4 -> activity5 -/

		bytes32 bytes32Value;

		(error, addr) = processModelRepository.createProcessModel("testModel2", [1,0,0], modelAuthor, false, dummyModelFileReference);
		if (addr == address(0)) return "Unable to create a ProcessModel";
		ProcessModel pm = ProcessModel(addr);

		addr = pm.createProcessDefinition("ProcessDefinition1", address(artifactsRegistry));
		ProcessDefinition pd = ProcessDefinition(addr);

		pd.createActivityDefinition(activityId1, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createIntermediateEvent(eventId1, BpmModel.EventType.TIMER_DURATION, BpmModel.IntermediateEventBehavior.CATCHING, EMPTY, EMPTY, address(0), 30, EMPTY_STRING); // 30 sec wait event
		pd.createActivityDefinition(activityId3, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createActivityDefinition(activityId4, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createActivityDefinition(activityId5, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createActivityDefinition(activityId6, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createGateway(transitionId1, BpmModel.GatewayType.XOR);
		pd.createGateway(transitionId2, BpmModel.GatewayType.XOR);
		pd.createTransition(activityId1, eventId1);
		pd.createTransition(eventId1, transitionId1);
		pd.createTransition(transitionId1, activityId3);
		pd.createTransition(transitionId1, activityId4);
		pd.createTransition(activityId4, activityId5);
 		pd.createTransition(activityId3, transitionId2);
		pd.createTransition(activityId5, transitionId2);
		pd.createTransition(transitionId2, activityId6);
		pd.createTransitionConditionForUint(transitionId1, activityId3, "Age", EMPTY, address(0), uint8(DataStorageUtils.COMPARISON_OPERATOR.GTE), 18);
		pd.setDefaultTransition(transitionId1, activityId4);

		// Validate to set the start activity and enable runtime configuration
		(success, bytes32Value) = pd.validate();
		if (!success) return bytes32Value.toString();

		ProcessInstance pi = new DefaultProcessInstance();
		pi.initialize(address(pd), address(this), EMPTY);
		graph.configure(pi);
		if (graph.processInstance != address(pi)) return "ProcessGraph.configure() should have set the process instance on the graph";

		if (graph.activityKeys.length != 6) return "There should be 6 activities in the ProcessGraph";
		if (graph.transitionKeys.length != 4) return "There should be 4 transitions in the ProcessGraph";
		if (!graph.activities[activityId1].exists) return "Activity1 not found in graph.";
		if (!graph.activities[eventId1].exists) return "Event1 not found in graph.";
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
		if (graph.activities[eventId1].node.inputs.length != 1) return "Event1 should have 1 inputs.";
		if (graph.activities[eventId1].node.outputs.length != 1) return "Event1 should have 1 outputs.";
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

		if (graph.activities[activityId1].node.outputs[0] != graph.activities[eventId1].node.inputs[0]) return "Activity1 and Event1 should share the same transition";
		if (graph.activities[eventId1].node.outputs[0] != graph.activities[activityId3].node.inputs[0]) return "Event1 and Activity3 should share the same transition";
		if (graph.activities[eventId1].node.outputs[0] != graph.activities[activityId4].node.inputs[0]) return "Event1 and Activity4 should share the same transition";
		if (graph.activities[activityId4].node.outputs[0] != graph.activities[activityId5].node.inputs[0]) return "Activity4 and Activity5 should share the same transition";
		if (graph.activities[activityId5].node.outputs[0] != graph.activities[activityId6].node.inputs[0]) return "Activity5 and Activity6 should share the same transition";
		if (graph.activities[activityId3].node.outputs[0] != graph.activities[activityId6].node.inputs[0]) return "Activity3 and Activity6 should share the same transition";

		if (graph.transitions[transitionId1].defaultOutput != activityId4) return "Transition1 should have activity4 as the default output";

		return SUCCESS;
	}

	/**
	 * @dev Uses a simple process flow in order to test BpmService-internal functions.
	 */
	function testInternalProcessExecution() external returns (string memory) {

		(error, addr) = processModelRepository.createProcessModel("testModel3", [1,0,0], modelAuthor, false, dummyModelFileReference);
		if (addr == address(0)) return "Unable to create a ProcessModel";
		ProcessModel pm = ProcessModel(addr);

		addr = pm.createProcessDefinition("ProcessDefinitionSequence", address(artifactsRegistry));
		ProcessDefinition pd = ProcessDefinition(addr);

		pd.createActivityDefinition(activityId1, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createActivityDefinition(activityId2, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createActivityDefinition(activityId3, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createTransition(activityId1, activityId2);
		pd.createTransition(activityId2, activityId3);
		
		// Validate to set the start activity and enable runtime configuration
		pd.validate();

		TestBpmService service = createNewTestBpmService();

		ProcessInstance pi = service.createDefaultProcessInstance(address(pd), address(this), EMPTY);

		pi.initRuntime();
		if (pi.getState() != uint(BpmRuntime.ProcessInstanceState.ACTIVE)) return "PI should be ACTIVE after runtime initiation";
		(success, ) = address(pi).call(abi.encodeWithSignature(functionSigInitRuntime));
		if (success)
			return "Attempting to initiate an ACTIVE PI again should revert";
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
	function testGatewayRouting() external returns (string memory) {

		//                                                 /-> activity3 -\
		//                                 /-> XOR SPLIT --                --> XOR JOIN -\
		// Graph: activity1 -> AND SPLIT --                \-> activity4 -/               \
		//                                 \                                               --> AND JOIN -> activity5
		//                                  \-> activity2 --------------------------------/

		bytes32 bytes32Value;
		bytes32 activityId;
		uint8 state;

		(error, addr) = processModelRepository.createProcessModel("routingModel", [1,0,0], modelAuthor, false, dummyModelFileReference);
		if (addr == address(0)) return "Unable to create a ProcessModel";
		ProcessModel pm = ProcessModel(addr);

		addr = pm.createProcessDefinition("RoutingPD", address(artifactsRegistry));
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
		pd.createTransitionConditionForUint(transitionId2, activityId3, "Age", EMPTY, address(0), uint8(DataStorageUtils.COMPARISON_OPERATOR.GTE), 18);
		pd.setDefaultTransition(transitionId2, activityId4);
		
		// Validate to set the start activity and enable runtime configuration
		(success, bytes32Value) = pd.validate();
		if (!success) return bytes32Value.toString();

		TestBpmService service = createNewTestBpmService();

		// Start first process instance with Age not set (should take default transition to activity4)
		ProcessInstance pi1 = service.createDefaultProcessInstance(address(pd), address(this), EMPTY);

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
		ProcessInstance pi2 = service.createDefaultProcessInstance(address(pd), address(this), EMPTY);
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
	 * @dev Tests a conditional looping implementation (see also loop graph test)
	 */
	function testConditionalLoopRoute() external returns (string memory) {

		//                               
		// Graph: activity1 -> XOR JOIN ->  -------- activity2  ------> XOR SPLIT -> activity4
		//                        |                                        |
		//                         \<--------------- activity3 <----------/

		// re-usable variables for return values
		bytes32 activityId;
		uint8 state;

		(error, addr) = processModelRepository.createProcessModel("loopingModel", [1,0,0], modelAuthor, false, dummyModelFileReference);
		if (addr == address(0)) return "Unable to create a ProcessModel";
		ProcessModel pm = ProcessModel(addr);

		addr = pm.createProcessDefinition("LoopingPD", address(artifactsRegistry));
		ProcessDefinition pd = ProcessDefinition(addr);

		pd.createActivityDefinition(activityId1, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createActivityDefinition(activityId2, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.RECEIVE, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createActivityDefinition(activityId3, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.RECEIVE, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createActivityDefinition(activityId4, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createGateway(transitionId1, BpmModel.GatewayType.XOR);
		pd.createGateway(transitionId2, BpmModel.GatewayType.XOR);
		pd.createTransition(activityId1, transitionId1);
		pd.createTransition(transitionId1, activityId2);
		pd.createTransition(activityId2, transitionId2);
		pd.createTransition(transitionId2, activityId3);
		pd.createTransition(transitionId2, activityId4);
 		pd.createTransition(activityId3, transitionId1);
		pd.createTransitionConditionForBool(transitionId2, activityId4, "PaymentsMade", "agreement", address(0), uint8(DataStorageUtils.COMPARISON_OPERATOR.EQ), true);
		pd.setDefaultTransition(transitionId2, activityId3);
		
		// Validate to set the start activity and enable runtime configuration
		(bool valid, bytes32 errorMsg) = pd.validate();
		if (!valid) return errorMsg.toString();

		TestBpmService service = createNewTestBpmService();

		// Start first process instance with Payments Made uninitialized
		ProcessInstance pi = new DefaultProcessInstance();
		pi.initialize(address(pd), address(this), EMPTY);
		graph.configure(pi);

		// inspect the process graph
		if (graph.activityKeys.length != 4) return "There should be 4 activities in the ProcessGraph";
		if (graph.transitionKeys.length != 2) return "There should be 2 transitions in the ProcessGraph";
		if (!graph.activities[activityId1].exists) return "Activity1 not found in graph.";
		if (!graph.activities[activityId2].exists) return "Activity2 not found in graph.";
		if (!graph.activities[activityId3].exists) return "Activity3 not found in graph.";
		if (!graph.activities[activityId4].exists) return "Activity4 not found in graph.";
		if (!graph.transitions[transitionId1].exists) return "Transition1 not found in graph.";
		if (graph.transitions[transitionId1].transitionType != BpmRuntime.TransitionType.XOR) return "Transition1 should be of type XOR.";
		if (!graph.transitions[transitionId2].exists) return "Transition2 not found in graph.";
		if (graph.transitions[transitionId2].transitionType != BpmRuntime.TransitionType.XOR) return "Transition2 should be of type XOR.";

		if (graph.activities[activityId1].node.inputs.length != 0) return "Activity1 should have no inputs.";
		if (graph.activities[activityId1].node.outputs.length != 1) return "Activity1 should have 1 outputs.";
		if (graph.transitions[transitionId1].node.inputs.length != 2) return "Transition1 should have 2 inputs.";
		if (graph.transitions[transitionId1].node.outputs.length != 1) return "Transition1 should have 1 outputs.";
		if (graph.activities[activityId2].node.inputs.length != 1) return "Activity2 should have 1 inputs.";
		if (graph.activities[activityId2].node.outputs.length != 1) return "Activity2 should have 1 outputs.";
		if (graph.transitions[transitionId2].node.inputs.length != 1) return "Transition2 should have 1 inputs.";
		if (graph.transitions[transitionId2].node.outputs.length != 2) return "Transition2 should have 2 outputs.";
		if (graph.activities[activityId3].node.inputs.length != 1) return "Activity3 should have 1 inputs.";
		if (graph.activities[activityId3].node.outputs.length != 1) return "Activity3 should have 1 outputs.";
		if (graph.activities[activityId4].node.inputs.length != 1) return "Activity4 should have 1 inputs.";
		if (graph.activities[activityId4].node.outputs.length != 0) return "Activity4 should have 0 outputs.";

		// start the process execution
		service.addProcessInstance(pi);
		TestData dataStorage = new TestData();
		pi.setDataValueAsAddress("agreement", address(dataStorage));
	
		// verify expected routing decisions ahead of start
		if (pi.resolveTransitionCondition(transitionId2, activityId4)) return "TransitionCondition to activity4 should be false with default value";

		error = service.startProcessInstance(pi);
		if (error != BaseErrors.NO_ERROR()) return "Unexpected error during process start of p1";
		if (pi.getState() != uint8(BpmRuntime.ProcessInstanceState.ACTIVE)) return "p1 should be active";

		if (pi.getNumberOfActivityInstances() != 2) return "There should be 2 AIs total in pi after start";

		pi.completeActivity(pi.getActivityInstanceAtIndex(1), service);
		if (pi.getNumberOfActivityInstances() != 3) return "There should be 3 AIs total in pi after activity2 first completion";
		(activityId, , , , , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(2));
		if (activityId != activityId3) return "Process should be in activity3 in first round";
		if (state != uint8(BpmRuntime.ActivityInstanceState.SUSPENDED)) return "activity3 should be suspended";

		pi.completeActivity(pi.getActivityInstanceAtIndex(2), service);
		if (pi.getNumberOfActivityInstances() != 4) return "There should be 4 AIs total in pi after activity3 first completion";
		(activityId, , , , , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(3));
		if (activityId != activityId2) return "Process should be in activity2 in second round";
		if (state != uint8(BpmRuntime.ActivityInstanceState.SUSPENDED)) return "activity2 should be suspended";

		pi.completeActivity(pi.getActivityInstanceAtIndex(3), service);
		if (pi.getNumberOfActivityInstances() != 5) return "There should be 5 AIs total in pi after activity2 second completion";
		(activityId, , , , , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(4));
		if (activityId != activityId3) return "Process should be in activity3 in second round";
		if (state != uint8(BpmRuntime.ActivityInstanceState.SUSPENDED)) return "activity3 should be suspended";

		pi.completeActivity(pi.getActivityInstanceAtIndex(4), service);
		if (pi.getNumberOfActivityInstances() != 6) return "There should be 6 AIs total in pi after activity3 second completion";
		(activityId, , , , , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(5));
		if (activityId != activityId2) return "Process should be in activity2 in third round";
		if (state != uint8(BpmRuntime.ActivityInstanceState.SUSPENDED)) return "activity2 should be suspended";

		dataStorage.setDataValueAsBool("PaymentsMade", true); // exit condition

		pi.completeActivity(pi.getActivityInstanceAtIndex(5), service);
		if (pi.getNumberOfActivityInstances() != 7) return "There should be 5 AIs total in pi after activity2 second completion";
		(activityId, , , , , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(6));
		if (activityId != activityId4) return "Process should be in activity4 at end";
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "activity4 should be completed";

		return SUCCESS;
	}

	/**
	 * @dev Tests a graph with multiple successive gateways and conditions and default transitions to ensure the logic is translated correctly
	 */
	function testSuccessiveGatewaysRoute() external returns (string memory) {

		//                                   default                               condition
		// Graph: activity1 -> XOR SPLIT ---/-----------------> XOR JOIN/SPLIT --------------------> XOR JOIN-> activity4
		//                               |                    |               |                    |
		//                    condition   \--- activity2 --->/        default  \-/- activity3 --->/

		// re-usable variables for return values
		bytes32 activityId;

		(error, addr) = processModelRepository.createProcessModel("twoGatewayModel", [1,0,0], modelAuthor, false, dummyModelFileReference);
		if (addr == address(0)) return "Unable to create a ProcessModel";
		ProcessModel pm = ProcessModel(addr);

		addr = pm.createProcessDefinition("TwoGatewayPD", address(artifactsRegistry));
		ProcessDefinition pd = ProcessDefinition(addr);
		
		// the process definition is using straight-through activities
		pd.createActivityDefinition(activityId1, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createActivityDefinition(activityId2, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createActivityDefinition(activityId3, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createActivityDefinition(activityId4, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		pd.createGateway(transitionId1, BpmModel.GatewayType.XOR);
		pd.createGateway(transitionId2, BpmModel.GatewayType.XOR);
		pd.createGateway(transitionId3, BpmModel.GatewayType.XOR);
		pd.createTransition(activityId1, transitionId1);
		pd.createTransition(transitionId1, transitionId2);
		pd.createTransition(transitionId1, activityId2);
 		pd.createTransition(activityId2, transitionId2);
		pd.createTransition(transitionId2, transitionId3);
		pd.createTransition(transitionId2, activityId3);
 		pd.createTransition(activityId3, transitionId3);
		pd.createTransition(transitionId3, activityId4);

		pd.createTransitionConditionForUint(transitionId1, activityId2, "Year", "agreement", address(0), uint8(DataStorageUtils.COMPARISON_OPERATOR.LT), uint(1978));
		pd.setDefaultTransition(transitionId1, transitionId2);
		pd.createTransitionConditionForString(transitionId2, transitionId3, "Lastname", "agreement", address(0), uint8(DataStorageUtils.COMPARISON_OPERATOR.EQ), "Smith");
		pd.setDefaultTransition(transitionId2, activityId3);
		
		// Validate to set the start activity and enable runtime configuration
		(bool valid, bytes32 errorMsg) = pd.validate();
		if (!valid) return errorMsg.toString();

		TestBpmService service = createNewTestBpmService();

		// Start first process instance with Payments Made uninitialized
		ProcessInstance pi = new DefaultProcessInstance();
		pi.initialize(address(pd), address(this), EMPTY);

		// produce a copy of the ProcessGraph for inspection
		graph.configure(pi);
		if (graph.activityKeys.length != 6) return "There should be 6 activities in the ProcessGraph (including 2 artificial between the gateways)";
		if (graph.transitionKeys.length != 3) return "There should be 3 transitions in the ProcessGraph";
		// scipping complete graph details here (they're covered in other tests) and concentrating on the essential
		if (graph.transitions[transitionId1].node.inputs.length != 1) return "Transition1 should have 1 inputs.";
		if (graph.transitions[transitionId1].node.outputs.length != 2) return "Transition1 should have 2 outputs.";
		if (graph.transitions[transitionId2].node.inputs.length != 2) return "Transition2 should have 2 inputs.";
		if (graph.transitions[transitionId2].node.outputs.length != 2) return "Transition2 should have 2 outputs.";
		if (graph.transitions[transitionId3].node.inputs.length != 2) return "Transition3 should have 2 inputs.";
		if (graph.transitions[transitionId3].node.outputs.length != 1) return "Transition3 should have 1 outputs.";
		// verify correct setup of default transitions
		if (graph.transitions[transitionId1].defaultOutput != keccak256(abi.encodePacked(transitionId1, transitionId2)))
			return "The default output of transition1 should be the artificial key of (t1+t2)";
		if (graph.transitions[transitionId2].defaultOutput != activityId3)
			return "The default output of transition2 should be activityId3";

		TestData dataStorage = new TestData();
		pi.setDataValueAsAddress("agreement", address(dataStorage));

		// FIRST RUN: Set conditions to make process go through ALL conditional activities (activities 2 + 3)
		dataStorage.setDataValueAsUint("Year", uint(1950));
	
		// Initialize the graph within the PI in order to correctly access transition conditions
		pi.initRuntime();
		// verify expected routing decisions ahead of start. The resolveTransitionCondition needs to handle the artificial activity inserted between gateway2 and gateway3
		if (pi.resolveTransitionCondition(transitionId1, activityId2) == false) return "TransitionCondition for Year should be true in first run";
		if (pi.resolveTransitionCondition(transitionId2, transitionId3) == true) return "TransitionCondition for Lastname should be false in first run using the PD element ID";
		if (pi.resolveTransitionCondition(transitionId2, keccak256(abi.encodePacked(transitionId2, transitionId3))) == true) return "TransitionCondition for Lastname should be false in first run using the artificial place ID";
		(success, ) = address(pi).call(abi.encodeWithSignature(functionSigResolveTransitionCondition, transitionId2, bytes32("fakeIdTTGGSS")));
		if (success)
			return "Attempting to resolve a condition with an unknown target element should revert";

		// start the process execution
		pi.execute(service);
		if (error != BaseErrors.NO_ERROR()) return "Unexpected error during process start of PI for first run";
		if (pi.getState() != uint8(BpmRuntime.ProcessInstanceState.COMPLETED)) return "PI in first run should be completed";

		if (pi.getNumberOfActivityInstances() != 4) return "There should be 4 AIs total in the PI on the first run";
		(activityId, , , , , ) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(1));
		if (activityId != activityId2) return "Process should have completed activity2 in first run";
		(activityId, , , , , ) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(2));
		if (activityId != activityId3) return "Process should should have completed activity3 in first run";


		// SECOND RUN: Set conditions to make process go straight through and skip activities 2 + 3
		pi = new DefaultProcessInstance();
		pi.initialize(address(pd), address(this), EMPTY);
		pi.setDataValueAsAddress("agreement", address(dataStorage));
		dataStorage.setDataValueAsUint("Year", uint(2000));
		dataStorage.setDataValueAsString("Lastname", "Smith");

		// Initialize the graph within the PI in order to correctly access transition conditions
		pi.initRuntime();
		// verify expected routing decisions ahead of start. The resolveTransitionCondition needs to handle the artificial activity inserted between gateway2 and gateway3
		if (pi.resolveTransitionCondition(transitionId1, activityId2) == true) return "TransitionCondition for Year should be false in second run";
		if (pi.resolveTransitionCondition(transitionId2, keccak256(abi.encodePacked(transitionId2, transitionId3))) == false) return "TransitionCondition for Lastname should be true in second run using the artificial place ID";

		// start the process execution
		pi.execute(service);
		if (error != BaseErrors.NO_ERROR()) return "Unexpected error during process start of PI for first run";
		if (pi.getState() != uint8(BpmRuntime.ProcessInstanceState.COMPLETED)) return "PI in second run should be completed";

		if (pi.getNumberOfActivityInstances() != 2) return "There should be 2 AIs total in the PI on the first run";
		(activityId, , , , , ) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(0));
		if (activityId != activityId1) return "Process should have completed activity1 in second run";
		(activityId, , , , , ) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(1));
		if (activityId != activityId4) return "Process should should have completed activity4 in second run";

		return SUCCESS;
	}

	/**
	 * Tests invocation of application completion functions in general
	 */
	function testSequentialServiceApplications() external returns (string memory) {

		// re-usable variables for return values
		bytes32 bytes32Value;
		uint8 state;
		bytes32 dataPath;

		// Init BpmService
		TestBpmService service = createNewTestBpmService();

		TestData dataStorage = new TestData();
		EventApplication eventApp = new EventApplication(service);
		FailureServiceApplication serviceApp = new FailureServiceApplication();

		(error, addr) = processModelRepository.createProcessModel("serviceApplicationsModel", [1,0,0], modelAuthor, false, dummyModelFileReference);
		if (addr == address(0)) return "Unable to create a ProcessModel";
		ProcessModel pm = ProcessModel(addr);

		applicationRegistry.addApplication(serviceApp1Id, BpmModel.ApplicationType.EVENT, address(eventApp), bytes4(EMPTY), EMPTY);
		applicationRegistry.addApplication(serviceApp2Id, BpmModel.ApplicationType.SERVICE, address(serviceApp), bytes4(EMPTY), EMPTY);

		addr = pm.createProcessDefinition("ServiceApplicationProcess", address(artifactsRegistry));
		ProcessDefinition pd = ProcessDefinition(addr);

		// Activity1 is configured as an asynchronous invocation in order to test the IN/OUT data mappings
		error = pd.createActivityDefinition(activityId1, BpmModel.ActivityType.TASK, BpmModel.TaskType.EVENT, BpmModel.TaskBehavior.SENDRECEIVE, EMPTY, false, serviceApp1Id, EMPTY, EMPTY);
		if (error != BaseErrors.NO_ERROR()) return "Error creating EVENT task activity1 definition";
		pd.createDataMapping(activityId1, BpmModel.Direction.IN, eventApp.inDataIdAge(), "Age", "storage", address(0));
		pd.createDataMapping(activityId1, BpmModel.Direction.IN, eventApp.inDataIdGreeting(), "Message", EMPTY, address(0));
		pd.createDataMapping(activityId1, BpmModel.Direction.OUT, eventApp.outDataIdResult(), "Response", EMPTY, address(0));
		error = pd.createActivityDefinition(activityId2, BpmModel.ActivityType.TASK, BpmModel.TaskType.SERVICE, BpmModel.TaskBehavior.SEND, EMPTY, false, serviceApp2Id, EMPTY, EMPTY);
		if (error != BaseErrors.NO_ERROR()) return "Error creating SERVICE task activity2 definition";
		pd.createTransition(activityId1, activityId2);
		
		// Validate to set the start activity and enable runtime configuration
		(success, bytes32Value) = pd.validate();
		if (!success) return bytes32Value.toString();

		// create a PI and set up data content for testing
		// NOTE: must match data mapping instructions in activity definitions above!
		ProcessInstance pi = service.createDefaultProcessInstance(address(pd), address(this), EMPTY);
		dataStorage.setDataValueAsUint("Age", 78);
		pi.setDataValueAsAddress("storage", address(dataStorage));
		pi.setDataValueAsString("Message", "Hello World");

		error = service.startProcessInstance(pi);
		if (error != BaseErrors.NO_ERROR()) return "Unexpected error during process start";

		// verify PI and AI state
		if (pi.getState() != uint8(BpmRuntime.ProcessInstanceState.ACTIVE)) return "The PI should still be active";
		( , , , addr, , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(0));
		if (state != uint8(BpmRuntime.ActivityInstanceState.SUSPENDED)) return "Activity1 should be suspended due to async invocation";
		if (addr != address(eventApp)) return "The event app should be the performer of activity1";

		// test IN data retrieval
		(addr, dataPath) = pi.resolveInDataLocation(pi.getActivityInstanceAtIndex(0), eventApp.inDataIdAge());
		if (addr != address(dataStorage)) return "The storage location for inDataIdAge should be the internal DataStorage";
		if (dataPath != "Age") return "The dataPath after storage resolution for inDataIdAge is not correct";
		(addr, dataPath) = pi.resolveInDataLocation(pi.getActivityInstanceAtIndex(0), eventApp.inDataIdGreeting());
		if (addr != address(pi)) return "The storage location for inDataIdGreeting should be the ProcessInstance";
		if (dataPath != "Message") return "The dataPath after storage resolution for inDataIdGreeting is not correct";

		// test failure scenarios for IN mappings
		(success, ) = address(pi).call(abi.encodeWithSignature(functionSigGetActivityInDataAsUint, eventApp.activityInstanceId(), eventApp.inDataIdAge()));
		if (success)
			return "Retrieving IN data outside of the application should REVERT";
		(success, ) = address(eventApp).call(abi.encodeWithSignature(functionSigRetrieveInDataAge));
		if (success)
			return "Retrieving IN data in the event application outside of APPLICATION state should REVERT";
		// test successful IN mappings set during completion of the event
		if (eventApp.getAgeDuringCompletion() != 78)
			return "IN data inDataIdAge not correctly saved during completion of eventApp";
		if (keccak256(abi.encodePacked(eventApp.getGreetingDuringCompletion())) != keccak256(abi.encodePacked("Hello World")))
			return "IN data inDataIdGreeting not correctly saved during completion of eventApp";

		// trying to set OUT data from here should fail
		(success, ) = address(pi).call(abi.encodeWithSignature(functionSigSetActivityOutDataAsBytes32, eventApp.activityInstanceId(), eventApp.inDataIdAge(), bytes32("bla")));
		if (success)
			return "Retrieving IN data outside of the application should REVERT";
		// try completing activity1 from here should fail
		error = pi.completeActivity(pi.getActivityInstanceAtIndex(0), service);
		if (error != BaseErrors.INVALID_ACTOR()) return "Only the application should be able to complete the suspended EVENT task";

		error = eventApp.completeExternal(pi.getActivityInstanceAtIndex(0), "Hello back");
		if (error != BaseErrors.NO_ERROR()) return "Error completing event task activity1 via the application";

		// // verify out data correctly stored in process by the event app
		if (pi.getDataValueAsBytes32("Response") != "Hello back")
			return "OUT data outDataIdResult not correctly stored in process via eventApp";

		( , , , , , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(0));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity1 should be completed after the external completion";
		// activity2 should be interrupted at first
		( , , , , , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(1));
		if (state != uint8(BpmRuntime.ActivityInstanceState.INTERRUPTED)) return "Activity2 should be interrupted";

		// reset the app and recover the process
		serviceApp.reset();
		// recovery should be possible from here and not via the service contract
		error = pi.completeActivity(pi.getActivityInstanceAtIndex(1), service);
		if (error != BaseErrors.NO_ERROR()) return "Unexpected error trying to recover interrupted activityInstance";
		( , , , , , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(1));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity2 should be completed now";

		if (pi.getState() != uint8(BpmRuntime.ProcessInstanceState.COMPLETED)) return "The PI should be completed";

		return SUCCESS;
	}

	function testParticipantResolution() external returns (string memory) {

		bytes32 bytes32Value;
		bytes32 dataPathOnAgreement = "buyer";
		bytes32 dataStorageId = "agreement";
		bytes32 dataPathOnProcess = "customAssignee";
	
		(error, addr) = processModelRepository.createProcessModel("conditionalPerformerModel", [1,0,0], modelAuthor, false, dummyModelFileReference);
		if (addr == address(0)) return "Unable to create a ProcessModel";
		ProcessModel pm = ProcessModel(addr);

		// Create participants, one conditional performer and one direct one.
		TestData dataStorage = new TestData(); // this simulates the Agreement's DataStorage
		dataStorage.setDataValueAsAddress(dataPathOnAgreement, assignee1);
		// conditional data path with direct storage address
		pm.addParticipant(participantId1, address(0), dataPathOnAgreement, EMPTY, address(dataStorage));
		// specific account participant
		pm.addParticipant(participantId2, address(this), EMPTY, EMPTY, address(0));
		// conditional data path with indirect storage ID
		pm.addParticipant(participantId3, address(0), dataPathOnAgreement, dataStorageId, address(0));
		// conditional data path on process instance
		pm.addParticipant(participantId4, address(0), dataPathOnProcess, EMPTY, address(0));

		addr = pm.createProcessDefinition("SingleTaskProcess", address(artifactsRegistry));
		ProcessDefinition pd = ProcessDefinition(addr);

		// creating a valid model with a single activity
		error = pd.createActivityDefinition(activityId1, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		if (error != BaseErrors.NO_ERROR()) return "Error creating USER task activity for participant1";
		(success, bytes32Value) = pd.validate();
		if (!success) return bytes32Value.toString();

		TestProcessInstance pi = new TestProcessInstance();
		pi.initialize(address(pd), address(0), EMPTY);
		pi.setDataValueAsAddress(dataStorageId, address(dataStorage)); // supports indirect navigation to DataStorage via a field in the process instance
		pi.setDataValueAsAddress(dataPathOnProcess, address(this)); // supports direct lookup of address via a field in the process instance
		pi.initRuntime();

		bytes32 dataPath;
		(addr, dataPath) = pi.resolveParticipant(participantId1);
		if (addr != address(dataStorage)) return "DataStorage address not resolved correctly for participant1";
		if (dataPath != dataPathOnAgreement) return "DataPath not resolved correctly for participant1";
		(addr, dataPath) = pi.resolveParticipant(participantId2);
		if (addr != address(this)) return "Participant2 performer address should point to this contract.";
		if (dataPath != "") return "DataPath should be empty for explicit participant2";
		(addr, dataPath) = pi.resolveParticipant(participantId3);
		if (addr != address(dataStorage)) return "DataStorage address not resolved correctly for participant3";
		if (dataPath != dataPathOnAgreement) return "DataPath not resolved correctly for participant3";
		(addr, dataPath) = pi.resolveParticipant(participantId4);
		if (addr != address(pi)) return "Participant4 dataStorage should point to the ProcessInstance.";
		if (dataPath != dataPathOnProcess) return "DataPath for participant4 not resolved correctly";

		return SUCCESS;
	}

	/**
	 * Tests a simple process flow using public BpmService API
	 */
	function testSequentialProcessWithUserTask() external returns (string memory) {

		bytes32 bytes32Value;
		bytes memory returnData;
		address[] memory emptyAddressArray;

		TestBpmService service = createNewTestBpmService();

		//TODO missing test coverage of the authorizePerformer function / completeActivity for users in different department settings

		UserAccount user1 = new DefaultUserAccount();
		user1.initialize(address(this), address(0));
		UserAccount organizationUser = new DefaultUserAccount();
		organizationUser.initialize(address(this), address(0));
		DefaultOrganization org1 = new DefaultOrganization();
		org1.initialize(emptyAddressArray, EMPTY);
		if (!org1.addUserToDepartment(address(organizationUser), EMPTY)) return "Unable to add user account to organization default department";

		// Register a typical WEB application with only a webform
		error = applicationRegistry.addApplication("Webform1", BpmModel.ApplicationType.WEB, address(0), bytes4(EMPTY), "MyCustomWebform");
		if (error != BaseErrors.NO_ERROR()) return "Error registering WEB application for user task";

		(error, addr) = processModelRepository.createProcessModel("testModelUserTasks", [1,0,0], modelAuthor, false, dummyModelFileReference);
		if (addr == address(0)) return "Unable to create a ProcessModel";
		ProcessModel pm = ProcessModel(addr);

		// Register participants to be used for USER tasks
		pm.addParticipant(participantId1, address(user1), EMPTY, EMPTY, address(0)); // user participant
		pm.addParticipant(participantId2, address(org1), EMPTY, EMPTY, address(0)); // organization participant

		addr = pm.createProcessDefinition("UserTaskProcess", address(artifactsRegistry));
		ProcessDefinition pd = ProcessDefinition(addr);

		// Activity 1 is assigned to user1
		// Activity 2 is assigned to the organizationUser via the org1 organization
		error = pd.createActivityDefinition(activityId1, BpmModel.ActivityType.TASK, BpmModel.TaskType.USER, BpmModel.TaskBehavior.SENDRECEIVE, participantId1, false, "Webform1", EMPTY, EMPTY);
		if (error != BaseErrors.NO_ERROR()) return "Error creating USER task activity for participant1";
		error = pd.createActivityDefinition(activityId2, BpmModel.ActivityType.TASK, BpmModel.TaskType.USER, BpmModel.TaskBehavior.SENDRECEIVE, participantId2, false, "Webform1", EMPTY, EMPTY);
		if (error != BaseErrors.NO_ERROR()) return "Error creating USER task activity for participant2";
		pd.createTransition(activityId1, activityId2);

		pd.createDataMapping(activityId1, BpmModel.Direction.IN, "nameAccessPoint", "Name", "storage", address(0));
		pd.createDataMapping(activityId1, BpmModel.Direction.OUT, "approvedAccessPoint", "Approved", EMPTY, address(0));
		pd.createDataMapping(activityId2, BpmModel.Direction.IN, "approvedAccessPoint", "Approved", EMPTY, address(0));
		pd.createDataMapping(activityId2, BpmModel.Direction.OUT, "ageAccessPoint", "Age", "storage", address(0));
		// Create a DataStorage to use for IN/OUT data mappings
		TestData dataStorage = new TestData();
		dataStorage.setDataValueAsBytes32("Name", "Smith");

		// Validate to set the start activity and enable runtime configuration
		(success, bytes32Value) = pd.validate();
		if (!success) return bytes32Value.toString();

		// test error conditions for creating a process via model and pd IDs
		(success, ) = address(service).call(abi.encodeWithSignature(functionSigStartProcessFromRepository, bytes32("FakeModelIdddddd"), bytes32("UserTaskProcess"), EMPTY));
		if (success)
			return "Starting a process with invalid model ID should REVERT";
		(success, ) = address(service).call(abi.encodeWithSignature(functionSigStartProcessFromRepository, pm.getId(), bytes32("TotallyFakeProcessssId"), EMPTY));
		if (success)
			return "Starting a process with invalid process definition ID should REVERT";

		// test successful creation via model and pd IDs
		(error, addr) = service.startProcessFromRepository(pm.getId(), "UserTaskProcess", EMPTY);
		if (error != BaseErrors.NO_ERROR()) return "Unexpected error during process start";
		if (addr == address(0)) return "No error during process start, but PI address is empty!";
		ProcessInstance pi = ProcessInstance(addr);

		// some of the data mappings reference a DataStorage object that needs to be set in the PI
		pi.setDataValueAsAddress("storage", address(dataStorage));

		// verify DB state
		if (service.getNumberOfProcessInstances() != 1) return "There should be 1 PI after process start";
		if (service.getNumberOfActivityInstances(address(pi)) != 1) return "There should be 1 AI after process start";
		if (pi.getNumberOfActivityInstances() != 1) return "There should be 1 AI in the ProcessInstance after start";

		// verify individual activity instances
		uint8 state;
		( , , , addr, , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(0));
		if (state != uint8(BpmRuntime.ActivityInstanceState.SUSPENDED)) return "Activity1 should be suspended";
		if (addr != address(user1)) return "Activity1 should be assigned to user1";

		// test data mappings via user-assigned task
		(success, ) = address(pi).call(abi.encodeWithSignature(functionSigGetActivityInDataAsBytes32, pi.getActivityInstanceAtIndex(0), bytes32("nameAccessPoint")));
		if (success)
			 return "It should not be possible to access IN data mappings from a non-performer address";
		returnData = user1.forwardCall(address(pi), abi.encodeWithSignature(functionSigGetActivityInDataAsBytes32, pi.getActivityInstanceAtIndex(0), bytes32("nameAccessPoint")));
		if (returnData.toBytes32() != "Smith") return "IN data mapping Name should return correctly via user1";
		returnData = user1.forwardCall(address(pi), abi.encodeWithSignature(functionSigSetActivityOutDataAsBool, pi.getActivityInstanceAtIndex(0), bytes32("approvedAccessPoint"), true));

		// complete user task 1 and check outcome
		returnData = organizationUser.forwardCall(address(pi), abi.encodeWithSignature(functionSigCompleteActivity, pi.getActivityInstanceAtIndex(0), service));
		if (returnData.toUint() != BaseErrors.INVALID_ACTOR()) return "Attempt to complete activity1 by organizationUser should fail";
		user1.forwardCall(address(pi), abi.encodeWithSignature(functionSigCompleteActivity, pi.getActivityInstanceAtIndex(0), service));
		( , , , , addr, state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(0));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity1 should be completed";
		if (addr != address(user1)) return "Activity1 should be completedBy user1";

		// verify new world state
		if (service.getNumberOfActivityInstances(address(pi)) != 2) return "There should be 2 AIs after task1 completion";
		if (pi.getNumberOfActivityInstances() != 2) return "There should be 2 AIs in the ProcessInstance after task1 completion";
		( , , , addr, , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(1));
		if (state != uint8(BpmRuntime.ActivityInstanceState.SUSPENDED)) return "Activity2 should be suspended";
		if (addr != address(org1)) return "Activity2 should be assigned to the organization org1";

		// test data mappings via organization-assigned task
		(success, ) = address(user1).call(abi.encodeWithSignature(functionSigForwardCall, address(pi), abi.encodeWithSignature(functionSigGetActivityInDataAsBool, pi.getActivityInstanceAtIndex(1), bytes32("approvedAccessPoint"))));
		if (success)
			return "Accessing IN data mappings from a user account that is not the performer should revert";
		returnData = organizationUser.forwardCall(address(pi), abi.encodeWithSignature(functionSigGetActivityInDataAsBool, pi.getActivityInstanceAtIndex(1), bytes32("approvedAccessPoint")));
		// TODO use "decode" with solidity 0.5
		if (returnData.length != 32) return "should have length 32";
		if (uint256(uint8(returnData[31])) != 1) return "IN data mapping Approved should return true via user organizationUser in activity2";
		organizationUser.forwardCall(address(pi), abi.encodeWithSignature(functionSigSetActivityOutDataAsUint, pi.getActivityInstanceAtIndex(1), bytes32("ageAccessPoint"), uint(21)));

		// complete user task 2 and check outcome
		returnData = user1.forwardCall(address(pi), abi.encodeWithSignature(functionSigCompleteActivity, pi.getActivityInstanceAtIndex(1), service));
		// TODO use "decode" with solidity 0.5
		if (returnData.toUint() != BaseErrors.INVALID_ACTOR()) return "Attempt to complete activity2 by user1 should fail";

		// complete the activity here using an OUT data mapping to set the Age
		returnData = organizationUser.forwardCall(address(pi), abi.encodeWithSignature(functionSigCompleteActivityWithUintData, pi.getActivityInstanceAtIndex(1), address(service), bytes32("Age"), uint(21)));
		if (returnData.toUint() != BaseErrors.NO_ERROR()) return "Attempt to complete activity2 by organizationUser should be successful";
		( , , , , addr, state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(1));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity2 should be completed";
		if (addr != address(organizationUser)) return "Activity2 should be completedBy the organizationUser";
		// check the fields that were set in the PI and data storage
		if (pi.getDataValueAsBool("Approved") != true)
			return "The Approved field in the PI should've been set via data mappings";
		if (dataStorage.getDataValueAsUint("Age") != 21)
			return "The Age field in the DataStorge should've been set at AI completion";

		// verify process state
		if (pi.getState() != uint8(BpmRuntime.ProcessInstanceState.COMPLETED)) return "The PI should be completed";

		return SUCCESS;
	}

	/**
	 * Tests aborting a process midflight
	 */
	function testProcessAbort() external returns (string memory) {

		bytes32 bytes32Value;

		TestBpmService service = createNewTestBpmService();

		UserAccount user1 = new DefaultUserAccount();
		user1.initialize(address(this), address(0));
	
		(error, addr) = processModelRepository.createProcessModel("testModelAbort", [1,0,0], modelAuthor, false, dummyModelFileReference);
		if (addr == address(0)) return "Unable to create a ProcessModel";
		ProcessModel pm = ProcessModel(addr);

		// Register participants to be used for USER tasks
		pm.addParticipant(participantId1, address(user1), EMPTY, EMPTY, address(0)); // user participant

		addr = pm.createProcessDefinition("AbortProcess", address(artifactsRegistry));
		ProcessDefinition pd = ProcessDefinition(addr);

		// Activity 1 is a NONE
		// Activity 2 is user task
		error = pd.createActivityDefinition(activityId1, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		if (error != BaseErrors.NO_ERROR()) return "Error creating NONE task activity";
		error = pd.createActivityDefinition(activityId2, BpmModel.ActivityType.TASK, BpmModel.TaskType.USER, BpmModel.TaskBehavior.SENDRECEIVE, participantId1, false, EMPTY, EMPTY, EMPTY);
		if (error != BaseErrors.NO_ERROR()) return "Error creating USER task activity for participant1";
		pd.createTransition(activityId1, activityId2);
		
		// Validate to set the start activity and enable runtime configuration
		(success, bytes32Value) = pd.validate();
		if (!success) return bytes32Value.toString();

		// create two process instances, one via the BpmService.startProcess function and one via direct constructor
		// to make sure they are both abortable by the ower (this contract)
		(error, addr) = service.startProcess(address(pd), EMPTY);
		if (error != BaseErrors.NO_ERROR()) return "Unexpected error during process start";
		if (addr == address(0)) return "No error during process start, but PI address is empty!";
		ProcessInstance pi1 = ProcessInstance(addr);
		ProcessInstance pi2 = new DefaultProcessInstance();
		pi2.initialize(address(pd), address(0), EMPTY);
		service.startProcessInstance(pi2);

		// verify DB state
		if (service.getNumberOfProcessInstances() != 2) return "There should be 1 PI after process start";
		if (service.getNumberOfActivityInstances(address(pi1)) != 2) return "There should be 2 AIs in pi1";
		if (service.getNumberOfActivityInstances(address(pi2)) != 2) return "There should be 2 AIs in pi2";

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

		// abort both processes and check that any previously open activity instances are aborted.
		pi1.abort();
		pi2.abort();

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
	function testMultiInstanceUserTask() external returns (string memory) {

		bytes32 bytes32Value;

		UserAccount user1 = new DefaultUserAccount();
		user1.initialize(address(this), address(0));
		UserAccount user2 = new DefaultUserAccount();
		user2.initialize(address(this), address(0));

		TestBpmService service = createNewTestBpmService();

		TestData dataStorage = new TestData();
		address[] memory signatories = new address[](2);
		signatories[0] = address(user1);
		signatories[1] = address(user2);
		dataStorage.setDataValueAsAddressArray("SIGNATORIES", signatories);

		(error, addr) = processModelRepository.createProcessModel("multiInstanceUserTasks", [1,0,0], modelAuthor, false, dummyModelFileReference);
		if (addr == address(0)) return "Unable to create a ProcessModel";
		ProcessModel pm = ProcessModel(addr);

		// Register a participant to be used for USER tasks that replicates the AN behavior
		pm.addParticipant(participantId1, address(0), "SIGNATORIES", "agreement", address(0));

		addr = pm.createProcessDefinition("MultiInstanceUserTaskProcess", address(artifactsRegistry));
		ProcessDefinition pd = ProcessDefinition(addr);

		error = pd.createActivityDefinition(activityId1, BpmModel.ActivityType.TASK, BpmModel.TaskType.USER, BpmModel.TaskBehavior.SENDRECEIVE, participantId1, true, EMPTY, EMPTY, EMPTY);
		if (error != BaseErrors.NO_ERROR()) return "Error creating USER task activity definition";
		error = pd.createActivityDefinition(activityId2, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		if (error != BaseErrors.NO_ERROR()) return "Error creating NONE task activity definition";
		pd.createTransition(activityId1, activityId2);
		
		// Validate to set the start activity and enable runtime configuration
		(success, bytes32Value) = pd.validate();
		if (!success) return bytes32Value.toString();

		// Start process instance
		ProcessInstance pi = service.createDefaultProcessInstance(address(pd), address(this), EMPTY);
		pi.setDataValueAsAddress("agreement", address(dataStorage));
		error = service.startProcessInstance(pi);
		if (error != BaseErrors.NO_ERROR()) return "Unexpected error during process start";

		// verify DB state
		if (service.getNumberOfProcessInstances() != 1) return "There should be 1 PI";
		if (service.getNumberOfActivityInstances(address(pi)) != 2) return "There should be 2 AIs";

		// verify process state
		if (pi.getState() != uint8(BpmRuntime.ProcessInstanceState.ACTIVE)) return "The PI should be active";

		// verify individual activity instances
		uint8 state;
		( , , , addr, , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(0));
		if (state != uint8(BpmRuntime.ActivityInstanceState.SUSPENDED)) return "Activity1.1 should be suspended";
		if (addr != address(user1)) return "Activity1.1 should be assigned to user1";
		( , , , addr, , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(1));
		if (state != uint8(BpmRuntime.ActivityInstanceState.SUSPENDED)) return "Activity1.2 should be suspended";
		if (addr != address(user2)) return "Activity1.2 should be assigned to user2";

		// complete first user task
		user1.forwardCall(address(pi), abi.encodeWithSignature(functionSigCompleteActivity, pi.getActivityInstanceAtIndex(0), service));
		( , , , , , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(0));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity1.1 should be completed";

		// verify process state
		if (pi.getState() != uint8(BpmRuntime.ProcessInstanceState.ACTIVE)) return "The PI should be completed";

		// number of AIs should still be 2 at this point
		if (service.getNumberOfActivityInstances(address(pi)) != 2) return "There should still be 2 AIs after completing only 1 instance";

		// complete remaining user task
		user2.forwardCall(address(pi), abi.encodeWithSignature(functionSigCompleteActivity, pi.getActivityInstanceAtIndex(1), service));
		( , , , , , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(1));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity1.2 should be completed";

		if (service.getNumberOfActivityInstances(address(pi)) != 3) return "There should be 3 AIs after completing all instances of the multi-instance user task";

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
	function testSubprocesses() external returns (string memory) {

		bytes32 bytes32Value;
		ProcessInstance[3] memory subProcesses;

		TestBpmService service = createNewTestBpmService();

		// Two process models
		(error, addr) = processModelRepository.createProcessModel("ModelA", [1,0,0], modelAuthor, false, dummyModelFileReference);
		if (addr == address(0)) return "Unable to create ProcessModel A";
		ProcessModel pmA = ProcessModel(addr);
		pmA.addParticipant(participantId1, address(this), EMPTY, EMPTY, address(0));

		(error, addr) = processModelRepository.createProcessModel("ModelB", [1,0,0], modelAuthor, false, dummyModelFileReference);
		if (addr == address(0)) return "Unable to create ProcessModel B";
		ProcessModel pmB = ProcessModel(addr);

		// One 'main' process and three sub-process definitions
		addr = pmA.createProcessDefinition("MainProcess", address(artifactsRegistry));
		ProcessDefinition pdMain = ProcessDefinition(addr);
		addr = pmA.createProcessDefinition("SubProcessA", address(artifactsRegistry));
		ProcessDefinition pdSubA = ProcessDefinition(addr);
		addr = pmA.createProcessDefinition("SubProcessA2", address(artifactsRegistry));
		ProcessDefinition pdSubA2 = ProcessDefinition(addr);
		addr = pmB.createProcessDefinition("SubProcessB", address(artifactsRegistry));
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
		(success, bytes32Value) = pdSubA.validate();
		if (!success) return bytes32Value.toString();
		(success, bytes32Value) = pdSubB.validate();
		if (!success) return bytes32Value.toString();
		(success, bytes32Value) = pdMain.validate();
		if (!success) return bytes32Value.toString();

		// Start process instance with data to simulate agreement reference
		ProcessInstance piMain = service.createDefaultProcessInstance(address(pdMain), address(this), EMPTY);
		piMain.setDataValueAsAddress("agreement", address(this));
		error = service.startProcessInstance(piMain);
		if (error != BaseErrors.NO_ERROR()) return "Unexpected error during process start";

		// verify DB state
		if (service.getBpmServiceDb().getNumberOfProcessInstances() != 3) return "There should be 3 PIs";
		if (service.getBpmServiceDb().getNumberOfActivityInstances() != 4) return "There should be 4 AIs total";
		subProcesses[0] = ProcessInstance(service.getProcessInstanceAtIndex(1));
		subProcesses[1] = ProcessInstance(service.getProcessInstanceAtIndex(2));
	
		// all processes should be active after main start
		if (piMain.getState() != uint8(BpmRuntime.ProcessInstanceState.ACTIVE)) return "The Main PI should be active";
		if (piMain.getNumberOfActivityInstances() != 2) return "There should be 2 AIs in the main process after start";
		if (subProcesses[0].getState() != uint8(BpmRuntime.ProcessInstanceState.ACTIVE)) return "SubprocessA should be active";
		if (subProcesses[1].getState() != uint8(BpmRuntime.ProcessInstanceState.ACTIVE)) return "SubprocessB should be active";
		uint state;
		( , , , , , state) = piMain.getActivityInstanceData(piMain.getActivityInstanceAtIndex(0));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity1 in Main should be completed";
		( , , , , , state) = piMain.getActivityInstanceData(piMain.getActivityInstanceAtIndex(1));
		if (state != uint8(BpmRuntime.ActivityInstanceState.SUSPENDED)) return "Activity2 in Main should be suspended";

		// verify that data was propagated to the subprocess
		if (subProcesses[0].getDataValueAsAddress("agreement") != address(this)) return "SubprocessA should have the agreement reference set";
		if (subProcesses[1].getDataValueAsAddress("agreement") != address(this)) return "SubprocessB should have the agreement reference set";

		// completing the SubprocessB activity should trigger completion of the subprocess and creation of the third subprocess
		error = subProcesses[1].completeActivity(subProcesses[1].getActivityInstanceAtIndex(0), service);
		if (error != BaseErrors.NO_ERROR()) return "Unexpected error completing the wait activity in SubprocessB";
		( , , , , , state) = subProcesses[1].getActivityInstanceData(subProcesses[1].getActivityInstanceAtIndex(0));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity1 in SubprocessB should be completed";
		( , , , , , state) = piMain.getActivityInstanceData(piMain.getActivityInstanceAtIndex(1));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity2 in Main should be completed now";
		// after completing SubprocessB, the third subprocess A2 is synchronous and has no wait activity, so its completion should complete the main process
		if (piMain.getNumberOfActivityInstances() != 3) return "There should be 3 AIs in the main process after completing SubprocessB";
		if (service.getNumberOfProcessInstances() != 4) return "There should be 4 PIs after completing the SubprocessB";
		( , , , , , state) = piMain.getActivityInstanceData(piMain.getActivityInstanceAtIndex(2));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity3 in Main should be completed";
		subProcesses[2] = ProcessInstance(service.getProcessInstanceAtIndex(3));

		( , , , , , state) = piMain.getActivityInstanceData(piMain.getActivityInstanceAtIndex(1));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity2 in Main should be completed";
		( , , , , , state) = piMain.getActivityInstanceData(piMain.getActivityInstanceAtIndex(2));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return "Activity2 in Main should be completed";
		if (subProcesses[0].getState() != uint8(BpmRuntime.ProcessInstanceState.ACTIVE)) return "Aynchronous SubprocessA should still be active";
		if (subProcesses[1].getState() != uint8(BpmRuntime.ProcessInstanceState.COMPLETED)) return "SubprocessB should be completed";		
		if (subProcesses[2].getState() != uint8(BpmRuntime.ProcessInstanceState.COMPLETED)) return "SubprocessA2 should be completed";		
		if (piMain.getState() != uint8(BpmRuntime.ProcessInstanceState.COMPLETED)) return "The Main PI should be completed";

		return SUCCESS;
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

	constructor (string memory _appRegistryId, string memory _modelRepoId) public
		DefaultBpmService(_appRegistryId, _modelRepoId) {
	}

	function addProcessInstance(ProcessInstance _pi) external {
		BpmServiceDb(database).addProcessInstance(address(_pi));
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
	function complete(address, bytes32, bytes32, address) public {
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
	function complete(address, bytes32 _aiId, bytes32, address) public {
		activityInstanceId = _aiId;
		ageDuringCompletion = retrieveInDataAge();
		greetingDuringCompletion = retrieveInDataGreeting();
	}

	/// writes the bytes32 to the outDataIdResult mapping and completes the activity
	function completeExternal(bytes32 _aiId, bytes32 _value) external returns (uint error) {
		address pi = bpmService.getProcessInstanceForActivity(_aiId);
		ProcessInstance(pi).setActivityOutDataAsBytes32(_aiId, outDataIdResult, _value);
		error = ProcessInstance(pi).completeActivity(_aiId, bpmService);
	}

	/// returns the age IN data saved in the completion function
	function getAgeDuringCompletion() external view returns (uint) {
		return ageDuringCompletion;
	}

	/// returns the greeting IN data saved in the completion function
	function getGreetingDuringCompletion() external view returns (string memory) {
		return greetingDuringCompletion;
	}

	/// allows invoking the inDataIdAge mapping via the application
	function retrieveInDataAge() public returns (uint) {
		address pi = bpmService.getProcessInstanceForActivity(activityInstanceId);
		return ProcessInstance(pi).getActivityInDataAsUint(activityInstanceId, inDataIdAge);
	}

	/// allows invoking the inDataIdGreeting mapping via the application
	function retrieveInDataGreeting() public returns (string memory) {
		address pi = bpmService.getProcessInstanceForActivity(activityInstanceId);
		return ProcessInstance(pi).getActivityInDataAsString(activityInstanceId, inDataIdGreeting);
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
