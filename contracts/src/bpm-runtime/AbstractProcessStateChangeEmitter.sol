pragma solidity ^0.5;

import "bpm-runtime/ProcessInstance.sol";
import "bpm-runtime/ProcessStateChangeEmitter.sol";
import "bpm-runtime/ProcessStateChangeListener.sol";

/**
 * @title AbstractProcessStateChangeEmitter
 * @dev Abstract implementation contract for emitting process state change events
 */
contract AbstractProcessStateChangeEmitter is ProcessStateChangeEmitter {

  ProcessStateChangeListener[] stateChangeListeners;

  /**
    * @dev Adds a ProcessStateChangeListener to listeners collection
    * @param _listener the ProcessStateChangeListener to add
    */
  function addProcessStateChangeListener(ProcessStateChangeListener _listener) external {
    stateChangeListeners.push(_listener);
  }

  /**
    * @dev Notifies listeners about a process state change
    */
  function notifyProcessStateChange() public;

}