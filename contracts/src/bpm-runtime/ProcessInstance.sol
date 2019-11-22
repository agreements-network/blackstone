pragma solidity ^0.5;

import "commons-base/OwnerTransferable.sol";
import "commons-collections/DataStorage.sol";
import "commons-collections/AddressScopes.sol";
import "commons-management/VersionedArtifact.sol";

import "bpm-runtime/BpmService.sol";
import "bpm-runtime/ProcessStateChangeEmitter.sol";
import "bpm-runtime/TransitionConditionResolver.sol";

/**
 * @title ProcessInstance Interface
 * @dev Interface for a BPM container that represents a process instance providing a data context for activities and code participating in the process.
 */
contract ProcessInstance is VersionedArtifact, DataStorage, AddressScopes, OwnerTransferable, ProcessStateChangeEmitter, TransitionConditionResolver {

	event LogProcessInstanceCreation(
		bytes32 indexed eventId,
		address processInstanceAddress,
		address processDefinitionAddress,
		uint8 state,
		address startedBy
	);

	event LogProcessInstanceStateUpdate(
		bytes32 indexed eventId,
		address processInstanceAddress,
		uint8 state
	);

	bytes32 public constant EVENT_ID_PROCESS_INSTANCES = "AN://process-instances";

    /**
	 * @dev Initializes this ProcessInstance with the provided parameters. This function replaces the
	 * contract constructor, so it can be used as the delegate target for an ObjectProxy.
     * @param _processDefinition the ProcessDefinition which this ProcessInstance should follow
     * @param _startedBy (optional) account which initiated the transaction that started the process. If empty, the msg.sender is registered as having started the process
     * @param _activityInstanceId the ID of a subprocess activity instance that initiated this ProcessInstance (optional)
     */
    function initialize(address _processDefinition, address _startedBy, bytes32 _activityInstanceId) external;

	/**
	 * @dev Initiates and populates the runtime graph that will handle the state of this ProcessInstance.
	 */
	function initRuntime() public;

	/**
	 * @dev Initiates execution of this ProcessInstance consisting of attempting to activate and process any activities and advance the
	 * state of the runtime graph.
	 * @param _service the BpmService managing this ProcessInstance (required for changes to this ProcessInstance and access to the BpmServiceDb)
	 * @return error code indicating success or failure
	 */
	function execute(BpmService _service) public returns (uint error);

	/**
	 * @dev Aborts this ProcessInstance and halts any ongoing activities. After the abort the ProcessInstance cannot be resurrected.
	 */
	function abort() external;

    // @SEAN
    function triggerBoundaryEvent(bytes32 _boundaryEventId) external;

	/**
	 * @dev Once an intermediate event is ready to run due the timer expiring, this function should be called from anything off-chain
	 */
    function triggerIntermediateEvent(bytes32 _eventId, BpmService _service) external;

	/**
	 * @dev Completes the specified activity
	 * @param _activityInstanceId the activity instance
	 * @param _service the BpmService managing this ProcessInstance (required for changes to this ProcessInstance after the activity completes)
	 * @return an error code indicating success or failure
	 */
	function completeActivity(bytes32 _activityInstanceId, BpmService _service) public returns (uint error);

    /**
	 * @dev Writes data via BpmService and then completes the specified activity.
	 * @param _activityInstanceId the task ID
	 * @param _service the BpmService required for lookup and access to the BpmServiceDb
	 * @param _dataMappingId the id of the dataMapping that points to data storage slot
	 * @param _value the bool value of the data
	 * @return error code if the completion failed
	 */
    function completeActivityWithBoolData(bytes32 _activityInstanceId, BpmService _service, bytes32 _dataMappingId, bool _value) external returns (uint error);

    /**
	 * @dev Writes data via BpmService and then completes the specified activity.
	 * @param _activityInstanceId the task ID
	 * @param _service the BpmService required for lookup and access to the BpmServiceDb
	 * @param _dataMappingId the id of the dataMapping that points to data storage slot
	 * @param _value the string value of the data
	 * @return error code if the completion failed
	 */
    function completeActivityWithStringData(bytes32 _activityInstanceId, BpmService _service, bytes32 _dataMappingId, string calldata _value) external returns (uint error);

    /**
	 * @dev Writes data via BpmService and then completes the specified activity.
	 * @param _activityInstanceId the task ID
	 * @param _service the BpmService required for lookup and access to the BpmServiceDb
	 * @param _dataMappingId the id of the dataMapping that points to data storage slot
	 * @param _value the bytes32 value of the data
	 * @return error code if the completion failed
	 */
    function completeActivityWithBytes32Data(bytes32 _activityInstanceId, BpmService _service, bytes32 _dataMappingId, bytes32 _value) external returns (uint error);

    /**
	 * @dev Writes data via BpmService and then completes the specified activity.
	 * @param _activityInstanceId the task ID
	 * @param _service the BpmService required for lookup and access to the BpmServiceDb
	 * @param _dataMappingId the id of the dataMapping that points to data storage slot
	 * @param _value the uint value of the data
	 * @return error code if the completion failed
	 */
    function completeActivityWithUintData(bytes32 _activityInstanceId, BpmService _service, bytes32 _dataMappingId, uint _value) external returns (uint error);

    /**
	 * @dev Writes data via BpmService and then completes the specified activity.
	 * @param _activityInstanceId the task ID
	 * @param _service the BpmService required for lookup and access to the BpmServiceDb
	 * @param _dataMappingId the id of the dataMapping that points to data storage slot
	 * @param _value the int value of the data
	 * @return error code if the completion failed
	 */
    function completeActivityWithIntData(bytes32 _activityInstanceId, BpmService _service, bytes32 _dataMappingId, int _value) external returns (uint error);

    /**
	 * @dev Writes data via BpmService and then completes the specified activity.
	 * @param _activityInstanceId the task ID
	 * @param _service the BpmService required for lookup and access to the BpmServiceDb
	 * @param _dataMappingId the id of the dataMapping that points to data storage slot
	 * @param _value the address value of the data
	 * @return error code if the completion failed
	 */
    function completeActivityWithAddressData(bytes32 _activityInstanceId, BpmService _service, bytes32 _dataMappingId, address _value) external returns (uint error);

	/**
	 * @dev Returns the bool value of the specified IN data mapping in the context of the given activity instance.
	 * @param _activityInstanceId the ID of an activity instance in this ProcessInstance
	 * @param _dataMappingId the ID of an IN data mapping defined for the activity
	 * @return the bool value resulting from resolving the data mapping
	 */
	function getActivityInDataAsBool(bytes32 _activityInstanceId, bytes32 _dataMappingId) external returns (bool);

	/**
	 * @dev Returns the string value of the specified IN data mapping in the context of the given activity instance.
	 * @param _activityInstanceId the ID of an activity instance in this ProcessInstance
	 * @param _dataMappingId the ID of an IN data mapping defined for the activity
	 * @return the string value resulting from resolving the data mapping
	 */
	function getActivityInDataAsString(bytes32 _activityInstanceId, bytes32 _dataMappingId) external returns (string memory);

	/**
	 * @dev Returns the bytes32 value of the specified IN data mapping in the context of the given activity instance.
	 * @param _activityInstanceId the ID of an activity instance in this ProcessInstance
	 * @param _dataMappingId the ID of an IN data mapping defined for the activity
	 * @return the bytes32 value resulting from resolving the data mapping
	 */
	function getActivityInDataAsBytes32(bytes32 _activityInstanceId, bytes32 _dataMappingId) external returns (bytes32);

	/**
	 * @dev Returns the uint value of the specified IN data mapping in the context of the given activity instance.
	 * @param _activityInstanceId the ID of an activity instance in this ProcessInstance
	 * @param _dataMappingId the ID of an IN data mapping defined for the activity
	 * @return the uint value resulting from resolving the data mapping
	 */
	function getActivityInDataAsUint(bytes32 _activityInstanceId, bytes32 _dataMappingId) external returns (uint);

	/**
	 * @dev Returns the int value of the specified IN data mapping in the context of the given activity instance.
	 * @param _activityInstanceId the ID of an activity instance in this ProcessInstance
	 * @param _dataMappingId the ID of an IN data mapping defined for the activity
	 * @return the int value resulting from resolving the data mapping
	 */
	function getActivityInDataAsInt(bytes32 _activityInstanceId, bytes32 _dataMappingId) external returns (int);

	/**
	 * @dev Returns the address value of the specified IN data mapping in the context of the given activity instance.
	 * @param _activityInstanceId the ID of an activity instance in this ProcessInstance
	 * @param _dataMappingId the ID of an IN data mapping defined for the activity
	 * @return the address value resulting from resolving the data mapping
	 */
	function getActivityInDataAsAddress(bytes32 _activityInstanceId, bytes32 _dataMappingId) external returns (address);

	/**
	 * @dev Applies the given value to the OUT data mapping with the specified ID on the specified activity instance.
	 * @param _activityInstanceId the ID of an activity instance in this ProcessInstance
	 * @param _dataMappingId the ID of an OUT data mapping defined for the activity
	 * @param _value the value to set
	 */
	function setActivityOutDataAsBool(bytes32 _activityInstanceId, bytes32 _dataMappingId, bool _value) public;

	/**
	 * @dev Applies the given value to the OUT data mapping with the specified ID on the specified activity instance.
	 * @param _activityInstanceId the ID of an activity instance in this ProcessInstance
	 * @param _dataMappingId the ID of an OUT data mapping defined for the activity
	 * @param _value the value to set
	 */
	function setActivityOutDataAsString(bytes32 _activityInstanceId, bytes32 _dataMappingId, string memory _value) public;

	/**
	 * @dev Applies the given bytes32 value to the OUT data mapping with the specified ID on the specified activity instance.
	 * @param _activityInstanceId the ID of an activity instance in this ProcessInstance
	 * @param _dataMappingId the ID of an OUT data mapping defined for the activity
	 * @param _value the value to set
	 */
	function setActivityOutDataAsBytes32(bytes32 _activityInstanceId, bytes32 _dataMappingId, bytes32 _value) public;

	/**
	 * @dev Applies the given value to the OUT data mapping with the specified ID on the specified activity instance.
	 * @param _activityInstanceId the ID of an activity instance in this ProcessInstance
	 * @param _dataMappingId the ID of an OUT data mapping defined for the activity
	 * @param _value the value to set
	 */
	function setActivityOutDataAsUint(bytes32 _activityInstanceId, bytes32 _dataMappingId, uint _value) public;

	/**
	 * @dev Applies the given int value to the OUT data mapping with the specified ID on the specified activity instance.
	 * @param _activityInstanceId the ID of an activity instance in this ProcessInstance
	 * @param _dataMappingId the ID of an OUT data mapping defined for the activity
	 * @param _value the value to set
	 */
	function setActivityOutDataAsInt(bytes32 _activityInstanceId, bytes32 _dataMappingId, int _value) public;

	/**
	 * @dev Applies the given value to the OUT data mapping with the specified ID on the specified activity instance.
	 * @param _activityInstanceId the ID of an activity instance in this ProcessInstance
	 * @param _dataMappingId the ID of an OUT data mapping defined for the activity
	 * @param _value the value to set
	 */
	function setActivityOutDataAsAddress(bytes32 _activityInstanceId, bytes32 _dataMappingId, address _value) public;

    /**
     * @dev Resolves the target storage location for the specified IN data mapping in the context of the given activity instance.
     * @param _activityInstanceId the ID of an activity instance
     * @param _dataMappingId the ID of a data mapping defined for the activity
     * @return dataStorage - the address of a DataStorage
     * @return dataPath - the dataPath under which to find data mapping value
     */
    function resolveInDataLocation(bytes32 _activityInstanceId, bytes32 _dataMappingId) public view returns (address dataStorage, bytes32 dataPath);

    /**
     * @dev Resolves the target storage location for the specified OUT data mapping in the context of the given activity instance.
     * @param _activityInstanceId the ID of an activity instance
     * @param _dataMappingId the ID of a data mapping defined for the activity
     * @return dataStorage - the address of a DataStorage
     * @return dataPath - the dataPath under which to find data mapping value
     */
    function resolveOutDataLocation(bytes32 _activityInstanceId, bytes32 _dataMappingId) public view returns (address dataStorage, bytes32 dataPath);

	/**
	 * @dev boundary and intermediate events should fire after a specific duration, which can be set as a string, e.g. "3 weeks". The conversion
	 * to an actual point in time is done off-chain, since this can get tricky. We might need to calculate number of weekdays excluding public
	 * holidays in a specific locale or calculate sunrise in Dallas. This is done off-chain and then this function is called with the blocktime
	 * at which the event should fire.
	 * @param _eventInstanceId - the event instance Id
	 * @param _targetTime - the unix epoch (or blocktime) at which the time should fire
	 */
    function setTimerEventTarget(bytes32 _eventInstanceId, uint _targetTime) public;

	/**
	 * @dev Returns the process definition on which this instance is based.
	 * @return the address of a ProcessDefinition
	 */
	function getProcessDefinition() external view returns (address);

	/**
	 * @dev Returns the state of this process instance
	 * @return the uint representation of the BpmRuntime.ProcessInstanceState
	 */
	function getState() external view returns (uint8);

    /**
     * @dev Returns the account that started this process instance
     * @return the address registered when creating the process instance
     */
    function getStartedBy() external view returns (address);

	/**
	 * @dev Returns the number of intermediate event instances currently contained in this ProcessInstance.
	 * Note that this number is subject to change as long as the process isntance is not completed.
	 * @return the number of intermediate event instances
	 */
	function getNumberOfIntermediateEventInstances() external view returns (uint size);

	/**
	 * @dev Returns the globally unique ID of the activity instance at the specified index in the ProcessInstance.
	 * @param _idx the index position
	 * @return the bytes32 ID
	 */
	function getIntermediateInstanceAtIndex(uint _idx) external view returns (bytes32);

	/**
	 * @dev Returns the number of activity instances currently contained in this ProcessInstance.
	 * Note that this number is subject to change as long as the process isntance is not completed.
	 * @return the number of activity instances
	 */
	function getNumberOfActivityInstances() external view returns (uint size);

	/**
	 * @dev Returns the globally unique ID of the activity instance at the specified index in the ProcessInstance.
	 * @param _idx the index position
	 * @return the bytes32 ID
	 */
	function getActivityInstanceAtIndex(uint _idx) external view returns (bytes32);

	/**
	 * @dev Returns information about the activity instance with the specified ID
	 * @param _id the global ID of the activity instance
	 * @return activityId - the ID of the activity as defined by the process definition
	 * @return created - the creation timestamp
	 * @return completed - the completion timestamp
	 * @return performer - the account who is performing the activity (for interactive activities only)
	 * @return completedBy - the account who completed the activity (for interactive activities only) 
	 * @return state - the uint8 representation of the BpmRuntime.ActivityInstanceState of this activity instance
	 */
	function getActivityInstanceData(bytes32 _id) external view returns (bytes32 activityId, uint created, uint completed, address performer, address completedBy, uint8 state);

}