pragma solidity ^0.5;

import "commons-auth/Ecosystem.sol";
import "commons-auth/DefaultEcosystem.sol";
import "commons-auth/EcosystemRegistry.sol";
import "commons-auth/DefaultEcosystemRegistry.sol";
import "commons-auth/EcosystemRegistryDb.sol";
import "commons-management/ArtifactsFinderEnabled.sol";
import "commons-management/ArtifactsRegistry.sol";
import "commons-management/DefaultArtifactsRegistry.sol";
import "commons-management/AbstractDbUpgradeable.sol";

contract EcosystemTest {
	
	string constant SUCCESS = "success";

	ArtifactsRegistry artifactsRegistry;

	Ecosystem defaultEcosystemImpl = new DefaultEcosystem();

	constructor () public {
		// ArtifactsRegistry
		artifactsRegistry = new DefaultArtifactsRegistry();
        DefaultArtifactsRegistry(address(artifactsRegistry)).initialize();
	}

	/**
	 * This function can be used in the beginning of a test to have a fresh BpmService instance.
	 */
	function createNewEcosystemRegistry() internal returns (EcosystemRegistry newRegistry) {
		EcosystemRegistryDb registryDb = new EcosystemRegistryDb();
		newRegistry = new DefaultEcosystemRegistry();
		registryDb.transferSystemOwnership(address(newRegistry));
		AbstractDbUpgradeable(address(newRegistry)).acceptDatabase(address(registryDb));
		ArtifactsFinderEnabled(address(newRegistry)).setArtifactsFinder(address(artifactsRegistry));
        artifactsRegistry.registerArtifact(newRegistry.OBJECT_CLASS_ECOSYSTEM(), address(defaultEcosystemImpl), defaultEcosystemImpl.getArtifactVersion(), true);
	}

	/**
	 * @dev Tests the functions of a single Ecosystem
	 */
	function testEcosystemLifecycle() external returns (string memory) {

		Ecosystem ecosystem = new DefaultEcosystem();
		ecosystem.initialize();
		ecosystem.addExternalAddress(address(this));
		if (!ecosystem.isKnownExternalAddress(address(this))) return "Ecosystem should detect registered address as known address";
		if (ecosystem.isKnownExternalAddress(msg.sender)) return "Ecosystem should detect unknown address";

		return SUCCESS;
	}

	/**
	 * @dev Tests the EcoystemRegistry
	 */
	function testEcosystemRegistry() external returns (string memory) {

		EcosystemRegistry registry = createNewEcosystemRegistry();

		address ecosystemAddress = registry.createEcosystem("MyEcosystem");
		if (ecosystemAddress == address(0)) return "Ecosystem not created successfully";
		bool success;
		(success, ) = address(registry).call(abi.encodeWithSignature("registerEcosystem(string,address)", "MyEcosystem", address(this)));
		if (success)
			return "Registering an ecosystem with an already taken name should revert";

		return SUCCESS;
	}

}