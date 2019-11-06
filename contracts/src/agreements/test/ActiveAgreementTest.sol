pragma solidity ^0.5;

import "commons-base/BaseErrors.sol";
import "commons-auth/DefaultOrganization.sol";
import "commons-auth/UserAccount.sol";
import "commons-auth/DefaultUserAccount.sol";

import "agreements/Agreements.sol";
import "agreements/AgreementsAPI.sol";
import "agreements/DefaultActiveAgreement.sol";
import "agreements/DefaultArchetype.sol";

contract ActiveAgreementTest {
  
  	string constant SUCCESS = "success";
	string constant EMPTY_STRING = "";
	bytes32 constant EMPTY = "";

	string constant functionSigAgreementInitialize = "initialize(address,address,address,string,bool,address[],address[])";
	string constant functionSigAgreementSign = "sign()";
	string constant functionSigAgreementCancel = "cancel()";
	string constant functionSigAgreementSetLegalState = "setLegalState(uint8)";
	string constant functionSigAgreementTestLegalState = "testLegalState(uint8)";
	string constant functionSigUpgradeOwnerPermission = "upgradeOwnerPermission(address)";

	address falseAddress = 0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa;
	string dummyFileRef = "{find me}";
	string dummyPrivateParametersFileRef = "{json grant}";
	uint maxNumberOfEvents = 5;
	bytes32 DATA_FIELD_AGREEMENT_PARTIES = "AGREEMENT_PARTIES";

	bytes32 bogusId = "bogus";
	UserAccount signer1;
	UserAccount signer2;

	address[] parties;
	address[] bogusArray = [0xCcD5bA65282C3dafB69b19351C7D5B77b9fDDCA6, 0x5e3621030C9E0aCbb417c8E63f0824A8215a8958, 0x8A8318bdCfFf8c83C4Da727AEEE9483806689cCF, 0x1915FBC9C4A2E610012150D102D1a916C78Aa44f];
	address[] emptyArray;

	/**
	 * @dev Covers the setup and proper data retrieval of an agreement
	 */
	function testActiveAgreementSetup() external returns (string memory) {

		address result;
		bool success;
		ActiveAgreement agreement;
		Archetype archetype;
		signer1 = new DefaultUserAccount();
		signer1.initialize(address(this), address(0));
		signer2 = new DefaultUserAccount();
		signer2.initialize(address(this), address(0));

		// set up the parties.
		delete parties;
		parties.push(address(signer1));
		parties.push(address(signer2));

		archetype = new DefaultArchetype();
		archetype.initialize(10, false, true, falseAddress, falseAddress, falseAddress, falseAddress, emptyArray);

		agreement = new DefaultActiveAgreement();
		// test positive creation first to confirm working function signature
		(success, ) = address(agreement).call(abi.encodeWithSignature(functionSigAgreementInitialize, archetype, address(this), address(this), dummyPrivateParametersFileRef, false, parties, emptyArray));
		if (!success) return "Creating an agreement with valid parameters should succeed";

		// test failures
		(success, ) = address(agreement).call(abi.encodeWithSignature(functionSigAgreementInitialize, address(0), address(this), address(this), dummyPrivateParametersFileRef, false, parties, emptyArray));
		if (success) return "Creating archetype with empty archetype should revert";

		(success, ) = address(agreement).call(abi.encodeWithSignature(functionSigAgreementInitialize, archetype, address(0), address(this), dummyPrivateParametersFileRef, false, parties, emptyArray));
		if (success) return "Creating archetype with empty creator should revert";

		(success, ) = address(agreement).call(abi.encodeWithSignature(functionSigAgreementInitialize, archetype, address(this), address(0), dummyPrivateParametersFileRef, false, parties, emptyArray));
		if (success) return "Creating archetype with empty owner should revert";


		// function testing
		agreement = new DefaultActiveAgreement();
		agreement.initialize(address(archetype), address(this), address(this), dummyPrivateParametersFileRef, false, parties, emptyArray);
		agreement.setEventLogReference(dummyFileRef);
		if (keccak256(abi.encodePacked(agreement.getEventLogReference())) != keccak256(abi.encodePacked(dummyFileRef)))
			return "The EventLog file reference was not set/retrieved correctly";
		agreement.setSignatureLogReference(dummyFileRef);
		if (keccak256(abi.encodePacked(agreement.getSignatureLogReference())) != keccak256(abi.encodePacked(dummyFileRef)))
			return "The SignatureLog file reference was not set/retrieved correctly";

		agreement.setDataValueAsAddressArray(bogusId, bogusArray);

		if (agreement.getNumberOfParties() != parties.length) return "Number of parties not returning expected size";

		result = agreement.getPartyAtIndex(1);
		if (result != address(signer2)) return "Address of party at index 1 not as expected";

		if (agreement.getArchetype() != address(archetype)) return "Archetype not set correctly";

		// test parties array retrieval via DataStorage (needed for workflow participants)
		address[] memory partiesArr = agreement.getDataValueAsAddressArray(DATA_FIELD_AGREEMENT_PARTIES);
		address[] memory bogusArr = agreement.getDataValueAsAddressArray(bogusId);
		if (partiesArr[0] != address(signer1)) return "address[] retrieval via DATA_FIELD_AGREEMENT_PARTIES did not yield first element as expected";
		if (bogusArr[0] != address(0xCcD5bA65282C3dafB69b19351C7D5B77b9fDDCA6)) return "address[] retrieval via regular ID did not yield first element as expected";
		if (agreement.getArrayLength(DATA_FIELD_AGREEMENT_PARTIES) != agreement.getNumberOfParties()) return "Array size count via DATA_FIELD_AGREEMENT_PARTIES did not match the number of parties";

		return SUCCESS;
	}

	/**
	 * @dev Tests the legal state change modifier
	 */
	function testLegalStateChangeValidation() external returns (string memory) {

		bool success;
		LegalStateEnforcedAgreement agreement;
		Archetype archetype;
		signer1 = new DefaultUserAccount();
		signer1.initialize(address(this), address(0));
		signer2 = new DefaultUserAccount();
		signer2.initialize(address(this), address(0));

		// set up the parties.
		delete parties;
		parties.push(address(signer1));
		parties.push(address(signer2));

		archetype = new DefaultArchetype();
		archetype.initialize(10, false, true, falseAddress, falseAddress, falseAddress, falseAddress, emptyArray);

		agreement = new LegalStateEnforcedAgreement();
		agreement.initialize(address(archetype), address(this), address(this), dummyPrivateParametersFileRef, false, parties, emptyArray);
		agreement.resetLegalState();

		if (agreement.getLegalState() != uint8(Agreements.LegalState.UNDEFINED))
			return "The legal state of the agreement should be UNDEFINED at the beginning of the test";
		// confirm function signature is working correctly first
		(success, ) = address(agreement).call(abi.encodeWithSignature(functionSigAgreementTestLegalState, uint8(Agreements.LegalState.EXECUTED)));
		if (!success) return "It should be possible to set the legal state to EXECUTED, if it was previously UNDEFINED";
		if (agreement.getLegalState() != uint8(Agreements.LegalState.EXECUTED))
			return "The legal state of the agreement should be EXECUTED after first setting";
		(success, ) = address(agreement).call(abi.encodeWithSignature(functionSigAgreementTestLegalState, uint8(Agreements.LegalState.FULFILLED)));
		if (!success) return "It should be possible to set the legal state to FULFILLED, if it was previously EXECUTED";
		if (agreement.getLegalState() != uint8(Agreements.LegalState.FULFILLED))
			return "The legal state of the agreement should be FULFILLED after second setting";
		(success, ) = address(agreement).call(abi.encodeWithSignature(functionSigAgreementTestLegalState, uint8(Agreements.LegalState.DRAFT)));
		if (success) return "It should not be possible to switch to DRAFT when agreement was previously FULFILLED";

		// run through a typical lifecycle and test illegal changes along the way
		agreement.resetLegalState();
		if (!agreement.testLegalState(Agreements.LegalState.FORMULATED)) return "UNDEFINED -> FORMULATED should be valid";
		if (!agreement.testLegalState(Agreements.LegalState.DRAFT)) return "FORMULATED -> DRAFT should be valid";
		(success, ) = address(agreement).call(abi.encodeWithSignature(functionSigAgreementTestLegalState, uint8(Agreements.LegalState.FULFILLED)));
		if (success) return "DRAFT -> FULFILLED should not be valid";
		(success, ) = address(agreement).call(abi.encodeWithSignature(functionSigAgreementTestLegalState, uint8(Agreements.LegalState.DEFAULT)));
		if (success) return "DRAFT -> DEFAULT should not be valid";
		(success, ) = address(agreement).call(abi.encodeWithSignature(functionSigAgreementTestLegalState, uint8(Agreements.LegalState.EXECUTED)));
		if (success) return "DRAFT -> EXECUTED should not be valid";
		if (!agreement.testLegalState(Agreements.LegalState.FORMULATED)) return "DRAFT -> FORMULATED should be valid";
		(success, ) = address(agreement).call(abi.encodeWithSignature(functionSigAgreementTestLegalState, uint8(Agreements.LegalState.FULFILLED)));
		if (success) return "FORMULATED -> FULFILLED should not be valid";
		(success, ) = address(agreement).call(abi.encodeWithSignature(functionSigAgreementTestLegalState, uint8(Agreements.LegalState.DEFAULT)));
		if (success) return "FORMULATED -> DEFAULT should not be valid";
		(success, ) = address(agreement).call(abi.encodeWithSignature(functionSigAgreementTestLegalState, uint8(Agreements.LegalState.UNDEFINED)));
		if (success) return "FORMULATED -> UNDEFINED should not be valid";
		if (!agreement.testLegalState(Agreements.LegalState.EXECUTED)) return "FORMULATED -> EXECUTED should be valid";
		(success, ) = address(agreement).call(abi.encodeWithSignature(functionSigAgreementTestLegalState, uint8(Agreements.LegalState.FORMULATED)));
		if (success) return "EXECUTED -> FORMULATED should not be valid";
		(success, ) = address(agreement).call(abi.encodeWithSignature(functionSigAgreementTestLegalState, uint8(Agreements.LegalState.DRAFT)));
		if (success) return "EXECUTED -> DRAFT should not be valid";
		(success, ) = address(agreement).call(abi.encodeWithSignature(functionSigAgreementTestLegalState, uint8(Agreements.LegalState.UNDEFINED)));
		if (success) return "EXECUTED -> UNDEFINED should not be valid";
		if (!agreement.testLegalState(Agreements.LegalState.DEFAULT)) return "EXECUTED -> DEFAULT should be valid";
		(success, ) = address(agreement).call(abi.encodeWithSignature(functionSigAgreementTestLegalState, uint8(Agreements.LegalState.EXECUTED)));
		if (success) return "DEFAULT -> EXECUTED should not be valid";
		(success, ) = address(agreement).call(abi.encodeWithSignature(functionSigAgreementTestLegalState, uint8(Agreements.LegalState.FORMULATED)));
		if (success) return "DEFAULT -> FORMULATED should not be valid";
		(success, ) = address(agreement).call(abi.encodeWithSignature(functionSigAgreementTestLegalState, uint8(Agreements.LegalState.FULFILLED)));
		if (success) return "DEFAULT -> FULFILLED should not be valid";

		return SUCCESS;
	}

	/**
	 * @dev Covers testing signing an agreement via users and organizations and the associated state changes.
	 */
	function testActiveAgreementSigning() external returns (string memory) {

	  	ActiveAgreement agreement;
		Archetype archetype;
		bool success;

		signer1 = new DefaultUserAccount();
		signer1.initialize(address(this), address(0));
		signer2 = new DefaultUserAccount();
		signer2.initialize(address(this), address(0));

		// set up the parties.
		// Signer1 is a direct signer
		// Signer 2 is signing on behalf of an organization (default department)
		address[] memory emptyAddressArray;
		Organization org1 = new DefaultOrganization();
		org1.initialize(emptyAddressArray, EMPTY);
		if (!org1.addUserToDepartment(address(signer2), EMPTY)) return "Unable to add user account to organization";
		delete parties;
		parties.push(address(signer1));
		parties.push(address(org1));

		archetype = new DefaultArchetype();
		archetype.initialize(10, false, true, falseAddress, falseAddress, falseAddress, falseAddress, emptyArray);
		agreement = new DefaultActiveAgreement();
		agreement.initialize(address(archetype), address(this), address(this), dummyPrivateParametersFileRef, false, parties, emptyArray);

		// test signing
		address signee;
		uint timestamp;
		(success, ) = address(agreement).call(abi.encodeWithSignature(functionSigAgreementSign));
		if (success) return "Signing from test address should REVERT due to invalid actor";
		(signee, timestamp) = agreement.getSignatureDetails(address(signer1));
		if (timestamp != 0) return "Signature timestamp for signer1 should be 0 before signing";
		if (AgreementsAPI.isFullyExecuted(address(agreement))) return "AgreementsAPI.isFullyExecuted should be false before signing";
		if (agreement.getLegalState() == uint8(Agreements.LegalState.EXECUTED)) return "Agreement legal state should NOT be EXECUTED";

		// Signing with Signer1 as party
		signer1.forwardCall(address(agreement), abi.encodeWithSignature(functionSigAgreementSign));
		if (!agreement.isSignedBy(address(signer1))) return "Agreement should be signed by signer1";
		(signee, timestamp) = agreement.getSignatureDetails(address(signer1));
		if (signee != address(signer1)) return "Signee for signer1 should be signer1";
		if (timestamp == 0) return "Signature timestamp for signer1 should be set after signing";
		if (AgreementsAPI.isFullyExecuted(address(agreement))) return "AgreementsAPI.isFullyExecuted should be false after signer1";
		if (agreement.getLegalState() == uint8(Agreements.LegalState.EXECUTED)) return "Agreement legal state should NOT be EXECUTED after signer1";

		// Signing with Signer2 via the organization
		signer2.forwardCall(address(agreement), abi.encodeWithSignature(functionSigAgreementSign));
		if (!agreement.isSignedBy(address(signer1))) return "Agreement should be signed by signer2";
		if (agreement.isSignedBy(address(org1))) return "Agreement should NOT be signed by org1";
		(signee, timestamp) = agreement.getSignatureDetails(address(org1));
		if (signee != address(signer2)) return "Signee for org1 should be signer1";
		if (timestamp == 0) return "Signature timestamp for org1 should be set after signing";
		if (!AgreementsAPI.isFullyExecuted(address(agreement))) return "AgreementsAPI.isFullyExecuted should be true after signer2";
		if (agreement.getLegalState() != uint8(Agreements.LegalState.EXECUTED)) return "Agreement legal state should be EXECUTED after signer2";

		// test external legal state control in combination with signing
		agreement = new DefaultActiveAgreement();
		agreement.initialize(address(archetype), address(this), address(this), dummyPrivateParametersFileRef, false, parties, emptyArray);
		agreement.initializeObjectAdministrator(address(this));
		agreement.grantPermission(agreement.ROLE_ID_LEGAL_STATE_CONTROLLER(), address(signer1));
		signer1.forwardCall(address(agreement), abi.encodeWithSignature(functionSigAgreementSign));
		signer2.forwardCall(address(agreement), abi.encodeWithSignature(functionSigAgreementSign));
		if (!AgreementsAPI.isFullyExecuted(address(agreement))) return "AgreementsAPI.isFullyExecuted should be true after both signatures were applied even with external legal state control";
		if (agreement.getLegalState() != uint8(Agreements.LegalState.FORMULATED)) return "Agreement legal state should still be FORMULATED with external legal state control";
		// externally change the legal state
		(success, ) = address(agreement).call(abi.encodeWithSignature(functionSigAgreementSetLegalState, uint8(Agreements.LegalState.EXECUTED)));
		if (success) return "The test contract should not be allowed to change the legal state of the agreement";
		signer1.forwardCall(address(agreement), abi.encodeWithSignature(functionSigAgreementSetLegalState, uint8(Agreements.LegalState.EXECUTED)));
		if (agreement.getLegalState() != uint8(Agreements.LegalState.EXECUTED)) return "Agreement legal state should be EXECUTED after legal state controller changed it";

		return SUCCESS;
	}

	/**
	 * @dev Covers canceling an agreement in different stages
	 */
	function testActiveAgreementCancellation() external returns (string memory) {

		ActiveAgreement agreement1;
		ActiveAgreement agreement2;
		Archetype archetype;
		bool success;

		signer1 = new DefaultUserAccount();
		signer1.initialize(address(this), address(0));
		signer2 = new DefaultUserAccount();
		signer2.initialize(address(this), address(0));

		// set up the parties.
		delete parties;
		parties.push(address(signer1));
		parties.push(address(signer2));

		archetype = new DefaultArchetype();
		archetype.initialize(10, false, true, falseAddress, falseAddress, falseAddress, falseAddress, emptyArray);
		agreement1 = new DefaultActiveAgreement();
		agreement1.initialize(address(archetype), address(this), address(this), dummyPrivateParametersFileRef, false, parties, emptyArray);
		agreement2 = new DefaultActiveAgreement();
		agreement2.initialize(address(archetype), address(this), address(this), dummyPrivateParametersFileRef, false, parties, emptyArray);

		// test invalid cancellation and states
		(success, ) = address(agreement1).call(abi.encodeWithSignature(functionSigAgreementCancel));
		if (success) return "Canceling from test address should REVERT due to invalid actor";
		if (agreement1.getLegalState() == uint8(Agreements.LegalState.CANCELED)) return "Agreement1 legal state should NOT be CANCELED";
		if (agreement2.getLegalState() == uint8(Agreements.LegalState.CANCELED)) return "Agreement2 legal state should NOT be CANCELED";

		// Agreement1 is canceled during formation
		signer2.forwardCall(address(agreement1), abi.encodeWithSignature(functionSigAgreementCancel));
		if (agreement1.getLegalState() != uint8(Agreements.LegalState.CANCELED)) return "Agreement1 legal state should be CANCELED after unilateral cancellation in formation";

		// Agreement2 is canceled during execution
		signer1.forwardCall(address(agreement2), abi.encodeWithSignature(functionSigAgreementSign));
		signer2.forwardCall(address(agreement2), abi.encodeWithSignature(functionSigAgreementSign));
		if (agreement2.getLegalState() != uint8(Agreements.LegalState.EXECUTED)) return "Agreemen2 legal state should be EXECUTED after parties signed";
		signer1.forwardCall(address(agreement2), abi.encodeWithSignature(functionSigAgreementCancel));
		if (agreement2.getLegalState() != uint8(Agreements.LegalState.EXECUTED)) return "Agreement2 legal state should still be EXECUTED after unilateral cancellation";
		signer2.forwardCall(address(agreement2), abi.encodeWithSignature(functionSigAgreementCancel));
		if (agreement2.getLegalState() != uint8(Agreements.LegalState.CANCELED)) return "Agreement2 legal state should be CANCELED after bilateral cancellation";

		return SUCCESS;
	}
}

/**
 * Helper contract to test the pre_validateNextLegalState modifier which is currently
 * not yet used in the DefaultActiveAgreement
 */
contract LegalStateEnforcedAgreement is DefaultActiveAgreement {

	function resetLegalState()
		external
	{
		legalState = Agreements.LegalState.UNDEFINED;
	}

	function testLegalState(Agreements.LegalState _legalState)
		pre_validateNextLegalState(_legalState)
		external
		returns (bool)
	{
		legalState = _legalState;
		return true;
	}
}