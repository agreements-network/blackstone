pragma solidity ^0.4.23;

import "commons-base/BaseErrors.sol";
import "commons-base/SystemOwned.sol";
import "commons-utils/DataTypes.sol";
import "commons-auth/ParticipantsManager.sol";
import "commons-auth/Organization.sol";
import "commons-auth/DefaultOrganization.sol";
import "commons-management/DOUG.sol";
import "commons-management/AbstractDbUpgradeable.sol";
import "bpm-model/BpmModel.sol";
import "bpm-model/ProcessModelRepository.sol";
import "bpm-model/ProcessModel.sol";
import "bpm-model/ProcessDefinition.sol";
import "bpm-runtime/BpmRuntime.sol";
import "bpm-runtime/BpmService.sol";
import "bpm-runtime/ProcessInstance.sol"; 
import "bpm-runtime/DefaultProcessInstance.sol"; 
import "bpm-runtime/ApplicationRegistry.sol";

import "agreements/ActiveAgreementRegistry.sol";
import "agreements/DefaultActiveAgreementRegistry.sol";
import "agreements/ArchetypeRegistry.sol";
import "agreements/AgreementPartyAccount.sol";
import "agreements/AgreementSignatureCheck.sol";

contract ActiveAgreementWorkflowTest {

	// test data
	bytes32 activityId1 = "activity1";
	bytes32 activityId2 = "activity2";
	bytes32 activityId3 = "activity3";

	bytes32 user1Id = "iamuser1";
	bytes32 user2Id = "iamuser2";
	bytes32 user3Id = "iamuser3";

	bytes32 appIdSignatureCheck = "AgreementSignatureCheck";

	bytes32 participantId1 = "Participant1";
	bytes32 participantId2 = "Participant2";

	bytes32 departmentId1 = "Dep1";

	address[] parties;
    address[10] approvers;

	// tests should overwrite the users and orgs as needed
	Organization org1;
	Organization org2;
	AgreementPartyAccount userAccount1;
	AgreementPartyAccount userAccount2;
	AgreementPartyAccount userAccount3;
	AgreementPartyAccount nonPartyAccount;


	string constant SUCCESS = "success";
	bytes32 EMPTY = "";
	bytes32 DATA_FIELD_AGREEMENT_PARTIES = "AGREEMENT_PARTIES";

	address[] governingArchetypes;
	address[] governingAgreements;

	// DOUG instance and dependencies retrieved from DOUG
	DOUG doug;
	BpmService bpmService;
	ArchetypeRegistry archetypeRegistry;
	ParticipantsManager participantsManager;
	ProcessModelRepository processModelRepository;
	ApplicationRegistry applicationRegistry;

	// re-usable entities as storage variables to avoid "stack too deep" problems in tests
	TestRegistry agreementRegistry = new TestRegistry();
	ActiveAgreementRegistryDb registryDb = new ActiveAgreementRegistryDb();

	function setDoug(DOUG _doug) external {
		doug = _doug;
		bpmService = BpmService(doug.lookupContract("BpmService"));
		archetypeRegistry = ArchetypeRegistry(doug.lookupContract("ArchetypeRegistry"));
		participantsManager = ParticipantsManager(doug.lookupContract("ParticipantsManager"));
		processModelRepository = ProcessModelRepository(doug.lookupContract("ProcessModelRepository"));
		applicationRegistry = ApplicationRegistry(doug.lookupContract("ApplicationRegistry"));
	}

	/**
	 * @dev Tests the DefaultActiveAgreementRegistry.transferAddressScopes function
	 */
	function testAddressScopeTransfer() external returns (string) {

		// re-usable variables for return values
		uint error;
		address addr;

		// make an agreement with fields of type address and add role qualifiers. Note: archetype is not used, so setting address to 'this'
		ActiveAgreement agreement = new DefaultActiveAgreement(this, "RoleQualifierAgreement", this, EMPTY, EMPTY, EMPTY, EMPTY, 8, false, parties, governingAgreements);
		agreement.setDataValueAsBytes32("AgreementRoleField43", "SellerRole");
		// Adding two scopes to the agreement:
		// 1. Buyer context: a fixed scope for the msg.sender
		// 2. Seller context: a conditional scope for this test address
		agreement.setAddressScope(msg.sender, "Buyer", "BuyerRole", EMPTY, EMPTY, 0x0);
		agreement.setAddressScope(address(this), "Seller", EMPTY, "AgreementRoleField43", EMPTY, 0x0);

		// make a model with participants that point to fields on the agreement
		ProcessModel pm;
		(error, addr) = processModelRepository.createProcessModel("RoleQualifiers", "Role Qualifiers", [1,0,0], this, false, EMPTY, EMPTY);
		if (addr == 0x0) return "Unable to create a ProcessModel";
		pm = ProcessModel(addr);
		pm.addParticipant(participantId1, 0x0, "Buyer", agreementRegistry.DATA_ID_AGREEMENT(), 0x0);
		pm.addParticipant(participantId2, 0x0, "Seller", agreementRegistry.DATA_ID_AGREEMENT(), 0x0);
		// make a ProcessDefinition with activities that use the participants
		(error, addr) = pm.createProcessDefinition("RoleQualifierProcess");
		if (addr == 0x0) return "Unable to create process definition";
		ProcessDefinition pd = ProcessDefinition(addr);
		error = pd.createActivityDefinition(activityId1, BpmModel.ActivityType.TASK, BpmModel.TaskType.USER, BpmModel.TaskBehavior.SENDRECEIVE, participantId1, false, EMPTY, EMPTY, EMPTY);
		error = pd.createActivityDefinition(activityId2, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		error = pd.createActivityDefinition(activityId3, BpmModel.ActivityType.TASK, BpmModel.TaskType.USER, BpmModel.TaskBehavior.SENDRECEIVE, participantId2, false, EMPTY, EMPTY, EMPTY);
		pd.createTransition(activityId1, activityId2);
		pd.createTransition(activityId2, activityId3);
		(bool valid, bytes32 errorMsg) = pd.validate();
		if (!valid) return bytes32ToString(errorMsg);

		// create a PI with agreement
		ProcessInstance pi = new DefaultProcessInstance(pd, this, EMPTY);
		pi.setDataValueAsAddress(agreementRegistry.DATA_ID_AGREEMENT(), address(agreement));

		// function under test
		agreementRegistry.transferAddressScopes(pi);

		bytes32[] memory newKeys = pi.getAddressScopeKeys();
		if (newKeys.length != 2) return "There should be 2 address scopes on the PI after transfer";
		// test if activity IDs were tagged correctly with address scopes. Activity1 is the Buyer, Activity2 the Seller
		if (pi.resolveAddressScope(msg.sender, activityId1, pi) != "BuyerRole") return "Scope for msg.sender on activity1 not correct after transfer to PI";
		( , , , addr) = pi.getAddressScopeDetails(address(this), activityId3);
		if (addr != address(agreement)) return "The ConditionalData of the address scope for activity3 should've been transformed to use the address of the agreement";
		if (pi.resolveAddressScope(address(this), activityId3, pi) != "SellerRole") return "Scope for address(this) on activity3 not correct after transfer to PI";

		return SUCCESS;
	}

	/**
	 * Tests a typical AN workflow with a multi-instance signing activity that produces an executed agreement
	 */
	function testExecutedAgreementWorkflow() external returns (uint, string) {

		// re-usable variables for return values
		uint error;
		address addr;
		bool valid;
		bytes32 errorMsg;
		uint8 state;
		ProcessDefinition formationPD;
		ProcessDefinition executionPD;
	
		// service / test setup
		agreementRegistry = new TestRegistry();
		registryDb = new ActiveAgreementRegistryDb();
		SystemOwned(registryDb).transferSystemOwnership(agreementRegistry);
		AbstractDbUpgradeable(agreementRegistry).acceptDatabase(registryDb);
		agreementRegistry.setBpmService(bpmService);

		TestSignatureCheck signatureCheckApp = new TestSignatureCheck();
		applicationRegistry.addApplication("AgreementSignatureCheck", BpmModel.ApplicationType.WEB, signatureCheckApp, bytes4(EMPTY), EMPTY);
		doug.deployContract("AgreementSignatureCheck", signatureCheckApp);
		if (signatureCheckApp.getBpmService() != address(bpmService)) return (BaseErrors.INVALID_STATE(), "BpmService not injected successfully into AgreementSignatureCheck application");

		//
		// ORGS/USERS
		//
		(error, addr) = agreementRegistry.createUserAccount(participantsManager, user1Id, this, address(0));
		if (error != BaseErrors.NO_ERROR()) return (error, "Error creating user account1 via BpmService");
		userAccount1 = AgreementPartyAccount(addr);
		(error, addr) = agreementRegistry.createUserAccount(participantsManager, "john.smith", this, address(0));
		if (error != BaseErrors.NO_ERROR()) return (error, "Error creating user account2 via BpmService");
		nonPartyAccount = AgreementPartyAccount(addr);
		// create additional users via constructor
		userAccount2 = new AgreementPartyAccount(user2Id, this, address(0));
		userAccount3 = new AgreementPartyAccount(user3Id, this, address(0));

		org1 = new DefaultOrganization(approvers);
		org2 = new DefaultOrganization(approvers);
		org1.addUser(userAccount2);
		org2.addDepartment(departmentId1, "Department 1");
		org2.addUserToDepartment(userAccount3, departmentId1);

		delete parties;
		// the parties to the agreement are: one user, one org, and one org with department scope
		parties.push(address(userAccount1));
		parties.push(address(org1));
		parties.push(address(org2));

		//
		// BPM
		//
		ProcessModel pm;
		(error, addr) = processModelRepository.createProcessModel("AN-Model", "AN Model", [1,0,0], userAccount1, false, EMPTY, EMPTY);
		if (addr == 0x0) return (BaseErrors.INVALID_STATE(), "Unable to create a ProcessModel");
		pm = ProcessModel(addr);
		pm.addParticipant(participantId1, 0x0, DATA_FIELD_AGREEMENT_PARTIES, agreementRegistry.DATA_ID_AGREEMENT(), 0x0);
		// Formation Process
		(error, addr) = pm.createProcessDefinition("FormationProcess");
		if (addr == 0x0) return (BaseErrors.INVALID_STATE(), "Unable to create FormationProcess definition");
		formationPD = ProcessDefinition(addr);
		error = formationPD.createActivityDefinition(activityId1, BpmModel.ActivityType.TASK, BpmModel.TaskType.USER, BpmModel.TaskBehavior.SENDRECEIVE, participantId1, true, appIdSignatureCheck, EMPTY, EMPTY);
		if (error != BaseErrors.NO_ERROR()) return (error, "Error creating USER task for formation process definition");
		formationPD.createDataMapping(activityId1, BpmModel.Direction.IN, "agreement", "agreement", EMPTY, 0x0);
		(valid, errorMsg) = formationPD.validate();
		if (!valid) return (BaseErrors.INVALID_STATE(), bytes32ToString(errorMsg));
		// Execution Process
		(error, addr) = pm.createProcessDefinition("ExecutionProcess");
		if (addr == 0x0) return (BaseErrors.INVALID_STATE(), "Unable to create ExecutionProcess definition");
		executionPD = ProcessDefinition(addr);
		error = executionPD.createActivityDefinition(activityId1, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.SEND, EMPTY, false, EMPTY, EMPTY, EMPTY);
		if (error != BaseErrors.NO_ERROR()) return (error, "Error creating SERVICE task for execution process definition");
		(valid, errorMsg) = executionPD.validate();
		if (!valid) return (BaseErrors.INVALID_STATE(), bytes32ToString(errorMsg));

		//
		// ARCHETYPE
		//
		addr = archetypeRegistry.createArchetype("TestArchetype", this, "description", 10, false, true, formationPD, executionPD, EMPTY, governingArchetypes);
		if (addr == 0x0) return (BaseErrors.INVALID_STATE(), "Error creating TestArchetype, address is empty");

		//
		// AGREEMENT
		//
		address agreement = agreementRegistry.createAgreement(addr, "TestAgreement", this, EMPTY, EMPTY, EMPTY, EMPTY, 8, false, parties, EMPTY, governingAgreements);
		// Org2 has a department, so we're setting the additional context on the agreement
		ActiveAgreement(agreement).setAddressScope(address(org2), DATA_FIELD_AGREEMENT_PARTIES, departmentId1, EMPTY, EMPTY, 0x0);
		//TODO we currently don't support a negotiation phase in the AN, so the agreement's prose contract is already formulated when the agreement is created.
		if (ActiveAgreement(agreement).getLegalState() != uint8(Agreements.LegalState.FORMULATED)) return (BaseErrors.INVALID_STATE(), "The agreement should be in FORMULATED state");

		//
		// FORMATION / EXECUTION
		//
		if (bpmService.getNumberOfProcessInstances() != 0) return (BaseErrors.INVALID_STATE(), "There should be 0 PIs in the system at test start");
		(error, addr) = agreementRegistry.startFormation(ActiveAgreement(agreement));
		if (error != BaseErrors.NO_ERROR()) return (error, "Error starting the formation on agreement");
		if (ActiveAgreement(agreement).getLegalState() != uint8(Agreements.LegalState.FORMULATED)) return (BaseErrors.INVALID_STATE(), "The agreement should be in FORMULATED state");

		ProcessInstance pi;
		if (bpmService.getNumberOfProcessInstances() != 1) return (BaseErrors.INVALID_STATE(), "There should be 1 PI in the system after agreement formation start");
		if (bpmService.getBpmServiceDb().getNumberOfActivityInstances() != 3) return (BaseErrors.INVALID_STATE(), "There should be 3 AIs total");
		pi = ProcessInstance(bpmService.getProcessInstanceAtIndex(0));
		if (pi.getState() != uint8(BpmRuntime.ProcessInstanceState.ACTIVE)) return (BaseErrors.INVALID_STATE(), "The Formation PI should be active");
		( , , , addr, , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(0));
		if (state != uint8(BpmRuntime.ActivityInstanceState.SUSPENDED)) return (BaseErrors.INVALID_STATE(), "Activity1 in Formation Process should be suspended");
		if (addr != address(userAccount1)) return (BaseErrors.INVALID_STATE(), "userAccount1 should be the performer of activity1");

		// the agreement should NOT be available as IN data via the application at this point since the user is still the performer!
		if (address(signatureCheckApp).call(keccak256(abi.encodePacked("getInDataAgreement(bytes32)")), pi.getActivityInstanceAtIndex(0)))
			return (BaseErrors.INVALID_STATE(), "Retrieving IN data via the application should REVERT while the user is still the performer");

		// test fail on invalid user
		error = nonPartyAccount.completeActivity(pi.getActivityInstanceAtIndex(0), bpmService);
		if (error != BaseErrors.INVALID_ACTOR()) return (BaseErrors.INVALID_STATE(), "Attempting to complete the Sign activity with an unassigned user should fail.");
		( , , , , , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(0));
		if (state != uint8(BpmRuntime.ActivityInstanceState.SUSPENDED)) return (BaseErrors.INVALID_STATE(), "Activity1 in Formation Process should still be suspended after wrong user attempt");
		// test fail on unsigned agreement
		error = userAccount1.completeActivity(pi.getActivityInstanceAtIndex(0), bpmService);
		if (error != BaseErrors.RUNTIME_ERROR()) return (error, "Attempting to complete the Sign activity without signing the agreement should fail");
		( , , , addr, , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(0));
		if (state != uint8(BpmRuntime.ActivityInstanceState.SUSPENDED)) return (BaseErrors.INVALID_STATE(), "Activity1 in Formation Process should still be suspended after completion attempt without signing");
		if (addr != address(userAccount1)) return (BaseErrors.INVALID_STATE(), "userAccount1 should still be the performer of activity1 even after completion failed");

		// test successful completion
		userAccount1.signAgreement(agreement);
		error = userAccount1.completeActivity(pi.getActivityInstanceAtIndex(0), bpmService);
		if (error != BaseErrors.NO_ERROR()) return (error, "Unexpected error attempting to complete Activity1 in Formation Process by user1");
		( , , , , , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(0));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return (BaseErrors.INVALID_STATE(), "ActivityInstance 1 in Formation Process should be completed");

		// verify that the signature app had access to the agreement data mapping
		if (signatureCheckApp.lastAgreement() != address(agreement)) return (BaseErrors.INVALID_STATE(), "The agreement should've been processed by the TestSignatureCheck app.");

		// complete the missing signatures and tasks
		userAccount2.signAgreement(agreement);
		error = userAccount2.completeActivity(pi.getActivityInstanceAtIndex(1), bpmService);
		if (error != BaseErrors.NO_ERROR()) return (error, "Unexpected error attempting to complete Activity1 in Formation Process by user2 in org1");
		( , , , , , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(1));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return (BaseErrors.INVALID_STATE(), "ActivityInstance 2 in Formation Process should be completed");

		userAccount3.signAgreement(agreement);

		if (pi.resolveAddressScope(address(org2), activityId1, pi) != departmentId1) return (BaseErrors.INVALID_STATE(), "Org2 in context of activity1 should show the additional department scope");
		error = userAccount3.completeActivity(pi.getActivityInstanceAtIndex(2), bpmService);
		if (error != BaseErrors.NO_ERROR()) return (error, "Unexpected error attempting to complete Activity1 in Formation Process by user3 in org2");
		( , , , , , state) = pi.getActivityInstanceData(pi.getActivityInstanceAtIndex(2));
		if (state != uint8(BpmRuntime.ActivityInstanceState.COMPLETED)) return (BaseErrors.INVALID_STATE(), "ActivityInstance 3 in Formation Process should be completed");

		// AIs 1-3 should all be completed now and the process has moved into execution
		if (bpmService.getNumberOfProcessInstances() != 2) return (BaseErrors.INVALID_STATE(), "There should be 2 PIs in the system after agreement formation is completed");
		if (bpmService.getBpmServiceDb().getNumberOfActivityInstances() != 4) return (BaseErrors.INVALID_STATE(), "There should be 4 AIs total");
		pi = ProcessInstance(bpmService.getProcessInstanceAtIndex(1));
		if (pi.getState() != uint8(BpmRuntime.ProcessInstanceState.COMPLETED)) return (BaseErrors.INVALID_STATE(), "The Execution PI should be completed");
		if (ActiveAgreement(agreement).getLegalState() != uint8(Agreements.LegalState.FULFILLED)) return (BaseErrors.INVALID_STATE(), "The agreement should be in FULFILLED state");

		return (BaseErrors.NO_ERROR(), SUCCESS);
	}

	/**
	 * Tests workflow handling where the agreement gets cancelled during formation as well as execution.
	 */
	function testCanceledAgreementWorkflow() external returns (uint, string) {

		// re-usable variables for return values
		uint error;
		address addr;
		bool valid;
		bytes32 errorMsg;
		ProcessDefinition formationPD;
		ProcessDefinition executionPD;
		uint numberOfPIs;
	
		// service / test setup
		agreementRegistry = new TestRegistry();
		registryDb = new ActiveAgreementRegistryDb();
		SystemOwned(registryDb).transferSystemOwnership(agreementRegistry);
		AbstractDbUpgradeable(agreementRegistry).acceptDatabase(registryDb);
		agreementRegistry.setBpmService(bpmService);

		userAccount1 = new AgreementPartyAccount(user1Id, this, address(0));
		userAccount2 = new AgreementPartyAccount(user2Id, this, address(0));
		delete parties;
		parties.push(userAccount1);
		parties.push(userAccount2);

		//
		// BPM
		//
		ProcessModel pm;
		(error, addr) = processModelRepository.createProcessModel("Cancellation-Model", "Cancellation Model", [1,0,0], userAccount1, false, EMPTY, EMPTY);
		if (addr == 0x0) return (BaseErrors.INVALID_STATE(), "Unable to create a ProcessModel");
		pm = ProcessModel(addr);
		// Formation Process
		(error, addr) = pm.createProcessDefinition("FormationProcess");
		if (addr == 0x0) return (BaseErrors.INVALID_STATE(), "Unable to create FormationProcess definition");
		formationPD = ProcessDefinition(addr);
		error = formationPD.createActivityDefinition(activityId1, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.RECEIVE, EMPTY, false, EMPTY, EMPTY, EMPTY);
		if (error != BaseErrors.NO_ERROR()) return (error, "Error creating NONE task for formation process definition");
		(valid, errorMsg) = formationPD.validate();
		if (!valid) return (BaseErrors.INVALID_STATE(), bytes32ToString(errorMsg));
		// Execution Process
		(error, addr) = pm.createProcessDefinition("ExecutionProcess");
		if (addr == 0x0) return (BaseErrors.INVALID_STATE(), "Unable to create ExecutionProcess definition");
		executionPD = ProcessDefinition(addr);
		error = executionPD.createActivityDefinition(activityId1, BpmModel.ActivityType.TASK, BpmModel.TaskType.NONE, BpmModel.TaskBehavior.RECEIVE, EMPTY, false, EMPTY, EMPTY, EMPTY);
		if (error != BaseErrors.NO_ERROR()) return (error, "Error creating SERVICE task for execution process definition");
		(valid, errorMsg) = executionPD.validate();
		if (!valid) return (BaseErrors.INVALID_STATE(), bytes32ToString(errorMsg));

		//
		// ARCHETYPE
		//
		addr = archetypeRegistry.createArchetype("TestArchetype", this, "description", 10, false, true, formationPD, executionPD, EMPTY, governingArchetypes);
		if (addr == 0x0) return (BaseErrors.INVALID_STATE(), "Error creating TestArchetype, address is empty");

		//
		// AGREEMENT
		//
		address agreement1;
		address agreement2;
		agreement1 = agreementRegistry.createAgreement(addr, "TestAgreement1", this, EMPTY, EMPTY, EMPTY, EMPTY, 8, false, parties, EMPTY, governingAgreements);
		if (agreement1 == 0x0) return (BaseErrors.INVALID_STATE(), "Unexpected error creating agreement1");
		agreement2 = agreementRegistry.createAgreement(addr, "TestAgreement2", this, EMPTY, EMPTY, EMPTY, EMPTY, 8, false, parties, EMPTY, governingAgreements);
		if (agreement2 == 0x0) return (BaseErrors.INVALID_STATE(), "Unexpected error creating agreement2");

		//
		// FORMATION / EXECUTION
		//
		numberOfPIs = bpmService.getNumberOfProcessInstances();
		ProcessInstance[3] memory pis; // to collect the created PIs
		(error, addr) = agreementRegistry.startFormation(ActiveAgreement(agreement1));
		if (error != BaseErrors.NO_ERROR()) return (error, "Error starting the formation process 1 on agreement1");
		pis[0] = ProcessInstance(addr);
		if (agreementRegistry.getTrackedFormationProcess(agreement1) == 0x0) return (BaseErrors.INVALID_STATE(), "There should be a tracked formation process for agreement1");
		if (agreementRegistry.getTrackedExecutionProcess(agreement1) != 0x0) return (BaseErrors.INVALID_STATE(), "There should be NO tracked execution process for agreement1");
		if (agreementRegistry.getTrackedFormationProcess(agreement1) != address(pis[0])) return (BaseErrors.INVALID_STATE(), "The tracked formation process should match the started formation PI for agreement1");
		(error, addr) = agreementRegistry.startFormation(ActiveAgreement(agreement2));
		if (error != BaseErrors.NO_ERROR()) return (error, "Error starting the formation process 2 on agreement2");
		pis[1] = ProcessInstance(addr);
		if (agreementRegistry.getTrackedFormationProcess(agreement2) == 0x0) return (BaseErrors.INVALID_STATE(), "There should be a tracked formation process for agreement2");
		if (agreementRegistry.getTrackedExecutionProcess(agreement2) != 0x0) return (BaseErrors.INVALID_STATE(), "There should be NO tracked execution process for agreement2");
		if (agreementRegistry.getTrackedFormationProcess(agreement2) != address(pis[1])) return (BaseErrors.INVALID_STATE(), "The tracked formation process should match the started formation PI for agreement2");

		// sign agreement2 and move PI2 into execution phase
		userAccount1.signAgreement(agreement2);
		userAccount2.signAgreement(agreement2);
		if (ActiveAgreement(agreement2).getLegalState() != uint8(Agreements.LegalState.EXECUTED)) return (BaseErrors.INVALID_STATE(), "The agreement2 should be in EXECUTED after signing");
		error = pis[1].completeActivity(pis[1].getActivityInstanceAtIndex(0), bpmService);
		if (error != BaseErrors.NO_ERROR()) return (error, "Error completing wait activity in formation process 2");
	
		if (bpmService.getNumberOfProcessInstances() != numberOfPIs+3) return (BaseErrors.INVALID_STATE(), "There should be 3 additional PIs in the system");
		numberOfPIs = bpmService.getNumberOfProcessInstances();
		// the last added PI should be the execution process of agreement2
		pis[2] = ProcessInstance(bpmService.getProcessInstanceAtIndex(numberOfPIs-1));
		if (agreementRegistry.getTrackedExecutionProcess(agreement2) == 0x0) return (BaseErrors.INVALID_STATE(), "There should now be a tracked execution process for agreement2 after signing");
		if (agreementRegistry.getTrackedExecutionProcess(agreement2) != address(pis[2])) return (BaseErrors.INVALID_STATE(), "The tracked execution process for agreement2 should match the last PI");
		if (pis[0].getState() != uint8(BpmRuntime.ProcessInstanceState.ACTIVE)) return (BaseErrors.INVALID_STATE(), "The Formation PI for agreement1 should be active");
		if (pis[1].getState() != uint8(BpmRuntime.ProcessInstanceState.COMPLETED)) return (BaseErrors.INVALID_STATE(), "The Formation PI for agreement2 should be completed");
		if (pis[2].getState() != uint8(BpmRuntime.ProcessInstanceState.ACTIVE)) return (BaseErrors.INVALID_STATE(), "The Execution PI for agreement2 should be active");

		// cancel the first agreement BEFORE its execution phase (uni-lateral cancellation)
		userAccount2.cancelAgreement(agreement1);
		if (ActiveAgreement(agreement1).getLegalState() != uint8(Agreements.LegalState.CANCELED)) return (BaseErrors.INVALID_STATE(), "agreement1 should be CANCELED");
		if (pis[0].getState() != uint8(BpmRuntime.ProcessInstanceState.ABORTED)) return (BaseErrors.INVALID_STATE(), "The Formation PI for agreement1 should be aborted after canceling");
		
		// cancel the second agreement AFTER it reaches execution phase (multi-lateral cancellation required)
		userAccount2.cancelAgreement(agreement2);
		if (pis[1].getState() != uint8(BpmRuntime.ProcessInstanceState.COMPLETED)) return (BaseErrors.INVALID_STATE(), "The Formation PI for agreement2 should still be completed after 1st cancellation");
		if (pis[2].getState() != uint8(BpmRuntime.ProcessInstanceState.ACTIVE)) return (BaseErrors.INVALID_STATE(), "The Formation PI for agreement2 should still be active after 1st cancellation");
		userAccount1.cancelAgreement(agreement2);
		if (pis[1].getState() != uint8(BpmRuntime.ProcessInstanceState.COMPLETED)) return (BaseErrors.INVALID_STATE(), "The Formation PI for agreement2 should still be completed after 2nd cancellation");
		if (pis[2].getState() != uint8(BpmRuntime.ProcessInstanceState.ABORTED)) return (BaseErrors.INVALID_STATE(), "The Formation PI for agreement2 should be aborted after 2nd cancellation");

		return (BaseErrors.NO_ERROR(), SUCCESS);
	}

	function bytes32ToString(bytes32 x) internal pure returns (string) {
	    bytes memory bytesString = new bytes(32);
	    uint charCount = 0;
	    for (uint j = 0; j < 32; j++) {
	        byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
	        if (char != 0) {
	            bytesString[charCount] = char;
	            charCount++;
	        }
	    }
	    bytes memory bytesStringTrimmed = new bytes(charCount);
	    for (j = 0; j < charCount; j++) {
	        bytesStringTrimmed[j] = bytesString[j];
	    }
	    return string(bytesStringTrimmed);
	}
}

/**
 * @dev ActiveAgreementRegistry that exposes internal structures and functions for testing
 */
contract TestRegistry is DefaultActiveAgreementRegistry {

	function getTrackedFormationProcess(address _agreement) public view returns (address) {
		return ActiveAgreementRegistryDb(database).getAgreementFormationProcess(_agreement);
	}

	function getTrackedExecutionProcess(address _agreement) public view returns (address) {
		return ActiveAgreementRegistryDb(database).getAgreementExecutionProcess(_agreement);
	}

	function setBpmService(BpmService _bpmService) external {
		bpmService = _bpmService;
	}
}

contract TestSignatureCheck is AgreementSignatureCheck {

	address public lastAgreement;

	function getBpmService() external view returns (address) {
		return bpmService;
	}

	function complete(bytes32 _aiId, bytes32 _aId, address _txPerformer) public {
		lastAgreement = bpmService.getActivityInDataAsAddress(_aiId, "agreement");
		super.complete(_aiId, _aId, _txPerformer);
	}

}