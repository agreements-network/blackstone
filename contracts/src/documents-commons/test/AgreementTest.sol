pragma solidity ^0.5;

import "commons-base/BaseErrors.sol";

import "documents-commons/Agreement.sol";
import "documents-commons/test/SignatoryProxy.sol";

contract AgreementTest {

    // this array can be used to pass multiple signatories to the agreement.addSignatories function
	address[] signatories;
	address public confirmedAgreement;

    // makes sure signatories are empty before entering a test function
    modifier pre_cleanSignatories() {
        delete signatories;
        _;
    }

    /**
     * @dev Tests agreement modifiers.
     */
	function testModifiers() external returns (string memory) {

        TestAgreement modAgreement;

        // onlyBySignatory
		modAgreement = new TestAgreement("modAgreement1");
		if (modAgreement.modifyByOnlyBySignatory(address(this))) return "onlyBySignatory for owner should fail";
		if (modAgreement.modifyByOnlyBySignatory(msg.sender)) return "onlyBySignatory with msg.sender should fail";
		modAgreement.addSignatory(address(this));
		if (!modAgreement.modifyByOnlyBySignatory(address(this))) return "onlyBySignatory should pass after adding owner";
		modAgreement.addSignatory(msg.sender);
        if (!modAgreement.modifyByOnlyBySignatory(msg.sender)) return "onlyBySignatory should pass after adding msg.sender";

        // onlyByOwnerOrSignatory
		modAgreement = new TestAgreement("modAgreement2");
		if (!modAgreement.modifyByOnlyByOwnerOrSignatory(address(this))) return "onlyByOwnerOrSignatory should pass for owner";
		if (modAgreement.modifyByOnlyByOwnerOrSignatory(msg.sender)) return "onlyByOwnerOrSignatory should fail for msg.sender";
		modAgreement.addSignatory(msg.sender);
		if (!modAgreement.modifyByOnlyByOwnerOrSignatory(msg.sender)) return "onlyByOwnerOrSignatory should pass after adding msg.sender";

		return "success";
	}

	/**
	 * @dev test different scenarios of adding signatories
	 */
	function testSignatoryManagement() external pre_cleanSignatories returns (string memory) {

		Agreement agreement = new Agreement("Agreement 1");

        SignatoryProxy party1 = new SignatoryProxy();
        SignatoryProxy party2 = new SignatoryProxy();
        SignatoryProxy party3 = new SignatoryProxy();

		// Various signatory scenarios
		signatories.push(address(party1));
		signatories.push(address(party2));
		agreement.addSignatories(signatories);
		if (agreement.getSignatoriesSize() != 2) return "signatoriesSize of 2 expected";
        agreement.addSignatory(address(this));
        if (agreement.getSignatoriesSize() != 3) return "signatoriesSize of 3 expected";

        // check invalid signatories
        agreement.addSignatory(address(0));
        if (agreement.getSignatoriesSize() != 3) return "signatoriesSize should be unchanged and reject 0x0";
        signatories.push(address(party3));
        agreement.addSignatories(signatories);
        if (agreement.getSignatoriesSize() != 4) return "signatoriesSize should have only added party3 and rejected existing addresses";

        return "success";
    }

    /**
     * @dev Uses the given agreement to test version adding, signing, and agreement state changes.
     */
    function testVersionSigning() external pre_cleanSignatories returns (string memory) {

        string memory versionHash1 = "9823nriJH76guFJBk66878g";
        string memory versionHash2 = "kh87tjGFytf65ghfyf76t7yuGYGY";

		Agreement agreement = new Agreement("MyAgreement");

        SignatoryProxy party1 = new SignatoryProxy();
        SignatoryProxy party2 = new SignatoryProxy();
        SignatoryProxy party3 = new SignatoryProxy();

		signatories.push(address(party1));
		signatories.push(address(party2));
		signatories.push(address(party3));
		signatories.push(address(this));
        agreement.addSignatories(signatories);

        // Sign first version with 2/4 signatories and check states
		agreement.addVersion(versionHash1);
        if (party1.signAgreement(address(agreement), versionHash1) != BaseErrors.NO_ERROR()) return "Party1 proxy encountered an error when signing version 1";
        if (party2.signAgreement(address(agreement), versionHash1) != BaseErrors.NO_ERROR()) return "Party2 proxy encountered an error when signing version 1";

        if (agreement.isFullyConfirmed(versionHash1)) return "Version 1 should not be fully confirmed.";
        if (agreement.isEffective()) return "Agreement with version 1 should not be effective.";

        // Add a second version and sign with all signatories in different order
		agreement.addVersion(versionHash2);
        if (party2.signAgreement(address(agreement), versionHash2) != BaseErrors.NO_ERROR()) return "Party2 proxy encountered an error when signing version 2";
        if (agreement.confirmExecutionVersion(versionHash2) != BaseErrors.NO_ERROR()) return "Owner/Signatory encountered an error directly signing version 2 via confirmExecutionVersion()";
        if (party3.signAgreement(address(agreement), versionHash2) != BaseErrors.NO_ERROR()) return "Party3 proxy encountered an error when signing version 2";
        if (agreement.isFullyConfirmed(versionHash2)) return "Version 2 should not be fully confirmed, yet.";
        if (party1.signAgreement(address(agreement), versionHash2) != BaseErrors.NO_ERROR()) return "Party1 proxy encountered an error when signing version 2";

        if (!agreement.isFullyConfirmed(versionHash2)) return "Version 2 should now be fully confirmed after last signature.";
        if (!agreement.isEffective()) return "Agreement with fully signed version 2 should now be effective.";

        confirmedAgreement = address(agreement);

		return "success";
	}

	function getSignatory(uint _index) public view returns (address) {
        return signatories[_index];
	}
}

/**
 * Extended agreement to test modifiers
 */
contract TestAgreement is Agreement {

    constructor(string memory _name) Agreement(_name) public {}

    /**
     * @dev Function to be modified by `onlyBySignatory`.
     */
    function modifyByOnlyBySignatory(address _party)
        onlyBySignatory(_party)
        external
        view
        returns (bool)
    {
        return true;
    }

    /**
     * @dev Function to be modified by `onlyByOwnerOrSignatory`.
     */
    function modifyByOnlyByOwnerOrSignatory(address _party)
        onlyByOwnerOrSignatory(_party)
        external
        view
        returns (bool)
    {
        return true;
    }

}
