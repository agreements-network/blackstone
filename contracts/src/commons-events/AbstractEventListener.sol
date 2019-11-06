pragma solidity ^0.5;

import "commons-events/EventListener.sol";

/**
 * @title AbstractEventListener
 * @dev Abstract implementation of the EventListener interface for subscribing to events from an EventEmitter.
 * By inheriting from this contract an implementing contract can selectively overwrite the listening functions it needs.
 * NOTE: variable names in the functions below are commented out to suppress Solidity compiler warnings
 */
contract AbstractEventListener is EventListener {

	/**
	 * @dev See EventListener.eventFired(bytes32,address)
	 */
	function eventFired(bytes32 /*_event*/, address /*_source*/) external {}

	/**
	 * @dev See EventListener.eventFired(bytes32,address,bytes32)
	 */
	function eventFired(bytes32 /*_event*/, address /*_source*/, bytes32 /*_data*/) external {}

	/**
	 * @dev See EventListener.eventFired(bytes32,address,uint)
	 */
	function eventFired(bytes32 /*_event*/, address /*_source*/, uint /*_data*/) external {}

	/**
	 * @dev See EventListener.eventFired(bytes32,address,address)
	 */
	function eventFired(bytes32 /*_event*/, address /*_source*/, address /*_data*/) external {}

	/**
	 * @dev See EventListener.eventFired(bytes32,address,string)
	 */
	function eventFired(bytes32 /*_event*/, address /*_source*/, string calldata /*_data*/) external {}

	/**
	 * @dev See EventListener.eventFired(bytes32,address,bytes32,address)
	 */
	function eventFired(bytes32 /*_event*/, address /*_source*/, bytes32 /*_key1*/, address /*_key2*/) external {}

}