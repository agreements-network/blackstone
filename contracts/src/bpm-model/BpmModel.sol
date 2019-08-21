pragma solidity ^0.5.12;

import "commons-collections/DataStorageUtils.sol";

/**
 * @title BpmModel Library
 * @dev This library defines the data structures and internal functions for BPM modeling.
 */
library BpmModel {

    enum ModelElementType {ACTIVITY,GATEWAY,INTERMEDIATE_EVENT, BOUNDARY_EVENT}
    enum ActivityType {TASK,SUBPROCESS}
    // TaskTypes were reduced/modified from BPMN spec (USER,MANUAL,SERVICE,SCRIPT,RULE,SEND,RECEIVE) to fit better to EVM reality
    enum TaskType {NONE,USER,SERVICE,EVENT}
    enum GatewayType {XOR,OR,AND}
    enum IntermediateEventBehavior {CATCHING,THROWING}
    enum BoundaryEventBehavior {INTERRUPTING,NON_INTERRUPTING}
    enum EventType {TIMER_TIMESTAMP,TIMER_DURATION}
    enum TaskBehavior {SEND,SENDRECEIVE,RECEIVE}
    enum ApplicationType {EVENT,SERVICE,WEB}
    enum Direction {IN,OUT}
	
    /**
     * @dev wrapper struct around an activity, a gateway, or an intermediate event.
     * Facilitates traversing the model.
     */
    struct ModelElement {
        bytes32 id;
        ModelElementType elementType;
        ActivityDefinition activity;
        Gateway gateway;
        IntermediateEvent intermediateEvent;
        BoundaryEvent boundaryEvent;
        bool exists;
    }

    /**
     * @dev struct to collect the elements of the model graph, i.e. activities and gateways
     * This map is not intended to support removal of elements!
     */
    struct ModelElementMap {
        mapping(bytes32 => ModelElement) rows;
        bytes32[] activityIds;
        bytes32[] gatewayIds;
        bytes32[] intermediateEventIds;
        bytes32[] boundaryEventIds;
    }

    /**
     * @dev Struct to describe a participant of a ProcessModel.
     * The participant can be specified specifically via an address or via conditional data
     */
    struct Participant {
        bytes32 id;
        address account;
        DataStorageUtils.ConditionalData conditionalPerformer;
    }

    struct ParticipantElement {
        uint keyIdx;
        Participant value;
        bool exists;
    }

    struct ParticipantMap {
        mapping(bytes32 => ParticipantElement) rows;
        bytes32[] keys;
    }

    /**
     * @dev A struct to be used to hold a primitive value.
     */
    struct Primitive {
        uint8 dataType;
        address addressValue;
        bytes32 bytes32Value;
        uint uintValue;
        int intValue;
        string stringValue;
        bool boolValue;
        bool exists;
    }

    /**
     * @dev Struct to describe conditions to be evaluated when traversing a transition
     */
    struct TransitionCondition {
        DataStorageUtils.ConditionalData lhData;
        DataStorageUtils.COMPARISON_OPERATOR operator;
        DataStorageUtils.ConditionalData rhData;
        Primitive rhPrimitive;
    }

    /**
     * ACTIVITY DEFINITION
     */
    struct ActivityDefinition {
        bytes32 id;
        ActivityType activityType;
        TaskType taskType;
        TaskBehavior behavior;
        bytes32 assignee; // this field references the model participant
        bool multiInstance;
        bytes32 application;
        bytes32 subProcessModelId;
        bytes32 subProcessDefinitionId;
        bytes32 predecessor;
        bytes32 successor;
        bytes32[] inMappingKeys;
        bytes32[] outMappingKeys;
        mapping(bytes32 => DataStorageUtils.ConditionalData) inMappings;
        mapping(bytes32 => DataStorageUtils.ConditionalData) outMappings;
        bytes32[] boundaryEventIds;
    }

    /**
     * GATEWAY
     */
    struct Gateway {
        bytes32 id;
        GatewayType gatewayType;
        bytes32 defaultOutput; // only applies to XOR or OR gateways to specify which of the output transitions is to be used as default.
        bytes32[] inputs;
        bytes32[] outputs;
    }

    /**
     * INTERMEDIATE EVENT
     */
    struct IntermediateEvent {
        bytes32 id;
        EventType eventType;
        IntermediateEventBehavior eventBehavior;
        DataStorageUtils.ConditionalData conditionalData;
        Primitive primitiveData;
        bytes32 predecessor;
        bytes32 successor;
    }

    /**
     * BOUNDARY EVENT
     */
    struct BoundaryEvent {
        bytes32 id;
        EventType eventType;
        BoundaryEventBehavior eventBehavior;
        DataStorageUtils.ConditionalData conditionalData;
        Primitive primitiveData;
        bytes32 successor;
        BoundaryEventAction[] actions;
    }

    struct BoundaryEventAction {
        DataStorageUtils.ConditionalData conditionalTarget;
        address fixedTarget;
        bytes4 targetFunction;
    }

    /**
     * APPLICATION
     */
    struct Application {
        bytes32 id;
        ApplicationType applicationType;
        address location;
        bytes4 method;
        bytes32 webForm;
        mapping(bytes32 => AccessPoint) accessPoints;
        bytes32[] accessPointKeys;
    }

    struct AccessPoint {
        bytes32 id;
        uint8 dataType;
        BpmModel.Direction direction;
        bool exists;
    }

    struct ApplicationMap {
        mapping(bytes32 => ApplicationElement) rows;
        bytes32[] keys;
    }

    struct ApplicationElement {
        uint keyIdx;
        Application value;
        bool exists;
    }

    /**
     * PROCESS INTERFACES
     */
    struct ProcessInterface {
        address model;
        bytes32 interfaceId;
    }

    struct ProcessInterfaceMap {
        mapping(bytes32 => ProcessInterfaceElement) rows;
        bytes32[] keys;
    }

    struct ProcessInterfaceElement {
        uint keyIdx;
        ProcessInterface value;
        bool exists;
    }

    /**
     * @dev Creates a TransitionCondition whose left-hand side is populated with the provided parameters as well as the given operator.
     * @param _dataPath the dataPath field to set in the left-hand ConditionalData
     * @param _dataStorageId the dataStorageId field to set in the left-hand ConditionalData
     * @param _dataStorage the dataStorage field to set in the left-hand ConditionalData
     * @param _operator the uint8 representation of a DataStorageUtils.COMPARISON_OPERATOR
     * @return a TransitionCondition struct initialized with a left-hand ConditionalData and operator
     */
    function createLeftHandTransitionCondition(bytes32 _dataPath, bytes32 _dataStorageId, address _dataStorage, uint8 _operator) internal pure returns (TransitionCondition memory condition) {
        DataStorageUtils.ConditionalData memory lhData = DataStorageUtils.ConditionalData({dataPath: _dataPath, dataStorageId: _dataStorageId, dataStorage: _dataStorage, exists: true});
        condition.lhData = lhData;
        condition.operator= DataStorageUtils.COMPARISON_OPERATOR(_operator);
    }
}