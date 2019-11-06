pragma solidity ^0.5;

import "commons-base/BaseErrors.sol";

import "commons-utils/TypeUtilsLib.sol";

import "commons-management/ArtifactsRegistry.sol";
import "commons-management/DefaultArtifactsRegistry.sol";
import "commons-management/ObjectProxy.sol";

contract ObjectProxyTest {

    string constant SUCCESS = "success";
    string objectClass = "AN://test-object";

    function testProxyHandling() external returns (string memory) {

        ArtifactsRegistry artifactsRegistry = new DefaultArtifactsRegistry();
        DefaultArtifactsRegistry(address(artifactsRegistry)).initialize(); // this sets the system owner

        ObjectInterface impl1 = new ObjectImplV1();
        ObjectInterface impl2 = new ObjectImplV2();
        uint8[3] memory version = [1,0,0];
        artifactsRegistry.registerArtifact(objectClass, address(impl1), version, true); // Set first active version of impl

        TestObjectProxy object = new TestObjectProxy(address(artifactsRegistry), objectClass);
        if (object.getFinder() != address(artifactsRegistry)) return "The DOUG proxy address should be retrievable in the ObjectProxy";
        if (keccak256(abi.encodePacked(object.getClass())) != keccak256(abi.encodePacked((objectClass)))) return "The object class string should be retrievable in the ObjectProxy";
        if (object.getDelegate() != address(impl1)) return "The ObjectProxy delegate should point to impl1";
        ObjectInterface(address(object)).setNumber(2);
        if (ObjectInterface(address(object)).getNumber() != 2) return "The ObjectProxy should return v1 number initially";

        // change the active implementation version in the registry
        version = [2,2,4];
        artifactsRegistry.registerArtifact(objectClass, address(impl2), version, true);
        if (object.getDelegate() != address(impl2)) return "The ObjectProxy delegate should point to impl2";
        if (ObjectInterface(address(object)).getNumber() != 4) return "The ObjectProxy should return v2 double number after impl upgrade in DOUG";

        return SUCCESS;
    }
}

/**
 * Test contract to expose internal ObjectProxy functions
 */
contract TestObjectProxy is ObjectProxy {

    constructor(address _artifactsFinder, string memory _objectClass) public
        ObjectProxy(_artifactsFinder, _objectClass) {}

    function getFinder() external view returns (address) {
        return getArtifactsFinder();
    }

    function getClass() external view returns (string memory) {
        return getObjectClass();
    }
}

// object interface
contract ObjectInterface {
    function setNumber(uint _v) external;
    function getNumber() external view returns (uint);
}

// object implementation v1
contract ObjectImplV1 is ObjectInterface {

    uint number;

    function setNumber(uint _v) external {
        number = _v;
    }

    function getNumber() external view returns (uint) {
        return number;
    }
}

// overwrites V1 to return double the number
contract ObjectImplV2 is ObjectImplV1 {

    function getNumber() external view returns (uint) {
        return number*2;
    }
}
