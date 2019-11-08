pragma solidity ^0.5;

import "documents-commons/Agreement.sol";
import "documents-commons/test/SignatoryProxy.sol";


contract UseCaseTest {

    function testMasterServiceAgreement() external returns (string memory) {

        string memory versionHash = "98h238f7dsyr923hr29f29283rjf92832rwosd";

        SignatoryProxy provider = new SignatoryProxy();
        SignatoryProxy consumer = new SignatoryProxy();

        // make an agreement, so that the test is the owner
        Agreement agreement = new Agreement("MSA 3928234");

        // add the two parties as signatories
        agreement.addSignatory(address(provider));
        agreement.addSignatory(address(consumer));
        if (agreement.getSignatoriesSize() != 2) return "There should be 2 signatories on the agreement.";

        // add a version to the agreement
        agreement.addVersion(versionHash);
        if (1 != agreement.getNumberOfVersions()) return "Version hash was not saved in the agreement.";

        // start signing and test effective and confirmed state
        consumer.signAgreement(address(agreement), versionHash);
        if (agreement.isEffective() || agreement.isConfirmedVersion(versionHash)) return "The agreement should not be effective or confirmed with one signature missing.";
        provider.signAgreement(address(agreement), versionHash);
        if (!agreement.isEffective() || !agreement.isConfirmedVersion(versionHash)) return "The agreement should be effective and confirmed after second signature.";

        return "success";
    }
}