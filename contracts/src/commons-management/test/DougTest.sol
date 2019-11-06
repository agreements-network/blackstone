pragma solidity ^0.5;

import "commons-management/DOUG.sol";
import "commons-management/DefaultDoug.sol";
import "commons-management/ArtifactsRegistry.sol";
import "commons-management/DefaultArtifactsRegistry.sol";
import "commons-management/AbstractVersionedArtifact.sol";
import "commons-management/AbstractObjectFactory.sol";
import "commons-management/ArtifactsFinderEnabled.sol";

import "commons-management/test/TestService.sol";

contract DougTest {

    string constant SUCCESS = "success";
    string constant EMPTY = "";
    string constant keyObject1 = "banana";
    string constant keyObject2 = "apple";
    string constant keyService1 = "agreements-network/services/TestService1";
    string constant keyService2 = "agreements-network/services/TestService2";
    string constant keyService3 = "agreements-network/services/TestService3";

    function testRegistration() external returns (string memory) {

        uint8[3] memory version;
        address location;
        bool success;

        ArtifactsRegistry artifactsRegistry = new DefaultArtifactsRegistry();
        DefaultArtifactsRegistry(address(artifactsRegistry)).initialize();

        DefaultDoug doug = new DefaultDoug();
        artifactsRegistry.transferSystemOwnership(address(doug));
        doug.setArtifactsRegistry(address(artifactsRegistry));

        TestObjectFactory f1 = new TestObjectFactory(keyObject1);
        doug.deploy("BananaFactory", address(f1)); // Deploying through Doug should inject the ArtifactsFinder for these factories
        TestObjectFactory f2 = new TestObjectFactory(keyObject2);
        doug.deploy("AppleFactory", address(f2));

        // test NULL failures
        (success, ) = address(doug).call(abi.encodeWithSignature("register", EMPTY, address(this)));
        if (success) return "Registering an empty ID should revert";
        (success, ) = address(doug).call(abi.encodeWithSignature("register", keyObject2, address(0)));
        if (success) return "Registering an empty address should revert";

        // register object classes and test versioning behavior
        VersionedObject o1 = new VersionedObject([1,0,0]);
        doug.register(keyObject1, address(o1));
        if (doug.lookup(keyObject1) != address(o1)) return "address for banana should be o1";
        if (doug.lookupVersion(keyObject1, [1,0,0]) != address(o1)) return "address for banana and version 1.0.0 should be o1";
        if (f1.getCurrentObjectRef() != address(o1)) return "ObjectFactory1 should point to o1";

        SimpleObject o2 = new SimpleObject();
        doug.register(keyObject2, address(o2));
        (location, version) = artifactsRegistry.getArtifact(keyObject2);
        if (location != address(o2)) return "o2 should should be in the registry as apple";
        if (!isSameVersion(version, [0,0,0])) return "o2 version should be 0.0.0";
        if (f2.getCurrentObjectRef() != address(o2)) return "ObjectFactory2 should point to o2";

        // test overwrite failures
        doug.register(keyObject2, address(o2)); // registering the same address and version should be ignored
        (success, ) = address(doug).call(abi.encodeWithSignature("register", keyObject2, address(this)));
        if (success) return "Registering an existing ID and version should revert";

        // registering a higher version should automatically activate it
        doug.registerVersion(keyObject2, address(this), [0,2,4]);
        if (doug.lookup(keyObject2) != address(this)) return "Active location for apple should be now be this contract";
        if (f2.getCurrentObjectRef() != address(this)) return "ObjectFactory2 should point to this contract now";

        // registering a lower version is possible, but it should not be the active version
        VersionedObject o3 = new VersionedObject([0,9,9]);
        doug.register(keyObject1, address(o3));
        if (doug.lookup(keyObject1) != address(o1)) return "The latest version of banana should still be o1";
        if (artifactsRegistry.getArtifactByVersion(keyObject1, [0,9,9]) != address(o3)) return "Apple version 0.9.9 should've been registered";
        if (f1.getCurrentObjectRef() != address(o1)) return "ObjectFactory1 should point still point to o1";

        return SUCCESS;
    }

    function testDeployment() external returns (string memory) {

        uint8[3] memory version;
        address location;
        bool success;

        ArtifactsRegistry artifactsRegistry = new DefaultArtifactsRegistry();
        DefaultArtifactsRegistry(address(artifactsRegistry)).initialize();

        DefaultDoug doug = new DefaultDoug();
        artifactsRegistry.transferSystemOwnership(address(doug));
        doug.setArtifactsRegistry(address(artifactsRegistry));

        if (!doug.deploy("blabla", address(this))) return "Deploying any contract with an unused ID should succeed";
        if (doug.lookupVersion("blabla", [0,0,0]) != address(this)) return "This blabla contract should've deployed as version 0.0.0";

        // Test services with dependencies
        TestService s1 = new TestService([1,0,0], "");
        TestService s2 = new TestService([2,0,0], keyService1); // service2 depends on service1
        TestService s3 = new TestService([3,0,0], keyService2); // service3 depends on service2

        // test for NULL failures and ownership failure
        (success, ) = address(doug).call(abi.encodeWithSignature("deploy", EMPTY, address(this)));
        if (success) return "Deploying an empty ID should revert";
        (success, ) = address(doug).call(abi.encodeWithSignature("deploy", keyService1, address(0)));
        if (success) return "Deploying an empty address should revert";
        (success, ) = address(doug).call(abi.encodeWithSignature("deploy", keyService1, address(s1)));
        if (success) return "Deploying an upgradeable service that is not upgradeOwned by DOUG should revert";

        s1.transferUpgradeOwnership(address(doug));
        s2.transferUpgradeOwnership(address(doug));
        s3.transferUpgradeOwnership(address(doug));
        if (!doug.deploy(keyService1, address(s1))) return "Deployment of TestService1 should succeed";
        if (!doug.deploy(keyService2, address(s2))) return "Deployment of TestService2 should succeed";
        if (!doug.deploy(keyService3, address(s3))) return "Deployment of TestService3 should succeed";

        (location, version) = artifactsRegistry.getArtifact(keyService1);
        if (location != address(s1)) return "Service1 location should be in the registry";
        if (!isSameVersion(version, [1,0,0])) return "Service1 version should be in the registry";

        (location, version) = artifactsRegistry.getArtifact(keyService2);
        if (location != address(s2)) return "Service2 location should be in the registry";
        if (!isSameVersion(version, [2,0,0])) return "Service2 version should be in the registry";

        if (s1.dependencyService() != address(0)) return "TestService1 should have no dependency";
        if (s2.dependencyService() != address(s1)) return "TestService2 should have s1 as dependency";
        if (s3.dependencyService() != address(s2)) return "TestService3 should have s2 as dependency";

        // test deploying a lower version
        TestService s2_lower = new TestService([1,0,5], keyService1);
        s2_lower.transferUpgradeOwnership(address(doug));
        if (!doug.deploy(keyService2, address(s2_lower))) return "Deployment of TestService2_lower should succeed despite lower version than the active service";
        if (doug.lookup(keyService2) != address(s2)) return "Active version and location for service 2 should still be s2";
        if (artifactsRegistry.getArtifactByVersion(keyService2, [1,0,5]) != address(s2_lower)) return "s2_lower should have been registered even with lower version";

        // test upgrading services and verify dependency changes
        TestService s2_1 = new TestService([2,2,1], keyService1);
        s2_1.transferUpgradeOwnership(address(doug));
        if (!doug.deploy(keyService2, address(s2_1))) return "Deployment of TestService2_1 should succeed";
        if (doug.lookup(keyService2) != address(s2_1)) return "Active version and location for service 2 should now be s2_1";
        if (s2_1.dependencyService() != address(s1)) return "TestService2_1 should still have s1 as dependency after upgrade due to not actively refreshing";
        if (s3.dependencyService() != address(s2)) return "TestService3 should still have s2 as dependency before refresh";
        s3.refreshDependencies();
        if (s3.dependencyService() != address(s2_1)) return "TestService3 should have s2_1 as dependency after upgrade";

        return SUCCESS;
    }

    function isSameVersion(uint8[3] memory _v1, uint8[3] memory _v2) private pure returns (bool) {
        return _v1[0] == _v2[0] && _v1[1] == _v2[1] && _v1[2] == _v2[2];
    }

}

contract SimpleObject {

}

contract VersionedObject is AbstractVersionedArtifact {

    constructor(uint8[3] memory _v) AbstractVersionedArtifact(_v[0],_v[1],_v[2]) public {

    }


}

contract TestObjectFactory is AbstractObjectFactory, ArtifactsFinderEnabled {

    string objectKey;

    constructor(string memory _objectKey) public {
        objectKey = _objectKey;
    }

    function getCurrentObjectRef() external view returns (address location) {
        (location, ) = artifactsFinder.getArtifact(objectKey);
    }
}
