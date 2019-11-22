pragma solidity ^0.5;

import "bpm-model/BpmModel.sol";
import "bpm-model/ProcessDefinition.sol";

/**
 * @title BpmRuntime Library
 * @dev This library defines the data structures to be used in conjunction with the BPM Runtime API library.
 */
library BpmRuntime {
	
	enum ProcessInstanceState {CREATED,ABORTED,ACTIVE,COMPLETED}
	enum ActivityInstanceState {CREATED,ABORTED,COMPLETED,INTERRUPTED,SUSPENDED,APPLICATION}
    enum EventBoundaryInstanceState {CREATED,ARMED,FIRED,COMPLETED}
    enum TransitionType {NONE,XOR,OR,AND}
	
	struct ProcessInstance {
        address addr;
        address startedBy;
        bytes32 subProcessActivityInstance;
        ProcessDefinition processDefinition;
		ProcessInstanceState state;
        ProcessGraph graph;
        ActivityInstanceMap activities;
        IntermediateEventInstanceMap intermediateEvents;
        BoundaryEventInstanceMap boundaryEvents;
	}
	
	struct ActivityInstance {
        bytes32 id;
        bytes32 activityId;
        address processInstance;
        uint multiInstanceIndex;
        uint created;
        uint completed;
        address performer;
        address completedBy;
		ActivityInstanceState state;
	}

    struct ActivityInstanceElement {
        bool exists;
        uint keyIdx;
        ActivityInstance value;
    }

    struct ActivityInstanceMap {
        mapping(bytes32 => ActivityInstanceElement) rows;
        bytes32[] keys;
    }

	struct IntermediateEventInstance {
        bytes32 id;
        bytes32 eventId;
        address processInstance;
        uint created;
        uint completed;
		ActivityInstanceState state;
        uint timerTarget;
	}

    struct IntermediateEventElement {
        bool exists;
        uint keyIdx;
        IntermediateEventInstance value;
    }

    struct IntermediateEventInstanceMap {
        mapping(bytes32 => IntermediateEventElement) rows;
        bytes32[] keys;
    }

    struct BoundaryEventInstance {
        bytes32 id;
        bytes32 boundaryId;
        bytes32 activityInstanceId;
        EventBoundaryInstanceState state;
        uint timerTarget;
    }

    struct BoundaryEventElement {
        bool exists;
        uint keyIdx;
        BoundaryEventInstance value;
    }

    struct BoundaryEventInstanceMap {
        mapping(bytes32 => BoundaryEventElement) rows;
        bytes32[] keys;
    }

    /**
     * ##### Petri Net Structs and Functions
     */

    // generic element with incoming and outgoing references
    struct Node {
        bytes32 id;
        bytes32[] inputs;
        bytes32[] outputs;
    }

    // represents the net graph
    struct ProcessGraph {
        address processInstance;
        mapping(bytes32 => ActivityNode) activities;
        bytes32[] activityKeys;
        mapping(bytes32 => Transition) transitions;
        bytes32[] transitionKeys;
    }

    // This structure corresponds to a "place" in a traditional petri net with a modification that it does not have a single token state.
    // Transitions create "activation tokens" and it's the responsibility of the place to signal it's readiness by setting a "completion token".
    // This supports the use of the places as state holders for BPM activities which generally require some form of processing before producing
    // a new token to activate an outgoing transition.
    // Additionally, the node contains the capacity for arbitrary activation tokens to be placed as "markers", or "colored"
    // tokens which allows the creation of dedicated transitions that respond only to a specific marker ID.
    struct ActivityNode {
        Node node;
        // Ready means that the activity is ready to executed
        bool ready;
        // Done means that the activity is completed
        bool done;
        // ActivityNode is used in a mapping; when reading non-existent entry is accessed,
        // solidity will give you an ActivityNode with zeroed fields. The field exists
        // is set to true if there is actually an entry there.
        bool exists;
        uint instancesTotal; // only used for tasks
        uint instancesCompleted; // only used for tasks
        mapping (bytes32 => bool) markers; // only used for tasks
    }

    // The Transition guides the implementation of different gateway types in the Petri net
    struct Transition {
        Node node;
        bytes32 defaultOutput; // only applies to XOR gateway to set the default transition
        TransitionType transitionType;
        bytes32 marker;
        bool exists;
    }

}