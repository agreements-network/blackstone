pragma solidity ^0.5;

import "commons-base/NamedElement.sol";
import "commons-base/AbstractNamedElement.sol";

/**
 * @dev Auxiliary contract to implement AbstractNamedElement
 */
contract TestElement is AbstractNamedElement {
	
	constructor(bytes32 _id, string memory _name) public {
		id = _id;
		name = _name;
	}
}

contract BaseTest {

	string name = "MyName";
	
	function testNamedElement() external returns (string memory) {
		
		NamedElement element = new TestElement("MyId", name);
		if (element.getId() != "MyId") return "ID not set correctly.";
		if (bytes(element.getName()).length != bytes(name).length) return "Name not set correctly.";
		
		return "success";
	}
	
}