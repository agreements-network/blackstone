pragma solidity ^0.4.23;

import "bpm-runtime/ProcessInstance.sol";
import "bpm-runtime/ProcessStateChangeListener.sol";

/**
 * @title ProcessStateChangeEmitter
 * @dev Interface contract for emitting process state change events
 */
contract ProcessStateChangeEmitter {

  /**
    * @dev Adds a ProcessStateChangeListener to listeners collection
    * @param _listener the ProcessStateChangeListener to add
    */
  function addProcessStateChangeListener(ProcessStateChangeListener _listener) external;

  /**
    * @dev Notifies listeners about a process state change
    */
  function notifyProcessStateChange() public;

}