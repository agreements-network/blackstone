pragma solidity ^0.5;

import "bpm-runtime/Application.sol";
import "bpm-runtime/ProcessInstance.sol";

contract TotalCounterCheck is Application {

    /**
     * @dev Increases a counter and writes result back. Also compares counter to total and set boolean output if total reached.
     * @param _piAddress the address of the ProcessInstance in which context this application is invoked
     * @param _activityInstanceId the ID of an ActivityInstance
     * param _activityId the ID of the activity definition
     * param _txPerformer the address which started the process transaction
     */
    function complete(address _piAddress, bytes32 _activityInstanceId, bytes32, address) public {
        uint current = ProcessInstance(_piAddress).getActivityInDataAsUint(_activityInstanceId, "numberIn");
        uint total = ProcessInstance(_piAddress).getActivityInDataAsUint(_activityInstanceId, "totalIn");
        current++;
        ProcessInstance(_piAddress).setActivityOutDataAsUint(_activityInstanceId, "numberOut", current);
        if (current >= total)
            ProcessInstance(_piAddress).setActivityOutDataAsBool(_activityInstanceId, "completedOut", true);
    }

}
