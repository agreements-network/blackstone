pragma solidity ^0.5;

/**
 * @title EventListener
 * @dev Interface contract for subscribing to events from an EventEmitter.
 */
interface EventListener {

	/**
	 * @dev Invoked by an EventEmitter for a named event without any additional data.
	 * @param _event the event name
	 * @param _source the source of the event
	 */
	function eventFired(bytes32 _event, address _source) external;

	/**
	 * @dev Invoked by an EventEmitter for a named event with an additional bytes32 payload.
	 * @param _event the event name
	 * @param _source the source of the event
	 * @param _data the payload
	 */
	function eventFired(bytes32 _event, address _source, bytes32 _data) external;

	/**
	 * @dev Invoked by an EventEmitter for a named event with an additional uint payload.
	 * @param _event the event name
	 * @param _source the source of the event
	 * @param _data the payload
	 */
	function eventFired(bytes32 _event, address _source, uint _data) external;

	/**
	 * @dev Invoked by an EventEmitter for a named event with an additional address payload.
	 * @param _event the event name
	 * @param _source the source of the event
	 * @param _data the payload
	 */
	function eventFired(bytes32 _event, address _source, address _data) external;

	/**
	 * @dev Invoked by an EventEmitter for a named event with an additional string payload.
	 * @param _event the event name
	 * @param _source the source of the event
	 * @param _data the payload
	 */
	function eventFired(bytes32 _event, address _source, string calldata _data) external;

	/**
	 * @dev Invoked by an EventEmitter for a named event with an additional bytes32 payload.
	 * @param _event the event name
	 * @param _source the source of the event
	 * @param _key1 the payload
	 * @param _key2 the payload
	 */
	function eventFired(bytes32 _event, address _source, bytes32 _key1, address _key2) external;

}