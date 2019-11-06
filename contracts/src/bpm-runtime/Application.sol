pragma solidity ^0.5;

/**
 * @title Application
 * @dev Interface declaration for a smart contract that participates in a BPM process as a callable application.
 */
contract Application {

    /**
     * @dev Completion function of this application. This function is invoked by the BPM engine when the application is being executed as part of an activity instance.
     * @param _processInstance the address of the ProcessInstance
     * @param _activityInstanceId the ID of an ActivityInstance
     * @param _activityId the ID of the activity definition
     * @param _txPerformer the address which started the process transaction
     */
    function complete(address _processInstance, bytes32 _activityInstanceId, bytes32 _activityId, address _txPerformer) public;
}