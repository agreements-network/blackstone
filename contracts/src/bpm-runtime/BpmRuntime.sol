pragma solidity ^0.5.12;

import "bpm-model/BpmModel.sol";
import "bpm-model/ProcessDefinition.sol";

/**
 * @title BpmRuntime Library
 * @dev This library defines the data structures to be used in conjunction with the BPM Runtime API library.
 */
library BpmRuntime {
	
	enum ProcessInstanceState {CREATED,ABORTED,ACTIVE,COMPLETED}
	enum ActivityInstanceState {CREATED,ABORTED,COMPLETED,INTERRUPTED,SUSPENDED,APPLICATION}
    enum TransitionType {NONE,XOR,OR,AND}
	
	struct ProcessInstance {
        address addr;
        address startedBy;
        bytes32 subProcessActivityInstance;
        ProcessDefinition processDefinition;
		ProcessInstanceState state;
        ProcessGraph graph;
        ActivityInstanceMap activities;
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
    struct ActivityNode {
        bool ready;
        bool done;
        bool exists;
        uint instancesTotal;
        uint instancesCompleted;
        Node node;
    }

    // The Transition guides the implementation of different gateway types in the Petri net
    struct Transition {
        Node node;
        bytes32 defaultOutput; // only applies to XOR gateway to set the default transition
        TransitionType transitionType;
        bool exists;
    }

}