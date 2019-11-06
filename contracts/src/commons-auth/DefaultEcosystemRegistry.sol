pragma solidity ^0.5;

import "commons-base/ErrorsLib.sol";
import "commons-management/AbstractObjectFactory.sol";
import "commons-management/AbstractDbUpgradeable.sol";
import "commons-management/ArtifactsFinderEnabled.sol";
import "commons-management/ObjectProxy.sol";

import "commons-auth/Ecosystem.sol";
import "commons-auth/DefaultEcosystem.sol";
import "commons-auth/EcosystemRegistry.sol";
import "commons-auth/EcosystemRegistryDb.sol";

/**
 * @title DefaultEcosystemRegistry
 * @dev Default implementation of the EcosystemRegistry interface.
 */
contract DefaultEcosystemRegistry is AbstractVersionedArtifact(1,0,0), AbstractObjectFactory, ArtifactsFinderEnabled, AbstractDbUpgradeable, EcosystemRegistry {

    /**
     * @dev Creates a new Ecosystem with the given name.
     * REVERTS if:
     * - the name is already registered
     * @param _name the name under which to register the Ecosystem
     * @return the address of the new Ecosystem
     */
    function createEcosystem(string calldata _name) external returns (address ecosystemAddress) {
        ErrorsLib.revertIf(EcosystemRegistryDb(database).ecosystemExists(_name),
            ErrorsLib.OVERWRITE_NOT_ALLOWED(), "DefaultEcosystemRegistry.registerEcosystem", "An ecosystem with the same name is already registered");
        ecosystemAddress = address(new ObjectProxy(address(artifactsFinder), OBJECT_CLASS_ECOSYSTEM));
        Ecosystem(ecosystemAddress).initialize();
        Ecosystem(ecosystemAddress).transferOwnership(msg.sender);
        EcosystemRegistryDb(database).addEcosystem(_name, ecosystemAddress);
    }

}