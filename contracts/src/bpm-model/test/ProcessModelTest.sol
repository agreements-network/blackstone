pragma solidity ^0.4.23;

import "commons-base/BaseErrors.sol";

import "bpm-model/DefaultProcessModel.sol";
import "bpm-model/DefaultProcessDefinition.sol";

contract ProcessModelTest {
	
	// test data
	bytes32 formHash = "8c7yb387ybtcnqf89y348t072q34fchg";
	bytes32 participant1Id = "Participant1";
	bytes32 participant2Id = "Participant2";
	address participant1Address = 0x776FDe59876aAB7D654D656e654Ed9876574c54c;
	address author = 0x9d7fDE63776AaB9E234d656E654ED9876574C54C;

	bytes32 EMPTY = "";

	function testProcessModel() external returns (string) {
		
		uint error;
		address newAddress;

		ProcessModel pm = new DefaultProcessModel("testModel", "Test Model", [1,2,3], author, false, "hoardAddress", "hoardSecret");
		if (pm.getId() != "testModel") return "ProcessModel ID not set correctly";
		if (pm.getName() != "Test Model") return "ProcessModel Name not set correctly";
		if (pm.getAuthor() != author) return "ProcessModel Author not set correctly";
		if (pm.isPrivate() != false) return "ProcessModel expected to be public";
		if (pm.major() != 1 || pm.minor() != 2 || pm.patch() != 3) return "ProcessModel Version not set correctly";
		bytes32 location;
		bytes32 secret;
		(location, secret) = pm.getDiagram();
		if (location != "hoardAddress") return "wrong hoard location retrieved";
		if (secret != "hoardSecret") return "wrong hoard secret retrieved";

		(error, newAddress) = pm.createProcessDefinition("p1");
		if (error != BaseErrors.NO_ERROR()) return "$1";
		ProcessDefinition pd = ProcessDefinition(newAddress);
		
		if (pm.getProcessDefinition("p1") != address(pd)) return "$1";

		// test process interface handling
		error = pm.addProcessInterface("AgreementFormation");
		if (error != BaseErrors.NO_ERROR()) return "Unable to add process interface to model";
		error = pd.addProcessInterfaceImplementation(0x0, "AgreementFormation");
		if (error != BaseErrors.NO_ERROR()) return "$1";
		if (pm.getNumberOfProcessInterfaces() != 1) return "Wrong number of process interfaces";

		// test participants
		error = pm.addParticipant(participant1Id, 0x0, EMPTY, EMPTY, 0x0);
		if (error != BaseErrors.INVALID_PARAM_VALUE()) return "$1";
		error = pm.addParticipant(participant1Id, participant1Address, EMPTY, EMPTY, this);
		if (error != BaseErrors.INVALID_PARAM_VALUE()) return "$1";
		error = pm.addParticipant(participant1Id, participant1Address, EMPTY, "storageId", 0x0);
		if (error != BaseErrors.INVALID_PARAM_VALUE()) return "$1";
		error = pm.addParticipant(participant1Id, participant1Address, EMPTY, EMPTY, 0x0);
		if (error != BaseErrors.NO_ERROR()) return "$1";
		error = pm.addParticipant(participant1Id, participant1Address, EMPTY, EMPTY, 0x0);
		if (error != BaseErrors.RESOURCE_ALREADY_EXISTS()) return "$1";

		error = pm.addParticipant(participant2Id, 0x0, "Buyer", "myDataStore", 0x0);
		if (error != BaseErrors.NO_ERROR()) return "$1";
		if (pm.getConditionalParticipant("Buyer", "", 0x0) != "")
			return "$1";
		if (pm.getConditionalParticipant("", "", 0x0) != "")
			return "Retrieving empty conditional participant should return nothing";
		if (pm.getConditionalParticipant("Buyer", "myDataStore", 0x0) != participant2Id)
			return "$1";

		return "success";
	}
}