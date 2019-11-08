pragma solidity ^0.5;

import "commons-collections/Mappings.sol";
import "commons-collections/MappingsLib.sol";

import "commons-events/EventListener.sol";
import "commons-events/EventEmitter.sol";

/**
 * @title DefaultEventEmitter
 * @dev Default implementation of the EventEmitter interface.
 */
contract DefaultEventEmitter is EventEmitter {

	using MappingsLib for Mappings.Bytes32AddressArrayMap;

	Mappings.Bytes32AddressArrayMap listeners;

	/**
	 * @dev Emits the given event as coming from the specified source. By providing a source other than 'this' contract's address, an EventEmitter can emit events for objects it knows about.
	 * @param _event the event key
	 * @param _source the emitting source's address
	 */
    function emitEvent(bytes32 _event, address _source) internal {
    	for (uint i=0; i<listeners.rows[_event].value.length; i++) {
    		EventListener(listeners.rows[_event].value[i]).eventFired(_event, _source);
    	}
    }

    /**
     * @dev Emits the given event as coming from the specified source with the given payload. By providing a source other than 'this' contract's address, an EventEmitter can emit events for objects it knows about.
     * @param _event the event key
     * @param _source the emitting source's address
     * @param _data the event payload
     */
    function emitEvent(bytes32 _event, address _source, bytes32 _data) internal {
        for (uint i=0; i<listeners.rows[_event].value.length; i++) {
            EventListener(listeners.rows[_event].value[i]).eventFired(_event, _source, _data);
        }
    }

    /**
     * @dev Emits the given event as coming from the specified source with the given payload. By providing a source other than 'this' contract's address, an EventEmitter can emit events for objects it knows about.
     * @param _event the event key
     * @param _source the emitting source's address
     * @param _data the event payload
     */
    function emitEvent(bytes32 _event, address _source, uint _data) internal {
        for (uint i=0; i<listeners.rows[_event].value.length; i++) {
            EventListener(listeners.rows[_event].value[i]).eventFired(_event, _source, _data);
        }
    }

    /**
     * @dev Emits the given event as coming from the specified source with the given payload. By providing a source other than 'this' contract's address, an EventEmitter can emit events for objects it knows about.
     * @param _event the event key
     * @param _source the emitting source's address
     * @param _data the event payload
     */
    function emitEvent(bytes32 _event, address _source, address _data) internal {
        for (uint i=0; i<listeners.rows[_event].value.length; i++) {
            EventListener(listeners.rows[_event].value[i]).eventFired(_event, _source, _data);
        }
    }

    /**
     * @dev Emits the given event as coming from the specified source with the given payload. By providing a source other than 'this' contract's address, an EventEmitter can emit events for objects it knows about.
     * @param _event the event key
     * @param _source the emitting source's address
     * @param _data the event payload
     */
    function emitEvent(bytes32 _event, address _source, string memory _data) internal {
        for (uint i=0; i<listeners.rows[_event].value.length; i++) {
            EventListener(listeners.rows[_event].value[i]).eventFired(_event, _source, _data);
        }
    }

    /**
     * @dev Emits the given event as coming from the specified source with the given payload. By providing a source other than 'this' contract's address, an EventEmitter can emit events for objects it knows about.
     * @param _event the event key
     * @param _source the emitting source's address
     * @param _key1 the event payload
     * @param _key2 the event payload
     */
    function emitEvent(bytes32 _event, address _source, bytes32 _key1, address _key2) internal {
        for (uint i=0; i<listeners.rows[_event].value.length; i++) {
            EventListener(listeners.rows[_event].value[i]).eventFired(_event, _source, _key1, _key2);
        }
    }

    /**
     * @dev Adds the msg.sender as listener for the specified event.
     * @param _event the event to subscribe to
     */
    function addEventListener(bytes32 _event) public {
        addEventListener(_event, msg.sender);
    }

    /**
     * @dev Adds the specified listener to the specified event.
     * @param _event the event to subscribe to
     * @param _listener the address of an EventListener
     */
    function addEventListener(bytes32 _event, address _listener) public {
        listeners.addToArray(_event, _listener, true);
    }

    /**
     * @dev Removes the msg.sender from the list of listeners for the specified event.
     * @param _event the event to unsubscribe from
     */
    function removeEventListener(bytes32 _event) public {
        removeEventListener(_event, msg.sender);
    }

    /**
     * @dev Removes the specified listener from the list of listeners for the specified event.
     * @param _event the event to unsubscribe from
     * @param _listener the address of an EventListener
     */
    function removeEventListener(bytes32 _event, address _listener) public {
        listeners.removeFromArray(_event, _listener, true);
    }
}