pragma solidity ^0.5;

import "commons-base/ErrorsLib.sol";
import "commons-standards/AbstractERC165.sol";

import "commons-management/ObjectFactory.sol";

/**
 * @title AbstractObjectFactory
 * @dev The abstract implementation for a contract able to produce upgradeable objects belonging to an object class.
 */
contract AbstractObjectFactory is AbstractERC165, ObjectFactory {

	constructor() internal {
        addInterfaceSupport(ERC165_ID_ObjectFactory);
	}

}