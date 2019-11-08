pragma solidity ^0.5;

import "commons-base/SystemOwned.sol";
import "commons-standards/ERC165Utils.sol";

import "commons-management/AbstractVersionedArtifact.sol";
import "commons-management/AbstractDbUpgradeable.sol";
import "commons-management/ArtifactsFinderEnabled.sol";
import "commons-management/ArtifactsRegistry.sol";
import "commons-management/DefaultArtifactsRegistry.sol";

contract ArtifactsRegistryTest {

    string constant keyService1 = "agreements-network/services/Service1";
    string constant keyService2 = "agreements-network/services/Service2";
    string constant EMPTY_STRING = "";
    string constant functionSigRegisterArtifact = "registerArtifact(string,address,uint8[3],bool)";

    // the ERC165 ID of ArtifactsFinderEnabled
    bytes4 constant ERC165_ID_ArtifactsFinderEnabled = bytes4(keccak256(abi.encodePacked("setArtifactsFinder(address)")));

    function testArtifactsRegistry() external returns (string memory) {

        address location;
        uint8[3] memory version;

        ArtifactsRegistry artifactsRegistry = new DefaultArtifactsRegistry();
        DefaultArtifactsRegistry(address(artifactsRegistry)).initialize(); // sets the system owner

        TestServiceWithDependency s1 = new TestServiceWithDependency([1,0,0]);
        s1.setArtifactsFinder(address(artifactsRegistry));
        DefaultTestService s2 = new DefaultTestService([1,2,0]);
        ServiceDb service1Db = new ServiceDb(address(s1));
        ServiceDb service2Db = new ServiceDb(address(s2));
        s1.acceptDatabase(address(service1Db));
        s2.acceptDatabase(address(service2Db));

        if (artifactsRegistry.getNumberOfArtifacts() > 0) return "There should be no artifacts";

        // test failure scenarios
        version = [1,0,0];
        bool success;
        (success, ) = address(artifactsRegistry).call(abi.encodeWithSignature(functionSigRegisterArtifact, EMPTY_STRING, address(s1), version, false));
        if (success)
            return "Registering an artifact with an empty ID should revert";
        (success, ) = address(artifactsRegistry).call(abi.encodeWithSignature(functionSigRegisterArtifact, keyService1, address(0), version, false));
        if (success)
            return "Registering an artifact with an empty address should revert";
        (success, ) = address(artifactsRegistry).call(abi.encodeWithSignature(functionSigRegisterArtifact, keyService1, address(s1), version, true));
        if (!success)
            return "Registering an artifact service1 correctly should succeed.";
        if (artifactsRegistry.getNumberOfArtifacts() != 1) return "There should be 1 artifact after service1 registration";

        (success, ) = address(artifactsRegistry).call(abi.encodeWithSignature(functionSigRegisterArtifact, keyService1, address(this), version, true));
        if (success)
            return "Registering an service1 with same ID and version, but different address should fail";

        // performing without the dependency should fail
        (success, ) = address(s1).call(abi.encodeWithSignature("performWithDependency()"));
        if (success) return "Calling service1 without the dependency registered should revert";
        if (s1.getDependency1() != address(0)) return "The dependency1 address on service1 should not be filled after the revert";

        artifactsRegistry.registerArtifact(keyService2, address(s2), [1,2,0], true);
        if (artifactsRegistry.getNumberOfArtifacts() != 2) return "There should be 2 artifacts after service2 registration";

        // now re-attempt to perform service1
        (success, ) = address(s1).call(abi.encodeWithSignature("performWithDependency()"));
        if (!success) return "Calling service1 with the dependency registered should succeed";
        if (s1.getDependency1() != address(s2)) return "The dependency1 address on service1 should now point to service2";

        // perform an update to service 2 and check if dependencies were updated
        DefaultTestService s2_1 = new DefaultTestService([2,4,0]);
        artifactsRegistry.registerArtifact(keyService2, address(s2_1), [2,4,0], true);
        if (artifactsRegistry.getNumberOfArtifacts() != 2) return "There should still be 2 artifacts after service2 upgrade with new version";
        (location, version) = artifactsRegistry.getArtifact(keyService2);
        if (location != address(s2_1)) return "The active location for service2 should have been changed after the upgrade.";
        (success, ) = address(s1).call(abi.encodeWithSignature("performWithDependency()"));
        if (!success) return "Calling service1 with an updated dependency registered should succeed";
        if (s1.getDependency1() != address(s2_1)) return "The dependency1 address on service1 should now point to service2_1";

        // test activation scenarios
        ( , version) = artifactsRegistry.getArtifact(keyService2);
        if (version[0] != 2 || version[1] != 4 || version[2] != 0) return "The currently active version for service2 should 2.4.0";
        artifactsRegistry.registerArtifact(keyService2, address(this), [3,0,1], true);
        ( , version) = artifactsRegistry.getArtifact(keyService2);
        if (version[0] != 3 || version[1] != 0 || version[2] != 1) return "The currently active version for service2 should new be 3.0.1";
        // switch back to the old version
        artifactsRegistry.setActiveVersion(keyService2, [2,4,0]);
        ( , version) = artifactsRegistry.getArtifact(keyService2);
        if (version[0] != 2 || version[1] != 4 || version[2] != 0) return "The currently active version for service2 should've been switched back to 2.4.0";

        return "success";
    }

}

/**
 * @dev A versioned service implementation with an upgradeable DB
 */
contract DefaultTestService is AbstractDbUpgradeable {

    constructor(uint8[3] memory _version) AbstractVersionedArtifact(_version[0], _version[1], _version[2]) public {

    }

    function getDatabase() public view returns (address) {
        return database;
    }
}

/**
 * @dev Extends the DefaultTestService with capabilities for dependency injection via a ArtifactsFinder
 */
contract TestServiceWithDependency is DefaultTestService, ArtifactsFinderEnabled {

    address dependency1;
    string dep1Name = "agreements-network/services/Service2";

    constructor(uint8[3] memory _version) DefaultTestService(_version) public {

    }

    function performWithDependency() external {
		(dependency1, ) = artifactsFinder.getArtifact(dep1Name);
		ErrorsLib.revertIf(address(dependency1) == address(0),
			ErrorsLib.DEPENDENCY_NOT_FOUND(), "TestServiceWithDependency.performWithDependency", "Dependency1 not found in ArtifactsFinder");
    }

    function getDependency1() public view returns (address) {
        return dependency1;
    }

}

contract ServiceDb is SystemOwned {

    constructor(address _systemOwner) public {
        systemOwner = _systemOwner;
    }

}
