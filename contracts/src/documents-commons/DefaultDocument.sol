pragma solidity ^0.5;

import "documents-commons/AbstractDocument.sol";

/**
 * @title DefaultDocument
 * @dev Default document implementation that restricts document manipulations to the owner.
 */
contract DefaultDocument is AbstractDocument {

	/**
	 * @dev Creates a new DefaultDocument with the specified name
	 * @param _name the document name
	 */
	constructor(string memory _name) AbstractDocument(_name) public { }

    /**
     * @dev Default implementation that allows the document owner add versions.
     * @return true if the msg.sender is the document owner
     */
    function canAddVersion() internal view returns (bool) {
        return msg.sender == owner;
    }

}