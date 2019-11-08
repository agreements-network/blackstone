pragma solidity ^0.5;

/**
 * @title EventEmitter Interface
 * @dev Supports a publish-subscribe pattern.
 */
contract EventEmitter {

	//TODO standard event types should be moved to inheriting contracts or a library
	bytes32 public EVENT_CREATED = "created";
	bytes32 public EVENT_UPDATED = "updated";
	bytes32 public EVENT_DELETED = "deleted";

    /**
     * @dev Adds the msg.sender as listener for the specified event.
     * @param _event the event to subscribe to
     */
    function addEventListener(bytes32 _event) public;

    /**
     * @dev Adds the msg.sender as listener for the specified event.
     * @param _event the event to subscribe to
     * @param _listener the address of an EventListener
     */
    function addEventListener(bytes32 _event, address _listener) public;

    /**
     * @dev Removes the msg.sender from the list of listeners for the specified event.
     * @param _event the event to unsubscribe from
     */
    function removeEventListener(bytes32 _event) public;

    /**
     * @dev Removes the msg.sender from the list of listeners for the specified event.
     * @param _event the event to unsubscribe from
     * @param _listener the address of an EventListener
     */
    function removeEventListener(bytes32 _event, address _listener) public;
}