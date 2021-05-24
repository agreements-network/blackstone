// SPDX-License-Identifier: Parity-6.0.0
pragma solidity >=0.5;

import "commons-base/ErrorsLib.sol";
import "commons-base/BaseErrors.sol";
import "commons-base/Owned.sol";
import "commons-collections/AbstractDataStorage.sol";
import "commons-collections/AbstractAddressScopes.sol";
import "bpm-model/ProcessDefinition.sol";
import "commons-management/AbstractVersionedArtifact.sol";
import "commons-management/AbstractDelegateTarget.sol";

import "bpm-runtime/BpmRuntime.sol";
import "bpm-runtime/BpmRuntimeLib.sol";
import "bpm-runtime/BpmService.sol";
import "bpm-runtime/ProcessInstance.sol";
import "bpm-runtime/AbstractProcessStateChangeEmitter.sol";

/**
 * @title DefaultProcessInstance
 * @dev Default implementation of the ProcessInstance interface
 */
contract DefaultProcessInstance is AbstractVersionedArtifact(1,0,0), AbstractDelegateTarget, AbstractDataStorage, AbstractAddressScopes, AbstractProcessStateChangeEmitter, Owned, ProcessInstance {

    using BpmRuntimeLib for ProcessDefinition;
    using BpmRuntimeLib for BpmRuntime.ProcessGraph;
    using BpmRuntimeLib for BpmRuntime.ProcessInstance;
    using BpmRuntimeLib for BpmRuntime.ActivityNode;
    using BpmRuntimeLib for BpmRuntime.ActivityInstanceMap;
    using BpmRuntimeLib for BpmRuntime.ActivityInstance;
    using BpmRuntimeLib for BpmRuntime.BoundaryEventInstance;
    using BpmRuntimeLib for BpmRuntime.IntermediateEventInstance;

    BpmRuntime.ProcessInstance self;

    /**
     * @dev REVERTS if
     * - the activity instance is not found in the database
     * - the activity is of task type USER, but not in SUSPENDED state
     * - the activity is of task type SERVICE or EVENT, but not in APPLICATION state
     * - the msg.sender or tx.origin cannot be authorized as the performer of the activity instance for all activity types except BpmModel.TaskType.NONE.
     */
    modifier pre_inDataPermissionCheck(bytes32 _activityInstanceId) {
        ErrorsLib.revertIf(!self.activities.rows[_activityInstanceId].exists,
            ErrorsLib.RESOURCE_NOT_FOUND(), "DefaultProcessInstance.pre_inDataPermissionCheck", "ActivityInstance with given ID not found");
        BpmRuntime.ActivityInstance memory ai = self.activities.rows[_activityInstanceId].value;
        ( , uint8 taskType, , , , , , ) = self.processDefinition.getActivityData(ai.activityId);
        if (taskType == uint8(BpmModel.TaskType.USER)) {
            ErrorsLib.revertIf(ai.state != BpmRuntime.ActivityInstanceState.SUSPENDED,
                ErrorsLib.INVALID_STATE(), "DefaultProcessInstance.pre_inDataPermissionCheck", "USER task state must be SUSPENDED for IN mappings");
        }
        else if (taskType == uint8(BpmModel.TaskType.SERVICE) || taskType == uint8(BpmModel.TaskType.EVENT)) {
            ErrorsLib.revertIf(ai.state != BpmRuntime.ActivityInstanceState.APPLICATION,
                ErrorsLib.INVALID_STATE(), "DefaultProcessInstance.pre_inDataPermissionCheck", "SERVICE or EVENT task state must be APPLICATION for IN mappings");
        }
        if (taskType != uint8(BpmModel.TaskType.NONE)) {
            ErrorsLib.revertIf(BpmRuntimeLib.authorizePerformer(_activityInstanceId, this) == address(0),
                ErrorsLib.UNAUTHORIZED(), "DefaultProcessInstance.pre_inDataPermissionCheck", "Unable to authorize msg.sender/tx.origin as performer of a USER/SERVICE/EVENT task for IN mappings");
        }
        _;
    }

    /**
     * @dev REVERTS if
     * - the activity instance is not found in the database
     * - the activity is of task type USER or EVENT, but not in SUSPENDED state
     * - the activity is of task type SERVICE, but not in APPLICATION state
     * - the msg.sender is not set as the performer of the activity instance for all activity types except BpmModel.TaskType.NONE.
     */
    modifier pre_outDataPermissionCheck(bytes32 _activityInstanceId) {
        ErrorsLib.revertIf(!self.activities.rows[_activityInstanceId].exists,
            ErrorsLib.RESOURCE_NOT_FOUND(), "DefaultProcessInstance.pre_inDataPermissionCheck", "ActivityInstance with given ID not found");
        BpmRuntime.ActivityInstance memory ai = self.activities.rows[_activityInstanceId].value;
        ( , uint8 taskType, , , , , , ) = self.processDefinition.getActivityData(ai.activityId);
        if (taskType == uint8(BpmModel.TaskType.USER) || taskType == uint8(BpmModel.TaskType.EVENT)) {
            ErrorsLib.revertIf(ai.state != BpmRuntime.ActivityInstanceState.SUSPENDED,
                ErrorsLib.INVALID_STATE(), "DefaultProcessInstance.pre_outDataPermissionCheck", "USER or EVENT task state must be SUSPENDED for OUT mappings");
        }
        else if (taskType == uint8(BpmModel.TaskType.SERVICE)) {
            ErrorsLib.revertIf(ai.state != BpmRuntime.ActivityInstanceState.APPLICATION,
                ErrorsLib.INVALID_STATE(), "DefaultProcessInstance.pre_outDataPermissionCheck", "SERVICE task state must be APPLICATION for OUT mappings");
        }
        if (taskType != uint8(BpmModel.TaskType.NONE)) {
            ErrorsLib.revertIf(BpmRuntimeLib.authorizePerformer(_activityInstanceId, this) == address(0),
                ErrorsLib.UNAUTHORIZED(), "DefaultProcessInstance.pre_outDataPermissionCheck", "Unable to authorize msg.sender/tx.origin as performer of a USER/SERVICE/EVENT task for OUT mappings");
        }
        _;
    }

    /**
	 * @dev Initializes this DefaultProcessInstance with the provided parameters. This function replaces the
	 * contract constructor, so it can be used as the delegate target for an ObjectProxy.
     * REVERTS if:
     * - the provided ProcessDefinition is NULL
     * @param _processDefinition the ProcessDefinition which this ProcessInstance should follow
     * @param _startedBy (optional) account which initiated the transaction that started the process. If empty, the msg.sender is registered as having started the process
     * @param _activityInstanceId the ID of a subprocess activity instance that initiated this ProcessInstance (optional)
     */
    function initialize(address _processDefinition, address _startedBy, bytes32 _activityInstanceId)
        external
        pre_post_initialize
    {
        ErrorsLib.revertIf(_processDefinition == address(0),
            ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultProcessInstance.constructor", "ProcessDefinition is NULL");
        owner = msg.sender;
        self.startedBy = (_startedBy == address(0)) ? msg.sender : _startedBy; //TODO should startedBy be filled when the process is actually started, i.e. switched to ACTIVE? Maybe if it's not filled, it'll get filled in initRuntime?
        self.subProcessActivityInstance = _activityInstanceId;
        self.addr = address(this);
        self.processDefinition = ProcessDefinition(_processDefinition);
        self.state = BpmRuntime.ProcessInstanceState.CREATED;
        emit LogProcessInstanceCreation(
			EVENT_ID_PROCESS_INSTANCES,
			address(this),
			_processDefinition,
			uint8(BpmRuntime.ProcessInstanceState.CREATED),
			self.startedBy
		);
    }

	/**
	 * @dev Initiates the runtime graph that handles the state of this ProcessInstance and activates the start activity.
     * The state of this ProcessInstance must be CREATED. If initiation is successful, the state of this ProcessInstance is set to ACTIVE.
	 * Triggers REVERT if the ProcessInstance is not in state CREATED.
	 */
    function initRuntime() public {
        ErrorsLib.revertIf(self.state != BpmRuntime.ProcessInstanceState.CREATED,
            ErrorsLib.INVALID_STATE(), "DefaultProcessInstance.initRuntime", "The ProcessInstanceState must be CREATED to initialize");
        self.graph.configure(this);
        // TODO assert() that everything is correct at this point to start the process
        self.graph.activities[self.processDefinition.getStartActivity()].ready = true;
        self.state = BpmRuntime.ProcessInstanceState.ACTIVE;
    }

	/**
	 * @dev Initiates execution of this ProcessInstance consisting of attempting to activate and process any activities and advance the
	 * state of the runtime graph.
	 * @param _service the BpmService managing this ProcessInstance (required for changes to this ProcessInstance and access to the BpmServiceDb)
	 * @return error code indicating success or failure
	 */
    function execute(BpmService _service) public returns (uint error) {
        // TODO should check that the owner of the DB and the owner of the PI match (or that the PI is in the DB)
        // TODO external invocation still possible, but might be OK since it might not result in any processing if the engine has not changed the state of the PI?!
        error = self.execute(_service);
        emit LogProcessInstanceStateUpdate(
            EVENT_ID_PROCESS_INSTANCES,
            address(this),
            uint8(self.state)
        );
        return error;
    }

	/**
	 * @dev Aborts this ProcessInstance and halts any ongoing activities. After the abort the ProcessInstance cannot be resurrected.
	 */
    function abort()
        external
        pre_onlyByOwner
    {
        self.abort();
        notifyProcessStateChange();
    }

    /**
     * @dev Triggers the boundary event with the specified ID
     * REVERTS if:
     * - the specified ActivityInstance cannot be found
     * - the specified BoundaryEventInstance cannot be found
     * - the BoundaryEventInstance is INACTIVE
     * - the event instance is a TIMER_TIMESTAMP or TIMER_DURATION type, but the timer target has not been reached yet
     * @param _activityInstanceId the ID of the ActivityInstance to which the event instance is bound
     * @param _eventInstanceId the ID of a BoundaryEventInstance
     */
    function triggerBoundaryEvent(bytes32 _activityInstanceId, bytes32 _eventInstanceId)
        external
    {
        ErrorsLib.revertIf(!self.activities.rows[_activityInstanceId].exists,
            ErrorsLib.RESOURCE_NOT_FOUND(), "DefaultProcessInstance.triggerBoundaryEvent", "The specified ActivityInstance cannot be found");

        BpmRuntime.ActivityInstance storage activityInstance = self.activities.rows[_activityInstanceId].value;

        ErrorsLib.revertIf(!activityInstance.boundaryEvents.rows[_eventInstanceId].exists,
                ErrorsLib.RESOURCE_NOT_FOUND(), "DefaultProcessInstance.triggerBoundaryEvent", "The specified BoundaryEventInstance cannot be found");

        BpmRuntime.BoundaryEventInstance storage instance = activityInstance.boundaryEvents.rows[_eventInstanceId].value;

        ErrorsLib.revertIf(instance.state != BpmRuntime.BoundaryEventInstanceState.INACTIVE,
                ErrorsLib.INVALID_STATE(), "DefaultProcessInstance.triggerBoundaryEvent", "BoundaryEventInstance is not active (bound). Call activateBoundaryEvent() or setIntermediateEventTimerTarget() first to activate");

        (BpmModel.EventType eventType, , ) = self.processDefinition.getBoundaryEventGraphDetails(instance.boundaryId);

        if (eventType == BpmModel.EventType.TIMER_TIMESTAMP || eventType == BpmModel.EventType.TIMER_DURATION) {
            // NOTE: we don't need to verify that a timerTarget is set, because the event instance is ACTIVE and the activateBoundaryEvent does not allow activation without a timerTarget set!
            ErrorsLib.revertIf(instance.timerTarget > block.timestamp,
                ErrorsLib.INVALID_STATE(), "DefaultProcessInstance.triggerBoundaryEvent", "Cannot trigger timer type boundary event before timer target expired");
        }

        // TODO: execute actions and deactivate the boundary event!
    }

    /**
     * @dev Triggers the intermediate event with the specified ID
     * REVERTS if:
     * - the specified IntermediateEventInstance cannot be found
     * @param _eventInstanceId the ID of a IntermediateEventInstance in this ProcessInstance
     * @param _service the address of the BpmService where this ProcessInstance is registered
     */
    function triggerIntermediateEvent(bytes32 _eventInstanceId, BpmService _service)
        external
    {
        ErrorsLib.revertIf(!self.intermediateEvents.rows[_eventInstanceId].exists,
                ErrorsLib.RESOURCE_NOT_FOUND(), "ProcessInstance.triggerIntermediateEvent", "The specified target event instance ID does not exist");

        BpmRuntime.IntermediateEventInstance storage instance = self.intermediateEvents.rows[_eventInstanceId].value;

        if (instance.state == BpmRuntime.ActivityInstanceState.COMPLETED) {
            // already triggered, this is fine
            return;
        }

        ErrorsLib.revertIf(instance.timerTarget == 0,
                ErrorsLib.INVALID_STATE(), "ProcessInstance.triggerIntermediateEvent", "The specified target event instance ID does not have timer set");

        ErrorsLib.revertIf(instance.timerTarget > block.timestamp,
                ErrorsLib.INVALID_STATE(), "ProcessInstance.triggerIntermediateEvent", "Attempt to fire intermediate event before timer expired");

        instance.completeIntermediateEventInstance();

        // mark activity as completed.
        self.graph.activities[instance.eventId].instancesCompleted = 1;
        self.graph.activities[instance.eventId].done = true;

        // execute!
        self.execute(_service);
    }

	/**
	 * @dev Completes the specified activity
	 * @param _activityInstanceId the activity instance
	 * @param _service the BpmService managing this ProcessInstance (required for changes to this ProcessInstance after the activity completes)
	 * @return BaseErrors.NO_ERROR() if successful
     * @return BaseErrors.RESOURCE_NOT_FOUND() if the activity instance cannot be located
     * @return BaseErrors.INVALID_STATE() if the activity is not in a state to be completed (SUSPENDED or INTERRUPTED)
     * @return BaseErrors.INVALID_ACTOR() if the msg.sender or tx.origin is not the assignee of the task
	 */
    function completeActivity(bytes32 _activityInstanceId, BpmService _service) public returns (uint error) {
        if (!self.activities.rows[_activityInstanceId].exists)
            return BaseErrors.RESOURCE_NOT_FOUND();
        if (self.activities.rows[_activityInstanceId].value.state != BpmRuntime.ActivityInstanceState.SUSPENDED &&
            self.activities.rows[_activityInstanceId].value.state != BpmRuntime.ActivityInstanceState.INTERRUPTED) {
            return BaseErrors.INVALID_STATE();
        }

        // Processing the activity instance is the beginning of a new recursive loop
        error = self.activities.rows[_activityInstanceId].value.executeActivity(this, self.processDefinition, _service);
        if (error != BaseErrors.NO_ERROR()) {
            return (error);
        }

        if (self.activities.rows[_activityInstanceId].value.state == BpmRuntime.ActivityInstanceState.COMPLETED) {
            BpmRuntime.ActivityInstance storage ai = self.activities.rows[_activityInstanceId].value;
            self.graph.activities[ai.activityId].instancesCompleted++;
            if (self.graph.activities[ai.activityId].instancesCompleted == self.graph.activities[ai.activityId].instancesTotal) {
                self.graph.activities[ai.activityId].done = true;
            }
        }

        // I think the BoundaryEventInstanceMap belongs into the ActivityInstance. Do we ever need to really iterate on all events?? We just need to be able to connect from an eventInstanceId to the storage struct in functions that live on the ProcessInstance .......?
        // ... just make the aiId part of the events and when triggering events and setting data!


        // attempt to continue the transaction as there might now be more activities to process
        return self.continueTransaction(_service);
    }

    /**
	 * @dev Writes data via BpmService and then completes the specified activity.
	 * @param _activityInstanceId the task ID
	 * @param _service the BpmService required for lookup and access to the BpmServiceDb
	 * @param _dataMappingId the id of the dataMapping that points to data storage slot
	 * @param _value the bool value of the data
	 * @return error code if the completion failed
	 */
    function completeActivityWithBoolData(bytes32 _activityInstanceId, BpmService _service, bytes32 _dataMappingId, bool _value)
        external
        returns (uint error)
    {
        setActivityOutDataAsBool(_activityInstanceId, _dataMappingId, _value);
        error = completeActivity(_activityInstanceId, _service);
        ErrorsLib.revertIf(error != BaseErrors.NO_ERROR(),
            ErrorsLib.RUNTIME_ERROR(), "DefaultProcessInstance.completeActivityWithBoolData", "Reverting data changes due to error completing the activity instance.");
    }

    /**
	 * @dev Writes data via BpmService and then completes the specified activity.
	 * @param _activityInstanceId the task ID
	 * @param _service the BpmService required for lookup and access to the BpmServiceDb
	 * @param _dataMappingId the id of the dataMapping that points to data storage slot
	 * @param _value the string value of the data
	 * @return error code if the completion failed
	 */
    function completeActivityWithStringData(bytes32 _activityInstanceId, BpmService _service, bytes32 _dataMappingId, string calldata _value)
        external
        returns (uint error)
    {
        setActivityOutDataAsString(_activityInstanceId, _dataMappingId, _value);
        error = completeActivity(_activityInstanceId, _service);
        ErrorsLib.revertIf(error != BaseErrors.NO_ERROR(),
            ErrorsLib.RUNTIME_ERROR(), "DefaultProcessInstance.completeActivityWithStringData", "Reverting data changes due to error completing the activity instance.");
    }

    /**
	 * @dev Writes data via BpmService and then completes the specified activity.
	 * @param _activityInstanceId the task ID
	 * @param _service the BpmService required for lookup and access to the BpmServiceDb
	 * @param _dataMappingId the id of the dataMapping that points to data storage slot
	 * @param _value the bytes32 value of the data
	 * @return error code if the completion failed
	 */
    function completeActivityWithBytes32Data(bytes32 _activityInstanceId, BpmService _service, bytes32 _dataMappingId, bytes32 _value)
        external
        returns (uint error)
    {
        setActivityOutDataAsBytes32(_activityInstanceId, _dataMappingId, _value);
        error = completeActivity(_activityInstanceId, _service);
        ErrorsLib.revertIf(error != BaseErrors.NO_ERROR(),
            ErrorsLib.RUNTIME_ERROR(), "DefaultProcessInstance.completeActivityWithBytes32Data", "Reverting data changes due to error completing the activity instance.");
    }

    /**
	 * @dev Writes data via BpmService and then completes the specified activity.
	 * @param _activityInstanceId the task ID
	 * @param _service the BpmService required for lookup and access to the BpmServiceDb
	 * @param _dataMappingId the id of the dataMapping that points to data storage slot
	 * @param _value the uint value of the data
	 * @return error code if the completion failed
	 */
    function completeActivityWithUintData(bytes32 _activityInstanceId, BpmService _service, bytes32 _dataMappingId, uint _value)
        external
        returns (uint error)
    {
        setActivityOutDataAsUint(_activityInstanceId, _dataMappingId, _value);
        error = completeActivity(_activityInstanceId, _service);
        ErrorsLib.revertIf(error != BaseErrors.NO_ERROR(),
            ErrorsLib.RUNTIME_ERROR(), "DefaultProcessInstance.completeActivityWithUintData", "Reverting data changes due to error completing the activity instance.");
    }

    /**
	 * @dev Writes data via BpmService and then completes the specified activity.
	 * @param _activityInstanceId the task ID
	 * @param _service the BpmService required for lookup and access to the BpmServiceDb
	 * @param _dataMappingId the id of the dataMapping that points to data storage slot
	 * @param _value the int value of the data
	 * @return error code if the completion failed
	 */
    function completeActivityWithIntData(bytes32 _activityInstanceId, BpmService _service, bytes32 _dataMappingId, int _value)
        external
        returns (uint error)
    {
        setActivityOutDataAsInt(_activityInstanceId, _dataMappingId, _value);
        error = completeActivity(_activityInstanceId, _service);
        ErrorsLib.revertIf(error != BaseErrors.NO_ERROR(),
            ErrorsLib.RUNTIME_ERROR(), "DefaultProcessInstance.completeActivityWithIntData", "Reverting data changes due to error completing the activity instance.");
    }

    /**
	 * @dev Writes data via BpmService and then completes the specified activity.
	 * @param _activityInstanceId the task ID
	 * @param _service the BpmService required for lookup and access to the BpmServiceDb
	 * @param _dataMappingId the id of the dataMapping that points to data storage slot
	 * @param _value the address value of the data
	 * @return error code if the completion failed
	 */
    function completeActivityWithAddressData(bytes32 _activityInstanceId, BpmService _service, bytes32 _dataMappingId, address _value)
        external
        returns (uint error)
    {
        setActivityOutDataAsAddress(_activityInstanceId, _dataMappingId, _value);
        error = completeActivity(_activityInstanceId, _service);
        ErrorsLib.revertIf(error != BaseErrors.NO_ERROR(),
            ErrorsLib.RUNTIME_ERROR(), "DefaultProcessInstance.completeActivityWithAddressData", "Reverting data changes due to error completing the activity instance.");
    }

	/**
	 * @dev Returns the bool value of the specified IN data mapping in the context of the given activity instance.
     * Note: This function triggers a REVERT under conditions set in the pre_inDataPermissionCheck(bytes32) modifier!
	 * @param _activityInstanceId the ID of an activity instance managed by this BpmService
	 * @param _dataMappingId the ID of an IN data mapping defined for the activity
	 * @return the bool value resulting from resolving the data mapping
	 */
    function getActivityInDataAsBool(bytes32 _activityInstanceId, bytes32 _dataMappingId)
        external
        pre_inDataPermissionCheck(_activityInstanceId)
        returns (bool)
    {
        (address storageAddress, bytes32 dataPath) = resolveInDataLocation(_activityInstanceId, _dataMappingId);
        return DataStorage(storageAddress).getDataValueAsBool(dataPath);
    }

	/**
	 * @dev Returns the string value of the specified IN data mapping in the context of the given activity instance.
     * Note: This function triggers a REVERT under conditions set in the pre_inDataPermissionCheck(bytes32) modifier!
	 * @param _activityInstanceId the ID of an activity instance managed by this BpmService
	 * @param _dataMappingId the ID of an IN data mapping defined for the activity
	 * @return the string value resulting from resolving the data mapping
	 */
    function getActivityInDataAsString(bytes32 _activityInstanceId, bytes32 _dataMappingId)
        external
        pre_inDataPermissionCheck(_activityInstanceId)
        returns (string memory)
    {
        (address storageAddress, bytes32 dataPath) = resolveInDataLocation(_activityInstanceId, _dataMappingId);
        return DataStorage(storageAddress).getDataValueAsString(dataPath);
    }

	/**
	 * @dev Returns the bytes32 value of the specified IN data mapping in the context of the given activity instance.
     * Note: This function triggers a REVERT under conditions set in the pre_inDataPermissionCheck(bytes32) modifier!
	 * @param _activityInstanceId the ID of an activity instance managed by this BpmService
	 * @param _dataMappingId the ID of an IN data mapping defined for the activity
	 * @return the bytes32 value resulting from resolving the data mapping
	 */
    function getActivityInDataAsBytes32(bytes32 _activityInstanceId, bytes32 _dataMappingId)
        external
        pre_inDataPermissionCheck(_activityInstanceId)
        returns (bytes32)
    {
        (address storageAddress, bytes32 dataPath) = resolveInDataLocation(_activityInstanceId, _dataMappingId);
        return DataStorage(storageAddress).getDataValueAsBytes32(dataPath);
    }

	/**
	 * @dev Returns the uint value of the specified IN data mapping in the context of the given activity instance.
     * Note: This function triggers a REVERT under conditions set in the pre_inDataPermissionCheck(bytes32) modifier!
	 * @param _activityInstanceId the ID of an activity instance managed by this BpmService
	 * @param _dataMappingId the ID of an IN data mapping defined for the activity
	 * @return the uint value resulting from resolving the data mapping
	 */
    function getActivityInDataAsUint(bytes32 _activityInstanceId, bytes32 _dataMappingId)
        external
        pre_inDataPermissionCheck(_activityInstanceId)
        returns (uint)
    {
        (address storageAddress, bytes32 dataPath) = resolveInDataLocation(_activityInstanceId, _dataMappingId);
        return DataStorage(storageAddress).getDataValueAsUint(dataPath);
    }

	/**
	 * @dev Returns the int value of the specified IN data mapping in the context of the given activity instance.
     * Note: This function triggers a REVERT under conditions set in the pre_inDataPermissionCheck(bytes32) modifier!
	 * @param _activityInstanceId the ID of an activity instance managed by this BpmService
	 * @param _dataMappingId the ID of an IN data mapping defined for the activity
	 * @return the int value resulting from resolving the data mapping
	 */
    function getActivityInDataAsInt(bytes32 _activityInstanceId, bytes32 _dataMappingId)
        external
        pre_inDataPermissionCheck(_activityInstanceId)
        returns (int)
    {
        (address storageAddress, bytes32 dataPath) = resolveInDataLocation(_activityInstanceId, _dataMappingId);
        return DataStorage(storageAddress).getDataValueAsInt(dataPath);
    }

	/**
	 * @dev Returns the address value of the specified IN data mapping in the context of the given activity instance.
     * Note: This function triggers a REVERT under conditions set in the pre_inDataPermissionCheck(bytes32) modifier!
	 * @param _activityInstanceId the ID of an activity instance managed by this BpmService
	 * @param _dataMappingId the ID of an IN data mapping defined for the activity
	 * @return the address value resulting from resolving the data mapping
	 */
    function getActivityInDataAsAddress(bytes32 _activityInstanceId, bytes32 _dataMappingId)
        external
        pre_inDataPermissionCheck(_activityInstanceId)
        returns (address)
    {
        (address storageAddress, bytes32 dataPath) = resolveInDataLocation(_activityInstanceId, _dataMappingId);
        return DataStorage(storageAddress).getDataValueAsAddress(dataPath);
    }

	/**
	 * @dev Applies the given value to the OUT data mapping with the specified ID on the specified activity instance.
     * Note: This function triggers a REVERT under conditions set in the pre_outDataPermissionCheck(bytes32) modifier!
	 * @param _activityInstanceId the ID of an activity instance managed by this BpmService
	 * @param _dataMappingId the ID of an OUT data mapping defined for the activity
	 * @param _value the value to set
	 */
    function setActivityOutDataAsBool(bytes32 _activityInstanceId, bytes32 _dataMappingId, bool _value)
        public
        pre_outDataPermissionCheck(_activityInstanceId)
    {
        (address storageAddress, bytes32 dataPath) = resolveOutDataLocation(_activityInstanceId, _dataMappingId);
        DataStorage(storageAddress).setDataValueAsBool(dataPath, _value);
    }

	/**
	 * @dev Applies the given value to the OUT data mapping with the specified ID on the specified activity instance.
     * Note: This function triggers a REVERT under conditions set in the pre_outDataPermissionCheck(bytes32) modifier!
	 * @param _activityInstanceId the ID of an activity instance managed by this BpmService
	 * @param _dataMappingId the ID of an OUT data mapping defined for the activity
	 * @param _value the value to set
	 */
    function setActivityOutDataAsString(bytes32 _activityInstanceId, bytes32 _dataMappingId, string memory _value)
        public
        pre_outDataPermissionCheck(_activityInstanceId)
    {
        (address storageAddress, bytes32 dataPath) = resolveOutDataLocation(_activityInstanceId, _dataMappingId);
        DataStorage(storageAddress).setDataValueAsString(dataPath, _value);
    }

	/**
	 * @dev Applies the given value to the OUT data mapping with the specified ID on the specified activity instance.
     * Note: This function triggers a REVERT under conditions set in the pre_outDataPermissionCheck(bytes32) modifier!
	 * @param _activityInstanceId the ID of an activity instance managed by this BpmService
	 * @param _dataMappingId the ID of an OUT data mapping defined for the activity
	 * @param _value the value to set
	 */
    function setActivityOutDataAsBytes32(bytes32 _activityInstanceId, bytes32 _dataMappingId, bytes32 _value)
        public
        pre_outDataPermissionCheck(_activityInstanceId)
    {
        (address storageAddress, bytes32 dataPath) = resolveOutDataLocation(_activityInstanceId, _dataMappingId);
        DataStorage(storageAddress).setDataValueAsBytes32(dataPath, _value);
    }

	/**
	 * @dev Applies the given value to the OUT data mapping with the specified ID on the specified activity instance.
     * Note: This function triggers a REVERT under conditions set in the pre_outDataPermissionCheck(bytes32) modifier!
	 * @param _activityInstanceId the ID of an activity instance managed by this BpmService
	 * @param _dataMappingId the ID of an OUT data mapping defined for the activity
	 * @param _value the value to set
	 */
    function setActivityOutDataAsUint(bytes32 _activityInstanceId, bytes32 _dataMappingId, uint _value)
        public
        pre_outDataPermissionCheck(_activityInstanceId)
    {
        (address storageAddress, bytes32 dataPath) = resolveOutDataLocation(_activityInstanceId, _dataMappingId);
        DataStorage(storageAddress).setDataValueAsUint(dataPath, _value);
    }

	/**
	 * @dev Applies the given value to the OUT data mapping with the specified ID on the specified activity instance.
     * Note: This function triggers a REVERT under conditions set in the pre_outDataPermissionCheck(bytes32) modifier!
	 * @param _activityInstanceId the ID of an activity instance managed by this BpmService
	 * @param _dataMappingId the ID of an OUT data mapping defined for the activity
	 * @param _value the value to set
	 */
    function setActivityOutDataAsInt(bytes32 _activityInstanceId, bytes32 _dataMappingId, int _value)
        public
        pre_outDataPermissionCheck(_activityInstanceId)
    {
        (address storageAddress, bytes32 dataPath) = resolveOutDataLocation(_activityInstanceId, _dataMappingId);
        DataStorage(storageAddress).setDataValueAsInt(dataPath, _value);
    }

	/**
	 * @dev Applies the given value to the OUT data mapping with the specified ID on the specified activity instance.
     * Note: This function triggers a REVERT under conditions set in the pre_outDataPermissionCheck(bytes32) modifier!
	 * @param _activityInstanceId the ID of an activity instance managed by this BpmService
	 * @param _dataMappingId the ID of an OUT data mapping defined for the activity
	 * @param _value the value to set
	 */
    function setActivityOutDataAsAddress(bytes32 _activityInstanceId, bytes32 _dataMappingId, address _value)
        public
        pre_outDataPermissionCheck(_activityInstanceId)
    {
        (address storageAddress, bytes32 dataPath) = resolveOutDataLocation(_activityInstanceId, _dataMappingId);
        DataStorage(storageAddress).setDataValueAsAddress(dataPath, _value);
    }

    /**
     * @dev Resolves the target storage location for the specified IN data mapping in the context of the given activity instance.
     * REVERTS: if there is no activity instance with the specified ID in this ProcessInstance
     * @param _activityInstanceId the ID of an activity instance
     * @param _dataMappingId the ID of a data mapping defined for the activity
     * @return dataStorage - the address of a DataStorage
     * @return dataPath - the dataPath under which to find data mapping value
     */
    function resolveInDataLocation(bytes32 _activityInstanceId, bytes32 _dataMappingId) public view returns (address dataStorage, bytes32 dataPath) {
        ErrorsLib.revertIf(!self.activities.rows[_activityInstanceId].exists,
            ErrorsLib.RESOURCE_NOT_FOUND(), "DefaultProcessInstance.resolveInDataLocation", "ActivityInstance not found");
        return self.resolveDataMappingLocation(_activityInstanceId, _dataMappingId, BpmModel.Direction.IN);
    }

    /**
     * @dev Resolves the target storage location for the specified OUT data mapping in the context of the given activity instance.
     * REVERTS: if there is no activity instance with the specified ID in this ProcessInstance
     * @param _activityInstanceId the ID of an activity instance
     * @param _dataMappingId the ID of a data mapping defined for the activity
     * @return dataStorage - the address of a DataStorage
     * @return dataPath - the dataPath under which to find data mapping value
     */
    function resolveOutDataLocation(bytes32 _activityInstanceId, bytes32 _dataMappingId) public view returns (address dataStorage, bytes32 dataPath) {
        ErrorsLib.revertIf(!self.activities.rows[_activityInstanceId].exists,
            ErrorsLib.RESOURCE_NOT_FOUND(), "DefaultProcessInstance.resolveInDataLocation", "ActivityInstance not found");
        return self.resolveDataMappingLocation(_activityInstanceId, _dataMappingId, BpmModel.Direction.OUT);
    }

    /**
     * @dev Resolves the transition condition identified by the given source and target using the data contained in this ProcessInstance.
     * Both source and target IDs are identifiers from the ProcessGraph and the function therefore takes into account that the target ID
     * could belong to an artificial activity (place) that was inserted to support to successive gateways. If this situation is detected,
     * this function will attempt to determine the correct target ID which was used in the ProcessDefinition (which usually is the transition element following the specified target).
     * @param _sourceId the ID of a graph element that is the source element of a transition (the source always corresponds to a gateway ID in the ProcessDefinition)
     * @param _targetId the ID of a graph element that is the target element of a transition
     * @return true if the transition condition exists and evaluates to true, false otherwise
     */
    function resolveTransitionCondition(bytes32 _sourceId, bytes32 _targetId) external view returns (bool) {
        if (self.processDefinition.modelElementExists(_targetId)) {
            return self.processDefinition.resolveTransitionCondition(_sourceId, _targetId, address(this));
        }
        else {
            BpmRuntime.ActivityNode memory currentTarget = self.graph.activities[_targetId];
            ErrorsLib.revertIf(!currentTarget.exists || currentTarget.node.outputs.length == 0,
                ErrorsLib.INVALID_INPUT(), "ProcessInstance.resolveTransitionCondition", "The specified target element ID is unsuitable to determine a successor. It is either not a graph activity or it has no output elements");
            ErrorsLib.revertIf(!self.processDefinition.modelElementExists(currentTarget.node.outputs[0]),
                ErrorsLib.INVALID_INPUT(), "ProcessInstance.resolveTransitionCondition", "Neither the specified target element nor its successor (in case of artificial graph places) is a known element in the ProcessDefinition");
            return self.processDefinition.resolveTransitionCondition(_sourceId, currentTarget.node.outputs[0], address(this));
        }
    }

	/**
	 * @dev Intermediate events should fire after a specific duration, which can be set as a string, e.g. "3 weeks". The conversion
	 * to an actual point in time is done off-chain, since this can get tricky. We might need to calculate number of weekdays excluding public
	 * holidays in a specific locale or calculate sunrise in Dallas. This is done off-chain and then this function is called with the blocktime
	 * at which the event should fire.
     * REVERTS if:
     * - The targetTime is zero (empty)
     * - No IntermediateEventInstance with the specified ID exist in the ProcessInstance
     * - The specified event instance already has a target timer set and cannot be overwritten
	 * @param _eventInstanceId - the event instance ID
	 * @param _targetTime - the unix epoch (or blocktime) at which the event should fire
	 */
    function setIntermediateEventTimerTarget(bytes32 _eventInstanceId, uint _targetTime) public {
        ErrorsLib.revertIf(_targetTime == 0,
            ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultProcessInstance.setIntermediateEventTimerTarget", "The target time parameter must be greater zero");
        ErrorsLib.revertIf(!self.intermediateEvents.rows[_eventInstanceId].exists,
            ErrorsLib.RESOURCE_NOT_FOUND(), "DefaultProcessInstance.setIntermediateEventTimerTarget", "The specified IntermediateEventInstance cannot be found");

        BpmRuntime.IntermediateEventInstance storage instance = self.intermediateEvents.rows[_eventInstanceId].value;

        if (instance.timerTarget == _targetTime) {
            // Allow setting time to be idempotent, but err if attempt is made to set a different time
            return;
        }

        ErrorsLib.revertIf(instance.timerTarget != 0,
            ErrorsLib.OVERWRITE_NOT_ALLOWED(), "DefaultProcessInstance.setIntermediateEventTimerTarget", "The specified target IntermediateEventInstance already has timer set to a different value and must be completed before being re-set");

        instance.updateIntermediateEventTimerTarget(_targetTime);
    }

    /**
	 * @dev Returns the timer timer target for the given intermediate event instance id
     * @param _eventInstanceId - the event instance ID
	 * @return uint timerTarget
	 */
    function getIntermediateEventTimerTarget(bytes32 _eventInstanceId) public returns (uint timerTarget) {
        ErrorsLib.revertIf(!self.intermediateEvents.rows[_eventInstanceId].exists,
            ErrorsLib.RESOURCE_NOT_FOUND(), "DefaultProcessInstance.getIntermediateEventTimerTarget", "The specified IntermediateEventInstance cannot be found");

        BpmRuntime.IntermediateEventInstance storage instance = self.intermediateEvents.rows[_eventInstanceId].value;
        return instance.timerTarget;
    }

	/**
	 * @dev Boundary events should fire after a specific duration, which can be set as a string, e.g. "3 weeks". The conversion
	 * to an actual point in time is done off-chain, since this can get tricky. We might need to calculate number of weekdays excluding public
	 * holidays in a specific locale or calculate sunrise in Dallas. This is done off-chain and then this function is called with the blocktime
	 * at which the event should fire.
     * REVERTS if:
     * - The targetTime is zero (empty)
     * - No BoundaryEventInstance with the specified ID and ActivityInstance exist in this ProcessInstance
     * - The specified event instance already has a target timer set and cannot be overwritten
     * @param _activityInstanceId - the ID of the ActivityInstance the event is bound to
	 * @param _eventInstanceId - the event instance ID
	 * @param _targetTime - the unix epoch (or blocktime) at which the event should fire
	 */
    function setBoundaryEventTimerTarget(bytes32 _activityInstanceId, bytes32 _eventInstanceId, uint _targetTime) public {
        ErrorsLib.revertIf(_targetTime == 0,
            ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultProcessInstance.setBoundaryEventTimerTarget", "The target time parameter must be greater zero");
        ErrorsLib.revertIf(!self.activities.rows[_activityInstanceId].exists,
            ErrorsLib.RESOURCE_NOT_FOUND(), "DefaultProcessInstance.setBoundaryEventTimerTarget", "The specified ActivityInstance cannot be found");

        BpmRuntime.ActivityInstance storage activityInstance = self.activities.rows[_activityInstanceId].value;

        ErrorsLib.revertIf(!activityInstance.boundaryEvents.rows[_eventInstanceId].exists,
                ErrorsLib.RESOURCE_NOT_FOUND(), "DefaultProcessInstance.setBoundaryEventTimerTarget", "The specified BoundaryEventInstance cannot be found");

        BpmRuntime.BoundaryEventInstance storage instance = activityInstance.boundaryEvents.rows[_eventInstanceId].value;

        ErrorsLib.revertIf(instance.timerTarget != 0,
            ErrorsLib.OVERWRITE_NOT_ALLOWED(), "DefaultProcessInstance.setBoundaryEventTimerTarget", "The specified target BoundaryEventInstance already has timer set");

        instance.timerTarget = _targetTime;
        // attempt to activate the boundary event after setting the timer target
        instance.activateBoundaryEvent(this, self.processDefinition);
    }

	/**
	 * @dev Returns the process definition on which this instance is based.
	 * @return the address of a ProcessDefinition
	 */
	function getProcessDefinition() external view returns (address) {
		return address(self.processDefinition);
	}

    /**
     * @dev Returns the state of this process instance
     * @return the uint8 representation of the BpmRuntime.ProcessInstanceState
     */
    function getState() external view returns (uint8) {
    	return uint8(self.state);
    }

    /**
     * @dev Returns the account that started this process instance
     * @return the address registered when creating the process instance
     */
    function getStartedBy() external view returns (address) {
    	return self.startedBy;
    }

	/**
	 * @dev Returns the number of activity instances currently contained in this ProcessInstance.
	 * Note that this number is subject to change as long as the process isntance is not completed.
	 * @return the number of activity instances
	 */
	function getNumberOfActivityInstances() external view returns (uint size) {
        return self.activities.keys.length;
    }

	/**
	 * @dev Returns the number of intermediate event instances currently contained in this ProcessInstance.
	 * Note that this number is subject to change as long as the process isntance is not completed.
	 * @return the number of intermediate event instances
	 */
	function getNumberOfIntermediateEventInstances() external view returns (uint size) {
        return self.intermediateEvents.keys.length;
    }

	/**
	 * @dev Returns the number of boundary event instances for the given ActivityInstance
     * @param _activityInstanceId the ActivityInstance ID
	 * @return the number of intermediate event instances
	 */
	function getNumberOfBoundaryEventInstances(bytes32 _activityInstanceId) external view returns (uint size) {
        return self.activities.rows[_activityInstanceId].value.boundaryEvents.keys.length;
    }

	/**
	 * @dev Returns the globally unique ID of the activity instance at the specified index in the ProcessInstance.
	 * @param _idx the index position
	 * @return the bytes32 ID
	 */
	function getActivityInstanceAtIndex(uint _idx) external view returns (bytes32) {
        if (_idx < self.activities.keys.length) {
            return self.activities.keys[_idx];
        }
    }

	/**
	 * @dev Returns the globally unique ID of the intermediate event instance at the specified index in the ProcessInstance.
	 * @param _idx the index position
	 * @return the bytes32 ID
	 */
	function getIntermediaEventIdAtIndex(uint _idx) external view returns (bytes32) {
        if (_idx < self.intermediateEvents.keys.length) {
            return self.intermediateEvents.keys[_idx];
        }
    }

	/**
	 * @dev Returns the globally unique ID of the boundary event instance at the specified index in the ProcessInstance.
     * @param _activityInstanceId the ActivityInstance to which the boundary event is bound
	 * @param _idx the index position
	 * @return the bytes32 ID
	 */
	function getBoundaryEventIdAtIndex(bytes32 _activityInstanceId, uint _idx) external view returns (bytes32) {
        if (_idx < self.activities.rows[_activityInstanceId].value.boundaryEvents.keys.length) {
            return self.activities.rows[_activityInstanceId].value.boundaryEvents.keys[_idx];
        }
    }

    /**
     * @dev Returns details about the BoundaryEventInstance with the given ID.
     * REVERTS if:
     * - the ActivityInstance or BoundaryEventInstance don't exist
     * @param _activityInstanceId the ActivityInstance to which the boundary event is bound
     * @param _eventInstanceId the event instance ID
     * @return state the uint8 representation of the BpmRuntime.BoundaryEventInstanceState
     * @return timerResolution the value of a timer, if the event is a timer event. Can return empty if the event instance is not active
     */
    function getBoundaryEventDetails(bytes32 _activityInstanceId, bytes32 _eventInstanceId) external view returns (uint8 state, uint timerResolution) {
        ErrorsLib.revertIf(!self.activities.rows[_activityInstanceId].value.boundaryEvents.rows[_eventInstanceId].exists,
            ErrorsLib.RESOURCE_NOT_FOUND(), "DefaultProcessInstance.getBoundaryEventDetails", "No BoundaryEventInstance found for the given ID");

        BpmRuntime.BoundaryEventInstance storage instance = self.activities.rows[_activityInstanceId].value.boundaryEvents.rows[_eventInstanceId].value;
        return (uint8(instance.state), instance.timerTarget);
    }

	/**
	 * @dev Returns information about the activity instance with the specified ID
	 * @param _id the global ID of the activity instance
	 * @return created - the creation timestamp
	 * @return completed - the completion timestamp
	 * @return performer - the account who is performing the activity (for interactive activities only)
	 * @return completedBy - the account who completed the activity (for interactive activities only)
	 * @return activityId - the ID of the activity as defined by the process definition
	 * @return state - the uint8 representation of the BpmRuntime.ActivityInstanceState of this activity instance
	 */
	function getActivityInstanceData(bytes32 _id) external view returns (bytes32 activityId, uint created, uint completed, address performer, address completedBy, uint8 state) {
        if (self.activities.rows[_id].exists) {
            activityId = self.activities.rows[_id].value.activityId;
            created = self.activities.rows[_id].value.created;
            completed = self.activities.rows[_id].value.completed;
            performer = self.activities.rows[_id].value.performer;
            completedBy = self.activities.rows[_id].value.completedBy;
            state = uint8(self.activities.rows[_id].value.state);
        }
    }

    /**
     * @dev Notifies listeners about a process state change
     */
    function notifyProcessStateChange() public {
        for (uint i=0; i<stateChangeListeners.length; i++) {
            stateChangeListeners[i].processStateChanged(this);
        }
    }

}
