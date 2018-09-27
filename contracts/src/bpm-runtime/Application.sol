pragma solidity ^0.4.23;

/**
 * @title Application
 * @dev Interface declaration for a smart contract that participates in a BPM process as a callable application.
 */
contract Application {

    /**
     * @dev Completion function of this application. This function is invoked by the BPM engine when the application is being executed as part of an activity instance.
     */
    function complete(bytes32 _activityInstanceId, bytes32 _activityId, address _txPerformer) public;
}