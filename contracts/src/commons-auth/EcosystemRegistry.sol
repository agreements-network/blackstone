pragma solidity ^0.5;

import "commons-management/Upgradeable.sol";
import "commons-management/ObjectFactory.sol";

/**
 * @title EcosystemRegistry Interface
 * @dev The interface describing interaction with an Ecosystem
 */
contract EcosystemRegistry is ObjectFactory, Upgradeable {

    string public constant OBJECT_CLASS_ECOSYSTEM = "commons.auth.Ecosystem";

    /**
     * @dev Creates a new Ecosystem with the given name.
     * @param _name the name under which to register the Ecosystem
     * @return the address of the new Ecosystem
     */
    function createEcosystem(string calldata _name) external returns (address);
}