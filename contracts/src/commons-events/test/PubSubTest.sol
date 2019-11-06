pragma solidity ^0.5;

import "commons-events/EventListener.sol";
import "commons-events/AbstractEventListener.sol";
import "commons-events/EventEmitter.sol";
import "commons-events/DefaultEventEmitter.sol";

contract PubSubTest {

	function testPubSub() external returns (string memory) {

		MyEmitter mine = new MyEmitter();
		YourEmitter yours = new YourEmitter();
		MyReceiver receiver = new MyReceiver();
		receiver.registerEmitters(mine, yours); // test both ways of addEventListener, from within listener and from outside
		mine.addEventListener("bytes32", address(receiver));
		yours.addEventListener("address", address(receiver));
		yours.addEventListener("uint", address(receiver));

		// check number of listerners for selected events
		if (mine.getNumberOfListeners(mine.EVENT_CREATED()) != 0) return "Expected # of listeners for EVENT_DELETED to be 0.";
		if (mine.getNumberOfListeners(mine.EVENT_UPDATED()) != 1) return "Expected # of listeners for EVENT_UPDATED to be 1.";
		if (mine.getNumberOfListeners(mine.EVENT_DELETED()) != 1) return "Expected # of listeners for EVENT_DELETED to be 1.";
		if (yours.getNumberOfListeners("fake") != 0) return "Expected # of listeners for fake to be 0.";
		if (yours.getNumberOfListeners("custom") != 1) return "Expected # of listeners for custom to be 1.";

		// check a few registered listeners for their addresses
		if (mine.getListenerAtIndex(mine.EVENT_UPDATED(), 0) != address(receiver)) return "Expected receiver to be registered for EVENT_UPDATED";
		if (mine.getListenerAtIndex(mine.EVENT_DELETED(), 0) != address(receiver)) return "Expected receiver to be registered for EVENT_DELETED";
		if (yours.getListenerAtIndex("custom", 0) != address(receiver)) return "Expected receiver to be registered for custom event";

		uint eventsCount = receiver.numberOfEvents();
		mine.modify();
		if (receiver.numberOfEvents() != eventsCount+1) return "Number of events unchanged after modify";
		if (receiver.lastEvent() != mine.EVENT_UPDATED()) return "lastEvent expected to be EVENT_UPDATED after modify";
		if (receiver.lastSource() != address(mine)) return "lastSource expected to be mine after modify";

		eventsCount = receiver.numberOfEvents();
		yours.customEvent("custom");
		if (receiver.numberOfEvents() != eventsCount+1) return "Number of events unchanged after customEvent";
		if (receiver.lastEvent() != "custom") return "lastEvent expected to be custom after customEvent";
		if (receiver.lastSource() != address(yours)) return "lastSource expected to be yours after customEvent";

		eventsCount = receiver.numberOfEvents();
		yours.customEvent("fakilicious");
		if (receiver.numberOfEvents() != eventsCount) return "Number of events expected to be unchanged after unknown event";
		if (receiver.lastEvent() != "custom") return "lastEvent still expected to be custom after unknown event";
		if (receiver.lastSource() != address(yours)) return "lastSource still expected to be yours after unknown event";

		eventsCount = receiver.numberOfEvents();
		mine.deleteByTest();
		if (receiver.numberOfEvents() != eventsCount+1) return "Number of events unchanged after deleteByTest";
		if (receiver.lastEvent() != mine.EVENT_DELETED()) return "lastEvent expected to be EVENT_DELETED after deleteByTest";
		if (receiver.lastSource() != address(this)) return "lastSource expected to be this after deleteByTest";

		eventsCount = receiver.numberOfEvents();
		mine.changeBytes32("someNewB32");
		if (receiver.numberOfEvents() != eventsCount+1) return "Number of events unchanged after changeBytes32";
		if (receiver.lastEvent() != "bytes32") return "lastEvent expected to be bytes32 after changeBytes32";
		if (receiver.lastSource() != address(mine)) return "lastSource expected to be mine after changeBytes32";
		if (receiver.bytes32Payload() != "someNewB32") return "bytes32Payload not set as expected after changeBytes32";

		eventsCount = receiver.numberOfEvents();
		yours.changeAddress(address(receiver));
		if (receiver.numberOfEvents() != eventsCount+1) return "Number of events unchanged after changeAddress";
		if (receiver.lastEvent() != "address") return "lastEvent expected to be address after changeAddress";
		if (receiver.lastSource() != address(yours)) return "lastSource expected to be mine after changeAddress";
		if (receiver.addressPayload() != address(receiver)) return "addressPayload not set as expected after changeAddress";

		eventsCount = receiver.numberOfEvents();
		yours.changeUint(999);
		if (receiver.numberOfEvents() != eventsCount+1) return "Number of events unchanged after changeUint";
		if (receiver.lastEvent() != "uint") return "lastEvent expected to be uint after changeUint";
		if (receiver.lastSource() != address(yours)) return "lastSource expected to be mine after changeUint";
		if (receiver.uintPayload() != 999) return "uintPayload not set as expected after changeUint";

		return "success";
	}

}

contract MyReceiver is AbstractEventListener {

	bytes32 public lastEvent = "bla";
	address public lastSource;
	uint public numberOfEvents;
	bytes32 public bytes32Payload;
	uint public uintPayload;
	address public addressPayload;
	string public stringPayload; //TODO string payload currently not tested

	function registerEmitters(EventEmitter _a, EventEmitter _b) external {
		_a.addEventListener(_a.EVENT_UPDATED());
		_a.addEventListener(_a.EVENT_DELETED());
		_b.addEventListener("custom");
	}

	function eventFired(bytes32 _event, address _source) external {
		lastEvent = _event;
		lastSource = _source;
		numberOfEvents++;
	}

	function eventFired(bytes32 _event, address _source, bytes32 _data) external {
		lastEvent = _event;
		lastSource = _source;
		bytes32Payload = _data;
		numberOfEvents++;
	}

	function eventFired(bytes32 _event, address _source, uint _data) external {
		lastEvent = _event;
		lastSource = _source;
		uintPayload = _data;
		numberOfEvents++;
	}

	function eventFired(bytes32 _event, address _source, address _data) external {
		lastEvent = _event;
		lastSource = _source;
		addressPayload = _data;
		numberOfEvents++;
	}

}

contract TestEmitter is DefaultEventEmitter {

	function getNumberOfListeners(bytes32 _event) external view returns (uint) {
		return listeners.rows[_event].value.length;
	}

	function getListenerAtIndex(bytes32 _event, uint _idx) external view returns (address) {
		return listeners.rows[_event].value[_idx];
	}
}

contract MyEmitter is TestEmitter {

	function modify() public {
		emitEvent(EVENT_UPDATED, address(this));
	}

	function deleteByTest() public {
		emitEvent(EVENT_DELETED, msg.sender);
	}

	function changeBytes32(bytes32 _newValue) public {
		emitEvent("bytes32", address(this), _newValue);
	}
}

contract YourEmitter is TestEmitter {

	function customEvent(bytes32 _event) public {
		emitEvent(_event, address(this));
	}

	function changeAddress(address _newValue) public {
		emitEvent("address", address(this), _newValue);
	}

	function changeUint(uint _newValue) public {
		emitEvent("uint", address(this), _newValue);
	}
}