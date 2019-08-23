pragma solidity ^0.5.12;

import "commons-base/Bytes32Identifiable.sol";
import "commons-management/VersionedArtifact.sol";

import "bpm-model/BpmModel.sol";
import "bpm-model/ProcessModel.sol";

/**
 * @title ProcessDefinition Interface
 * @dev A ProcessDefinition provides the canvas to define activities and the sequence and logic of processing them in order.
 * A ProcessDefinition can also declare to implement a number of ProcessInterfaces.
 */
contract ProcessDefinition is VersionedArtifact, Bytes32Identifiable {

	event LogProcessDefinitionCreation(
		bytes32 indexed eventId,
		address processDefinitionAddress,
		bytes32 id,
		bytes32 interfaceId,
		bytes32 modelId,
		address modelAddress
	);

	event LogProcessDefinitionInterfaceIdUpdate(
		bytes32 indexed eventId,
		address processDefinitionAddress,
		bytes32 interfaceId
	);

	event LogActivityDefinitionCreation(
		bytes32 indexed eventId,
		address processDefinitionAddress,
		bytes32 activityId,
		uint8 activityType,
		uint8 taskType,
		uint8 taskBehavior,
		bytes32 participantId,
		bool multiInstance,
		bytes32 application,
		bytes32 subProcessModelId,
		bytes32 subProcessDefinitionId
	);

	event LogDataMappingCreation(
		bytes32 indexed eventId,
		address processDefinitionAddress,
		bytes32 activityId,
    	bytes32 dataMappingId,
		bytes32 dataPath,
		bytes32 dataStorageId,
		address dataStorage,
		uint direction
	);

	bytes32 public constant EVENT_ID_PROCESS_DEFINITIONS = "AN://process-definitions";
	bytes32 public constant EVENT_ID_ACTIVITY_DEFINITIONS = "AN://activity-definitions";
	bytes32 public constant EVENT_ID_DATA_MAPPINGS = "AN://data-mappings";

	/**
	 * @dev Initializes this DefaultOrganization with the specified ID and belonging to the given model. This function replaces the
	 * contract constructor, so it can be used as the delegate target for an ObjectProxy.
	 * REVERTS if
	 * - the _model is an empty address or if the ID is empty
	 * @param _id the ProcessDefinition ID
	 * @param _model the address of a ProcessModel in which this ProcessDefinition is created
	 */
	function initialize(bytes32 _id, address _model) external;

	/**
	 * @dev Creates a new activity definition with the specified parameters.
	 * @param _id the activity ID
	 * @param _activityType the BpmModel.ActivityType [TASK|SUBPROCESS]
	 * @param _taskType the BpmModel.TaskType [NONE|USER|SERVICE|EVENT]
	 * @param _behavior the BpmModel.TaskBehavior [SEND|SENDRECEIVE|RECEIVE]
	 * @param _assignee the ID of the participant performing the activity (for USER tasks only)
	 * @param _multiInstance whether the activity represents multiple instances
	 * @param _application the application handling the execution of the activity
	 * @param _subProcessModelId references the model containg a subprocess definition (only for SUBPROCESS ActivityType)
	 * @param _subProcessDefinitionId references a subprocess definition (only for SUBPROCESS ActivityType)
	 * @return an error code indicating success or failure
	 */
	function createActivityDefinition(bytes32 _id, BpmModel.ActivityType _activityType, BpmModel.TaskType _taskType, BpmModel.TaskBehavior _behavior, bytes32 _assignee, bool _multiInstance, bytes32 _application, bytes32 _subProcessModelId, bytes32 _subProcessDefinitionId) external returns (uint error);

	/**
	 * @dev Creates a new BpmModel.Gateway model element with the specified ID and type
	 * @param _id the ID under which to register the element
	 * @param _type a BpmModel.GatewayType
	 */
	function createGateway(bytes32 _id, BpmModel.GatewayType _type) external;

	/**
	 * Creates a new intermediate event definition with the specified parameters and conditional (DataStorage-based) data.
	 * @param _id the ID under which to register the element
	 * @param _eventType a BpmModel.EventType
	 * @param _eventBehavior a BpmModel.IntermediateEventBehavior
	 * @param _dataPath a data path (key) to use for data lookup on a DataStorage.
	 * @param _dataStorageId an optional key to identify a DataStorage as basis for the data path other than the default one
	 * @param _dataStorage an optional address of a DataStorage as basis for the data path other than the default one
	 * @param _constantValue a fixed value for timer based events representing either a datetime or a duration in secs
	 */
	function createIntermediateEvent(bytes32 _id, BpmModel.EventType _eventType, BpmModel.IntermediateEventBehavior _eventBehavior, bytes32 _dataPath, bytes32 _dataStorageId, address _dataStorage, uint256 _constantValue) external;

	/**
	 * @dev Addes a boundary event to the specified activity using the provided ID, parameters, conditional (DataStorage-based)
	 * data or constant uint value. If a constant value is provided, the conditional data will be ignored! 
	 * @param _activityId the activity for which the boundary event is added
	 * @param _id the ID under which to register the element
	 * @param _eventType a BpmModel.EventType.
	 * @param _eventBehavior a BpmModel.IntermediateEventBehavior
	 * @param _dataPath a data path (key) to use for data lookup on a DataStorage.
	 * @param _dataStorageId an optional key to identify a DataStorage as basis for the data path other than the default one
	 * @param _dataStorage an optional address of a DataStorage as basis for the data path other than the default one
	 * @param _constantValue a fixed value for timer based events representing either a datetime or a duration in secs
	 */
	function addBoundaryEvent(bytes32 _activityId, bytes32 _id, BpmModel.EventType _eventType, BpmModel.BoundaryEventBehavior _eventBehavior, bytes32 _dataPath, bytes32 _dataStorageId, address _dataStorage, uint256 _constantValue) external;

	/**
	 * @dev Adds an event action to a given boundary event.
	 * @param _id the boundary event ID
	 * @param _dataPath a data path (key) to use for data lookup on a DataStorage to find the escalation target
	 * @param _dataStorageId an optional key to identify a DataStorage as basis for the data path to find the escalation target
	 * @param _dataStorage an optional address of a DataStorage as basis for the data path to find the escalation target
	 * @param _fixedTarget a fixed address for the escalation target
	 * @param _actionFunction a function signature to be invoked on the escalation target
	 */
	function addBoundaryEventAction(bytes32 _id, bytes32 _dataPath, bytes32 _dataStorageId, address _dataStorage, address _fixedTarget, string _actionFunction) external;

	/**
	 * @dev Creates a transition between the specified source and target elements.
	 * @param _source the start of the transition
	 * @param _target the end of the transition
	 * @return an error code indicating success or failure
	 */
	function createTransition(bytes32 _source, bytes32 _target) external returns (uint error);

	/**
	 * @dev Sets the specified activity to be the default output (default transition) of the specified gateway.
	 * @param _gatewayId the ID of a gateway in this ProcessDefinition
	 * @param _targetElementId the ID of a graph element (activity or gateway) in this ProcessDefinition
	 */
	function setDefaultTransition(bytes32 _gatewayId, bytes32 _targetElementId) external;

	/**
	 * @dev Create a data mapping for the specified activity and direction.
	 * @param _activityId the ID of the activity in this ProcessDefinition
	 * @param _direction the BpmModel.Direction [IN|OUT]
	 * @param _accessPath the access path offered by the application. If the application does not have any access paths, this field is used as an ID for the mapping.
	 * @param _dataPath a data path (key) to use for data lookup on a DataStorage.
	 * @param _dataStorageId an optional key to identify a DataStorage as basis for the data path other than the default one
	 * @param _dataStorage an optional address of a DataStorage as basis for the data path other than the default one
	 */
	function createDataMapping(bytes32 _activityId, BpmModel.Direction _direction, bytes32 _accessPath, bytes32 _dataPath, bytes32 _dataStorageId, address _dataStorage) external;

	/**
	 * @dev Adds the specified process interface to the list of supported process interfaces of this ProcessDefinition
	 * @param _model the model defining the interface
	 * @param _interfaceId the ID of the interface
	 * @return an error code signaling success or failure
	 */
	function addProcessInterfaceImplementation(address _model, bytes32 _interfaceId) external returns (uint error);

	/**
	 * @dev Creates a transition condition between the specified gateway and activity using the given parameters.
	 * The parameters dataPath, dataStorageId, and dataStorage are used to construct a left-hand side DataStorageUtils.ConditionalData object.
	 * @param _gatewayId the ID of a gateway in this ProcessDefinition
	 * @param _targetElementId the ID of a graph element (activity or gateway) in this ProcessDefinition
	 * @param _dataPath the left-hand side dataPath condition
	 * @param _dataStorageId the left-hand side dataStorageId condition
	 * @param _dataStorage the left-hand side dataStorage condition
	 * @param _operator the uint8 representation of a DataStorageUtils.COMPARISON_OPERATOR
	 * @param _value the right-hand side comparison value
	 */
	function createTransitionConditionForString(bytes32 _gatewayId, bytes32 _targetElementId, bytes32 _dataPath, bytes32 _dataStorageId, address _dataStorage, uint8 _operator, string calldata _value) external;

	/**
	 * @dev Creates a transition condition between the specified gateway and activity using the given parameters.
	 * The parameters dataPath, dataStorageId, and dataStorage are used to construct a left-hand side DataStorageUtils.ConditionalData object.
	 * @param _gatewayId the ID of a gateway in this ProcessDefinition
	 * @param _targetElementId the ID of a graph element (activity or gateway) in this ProcessDefinition
	 * @param _dataPath the left-hand side dataPath condition
	 * @param _dataStorageId the left-hand side dataStorageId condition
	 * @param _dataStorage the left-hand side dataStorage condition
	 * @param _operator the uint8 representation of a DataStorageUtils.COMPARISON_OPERATOR
	 * @param _value the right-hand side comparison value
	 */
	function createTransitionConditionForBytes32(bytes32 _gatewayId, bytes32 _targetElementId, bytes32 _dataPath, bytes32 _dataStorageId, address _dataStorage, uint8 _operator, bytes32 _value) external;

	/**
	 * @dev Creates a transition condition between the specified gateway and activity using the given parameters.
	 * The parameters dataPath, dataStorageId, and dataStorage are used to construct a left-hand side DataStorageUtils.ConditionalData object.
	 * @param _gatewayId the ID of a gateway in this ProcessDefinition
	 * @param _targetElementId the ID of a graph element (activity or gateway) in this ProcessDefinition
	 * @param _dataPath the left-hand side dataPath condition
	 * @param _dataStorageId the left-hand side dataStorageId condition
	 * @param _dataStorage the left-hand side dataStorage condition
	 * @param _operator the uint8 representation of a DataStorageUtils.COMPARISON_OPERATOR
	 * @param _value the right-hand side comparison value
	 */
	function createTransitionConditionForAddress(bytes32 _gatewayId, bytes32 _targetElementId, bytes32 _dataPath, bytes32 _dataStorageId, address _dataStorage, uint8 _operator, address _value) external;

	/**
	 * @dev Creates a transition condition between the specified gateway and activity using the given parameters.
	 * The parameters dataPath, dataStorageId, and dataStorage are used to construct a left-hand side DataStorageUtils.ConditionalData object.
	 * @param _gatewayId the ID of a gateway in this ProcessDefinition
	 * @param _targetElementId the ID of a graph element (activity or gateway) in this ProcessDefinition
	 * @param _dataPath the left-hand side dataPath condition
	 * @param _dataStorageId the left-hand side dataStorageId condition
	 * @param _dataStorage the left-hand side dataStorage condition
	 * @param _operator the uint8 representation of a DataStorageUtils.COMPARISON_OPERATOR
	 * @param _value the right-hand side comparison value
	 */
	function createTransitionConditionForBool(bytes32 _gatewayId, bytes32 _targetElementId, bytes32 _dataPath, bytes32 _dataStorageId, address _dataStorage, uint8 _operator, bool _value) external;

	/**
	 * @dev Creates a transition condition between the specified gateway and activity using the given parameters.
	 * The parameters dataPath, dataStorageId, and dataStorage are used to construct a left-hand side DataStorageUtils.ConditionalData object.
	 * @param _gatewayId the ID of a gateway in this ProcessDefinition
	 * @param _targetElementId the ID of a graph element (activity or gateway) in this ProcessDefinition
	 * @param _dataPath the left-hand side dataPath condition
	 * @param _dataStorageId the left-hand side dataStorageId condition
	 * @param _dataStorage the left-hand side dataStorage condition
	 * @param _operator the uint8 representation of a DataStorageUtils.COMPARISON_OPERATOR
	 * @param _value the right-hand side comparison value
	 */
	function createTransitionConditionForUint(bytes32 _gatewayId, bytes32 _targetElementId, bytes32 _dataPath, bytes32 _dataStorageId, address _dataStorage, uint8 _operator, uint _value) external;

	/**
	 * @dev Creates a transition condition between the specified gateway and activity using the given parameters.
	 * The parameters dataPath, dataStorageId, and dataStorage are used to construct a left-hand side DataStorageUtils.ConditionalData object.
	 * @param _gatewayId the ID of a gateway in this ProcessDefinition
	 * @param _targetElementId the ID of a graph element (activity or gateway) in this ProcessDefinition
	 * @param _dataPath the left-hand side dataPath condition
	 * @param _dataStorageId the left-hand side dataStorageId condition
	 * @param _dataStorage the left-hand side dataStorage condition
	 * @param _operator the uint8 representation of a DataStorageUtils.COMPARISON_OPERATOR
	 * @param _value the right-hand side comparison value
	 */
	function createTransitionConditionForInt(bytes32 _gatewayId, bytes32 _targetElementId, bytes32 _dataPath, bytes32 _dataStorageId, address _dataStorage, uint8 _operator, int _value) external;

	/**
	 * @dev Creates a transition condition between the specified gateway and activity using the given parameters.
	 * The "lh..." parameters are used to construct a left-hand side DataStorageUtils.ConditionalData object while the "rh..." ones are used
	 * for a right-hand side DataStorageUtils.ConditionalData as comparison
	 * @param _gatewayId the ID of a gateway in this ProcessDefinition
	 * @param _targetElementId the ID of a graph element (activity or gateway) in this ProcessDefinition
	 * @param _lhDataPath the left-hand side dataPath condition
	 * @param _lhDataStorageId the left-hand side dataStorageId condition
	 * @param _lhDataStorage the left-hand side dataStorage condition
	 * @param _operator the uint8 representation of a DataStorageUtils.COMPARISON_OPERATOR
	 * @param _rhDataPath the right-hand side dataPath condition
	 * @param _rhDataStorageId the right-hand side dataStorageId condition
	 * @param _rhDataStorage the right-hand side dataStorage condition
	 */
	function createTransitionConditionForDataStorage(bytes32 _gatewayId, bytes32 _targetElementId, bytes32 _lhDataPath, bytes32 _lhDataStorageId, address _lhDataStorage, uint8 _operator, bytes32 _rhDataPath, bytes32 _rhDataStorageId, address _rhDataStorage) external;

	/**
	 * @dev Resolves a transition condition between the given source and target model elements using the provided DataStorage to lookup data.
	 * The function should return 'true' as default if no condition exists for the specified transition.
	 * @param _sourceId the ID of a model element in this ProcessDefinition, e.g. a gateway
	 * @param _targetId the ID of a model element in this ProcessDefinition, e.g. an activity
	 * @param _dataStorage the address of a DataStorage.
	 * @return true if the condition evaluated to 'true' or if no condition exists, false otherwise
	 */
	function resolveTransitionCondition(bytes32 _sourceId, bytes32 _targetId, address _dataStorage) external view returns (bool);

	/**
	 * @dev Returns the IDs of all activities connected to the given model participant. This function
	 * can be used to retrieve all user tasks belonging to the same "swimlane" in the model.
	 * @param _participantId the ID of a participant in the model
	 * @return an array of activity IDs
	 */
	function getActivitiesForParticipant(bytes32 _participantId) external view returns (bytes32[] memory);

	/**
	 * @dev Returns the number of IN data mappings for the specified activity.
	 * @param _activityId the ID of the activity in this ProcessDefinition
	 * @return the number of IN data mappings
	 */
	function getNumberOfInDataMappings(bytes32 _activityId) external view returns (uint size);

	/**
	 * @dev Returns the number of OUT data mappings for the specified activity.
	 * @param _activityId the ID of the activity in this ProcessDefinition
	 * @return the number of OUT data mappings
	 */
	function getNumberOfOutDataMappings(bytes32 _activityId) external view returns (uint size);

	/**
	 * @dev Returns the ID of the IN data mapping of the specified activity at the specified index.
	 * @param _activityId the ID of the activity in this ProcessDefinition
	 * @param _idx the index position
	 * @return the mapping ID, if it exists
	 */
	function getInDataMappingIdAtIndex(bytes32 _activityId, uint _idx) external view returns (bytes32);

	/**
	 * @dev Returns the ID of the OUT data mapping of the specified activity at the specified index.
	 * @param _activityId the ID of the activity in this ProcessDefinition
	 * @param _idx the index position
	 * @return the mapping ID, if it exists
	 */
	function getOutDataMappingIdAtIndex(bytes32 _activityId, uint _idx) external view returns (bytes32);

	/**
	 * @dev Returns an array of the IN data mapping ids of the specified activity.
	 * @param _activityId the ID of the activity in this ProcessDefinition
	 * @return the data mapping ids
	 */
	function getInDataMappingKeys(bytes32 _activityId) external view returns (bytes32[] memory);

	/**
	 * @dev Returns an array of the OUT data mapping ids of the specified activity.
	 * @param _activityId the ID of the activity in this ProcessDefinition
	 * @return the data mapping ids
	 */
	function getOutDataMappingKeys(bytes32 _activityId) external view returns (bytes32[] memory);

	/**
	 * @dev Returns information about the IN data mapping of the specified activity with the given ID.
	 * @param _activityId the ID of the activity in this ProcessDefinition
	 * @param _id the data mapping ID
	 * @return dataMappingId the id of the data mapping
	 * @return accessPath the access path on the application
	 * @return dataPath a data path (key) to use for identifying the data location in a DataStorage contract
	 * @return dataStorageId a key to identify a secondary DataStorage as basis for the data path other than the default one
	 * @return dataStorage an address of a DataStorage as basis for the data path other than the default one
	 */
	function getInDataMappingDetails(bytes32 _activityId, bytes32 _id) external view returns (bytes32 dataMappingId, bytes32 accessPath, bytes32 dataPath, bytes32 dataStorageId, address dataStorage);

	/**
	 * @dev Returns information about the OUT data mapping of the specified activity with the given ID.
	 * @param _activityId the ID of the activity in this ProcessDefinition
	 * @param _id the data mapping ID
	 * @return dataMappingId the id of the data mapping
	 * @return accessPath the access path on the application
	 * @return dataPath a data path (key) to use for identifying the data location in a DataStorage contract
	 * @return dataStorageId a key to identify a secondary DataStorage as basis for the data path other than the default one
	 * @return dataStorage an address of a DataStorage as basis for the data path other than the default one
	 */
	function getOutDataMappingDetails(bytes32 _activityId, bytes32 _id) external view returns (bytes32 dataMappingId, bytes32 accessPath, bytes32 dataPath, bytes32 dataStorageId, address dataStorage);

	/**
	 * @dev Returns the number of activity definitions in this ProcessDefinition.
	 * @return the number of activity definitions
	 */
	function getNumberOfActivities() external view returns (uint);

	/**
	 * @dev Returns the ID of the ActivityDefinition at the specified index position of the given Process Definition
	 * @param _index the index position
	 * @return bytes32 the ActivityDefinition ID, if it exists
	 */
	function getActivityAtIndex(uint _index) external view returns (bytes32);

	/**
	 * @dev Returns information about the activity definition with the given ID.
	 * @param _id the bytes32 id of the activity definition
	 * @return activityType the BpmModel.ActivityType as uint8
	 * @return taskType the BpmModel.TaskType as uint8
	 * @return taskBehavior the BpmModel.TaskBehavior as uint8
	 * @return assignee the ID of the activity's assignee (for interactive activities)
	 * @return multiInstance whether the activity is a multi-instance
	 * @return application the activity's application
	 * @return subProcessModelId the ID of a process model (for subprocess activities)
	 * @return subProcessDefinitionId the ID of a process definition (for subprocess activities)
	 */
	function getActivityData(bytes32 _id) external view returns (uint8 activityType, uint8 taskType, uint8 taskBehavior, bytes32 assignee, bool multiInstance, bytes32 application, bytes32 subProcessModelId, bytes32 subProcessDefinitionId);

	/**
	 * @dev Returns connectivity details about the specified activity.
	 * @param _id the ID of an activity
	 * @return predecessor - the ID of its predecessor model element
	 * @return successor - the ID of its successor model element
	 * @return boundaryEventIds - the IDs of its boundary events, if any
	 */
	function getActivityGraphDetails(bytes32 _id) external view returns (bytes32 predecessor, bytes32 successor, bytes32[] boundaryEventIds);

	/**
	 * @dev Returns connectivity details about the specified gateway.
	 * @param _id the ID of a gateway
	 * @return inputs - the IDs of model elements that are inputs to this gateway
	 * @return outputs - the IDs of model elements that are outputs of this gateway
	 * @return gatewayType - the BpmModel.GatewayType
	 * @return defaultOutput - the default output connection (applies only to XOR|OR type gateways)
	 */
	function getGatewayGraphDetails(bytes32 _id) external view returns (bytes32[] memory inputs, bytes32[] memory outputs, BpmModel.GatewayType gatewayType, bytes32 defaultOutput);

	function getBoundaryEventGraphDetails(bytes32 _id) external view returns (bytes32 id, BpmModel.EventType eventType, BpmModel.BoundaryEventBehavior eventBehavior, bytes32 successor);

	/**
	 * @dev indicates whether this ProcessDefinition implements the specified interface
	 * @param _model the model defining the interface
	 * @param _interfaceId the ID of the interface
	 * @return true if the interface is supported, false otherwise
	 */
	function implementsProcessInterface(address _model, bytes32 _interfaceId) external view returns (bool);

	/**
	 * @dev Returns the number of implemented process interfaces implemented by this ProcessDefinition
	 * @return the number of process interfaces
	 */
	function getNumberOfImplementedProcessInterfaces() external view returns (uint size);

	/**
	 * @dev Returns information about the process interface at the given index
	 * @param _idx the index position
	 * @return modelAddress the interface's model
	 * @return interfaceId the interface ID
	 */
	function getImplementedProcessInterfaceAtIndex(uint _idx) external view returns (address modelAddress, bytes32 interfaceId);

	/**
	 * @dev Returns the ID of the start activity of this process definition. If the process is valid, this value must be set.
	 * @return the ID of the identified start activity
	 */
	function getStartActivity() external view returns (bytes32);

	/**
	 * @dev Returns the ProcessModel which contains this process definition
	 * @return the ProcessModel reference
	 */
	function getModel() external view returns (ProcessModel);

	/**
	 * @dev Returns the ID of the model which contains this process definition
	 * @return the model ID
	 */
	function getModelId() external view returns (bytes32);

	/**
	 * @dev Returns whether the given ID belongs to a model element (gateway or activity) known in this ProcessDefinition.
	 * @param _id the ID of a model element
	 * @return true if it exists, false otherwise
	 */
	function modelElementExists(bytes32 _id) external view returns (bool);

	/**
	 * @dev Returns the ModelElementType for the element with the specified ID.
	 * @param _id the ID of a model element
	 * @return the BpmModel.ModelElementType
	 */
	function getElementType(bytes32 _id) external view returns (BpmModel.ModelElementType);

	/**
	 * @dev Validates the coherence of the process definition in terms of the diagram and its configuration and sets the valid flag.
	 * @return valid - boolean indicating validity
	 * @return errorMessage - empty string if valid, otherwise contains a hint what failed
	 */
	function validate() external returns (bool result, bytes32 errorMessage);

	/**
	 * @dev Returns the current validity state
	 * @return true if valid, false otherwise
	 */
	function isValid() external view returns (bool);

}