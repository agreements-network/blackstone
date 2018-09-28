pragma solidity ^0.4.23;

import "commons-base/BaseErrors.sol";
import "commons-auth/DefaultOrganization.sol";

import "agreements/AgreementPartyAccount.sol";
import "agreements/Agreements.sol";
import "agreements/AgreementsAPI.sol";
import "agreements/DefaultActiveAgreement.sol";
import "agreements/DefaultArchetype.sol";

contract ActiveAgreementTest {
  
  string constant SUCCESS = "success";

	DefaultArchetype archetype;
	address falseAddress = 0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa;
	bytes32 dummyHoardAddress = "hoardAddress";
	bytes32 dummyHoardSecret = "hoardSecret";
	bytes32 dummyEventLogHoardAddress = "eventLogHoardAddress";
	bytes32 dummyEventLogHoardSecret = "eventLogHoardSecret";
	uint maxNumberOfEvents = 5;
	bytes32 DATA_FIELD_AGREEMENT_PARTIES = "AGREEMENT_PARTIES";

	bytes32 agreementName = "active agreement name";
	bytes32 bogusId = "bogus";
	TestSigner signer1 = new TestSigner("signer1");
	TestSigner signer2 = new TestSigner("signer2");

	address[] parties;
	address[100] bogusArray = [0xCcD5bA65282C3dafB69b19351C7D5B77b9fDDCA6, 0x5e3621030C9E0aCbb417c8E63f0824A8215a8958, 0x8A8318bdCfFf8c83C4Da727AEEE9483806689cCF, 0x1915FBC9C4A2E610012150D102D1a916C78Aa44f];
	address[] emptyArray;

	/**
	 * @dev Covers the setup and proper data retrieval of an agreement
	 */
	function testActiveAgreementSetup() external returns (string) {

		address result;
	  ActiveAgreement agreement;

		// set up the parties.
		delete parties;
		parties.push(address(signer1));
		parties.push(address(signer2));

		archetype = new DefaultArchetype("archetype name", falseAddress, "description", 10, false, true, falseAddress, falseAddress, emptyArray);
		agreement = new DefaultActiveAgreement(archetype, agreementName, this, dummyHoardAddress, dummyHoardSecret, dummyEventLogHoardAddress, dummyEventLogHoardSecret, maxNumberOfEvents, false, parties, emptyArray);
		agreement.setDataValueAsAddressArray(bogusId, bogusArray);

		if (agreement.getName() != agreementName) return "Name not set correctly";
		if (agreement.getNumberOfParties() != parties.length) return "Number of parties not returning expected size";

		result = agreement.getPartyAtIndex(1);
		if (result != address(signer2)) return "Address of party at index 1 not as expected";

		if (agreement.getArchetype() != address(archetype)) return "Archetype not set correctly";

		// test parties array retrieval via DataStorage (needed for workflow participants)
		address[100] memory partiesArr = agreement.getDataValueAsAddressArray(DATA_FIELD_AGREEMENT_PARTIES);
		address[100] memory bogusArr = agreement.getDataValueAsAddressArray(bogusId);
		if (partiesArr[0] != address(signer1)) return "$1";
		if (bogusArr[0] != address(0xCcD5bA65282C3dafB69b19351C7D5B77b9fDDCA6)) return "$1";
		if (agreement.getNumberOfArrayEntries(DATA_FIELD_AGREEMENT_PARTIES, false) != agreement.getNumberOfParties()) return "$1";

		return SUCCESS;
	}

	/**
	 * @dev Covers testing signing an agreement via users and organizations and the associated state changes.
	 */
	function testActiveAgreementSigning() external returns (string) {

		uint error;
	  	ActiveAgreement agreement;

		// set up the parties.
		// Signer1 is a direct signer
		// Signer 2 is signing on behalf of an organization
		address[10] memory emptyAddressArray;
		DefaultOrganization org1 = new DefaultOrganization(emptyAddressArray);
		if (!org1.addUser(signer2)) return "Unable to add user account to organization";
		delete parties;
		parties.push(address(signer1));
		parties.push(address(org1));

		archetype = new DefaultArchetype("archetype name", falseAddress, "description", 10, false, true, falseAddress, falseAddress, emptyArray);
		agreement = new DefaultActiveAgreement(archetype, agreementName, this, dummyHoardAddress, dummyHoardSecret, dummyEventLogHoardAddress, dummyEventLogHoardSecret, maxNumberOfEvents, false, parties, emptyArray);

		// test signing
		address signee;
		uint timestamp;
		if (address(agreement).call(bytes4(keccak256(abi.encodePacked("sign()")))))
			return "Signing from test address should REVERT due to invalid actor";
		(signee, timestamp) = agreement.getSignatureDetails(signer1);
		if (timestamp != 0) return "$1";
		if (AgreementsAPI.isFullyExecuted(agreement)) return "$1";
		if (agreement.getLegalState() == uint8(Agreements.LegalState.EXECUTED)) return "Agreement legal state should NOT be EXECUTED";

		// Signing with Signer1 as party
		signer1.signAgreement(agreement);
		if (!agreement.isSignedBy(signer1)) return "Agreement should be signed by signer1";
		(signee, timestamp) = agreement.getSignatureDetails(signer1);
		if (signee != address(signer1)) return "Signee for signer1 should be signer1";
		if (timestamp == 0) return "$1";
		if (AgreementsAPI.isFullyExecuted(agreement)) return "$1";
		if (agreement.getLegalState() == uint8(Agreements.LegalState.EXECUTED)) return "$1";

		// Signing with Signer2 via the organization
		signer2.signAgreement(agreement);
		if (!agreement.isSignedBy(signer1)) return "Agreement should be signed by signer2";
		if (agreement.isSignedBy(org1)) return "Agreement should NOT be signed by org1";
		(signee, timestamp) = agreement.getSignatureDetails(org1);
		if (signee != address(signer2)) return "Signee for org1 should be signer1";
		if (timestamp == 0) return "$1";
		if (!AgreementsAPI.isFullyExecuted(agreement)) return "$1";
		if (agreement.getLegalState() != uint8(Agreements.LegalState.EXECUTED)) return "$1";

		return SUCCESS;
	}

	/**
	 * @dev Covers canceling an agreement in different stages
	 */
	function testActiveAgreementCancellation() external returns (string) {

		ActiveAgreement agreement1;
		ActiveAgreement agreement2;

		// set up the parties.
		delete parties;
		parties.push(address(signer1));
		parties.push(address(signer2));

		archetype = new DefaultArchetype("archetype name", falseAddress, "description", 10, false, true, falseAddress, falseAddress, emptyArray);
		agreement1 = new DefaultActiveAgreement(archetype, "Agreement1", this, dummyHoardAddress, dummyHoardSecret, dummyEventLogHoardAddress, dummyEventLogHoardSecret, maxNumberOfEvents, false, parties, emptyArray);
		agreement2 = new DefaultActiveAgreement(archetype, "Agreement2", this, dummyHoardAddress, dummyHoardSecret, dummyEventLogHoardAddress, dummyEventLogHoardSecret, maxNumberOfEvents, false, parties, emptyArray);

		// test invalid cancellation and states
		if (address(agreement1).call(bytes4(keccak256(abi.encodePacked("cancel()")))))
			return "Canceling from test address should REVERT due to invalid actor";
		if (agreement1.getLegalState() == uint8(Agreements.LegalState.CANCELED)) return "Agreement1 legal state should NOT be CANCELED";
		if (agreement2.getLegalState() == uint8(Agreements.LegalState.CANCELED)) return "Agreement2 legal state should NOT be CANCELED";

		// Agreement1 is canceled during formation
		signer2.cancelAgreement(agreement1);
		if (agreement1.getLegalState() != uint8(Agreements.LegalState.CANCELED)) return "$1";

		// Agreement2 is canceled during execution
		signer1.signAgreement(agreement2);
		signer2.signAgreement(agreement2);
		if (agreement2.getLegalState() != uint8(Agreements.LegalState.EXECUTED)) return "$1";
		signer1.cancelAgreement(agreement2);
		if (agreement2.getLegalState() != uint8(Agreements.LegalState.EXECUTED)) return "$1";
		signer2.cancelAgreement(agreement2);
		if (agreement2.getLegalState() != uint8(Agreements.LegalState.CANCELED)) return "$1";

		return SUCCESS;
	}

}

contract TestSigner is AgreementPartyAccount {

	constructor(bytes32 _id) public AgreementPartyAccount(_id, msg.sender, 0x0) {

	}

}
