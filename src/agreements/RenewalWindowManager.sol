pragma solidity ^0.5;

import "commons-base/ErrorsLib.sol";
import "commons-base/BaseErrors.sol";
import "commons-collections/DataStorage.sol";
import "bpm-runtime/Application.sol";
import "bpm-runtime/BpmService.sol";
import "bpm-runtime/ProcessInstance.sol";
import "agreements/ActiveAgreement.sol";
import "agreements/Renewable.sol";

contract RenewalWindowManager is Application {

    /**
     * @dev This event also emits the extendExpirationBy offset which
     * must be used to calculate the next expiration timestamp and 
     * included as an argument to the terminateRenewalWindow() call.
     */
    event LogRenewalWindowCloseOffset(
        bytes32 indexed eventURN,
        bytes32 activityInstanceId,
        bytes32 activityId,
        address agreementAddress,
        address processInstanceAddress,
        address performer,
        int scheduledFor,
        string scheduledForOffset,
        int currentExpiration,
        string extendExpirationBy
    );

    event LogPendingUserTaskCloseOffset(
        bytes32 indexed eventURN,
        bytes32 activityInstanceId,
        bytes32 activityId,
        address agreementAddress,
        address processInstanceAddress,
        address performer,
        int scheduledFor,
        string scheduledForOffset
    );

    event LogRenewalVoteNotificationTrigger(
        bytes32 indexed eventURN,
        address agreementAddress,
        address processInstanceAddress,
        address franchisee
    );

    bytes32 constant EVENT_ID_RENEWAL_WINDOW_MANAGER = "AN://agreement-renewal-manager";
    bytes32 constant MAPPING_ID_PENDING_USER_TASK_ID = "pendingUserTaskId";
    BpmService bpmService;

    struct Parent {
        address processInstanceAddress;
        address agreementAddress;
        bool exists;
    }

    mapping(bytes32 => Parent) activityParentMap;

    /**
     * @dev Constructor to initialize the bpmService.
     * @param _service the address of the BpmService
     */
    constructor(address _service) public {
        bpmService = BpmService(_service);
    }
    
    /**
     * @dev Accesses scheduledFor and scheduledForOffset parameters from the process instance via data mappings in order to
     * emit those value for an extermal system to consume and process.
     * @param _piAddress the address of the ProcessInstance in which context the application is invoked
     * @param _activityInstanceId the globally unique ID of the ActivityInstance invoking this contract
     * @param _activityId the ID of the activity definition
     * @param _txPerformer the address performing the transaction
     */
    function complete(address _piAddress, bytes32 _activityInstanceId, bytes32 _activityId, address _txPerformer) public {
        address agreement = ProcessInstance(_piAddress).getActivityInDataAsAddress(_activityInstanceId, "agreement");
        
        ErrorsLib.revertIf(agreement == address(0),
            ErrorsLib.INVALID_STATE(), "RenewalWindowManager.complete", "Empty agreement address found on given ProcessInstance");
        
        int expirationDate;
        string memory closeOffset;

        ( , expirationDate, , closeOffset, ) = Renewable(agreement).getRenewalTerms();

        ErrorsLib.revertIf(expirationDate == 0,
            ErrorsLib.INVALID_STATE(), "RenewalWindowManager.complete", "expirationDate is 0. Must be a valid time for activity to close.");

        ErrorsLib.revertIf(bytes(closeOffset).length == 0,
            ErrorsLib.INVALID_STATE(), "RenewalWindowManager.complete", "closeOffset is empty. Must be a valid ISO 8601 offset string.");

        Renewable(agreement).openRenewalWindow();

        emitPendingUserTaskDetails(
            _activityInstanceId,
            _piAddress,
            agreement,
            expirationDate,
            closeOffset
        );

        emitFranchiseeDetails(_piAddress, agreement);

        string memory extensionOffset;
        ( , , , , extensionOffset) = Renewable(agreement).getRenewalTerms();

        emit LogRenewalWindowCloseOffset(
            EVENT_ID_RENEWAL_WINDOW_MANAGER,
            _activityInstanceId,
            _activityId,
            agreement,
            _piAddress,
            _txPerformer,
            expirationDate,
            closeOffset,
            expirationDate,
            extensionOffset
        );
        
        activityParentMap[_activityInstanceId].processInstanceAddress = _piAddress;
        activityParentMap[_activityInstanceId].agreementAddress = agreement;
        activityParentMap[_activityInstanceId].exists = true;
    }

    /**
     * This function tries to find on the process instance a suspended user task instance and then attempts to close it.
     * This is useful in situations where there may be a pending user task blocking the process from moving forward.
     * By configuring the activityId of such a task as a data mapping on the current activity, we can attempt to close them.
     */
    function emitPendingUserTaskDetails(bytes32 _activityInstanceId, address _piAddress, address _agreement, int _scheduledFor, string memory _offset) public {
        bytes32 pendingUserTaskId = ProcessInstance(_piAddress).getActivityInDataAsBytes32(_activityInstanceId, MAPPING_ID_PENDING_USER_TASK_ID);
        if (pendingUserTaskId != "") {
            for (uint i = 0; i < ProcessInstance(_piAddress).getNumberOfActivityInstances(); i++) {
                bytes32 aiId =  ProcessInstance(_piAddress).getActivityInstanceAtIndex(i);
                (bytes32 activityId, , , address performer, , ) = ProcessInstance(_piAddress).getActivityInstanceData(aiId);
                if (pendingUserTaskId == activityId) {
                    // The pendingUserTaskId must be set on the process instance in order for this event
                    // to be emitted indicating a request to close any instances of the activity 
                    // at the correct scheduledFor +/- offset.
                    // If it's not set, we don't want to emit any task closure events because we don't know which
                    // tasks need to be closed.
                    emit LogPendingUserTaskCloseOffset(
                        EVENT_ID_RENEWAL_WINDOW_MANAGER,
                        aiId,
                        activityId,
                        _agreement,
                        _piAddress,
                        performer,
                        _scheduledFor,
                        _offset
                    );
                }
            }
        }
    }

    function emitFranchiseeDetails(address _piAddress, address _agreement) public {
        for (uint i = 0; i< Renewable(_agreement).getNumberOfRenewalFranchisees(); i++) {
            address franchisee = Renewable(_agreement).getRenewalFranchiseeAtIndex(i);
            emit LogRenewalVoteNotificationTrigger(
                EVENT_ID_RENEWAL_WINDOW_MANAGER,
                _agreement,
                _piAddress,
                franchisee
            );
        }
    }

    /**
     * @dev Allows to complete the Renewal Offset Emitter Activity via an external call.
     * @param _terminateActivityId the ID of an ActivityInstance waiting for completion.
     * @param _nextExpirationDate int
     */
    function terminateRenewalWindow(bytes32 _terminateActivityId, int _nextExpirationDate) external {

        ErrorsLib.revertIf(!activityParentMap[_terminateActivityId].exists,
            ErrorsLib.INVALID_INPUT(), "RenewalWindowManager.terminateRenewalWindow", "The provided ActivityInstance ID is not registered");

        address piAddress = activityParentMap[_terminateActivityId].processInstanceAddress;
        address agreement = activityParentMap[_terminateActivityId].agreementAddress;

        // Set the next expiration date
        Renewable(agreement).setNextExpirationDate(_nextExpirationDate);

        // Close the renewal voting window
        Renewable(agreement).closeRenewalWindow();

        uint error = ProcessInstance(piAddress).completeActivity(_terminateActivityId, bpmService);

        if (error == BaseErrors.NO_ERROR()) {
            delete activityParentMap[_terminateActivityId];
        }
    }
}