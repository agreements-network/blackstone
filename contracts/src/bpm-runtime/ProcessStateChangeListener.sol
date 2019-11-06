pragma solidity ^0.5;

import "bpm-runtime/ProcessInstance.sol";

/**
 * @title ProcessStateChangeListener
 * @dev Interface contract for subscribing to events from ProcessStateChangeEmitter.
 */
interface ProcessStateChangeListener {

  /**
	 * @dev Invoked by a ProcessStateChangeEventEmitter to notify of process state change
	 * @param _pi the process instance whose state changed
	 */
  function processStateChanged(ProcessInstance _pi) external;
}