pragma solidity ^0.5;

import "bpm-runtime/Application.sol";
import "bpm-runtime/ProcessInstance.sol";

import "agreements/ActiveAgreement.sol";

contract AgreementSignatureCheck is Application {
    
    /**
     * @dev Accesses the "agreement" IN data mapping to retrieve the address of an ActiveAgreement and verifies that the TX performer has applied a signature.
     * REVERTS if:
     * - the IN data mapping "agreement" cannot be accessed or results in an empty address
     * - the presence of the signature on the agreement cannot be established.
     * @param _piAddress the address of the ProcessInstance in which context the application is invoked
     * @param _activityInstanceId the globally unique ID of the ActivityInstance invoking this contract
     * param _activityId the ID of the activity definition
     * @param _txPerformer the address performing the transaction
     */
    function complete(address _piAddress, bytes32 _activityInstanceId, bytes32, address _txPerformer) public {
        address agreement = ProcessInstance(_piAddress).getActivityInDataAsAddress(_activityInstanceId, "agreement");
        require(agreement != address(0), "Unable to locate an ActiveAgreement.");
        require(ActiveAgreement(agreement).isSignedBy(_txPerformer), "ActiveAgreement is not signed by the performing user. Reverting ...");
    }

}