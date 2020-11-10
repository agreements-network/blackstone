pragma solidity ^0.5;

import "../Completables.sol";
import "./Mocks.sol";

// lol solidity - just give me the constants
contract CompletablesTest is CompletableOptions {
    string constant SUCCESS = "success";

    string constant initSignature = "init(bytes32,string,string,address,address[],uint256,bool,string)";
    string constant attestSignature = "attest(bytes32,int256)";
    string constant updateMetaSignature = "updateMeta(bytes32,string)";

    function testCompletables() external returns (string memory) {
        address us = address(this);
        MockParty them = new MockParty();
        address[] memory parties = new address[](2);
        parties[0] = us;
        parties[1] = address(them);
        MockAgreement agreement = new MockAgreement(parties);
        Completables comp = new Completables();
        address[] memory franchisees = new address[](2);
        franchisees[0] = address(this);
        franchisees[1] = address(them);

        uint threshold = 2;
        bytes32 intervalId = "foo";
        uint options = COMPLETE_ON_RATIFICATION;
        bool success;

        (success,) = address(comp).call(abi.encodeWithSignature(updateMetaSignature,
            intervalId,
            "nada"));
        if (success) {
            return "Should revert when trying update meta data for a completable that has not been initialized";
        }

        comp.init(intervalId, "crochet", "quaver", address(agreement), franchisees, threshold, options, "nada");
        comp.begin(intervalId, 0);
        comp.attest(intervalId, 0);

        // Duplicate completable not allowed
        (success,) = address(comp).call(abi.encodeWithSignature(initSignature,
            intervalId,
            address(agreement),
            franchisees,
            threshold,
            options,
            "nada"));

        if (success) {
            return "Should revert when trying to init a Completable with same intervalId as existing open interval";
        }

        comp.updateMeta(intervalId, "newMeta");

        // Let's attest
        them.forwardCall(address(comp), abi.encodeWithSignature(attestSignature, intervalId, 0));

        int ratificationTimestamp = comp.ratifiedAt(intervalId);
        if (ratificationTimestamp != int(block.timestamp)) {
            return "Ratification timestamp should equal block timestamp";
        }

        // Now the Completable has closed and been deleted so we should be able to re-init with the same intervalId

        return SUCCESS;
    }

}
