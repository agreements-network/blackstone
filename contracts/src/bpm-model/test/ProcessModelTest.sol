pragma solidity ^0.5;

import "commons-base/BaseErrors.sol";
import "commons-utils/DataTypes.sol";
import "commons-management/ArtifactsRegistry.sol";
import "commons-management/DefaultArtifactsRegistry.sol";

import "bpm-model/DefaultProcessModel.sol";
import "bpm-model/DefaultProcessDefinition.sol";

contract ProcessModelTest {
	
	// test data
	bytes32 formHash = "8c7yb387ybtcnqf89y348t072q34fchg";
	bytes32 participant1Id = "Participant1";
	bytes32 participant2Id = "Participant2";
	address participant1Address = 0x776FDe59876aAB7D654D656e654Ed9876574c54c;
	address author = 0x9d7fDE63776AaB9E234d656E654ED9876574C54C;
	string modelName = "Test Model";
	string dummyModelFileReference = "{json grant string}";

	bytes32 EMPTY = "";

	ProcessDefinition defaultProcessDefinitionImpl = new DefaultProcessDefinition();

	function testProcessModel() external returns (string memory) {
		
		uint error;
		address newAddress;

		ProcessModel pm = new DefaultProcessModel();
		ArtifactsRegistry artifactsRegistry = new DefaultArtifactsRegistry();
        DefaultArtifactsRegistry(address(artifactsRegistry)).initialize();
		artifactsRegistry.registerArtifact(pm.OBJECT_CLASS_PROCESS_DEFINITION(), address(defaultProcessDefinitionImpl), defaultProcessDefinitionImpl.getArtifactVersion(), true);

		pm.initialize("testModel", [1,2,3], author, false, dummyModelFileReference);
		if (pm.getId() != "testModel") return "ProcessModel ID not set correctly";
		if (pm.getAuthor() != author) return "ProcessModel Author not set correctly";
		if (pm.isPrivate() != false) return "ProcessModel expected to be public";
		if (pm.getVersionMajor() != 1 || pm.getVersionMinor() != 2 || pm.getVersionPatch() != 3) return "ProcessModel Version not set correctly";
		string memory modelFileRef = pm.getModelFileReference();
		if (keccak256(abi.encodePacked(modelFileRef)) != keccak256(abi.encodePacked(dummyModelFileReference))) return "model file reference should match";

		// data definitions
		if (pm.getNumberOfDataDefinitions() != 0) return "There should not be any data definitions in the model after creation";
		pm.addDataDefinition(EMPTY, "Age", DataTypes.ParameterType.POSITIVE_NUMBER);
		pm.addDataDefinition("agreement", "Hash", DataTypes.ParameterType.BYTES32);
		if (pm.getNumberOfDataDefinitions() != 2) return "There should 2 data definitions in the model";
		bytes32 key;
		uint paramType;
		(key, paramType) = pm.getDataDefinitionDetailsAtIndex(0);
		if (key != keccak256(abi.encodePacked(EMPTY,bytes32("Age")))) return "Hashed key for Age data definition should match";
		if (paramType != uint(DataTypes.ParameterType.POSITIVE_NUMBER)) return "Parameter type for Age data definition should be Number";
		(key, paramType) = pm.getDataDefinitionDetailsAtIndex(1);
		if (key != keccak256(abi.encodePacked(bytes32("agreement"),bytes32("Hash")))) return "Hashed key for Hash data definition should match";
		if (paramType != uint(DataTypes.ParameterType.BYTES32)) return "Parameter type for Hash data definition should be Bytes32";

		newAddress = pm.createProcessDefinition("p1", address(artifactsRegistry));
		ProcessDefinition pd = ProcessDefinition(newAddress);
		
		if (pm.getProcessDefinition("p1") != address(pd)) return "Returned ProcessDefinition address does not match.";

		// test process interface handling
		error = pm.addProcessInterface("AgreementFormation");
		if (error != BaseErrors.NO_ERROR()) return "Unable to add process interface to model";
		error = pd.addProcessInterfaceImplementation(address(0), "AgreementFormation");
		if (error != BaseErrors.NO_ERROR()) return "Unable to add valid process interface to process definition.";
		if (pm.getNumberOfProcessInterfaces() != 1) return "Wrong number of process interfaces";

		// test participants
		error = pm.addParticipant(participant1Id, address(0), EMPTY, EMPTY, address(0));
		if (error != BaseErrors.INVALID_PARAM_VALUE()) return "Expected INVALID_PARAM_VALUE setting conditional participant without dataPath";
		error = pm.addParticipant(participant1Id, participant1Address, EMPTY, EMPTY, address(this));
		if (error != BaseErrors.INVALID_PARAM_VALUE()) return "Expected INVALID_PARAM_VALUE setting participant and conditional participant dataStorage";
		error = pm.addParticipant(participant1Id, participant1Address, EMPTY, "storageId", address(0));
		if (error != BaseErrors.INVALID_PARAM_VALUE()) return "Expected INVALID_PARAM_VALUE setting participant and conditional participant dataStorage ID";
		error = pm.addParticipant(participant1Id, participant1Address, EMPTY, EMPTY, address(0));
		if (error != BaseErrors.NO_ERROR()) return "Unexpected error adding valid participant1 to the model";
		error = pm.addParticipant(participant1Id, participant1Address, EMPTY, EMPTY, address(0));
		if (error != BaseErrors.RESOURCE_ALREADY_EXISTS()) return "Expected RESOURCE_ALREADY_EXISTS adding participant twice";

		error = pm.addParticipant(participant2Id, address(0), "Buyer", "myDataStore", address(0));
		if (error != BaseErrors.NO_ERROR()) return "Unexpected error adding valid participant2 to the model";
		if (pm.getConditionalParticipant("Buyer", "", address(0)) != "")
			return "Retrieving invalid conditional participant Buyer should return nothing";
		if (pm.getConditionalParticipant("", "", address(0)) != "")
			return "Retrieving empty conditional participant should return nothing";
		if (pm.getConditionalParticipant("Buyer", "myDataStore", address(0)) != participant2Id)
			return "Retrieving valid conditional participant should return participant2";

		return "success";
	}
}