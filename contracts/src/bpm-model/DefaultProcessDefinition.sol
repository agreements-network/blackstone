pragma solidity ^0.5.12;

import "commons-base/ErrorsLib.sol";
import "commons-base/BaseErrors.sol";
import "commons-base/Owned.sol";
import "commons-utils/ArrayUtilsLib.sol";
import "commons-utils/TypeUtilsLib.sol";
import "commons-management/AbstractVersionedArtifact.sol";
import "commons-management/AbstractDelegateTarget.sol";

import "bpm-model/BpmModel.sol";
import "bpm-model/BpmModelLib.sol";
import "bpm-model/ProcessDefinition.sol";
import "bpm-model/ProcessModel.sol";

/**
 * @title DefaultProcessDefinition
 * @dev Default implementation of the ProcessDefinition interface
 */
contract DefaultProcessDefinition is AbstractVersionedArtifact(1,0,0), AbstractDelegateTarget, Owned, ProcessDefinition {

	using ArrayUtilsLib for bytes32[];
	using TypeUtilsLib for bytes32;
	using BpmModelLib for BpmModel.TransitionCondition;

	BpmModel.ModelElementMap graphElements;
	BpmModel.ProcessInterfaceMap processInterfaces;
	mapping(bytes32 => BpmModel.TransitionCondition) transitionConditions;

	bytes32 id;
	ProcessModel model;
	bytes32 startActivity;
	bool valid;

	// TODO need to express locking which prohibits any further changes. Initiated by the model which carries the lock. Can only lock if the model is valid and all process defs. 

	// marks the process definition as dirty prior to executing changes
	modifier pre_invalidate() {
		if (valid) {
			valid = false;
		}
		_;
	}

	/**
	 * @dev Ensures the gateway and target element exist and are connected.
	 * The target element can either be an activity or another gateway
	 */
	modifier pre_gatewayOutTransitionExists(bytes32 _gatewayId, bytes32 _targetElementId) {
		ErrorsLib.revertIf(!graphElements.rows[_gatewayId].exists,
			ErrorsLib.RESOURCE_NOT_FOUND(),"ProcessDefinition.pre_gatewayOutTransitionExists","The gateway does not exist");
		ErrorsLib.revertIf(!graphElements.rows[_targetElementId].exists,
			ErrorsLib.RESOURCE_NOT_FOUND(),"ProcessDefinition.pre_gatewayOutTransitionExists","The target element (activity|gateway) does not exist");
		// check the connection, i.e. the references depending on target type
		ErrorsLib.revertIf(!(graphElements.rows[_gatewayId].gateway.outputs.contains(_targetElementId) &&
							(graphElements.rows[_targetElementId].elementType == BpmModel.ModelElementType.ACTIVITY ?
								graphElements.rows[_targetElementId].activity.predecessor == _gatewayId : graphElements.rows[_targetElementId].gateway.inputs.contains(_gatewayId))),
			ErrorsLib.RESOURCE_NOT_FOUND(),"ProcessDefinition.pre_gatewayOutTransitionExists","No transition found between gateway and activity");
		_;
	}

	/**
	 * @dev ensures the target element is not the gateway's default transition
	 */
	modifier pre_targetNotDefaultTransition(bytes32 _gatewayId, bytes32 _targetElementId) {
		ErrorsLib.revertIf(graphElements.rows[_gatewayId].gateway.defaultOutput == _targetElementId,
			ErrorsLib.INVALID_PARAMETER_STATE(),"ProcessDefinition.pre_targetNotDefaultTransition","The target element is the gateway's default transition");
		_;
	}

	/**
	 * @dev Initializes this DefaultOrganization with the specified ID and belonging to the given model. This function replaces the
	 * contract constructor, so it can be used as the delegate target for an ObjectProxy.
	 * REVERTS if
	 * - the _model is an empty address or if the ID is empty
	 * @param _id the ProcessDefinition ID
	 * @param _model the address of a ProcessModel in which this ProcessDefinition is created
	 */
	function initialize(bytes32 _id, address _model)
		external
		pre_post_initialize
	{
		ErrorsLib.revertIf(_id == "",
			ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(),"ProcessDefinition.constructor","_id is NULL");
		ErrorsLib.revertIf(_model == address(0),
			ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(),"ProcessDefinition.constructor","_model is NULL");
		owner = msg.sender;
		id = _id;
		model = ProcessModel(_model);
		emit LogProcessDefinitionCreation(
			EVENT_ID_PROCESS_DEFINITIONS,
			address(this),
			_id,
			bytes32(""),
			model.getId(),
			_model
		);
	}

	/**
	 * @dev Returns the id of the process definition
	 * @return bytes32 id of the process definition
	 */
	function getId() public view returns (bytes32) {
		return id;
	}

	/**
	 * @dev Creates a new activity definition with the specified parameters.
	 * @param _id the activity ID
	 * @param _activityType the BpmModel.ActivityType [TASK|SUBPROCESS]
	 * @param _taskType the BpmModel.TaskType [NONE|USER|SERVICE|EVENT]
	 * @param _behavior the BpmModel.TaskBehavior [SEND|SENDRECEIVE|RECEIVE]
	 * @param _assignee the ID of the participant performing the activity (for USER tasks only)
	 * @param _multiInstance whether the activity represents multiple instances
	 * @param _application the application handling the execution of the activity
	 * @param _subProcessModelId references the model containing a subprocess definition (only for SUBPROCESS ActivityType)
	 * @param _subProcessDefinitionId references a subprocess definition (only for SUBPROCESS ActivityType)
	 * @return BaseErrors.RESOURCE_ALREADY_EXISTS() if an activity with the same ID already exists
	 * @return BaseErrors.INVALID_PARAM_VALUE() if an assignee is specified, but the BpmModel.TaskType is not USER
	 * @return BaseErrors.NULL_PARAM_NOT_ALLOWED() if BpmModel.TaskType is USER, but no assignee was specified
	 * @return BaseErrors.RESOURCE_NOT_FOUND() if an assignee is specified that does not exist in the model
	 * @return BaseErrors.NO_ERROR() upon successful creation.
	 */
	function createActivityDefinition(bytes32 _id, BpmModel.ActivityType _activityType, BpmModel.TaskType _taskType, BpmModel.TaskBehavior _behavior, bytes32 _assignee, bool _multiInstance, bytes32 _application, bytes32 _subProcessModelId, bytes32 _subProcessDefinitionId)
		external
		pre_invalidate
		returns (uint error)
	{
		if (graphElements.rows[_id].exists) {
			return BaseErrors.RESOURCE_ALREADY_EXISTS();
		}
        if (!_assignee.isEmpty()) {
			if (!model.hasParticipant(_assignee)) {
				return BaseErrors.RESOURCE_NOT_FOUND(); // participant must exist in model
			}
			if (_taskType != BpmModel.TaskType.USER) {
				return BaseErrors.INVALID_PARAM_VALUE(); // assignee can only be paired with TaskType.USER
			}
		}
		else if (_taskType == BpmModel.TaskType.USER) {
			return BaseErrors.NULL_PARAM_NOT_ALLOWED(); // TaskType.USER requires an assignee
		}

		graphElements.activityIds.push(_id);
		graphElements.rows[_id].elementType = BpmModel.ModelElementType.ACTIVITY;
		graphElements.rows[_id].activity.id = _id;
		graphElements.rows[_id].activity.activityType = _activityType;
		graphElements.rows[_id].activity.taskType = _taskType;
		graphElements.rows[_id].activity.behavior = _behavior;
		graphElements.rows[_id].activity.assignee = _assignee;
		graphElements.rows[_id].activity.multiInstance = _multiInstance;
		graphElements.rows[_id].activity.application = _application;
		graphElements.rows[_id].activity.subProcessModelId = _subProcessModelId;
		graphElements.rows[_id].activity.subProcessDefinitionId = _subProcessDefinitionId;
		graphElements.rows[_id].exists = true;
		emit LogActivityDefinitionCreation(
			EVENT_ID_ACTIVITY_DEFINITIONS,
			address(this),
			_id,
			uint8(_activityType),
			uint8(_taskType),
			uint8(_behavior),
			_assignee,
			_multiInstance,
			_application,
			_subProcessModelId,
			_subProcessDefinitionId
		);
		return BaseErrors.NO_ERROR();
	}

	/**
	 * @dev Creates a new BpmModel.Gateway model element with the specified ID and type
	 * REVERTS if:
	 * - the ID already exists as a model element
	 * @param _id the ID under which to register the element
	 * @param _type a BpmModel.GatewayType
	 */
	function createGateway(bytes32 _id, BpmModel.GatewayType _type)
		external
		pre_invalidate
	{
		ErrorsLib.revertIf(graphElements.rows[_id].exists,
			ErrorsLib.RESOURCE_ALREADY_EXISTS(), "ProcessDefinition.createGateway", "Graph element with _id already exists");
		graphElements.gatewayIds.push(_id);
		graphElements.rows[_id].elementType = BpmModel.ModelElementType.GATEWAY;
		graphElements.rows[_id].gateway.id = _id;
		graphElements.rows[_id].gateway.gatewayType = _type;
		graphElements.rows[_id].exists = true;
	}

	/**
	 * Creates a new intermediate event definition with the specified parameters and conditional (DataStorage-based) data
	 * or constant uint value. If a constant value is provided, the conditional data will be ignored! 
	 * REVERTS if:
	 * - the ID already exists as a model element
	 * @param _id the ID under which to register the element
	 * @param _eventType a BpmModel.EventType. Note that TIMER_TIMESTAMP and TIMER_DURATION event types enforce CATCHING behavior.
	 * @param _eventBehavior a BpmModel.IntermediateEventBehavior
	 * @param _dataPath a data path (key) to use for data lookup on a DataStorage.
	 * @param _dataStorageId an optional key to identify a DataStorage as basis for the data path other than the default one
	 * @param _dataStorage an optional address of a DataStorage as basis for the data path other than the default one
	 * @param _constantValue a fixed value for timer based events representing either a datetime or a duration in secs
	 */
	function createIntermediateEvent(bytes32 _id, BpmModel.EventType _eventType, BpmModel.IntermediateEventBehavior _eventBehavior, bytes32 _dataPath, bytes32 _dataStorageId, address _dataStorage, uint256 _constantValue)
		external
		pre_invalidate
	{
		ErrorsLib.revertIf(graphElements.rows[_id].exists,
			ErrorsLib.RESOURCE_ALREADY_EXISTS(), "ProcessDefinition.createIntermediateEvent", "Graph element with _id already exists");
		graphElements.intermediateEventIds.push(_id);
		graphElements.rows[_id].elementType = BpmModel.ModelElementType.INTERMEDIATE_EVENT;
		graphElements.rows[_id].intermediateEvent.id = _id;
		graphElements.rows[_id].intermediateEvent.eventType = _eventType;
		if (_eventType == BpmModel.EventType.TIMER_TIMESTAMP || _eventType == BpmModel.EventType.TIMER_DURATION)
			graphElements.rows[_id].intermediateEvent.eventBehavior = BpmModel.IntermediateEventBehavior.CATCHING;
		else
			graphElements.rows[_id].intermediateEvent.eventBehavior = _eventBehavior;
		if (_constantValue > 0) {
			graphElements.rows[_id].intermediateEvent.primitiveData.uintValue = _constantValue;
		}
		else {
			graphElements.rows[_id].intermediateEvent.conditionalData.dataPath = _dataPath;
			graphElements.rows[_id].intermediateEvent.conditionalData.dataStorageId = _dataStorageId;
			graphElements.rows[_id].intermediateEvent.conditionalData.dataStorage = _dataStorage;
		}
		graphElements.rows[_id].exists = true;
	}

	/**
	 * @dev Addes a boundary event to the specified activity using the provided ID, parameters, conditional (DataStorage-based)
	 * data or constant uint value. If a constant value is provided, the conditional data will be ignored! 
	 * REVERTS if:
	 * - the activity does not exist
	 * - the event ID already exists as a model element
	 * @param _activityId the activity for which the boundary event is added
	 * @param _id the ID under which to register the element
	 * @param _eventType a BpmModel.EventType. Note that TIMER_TIMESTAMP and TIMER_DURATION event types enforce CATCHING behavior.
	 * @param _eventBehavior a BpmModel.IntermediateEventBehavior
	 * @param _dataPath a data path (key) to use for data lookup on a DataStorage.
	 * @param _dataStorageId an optional key to identify a DataStorage as basis for the data path other than the default one
	 * @param _dataStorage an optional address of a DataStorage as basis for the data path other than the default one
	 * @param _constantValue a fixed value for timer based events representing either a datetime or a duration in secs
	 */
	function addBoundaryEvent(bytes32 _activityId, bytes32 _id, BpmModel.EventType _eventType, BpmModel.BoundaryEventBehavior _eventBehavior, bytes32 _dataPath, bytes32 _dataStorageId, address _dataStorage, uint256 _constantValue)
		external
		pre_invalidate
	{
		ErrorsLib.revertIf(!(graphElements.rows[_activityId].exists && graphElements.rows[_activityId].elementType == BpmModel.ModelElementType.ACTIVITY), 
			ErrorsLib.INVALID_PARAMETER_STATE(), "DefaultProcessDefinition.addBoundaryEvent", "Cannot create boundary event since given activityId is either non-existent or not of the correct type BpmModel.ModelElementType.ACTIVITY");
		ErrorsLib.revertIf(graphElements.rows[_id].exists,
			ErrorsLib.RESOURCE_ALREADY_EXISTS(),"ProcessDefinition.addBoundaryEvent","Graph element with _id already exists");
		// no need to check if the event already exists in the activity.boundaryEventIds, because the same ID would already be in the graphElements.rows and is covered by the prior check

		graphElements.boundaryEventIds.push(_id);
		graphElements.rows[_id].elementType = BpmModel.ModelElementType.BOUNDARY_EVENT;
		graphElements.rows[_id].boundaryEvent.id = _id;
		graphElements.rows[_id].boundaryEvent.eventType = _eventType;
		graphElements.rows[_id].boundaryEvent.eventBehavior = _eventBehavior;
		if (_constantValue > 0) {
			graphElements.rows[_id].boundaryEvent.primitiveData.uintValue = _constantValue;
		}
		else {
			graphElements.rows[_id].boundaryEvent.conditionalData.dataPath = _dataPath;
			graphElements.rows[_id].boundaryEvent.conditionalData.dataStorageId = _dataStorageId;
			graphElements.rows[_id].boundaryEvent.conditionalData.dataStorage = _dataStorage;
		}
		graphElements.rows[_activityId].activity.boundaryEventIds.push(_id);
		graphElements.rows[_id].exists = true;
	}

	/**
	 * @dev Adds an event action to a given boundary event.
	 * @param _id the boundary event ID
	 * @param _dataPath a data path (key) to use for data lookup on a DataStorage to find the escalation target
	 * @param _dataStorageId an optional key to identify a DataStorage as basis for the data path to find the escalation target
	 * @param _dataStorage an optional address of a DataStorage as basis for the data path to find the escalation target
	 * @param _fixedTarget a fixed address for the escalation target
	 * @param _actionFunction a function signature to be invoked on the escalation target
	 */
	function addBoundaryEventAction(bytes32 _id, bytes32 _dataPath, bytes32 _dataStorageId, address _dataStorage, address _fixedTarget, string _actionFunction)
		external
		pre_invalidate
	{
		ErrorsLib.revertIf(!(graphElements.rows[_id].exists && graphElements.rows[_id].elementType == BpmModel.ModelElementType.BOUNDARY_EVENT), 
			ErrorsLib.INVALID_PARAMETER_STATE(), "DefaultProcessDefinition.addBoundaryEventAction", "Cannot add boundary event action since the given ID is either non-existent or not of the correct type BpmModel.ModelElementType.BOUNDARY_EVENT");
		ErrorsLib.revertIf(_dataPath.isEmpty() && _fixedTarget == address(0), 
			ErrorsLib.INVALID_INPUT(), "DefaultProcessDefinition.addBoundaryEventAction", "Either a ConditionalData (via a _dataPath at a minimum) or a _fixedEscalationTartget must be provided");
		ErrorsLib.revertIf(bytes(_actionFunction).length == 0, 
			ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultProcessDefinition.addBoundaryEventAction", "Action function parameter must not be empty");
		BpmModel.BoundaryEventAction memory action;
		action.conditionalTarget.dataPath = _dataPath;
		action.conditionalTarget.dataStorageId = _dataStorageId;
		action.conditionalTarget.dataStorage = _dataStorage;
		action.fixedTarget = _fixedTarget;
		action.targetFunction = bytes4(keccak256(abi.encodePacked(_actionFunction)));
		graphElements.rows[_id].boundaryEvent.actions.push(action);
		
	}

	/**
	 * @dev Creates a transition between the specified source and target objects.
	 * REVERTS if:
	 * - no element with the source ID exists
	 * - no element with the target ID exists
	 * - one of source/target is an activity and an existing connection on that activity would be overwritten. This is a necessary restriction to avoid dangling references
	 * @param _source the start of the transition
	 * @param _target the end of the transition
	 * @return BaseErrors.NO_ERROR() upon successful creation.
	 */
	function createTransition(bytes32 _source, bytes32 _target) external pre_invalidate returns (uint) {
		ErrorsLib.revertIf(!graphElements.rows[_source].exists,
			ErrorsLib.RESOURCE_NOT_FOUND(), "ProcessDefinition.createTransition", "source graph element not found");
		ErrorsLib.revertIf(!graphElements.rows[_target].exists,
			ErrorsLib.RESOURCE_NOT_FOUND(), "ProcessDefinition.createTransition", "target graph element not found");

		// SOURCE
		if (graphElements.rows[_source].elementType == BpmModel.ModelElementType.ACTIVITY) {
			// not allowed to overwrite an existing transition since it can leave dangling references if it was connected to a gateway
			ErrorsLib.revertIf(graphElements.rows[_source].activity.successor != "",
				ErrorsLib.OVERWRITE_NOT_ALLOWED(),"ProcessDefinition.createTransition","Not allowed to overwrite an existing successor of an activity");
			graphElements.rows[_source].activity.successor = _target;
		}
		else if (graphElements.rows[_source].elementType == BpmModel.ModelElementType.INTERMEDIATE_EVENT) {
			// not allowed to overwrite an existing transition since it can leave dangling references if it was connected to a gateway
			ErrorsLib.revertIf(graphElements.rows[_source].intermediateEvent.successor != "",
				ErrorsLib.OVERWRITE_NOT_ALLOWED(),"ProcessDefinition.createTransition","Not allowed to overwrite an existing successor of an intermediate event");
			graphElements.rows[_source].intermediateEvent.successor = _target;
		}
		else if (graphElements.rows[_source].elementType == BpmModel.ModelElementType.BOUNDARY_EVENT) {
			// not allowed to overwrite an existing transition since it can leave dangling references if it was connected to a gateway
			ErrorsLib.revertIf(graphElements.rows[_source].boundaryEvent.successor != "",
				ErrorsLib.OVERWRITE_NOT_ALLOWED(),"ProcessDefinition.createTransition","Not allowed to overwrite an existing successor of a boundary event");
			graphElements.rows[_source].boundaryEvent.successor = _target;
		}
		else if (graphElements.rows[_source].elementType == BpmModel.ModelElementType.GATEWAY) {
			if (!graphElements.rows[_source].gateway.outputs.contains(_target)) { // avoid duplicates
				graphElements.rows[_source].gateway.outputs.push(_target);
			}
		}
		else {
			revert(ErrorsLib.format(ErrorsLib.INVALID_INPUT(),
				"ProcessDefinition.createTransition", "Unknown/Unsupported BpmModel.ModelElementType for source element"));
		}

		// TARGET
		if (graphElements.rows[_target].elementType == BpmModel.ModelElementType.ACTIVITY) {
			// not allowed to overwrite an existing transition since it can leave dangling references if it was connected to a gateway
			ErrorsLib.revertIf(graphElements.rows[_target].activity.predecessor != "",
				ErrorsLib.OVERWRITE_NOT_ALLOWED(),"ProcessDefinition.createTransition","Not allowed to overwrite an existing predecessor of an activity");
			graphElements.rows[_target].activity.predecessor = _source;
		}
		else if (graphElements.rows[_target].elementType == BpmModel.ModelElementType.INTERMEDIATE_EVENT) {
			// not allowed to overwrite an existing transition since it can leave dangling references if it was connected to a gateway
			ErrorsLib.revertIf(graphElements.rows[_target].intermediateEvent.predecessor != "",
				ErrorsLib.OVERWRITE_NOT_ALLOWED(),"ProcessDefinition.createTransition","Not allowed to overwrite an existing predecessor of an intermediate event");
			graphElements.rows[_target].intermediateEvent.predecessor = _source;
		}
		else if (graphElements.rows[_target].elementType == BpmModel.ModelElementType.GATEWAY) {
			if (!graphElements.rows[_target].gateway.inputs.contains(_source)) { // avoid duplicates
				graphElements.rows[_target].gateway.inputs.push(_source);
			}
		}
		else {
			revert(ErrorsLib.format(ErrorsLib.INVALID_INPUT(),
				"ProcessDefinition.createTransition", "Unknown/Unsupported BpmModel.ModelElementType for target element"));
		}

		return BaseErrors.NO_ERROR();
	}

	/**
	 * @dev Sets the specified activity to be the default output (default transition) of the specified gateway.
	 * REVERTS if:
	 * - the specified transition between the gateway and target element does not exist
	 * @param _gatewayId the ID of a gateway in this ProcessDefinition
	 * @param _targetElementId the ID of a graph element (activity or gateway) in this ProcessDefinition
	 */
	function setDefaultTransition(bytes32 _gatewayId, bytes32 _targetElementId)
		external
		pre_gatewayOutTransitionExists(_gatewayId, _targetElementId)
		pre_invalidate
	{
		// delete any pre-existing condition for this pair
		delete transitionConditions[keccak256(abi.encodePacked(_gatewayId, _targetElementId))];
		graphElements.rows[_gatewayId].gateway.defaultOutput = _targetElementId;
	}

	/**
	 * @dev Create a data mapping for the specified activity and direction.
	 * @param _activityId the ID of the activity in this ProcessDefinition
	 * @param _direction the BpmModel.Direction [IN|OUT]
	 * @param _accessPath the access path offered by the application. If the application does not have any access paths, this field is used as an ID for the mapping.
	 * @param _dataPath a data path (key) to use for data lookup on a DataStorage.
	 * @param _dataStorageId an optional key to identify a DataStorage as basis for the data path other than the default one
	 * @param _dataStorage an optional address of a DataStorage as basis for the data path other than the default one
	 */
	function createDataMapping(bytes32 _activityId, BpmModel.Direction _direction, bytes32 _accessPath, bytes32 _dataPath, bytes32 _dataStorageId, address _dataStorage) external pre_invalidate {
		ErrorsLib.revertIf(!(graphElements.rows[_activityId].exists && graphElements.rows[_activityId].elementType == BpmModel.ModelElementType.ACTIVITY), 
			ErrorsLib.RESOURCE_NOT_FOUND(), "DefaultProcessDefinition.createDataMapping", "Cannot create data mapping since given activityId is either non-existent or not of the correct type BpmModel.ModelElementType.ACTIVITY");
		if (_direction == BpmModel.Direction.IN) {
			if (!graphElements.rows[_activityId].activity.inMappings[_accessPath].exists) {
				graphElements.rows[_activityId].activity.inMappingKeys.push(_accessPath);
			}
			graphElements.rows[_activityId].activity.inMappings[_accessPath] = DataStorageUtils.ConditionalData({dataPath: _dataPath, dataStorageId: _dataStorageId, dataStorage: _dataStorage, exists: true});
		}
		else if (_direction == BpmModel.Direction.OUT) {
			if (!graphElements.rows[_activityId].activity.outMappings[_accessPath].exists) {
				graphElements.rows[_activityId].activity.outMappingKeys.push(_accessPath);
			}
			graphElements.rows[_activityId].activity.outMappings[_accessPath] = DataStorageUtils.ConditionalData({dataPath: _dataPath, dataStorageId: _dataStorageId, dataStorage: _dataStorage, exists: true});
		}
		emit LogDataMappingCreation(EVENT_ID_DATA_MAPPINGS, address(this), _activityId, _accessPath, _dataPath, _dataStorageId, _dataStorage, uint(_direction));
	}

	/**
	 * @dev Adds the specified process interface to the list of supported process interfaces of this ProcessDefinition
	 * The model address is allowed to be empty in which case this process definition's model will be used.
	 * @param _model the model defining the interface
	 * @param _interfaceId the ID of the interface
	 * @return BaseErrors.RESOURCE_NOT_FOUND() if the specified interface cannot be located in the model
	 * @return BaseErrors.NO_ERROR() upon successful creation.
	 */
	function addProcessInterfaceImplementation(address _model, bytes32 _interfaceId)
		external
		pre_invalidate
		returns (uint error)
	{
		error = BaseErrors.NO_ERROR();
		address pm = _model == address(0) ? address(model) : _model;
		bytes32 key = keccak256(abi.encodePacked(pm, _interfaceId));
		if (processInterfaces.rows[key].exists)
			return (error); // ignore if the interface was added already
		if (ProcessModel(pm).hasProcessInterface(_interfaceId) == false) return BaseErrors.RESOURCE_NOT_FOUND();
		processInterfaces.rows[key].keyIdx = processInterfaces.keys.push(key);
		processInterfaces.rows[key].value = BpmModel.ProcessInterface({model: pm, interfaceId: _interfaceId});
		processInterfaces.rows[key].exists = true;
		emit LogProcessDefinitionInterfaceIdUpdate(
			EVENT_ID_PROCESS_DEFINITIONS,
			address(this),
			_interfaceId
		);
	}

	/**
	 * @dev Creates a transition condition between the specified gateway and activity using the given parameters.
	 * The parameters dataPath, dataStorageId, and dataStorage are used to construct a left-hand side DataStorageUtils.ConditionalData object.
	 * REVERT: if the specified transition between the gateway and activity does not exist
	 * REVERT: if the specified activity is set as the default output of the gateway
	 * @param _gatewayId the ID of a gateway in this ProcessDefinition
	 * @param _targetElementId the ID of a graph element (activity or gateway) in this ProcessDefinition
	 * @param _dataPath the left-hand side dataPath condition
	 * @param _dataStorageId the left-hand side dataStorageId condition
	 * @param _dataStorage the left-hand side dataStorage condition
	 * @param _operator the uint8 representation of a DataStorageUtils.COMPARISON_OPERATOR
	 * @param _value the right-hand side primitive comparison value
	 */
	function createTransitionConditionForString(bytes32 _gatewayId, bytes32 _targetElementId, bytes32 _dataPath, bytes32 _dataStorageId, address _dataStorage, uint8 _operator, string calldata _value)
		external
		pre_gatewayOutTransitionExists(_gatewayId, _targetElementId)
		pre_targetNotDefaultTransition(_gatewayId, _targetElementId)
		pre_invalidate
	{
		bytes32 key = keccak256(abi.encodePacked(_gatewayId, _targetElementId));
		transitionConditions[key] = BpmModel.createLeftHandTransitionCondition(_dataPath, _dataStorageId, _dataStorage, _operator);
		transitionConditions[key].rhPrimitive.stringValue = _value;
		transitionConditions[key].rhPrimitive.exists = true;
	}

	/**
	 * @dev Creates a transition condition between the specified gateway and activity using the given parameters.
	 * The parameters dataPath, dataStorageId, and dataStorage are used to construct a left-hand side DataStorageUtils.ConditionalData object.
	 * REVERT: if the specified transition between the gateway and activity does not exist
	 * REVERT: if the specified activity is set as the default output of the gateway
	 * @param _gatewayId the ID of a gateway in this ProcessDefinition
	 * @param _targetElementId the ID of a graph element (activity or gateway) in this ProcessDefinition
	 * @param _dataPath the left-hand side dataPath condition
	 * @param _dataStorageId the left-hand side dataStorageId condition
	 * @param _dataStorage the left-hand side dataStorage condition
	 * @param _operator the uint8 representation of a DataStorageUtils.COMPARISON_OPERATOR
	 * @param _value the right-hand side primitive comparison value
	 */
	function createTransitionConditionForBytes32(bytes32 _gatewayId, bytes32 _targetElementId, bytes32 _dataPath, bytes32 _dataStorageId, address _dataStorage, uint8 _operator, bytes32 _value)
		external
		pre_gatewayOutTransitionExists(_gatewayId, _targetElementId)
		pre_targetNotDefaultTransition(_gatewayId, _targetElementId)
		pre_invalidate
	{
		bytes32 key = keccak256(abi.encodePacked(_gatewayId, _targetElementId));
		transitionConditions[key] = BpmModel.createLeftHandTransitionCondition(_dataPath, _dataStorageId, _dataStorage, _operator);
		transitionConditions[key].rhPrimitive.bytes32Value = _value;
		transitionConditions[key].rhPrimitive.exists = true;
	}

	/**
	 * @dev Creates a transition condition between the specified gateway and activity using the given parameters.
	 * The parameters dataPath, dataStorageId, and dataStorage are used to construct a left-hand side DataStorageUtils.ConditionalData object.
	 * REVERT: if the specified transition between the gateway and activity does not exist
	 * REVERT: if the specified activity is set as the default output of the gateway
	 * @param _gatewayId the ID of a gateway in this ProcessDefinition
	 * @param _targetElementId the ID of a graph element (activity or gateway) in this ProcessDefinition
	 * @param _dataPath the left-hand side dataPath condition
	 * @param _dataStorageId the left-hand side dataStorageId condition
	 * @param _dataStorage the left-hand side dataStorage condition
	 * @param _operator the uint8 representation of a DataStorageUtils.COMPARISON_OPERATOR
	 * @param _value the right-hand side primitive comparison value
	 */
	function createTransitionConditionForAddress(bytes32 _gatewayId, bytes32 _targetElementId, bytes32 _dataPath, bytes32 _dataStorageId, address _dataStorage, uint8 _operator, address _value)
		external
		pre_gatewayOutTransitionExists(_gatewayId, _targetElementId)
		pre_targetNotDefaultTransition(_gatewayId, _targetElementId)
		pre_invalidate
	{
		bytes32 key = keccak256(abi.encodePacked(_gatewayId, _targetElementId));
		transitionConditions[key] = BpmModel.createLeftHandTransitionCondition(_dataPath, _dataStorageId, _dataStorage, _operator);
		transitionConditions[key].rhPrimitive.addressValue = _value;
		transitionConditions[key].rhPrimitive.exists = true;
	}

	/**
	 * @dev Creates a transition condition between the specified gateway and activity using the given parameters.
	 * The parameters dataPath, dataStorageId, and dataStorage are used to construct a left-hand side DataStorageUtils.ConditionalData object.
	 * REVERT: if the specified transition between the gateway and activity does not exist
	 * REVERT: if the specified activity is set as the default output of the gateway
	 * @param _gatewayId the ID of a gateway in this ProcessDefinition
	 * @param _targetElementId the ID of a graph element (activity or gateway) in this ProcessDefinition
	 * @param _dataPath the left-hand side dataPath condition
	 * @param _dataStorageId the left-hand side dataStorageId condition
	 * @param _dataStorage the left-hand side dataStorage condition
	 * @param _operator the uint8 representation of a DataStorageUtils.COMPARISON_OPERATOR
	 * @param _value the right-hand side primitive comparison value
	 */
	function createTransitionConditionForBool(bytes32 _gatewayId, bytes32 _targetElementId, bytes32 _dataPath, bytes32 _dataStorageId, address _dataStorage, uint8 _operator, bool _value)
		external
		pre_gatewayOutTransitionExists(_gatewayId, _targetElementId)
		pre_targetNotDefaultTransition(_gatewayId, _targetElementId)
		pre_invalidate
	{
		bytes32 key = keccak256(abi.encodePacked(_gatewayId, _targetElementId));
		transitionConditions[key] = BpmModel.createLeftHandTransitionCondition(_dataPath, _dataStorageId, _dataStorage, _operator);
		transitionConditions[key].rhPrimitive.boolValue = _value;
		transitionConditions[key].rhPrimitive.exists = true;
	}

	/**
	 * @dev Creates a transition condition between the specified gateway and activity using the given parameters.
	 * The parameters dataPath, dataStorageId, and dataStorage are used to construct a left-hand side DataStorageUtils.ConditionalData object.
	 * REVERT: if the specified transition between the gateway and activity does not exist
	 * REVERT: if the specified activity is set as the default output of the gateway
	 * @param _gatewayId the ID of a gateway in this ProcessDefinition
	 * @param _targetElementId the ID of a graph element (activity or gateway) in this ProcessDefinition
	 * @param _dataPath the left-hand side dataPath condition
	 * @param _dataStorageId the left-hand side dataStorageId condition
	 * @param _dataStorage the left-hand side dataStorage condition
	 * @param _operator the uint8 representation of a DataStorageUtils.COMPARISON_OPERATOR
	 * @param _value the right-hand side primitive comparison value
	 */
	function createTransitionConditionForUint(bytes32 _gatewayId, bytes32 _targetElementId, bytes32 _dataPath, bytes32 _dataStorageId, address _dataStorage, uint8 _operator, uint _value)
		external
		pre_gatewayOutTransitionExists(_gatewayId, _targetElementId)
		pre_targetNotDefaultTransition(_gatewayId, _targetElementId)
		pre_invalidate
	{
		bytes32 key = keccak256(abi.encodePacked(_gatewayId, _targetElementId));
		transitionConditions[key] = BpmModel.createLeftHandTransitionCondition(_dataPath, _dataStorageId, _dataStorage, _operator);
		transitionConditions[key].rhPrimitive.uintValue = _value;
		transitionConditions[key].rhPrimitive.exists = true;
	}

	/**
	 * @dev Creates a transition condition between the specified gateway and activity using the given parameters.
	 * The parameters dataPath, dataStorageId, and dataStorage are used to construct a left-hand side DataStorageUtils.ConditionalData object.
	 * REVERT: if the specified transition between the gateway and activity does not exist
	 * REVERT: if the specified activity is set as the default output of the gateway
	 * @param _gatewayId the ID of a gateway in this ProcessDefinition
	 * @param _targetElementId the ID of a graph element (activity or gateway) in this ProcessDefinition
	 * @param _dataPath the left-hand side dataPath condition
	 * @param _dataStorageId the left-hand side dataStorageId condition
	 * @param _dataStorage the left-hand side dataStorage condition
	 * @param _operator the uint8 representation of a DataStorageUtils.COMPARISON_OPERATOR
	 * @param _value the right-hand side primitive comparison value
	 */
	function createTransitionConditionForInt(bytes32 _gatewayId, bytes32 _targetElementId, bytes32 _dataPath, bytes32 _dataStorageId, address _dataStorage, uint8 _operator, int _value)
		external
		pre_gatewayOutTransitionExists(_gatewayId, _targetElementId)
		pre_targetNotDefaultTransition(_gatewayId, _targetElementId)
		pre_invalidate
	{
		bytes32 key = keccak256(abi.encodePacked(_gatewayId, _targetElementId));
		transitionConditions[key] = BpmModel.createLeftHandTransitionCondition(_dataPath, _dataStorageId, _dataStorage, _operator);
		transitionConditions[key].rhPrimitive.intValue = _value;
		transitionConditions[key].rhPrimitive.exists = true;
	}

	/**
	 * @dev Creates a transition condition between the specified gateway and activity using the given parameters.
	 * The "lh..." parameters are used to construct a left-hand side DataStorageUtils.ConditionalData object while the "rh..." ones are used
	 * for a right-hand side DataStorageUtils.ConditionalData as comparison
	 * REVERT: if the specified transition between the gateway and activity does not exist
	 * REVERT: if the specified activity is set as the default output of the gateway
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
	function createTransitionConditionForDataStorage(bytes32 _gatewayId, bytes32 _targetElementId, bytes32 _lhDataPath, bytes32 _lhDataStorageId, address _lhDataStorage, uint8 _operator, bytes32 _rhDataPath, bytes32 _rhDataStorageId, address _rhDataStorage)
		external
		pre_gatewayOutTransitionExists(_gatewayId, _targetElementId)
		pre_targetNotDefaultTransition(_gatewayId, _targetElementId)
		pre_invalidate
	{
		bytes32 key = keccak256(abi.encodePacked(_gatewayId, _targetElementId));
		transitionConditions[key] = BpmModel.createLeftHandTransitionCondition(_lhDataPath, _lhDataStorageId, _lhDataStorage, _operator);
		transitionConditions[key].rhData.dataPath = _rhDataPath;
		transitionConditions[key].rhData.dataStorageId = _rhDataStorageId;
		transitionConditions[key].rhData.dataStorage = _rhDataStorage;
		transitionConditions[key].rhData.exists = true;
	}

	/**
	 * @dev Resolves a transition condition between the given source and target model elements using the provided DataStorage to lookup data.
	 * If no condition exists for the specified transition, the function will always return 'true' as default.
	 * @param _sourceId the ID of a model element in this ProcessDefinition, e.g. a gateway
	 * @param _targetId the ID of a model element in this ProcessDefinition, e.g. an activity
	 * @param _dataStorage the address of a DataStorage.
	 * @return true if the condition evaluated to 'true' or if no condition exists, false otherwise
	 */
	function resolveTransitionCondition(bytes32 _sourceId, bytes32 _targetId, address _dataStorage)
		external view
		returns (bool)
	{
		bytes32 key = keccak256(abi.encodePacked(_sourceId, _targetId));
		if (transitionConditions[key].lhData.exists) // currently using the existence of the left-hand data to assume that the condition was set up properly
			return transitionConditions[key].resolve(_dataStorage);
		return true; // a transition without a condition is 'true' by default
	}

	/**
	 * @dev Returns the IDs of all activities connected to the given model participant. This function
	 * can be used to retrieve all user tasks belonging to the same "swimlane" in the model.
	 * @param _participantId the ID of a participant in the model
	 * @return an array of activity IDs
	 */
	function getActivitiesForParticipant(bytes32 _participantId) external view returns (bytes32[] memory) {
		if (_participantId != "") {
			uint i;
			uint resultSize = 0;
			// due to limitations in Solidity, we have to create a fixed size memory array that is larger than the intended result
			bytes32[] memory tempResult = new bytes32[](graphElements.activityIds.length);
			for (i=0; i<graphElements.activityIds.length; i++) {
				if (graphElements.rows[graphElements.activityIds[i]].activity.assignee == _participantId) {
					tempResult[resultSize++] = graphElements.activityIds[i];
				}
			}
			// once we know how many results there are, we can create a correctly sized return array
			bytes32[] memory prunedResult = new bytes32[](resultSize);
			for (i=0; i<resultSize; i++) {
				prunedResult[i] = tempResult[i];
			}
			return prunedResult;
		}
	}

	/**
	 * @dev Returns the number of IN data mappings for the specified activity.
	 * @param _activityId the ID of the activity in this ProcessDefinition
	 * @return the number of IN data mappings
	 */
	function getNumberOfInDataMappings(bytes32 _activityId) external view returns (uint size) {
		size = graphElements.rows[_activityId].activity.inMappingKeys.length;
	}

	/**
	 * @dev Returns the number of OUT data mappings for the specified activity.
	 * @param _activityId the ID of the activity in this ProcessDefinition
	 * @return the number of OUT data mappings
	 */
	function getNumberOfOutDataMappings(bytes32 _activityId) external view returns (uint size) {
		size = graphElements.rows[_activityId].activity.outMappingKeys.length;
	}

	/**
	 * @dev Returns the ID of the IN data mapping of the specified activity at the specified index.
	 * @param _activityId the ID of the activity in this ProcessDefinition
	 * @param _idx the index position
	 * @return the mapping ID, if it exists
	 */
	function getInDataMappingIdAtIndex(bytes32 _activityId, uint _idx) external view returns (bytes32) {
		return graphElements.rows[_activityId].activity.inMappingKeys[_idx];
	}

	/**
	 * @dev Returns the ID of the OUT data mapping of the specified activity at the specified index.
	 * @param _activityId the ID of the activity in this ProcessDefinition
	 * @param _idx the index position
	 * @return the mapping ID, if it exists
	 */
	function getOutDataMappingIdAtIndex(bytes32 _activityId, uint _idx) external view returns (bytes32) {
		graphElements.rows[_activityId].activity.outMappingKeys[_idx];
	}

	/**
	 * @dev Returns an array of the IN data mapping ids of the specified activity.
	 * @param _activityId the ID of the activity in this ProcessDefinition
	 * @return the data mapping ids
	 */
	function getInDataMappingKeys(bytes32 _activityId) external view returns (bytes32[] memory) {
		return graphElements.rows[_activityId].activity.inMappingKeys;
	}

	/**
	 * @dev Returns an array of the OUT data mapping ids of the specified activity.
	 * @param _activityId the ID of the activity in this ProcessDefinition
	 * @return the data mapping ids
	 */
	function getOutDataMappingKeys(bytes32 _activityId) external view returns (bytes32[] memory) {
		return graphElements.rows[_activityId].activity.outMappingKeys;
	}

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
	function getInDataMappingDetails(bytes32 _activityId, bytes32 _id) external view returns (bytes32 dataMappingId, bytes32 accessPath, bytes32 dataPath, bytes32 dataStorageId, address dataStorage) {
		if (graphElements.rows[_activityId].exists) {
			dataMappingId = _id;
			accessPath = _id; // TODO at the moment the accessPath doubles as the ID
			dataPath = graphElements.rows[_activityId].activity.inMappings[_id].dataPath;
			dataStorageId = graphElements.rows[_activityId].activity.inMappings[_id].dataStorageId;
			dataStorage = graphElements.rows[_activityId].activity.inMappings[_id].dataStorage;
		}
	}

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
	function getOutDataMappingDetails(bytes32 _activityId, bytes32 _id) external view returns (bytes32 dataMappingId, bytes32 accessPath, bytes32 dataPath, bytes32 dataStorageId, address dataStorage) {
		if (graphElements.rows[_activityId].exists) {
			dataMappingId = _id;
			accessPath = _id; // TODO at the moment the accessPath doubles as the ID
			dataPath = graphElements.rows[_activityId].activity.outMappings[_id].dataPath;
			dataStorageId = graphElements.rows[_activityId].activity.outMappings[_id].dataStorageId;
			dataStorage = graphElements.rows[_activityId].activity.outMappings[_id].dataStorage;
		}
	}

	/**
	 * @dev Returns the number of activity definitions in this ProcessDefinition.
	 * @return the number of activity definitions
	 */
	function getNumberOfActivities() external view returns (uint) {
		return graphElements.activityIds.length;
	}

	/**
	 * @dev Returns the ID of the ActivityDefinition at the specified index position of the given Process Definition
	 * @param _index the index position
	 * @return bytes32 the ActivityDefinition ID, if it exists
	 */
	function getActivityAtIndex(uint _index) external view returns (bytes32) {
		return graphElements.activityIds[_index];
	}

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
	function getActivityData(bytes32 _id) external view returns (uint8 activityType, uint8 taskType, uint8 taskBehavior, bytes32 assignee, bool multiInstance, bytes32 application, bytes32 subProcessModelId, bytes32 subProcessDefinitionId) {
		if (graphElements.rows[_id].exists) {
			activityType = uint8(graphElements.rows[_id].activity.activityType);
			taskType = uint8(graphElements.rows[_id].activity.taskType);
			taskBehavior = uint8(graphElements.rows[_id].activity.behavior);
			assignee = graphElements.rows[_id].activity.assignee;
			multiInstance = graphElements.rows[_id].activity.multiInstance;
			application = graphElements.rows[_id].activity.application;
			subProcessModelId = graphElements.rows[_id].activity.subProcessModelId;
			subProcessDefinitionId = graphElements.rows[_id].activity.subProcessDefinitionId;
		}
	}

	/**
	 * @dev Returns connectivity details about the specified activity.
	 * @param _id the ID of an activity
	 * @return predecessor - the ID of its predecessor model element
	 * @return successor - the ID of its successor model element
	 * @return boundaryEventIds - the IDs of its boundary events, if any
	 */
	function getActivityGraphDetails(bytes32 _id) external view returns (bytes32 predecessor, bytes32 successor, bytes32[] boundaryEventIds) {
		predecessor = graphElements.rows[_id].activity.predecessor;
		successor = graphElements.rows[_id].activity.successor;
		boundaryEventIds = graphElements.rows[_id].activity.boundaryEventIds;
	}

	/**
	 * @dev Returns connectivity details about the specified gateway.
	 * @param _id the ID of a gateway
	 * @return inputs - the IDs of model elements that are inputs to this gateway
	 * @return outputs - the IDs of model elements that are outputs of this gateway
	 * @return gatewayType - the BpmModel.GatewayType
	 * @return defaultOutput - the default output connection (applies only to XOR|OR type gateways)
	 */
	function getGatewayGraphDetails(bytes32 _id) external view returns (bytes32[] memory inputs, bytes32[] memory outputs, BpmModel.GatewayType gatewayType, bytes32 defaultOutput) {
		inputs = graphElements.rows[_id].gateway.inputs;
		outputs = graphElements.rows[_id].gateway.outputs;
		gatewayType = graphElements.rows[_id].gateway.gatewayType;
		defaultOutput = graphElements.rows[_id].gateway.defaultOutput;
	}

	/**
	 * @dev indicates whether this ProcessDefinition implements the specified interface
	 * @param _model the model defining the interface
	 * @param _interfaceId the ID of the interface
	 * @return true if the interface is supported, false otherwise
	 */
	function implementsProcessInterface(address _model, bytes32 _interfaceId) external view returns (bool) {
		return processInterfaces.rows[keccak256(abi.encodePacked(_model, _interfaceId))].exists;
	}

	/**
	 * @dev Returns the number of implemented process interfaces implemented by this ProcessDefinition
	 * @return the number of process interfaces
	 */
	function getNumberOfImplementedProcessInterfaces() external view returns (uint size) {
		return processInterfaces.keys.length;
	}

	/**
	 * @dev Returns information about the process interface at the given index
	 * @param _idx the index position
	 * @return modelAddress the interface's model
	 * @return interfaceId the interface ID
	 */
	function getImplementedProcessInterfaceAtIndex(uint _idx) external view returns (address modelAddress, bytes32 interfaceId) {
		BpmModel.ProcessInterface storage pi = processInterfaces.rows[processInterfaces.keys[_idx]].value;
		modelAddress = pi.model;
		interfaceId = pi.interfaceId;
	}

	/**
	 * @dev Returns the ID of the start activity of this process definition. This value is set during the validate() function, if the process is valid.
	 * @return the ID of the identified start activity
	 */
	function getStartActivity() external view returns (bytes32) {
		return startActivity;
	}

	/**
	 * @dev Returns the ProcessModel which contains this process definition
	 * @return the ProcessModel reference
	 */
	function getModel() external view returns (ProcessModel) {
		return model;
	}

	/**
	 * @dev Returns the ID of the model which contains this process definition
	 * @return the model ID
	 */
	function getModelId() external view returns (bytes32) {
		return model.getId();
	}

	/**
	 * @dev Returns whether the given ID belongs to a model element (gateway or activity) known in this ProcessDefinition.
	 * @param _id the ID of a model element
	 * @return true if it exists, false otherwise
	 */
	function modelElementExists(bytes32 _id) external view returns (bool) {
		return graphElements.rows[_id].exists;
	}

	/**
	 * @dev Returns the ModelElementType for the element with the specified ID.
	 * REVERTS if:
	 * - the element does not exist to avoid returning 0 as a valid type.
	 * @param _id the ID of a model element
	 * @return the BpmModel.ModelElementType
	 */
	function getElementType(bytes32 _id) external view returns (BpmModel.ModelElementType) {
		ErrorsLib.revertIf(!graphElements.rows[_id].exists,
			ErrorsLib.RESOURCE_NOT_FOUND(),"ProcessDefinition.getElementType","Graph element with given ID not found");
		return graphElements.rows[_id].elementType;
	}

	/**
	 * @dev Validates the coherence of the process definition in terms of the diagram and its configuration and sets the valid flag.
	 * Currently performed validation:
	 * 1. There must be exactly one start activity, i.e. one activity with no predecessor
	 * @return result - boolean indicating validity
	 * @return errorMessage - empty string if valid, otherwise contains a hint what failed
	 */
	 function validate() external returns (bool, bytes32) {
	 	valid = false;
	 	startActivity = ""; // reset start activity since a new one might be determined
	 	BpmModel.ActivityDefinition memory ad;
		uint i;
		// iterate over all activities to find start activity
	 	for (i=0; i<graphElements.activityIds.length; i++) {
	 		ad = graphElements.rows[graphElements.activityIds[i]].activity;
	 		if (ad.predecessor.isEmpty()) {
	 			if (!startActivity.isEmpty())
	 				return (false, "duplicate start activities");
	 			startActivity = ad.id;
	 		}
	 	}
	 	if (startActivity.isEmpty())
			return (false, "no start activity");

		BpmModel.IntermediateEvent memory ie;
	 	for (i=0; i<graphElements.intermediateEventIds.length; i++) {
	 		ie = graphElements.rows[graphElements.intermediateEventIds[i]].intermediateEvent;
	 		if (ie.predecessor.isEmpty()) {
	 			return (false, "interm. event w/out predecessor");
	 		}
	 		if (ie.successor.isEmpty()) {
	 			return (false, "interm. event w/out successor");
	 		}
	 	}

		BpmModel.Gateway memory gw;
	 	for (i=0; i<graphElements.gatewayIds.length; i++) {
	 		gw = graphElements.rows[graphElements.gatewayIds[i]].gateway;
	 		if (gw.inputs.length == 0) {
	 			return (false, "unreachable gateway");
	 		}
			else if (gw.outputs.length == 0) {
				return (false, "gateway without outputs");
			}
	 	}

		valid = true;
	 	return (true, "model valid");
	 }

	 /**
	  * @dev Returns the current validity state
	  * @return true if valid, false otherwise
	  */
	 function isValid() external view returns (bool) {
	 	return valid;
	 }

}