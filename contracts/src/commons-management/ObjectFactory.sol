pragma solidity ^0.5;

/**
 * @title ObjectFactory
 * @dev The interface for a contract able to produce upgradeable objects belonging to an object class.
 */
contract ObjectFactory {

	bytes4 public constant ERC165_ID_ObjectFactory = bytes4(keccak256(abi.encodePacked("getObjectClasses()")));

	// it's currently unclear what functions an ObjectFactory should expose
}