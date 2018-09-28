pragma solidity ^0.4.23;

import "commons-base/BaseErrors.sol";
import "commons-base/SystemOwned.sol";
import "commons-utils/DataTypes.sol";
import "bpm-model/BpmModel.sol";
import "commons-management/AbstractDbUpgradeable.sol";

import "bpm-runtime/ApplicationRegistry.sol";
import "bpm-runtime/ApplicationRegistryDb.sol";
import "bpm-runtime/DefaultApplicationRegistry.sol";
import "bpm-runtime/Application.sol";

contract ApplicationRegistryTest {

    string constant SUCCESS = "success";
    bytes32 EMPTY = "";

	bytes32 serviceApp1Id = "ServiceApp1";
    bytes32 app1AccessPoint1 = "app1InData";
    bytes32 app1AccessPoint2 = "app1OutData";
	bytes32 serviceApp2Id = "ServiceApp2";

    bytes4 customCompletionFunction = bytes4(keccak256(abi.encodePacked("customComplete(address,bytes32,address)")));

    function testApplicationRegistry() external returns (string) {

        uint error;

        ApplicationRegistry registry = new DefaultApplicationRegistry();
        ApplicationRegistryDb registryDb = new ApplicationRegistryDb();
        SystemOwned(registryDb).transferSystemOwnership(registry);
        AbstractDbUpgradeable(registry).acceptDatabase(registryDb);

        TestApplication app1 = new TestApplication();
        TestApplication app2 = new TestApplication();

        // add applications
        error = registry.addApplication(serviceApp1Id, BpmModel.ApplicationType.SERVICE, app1, bytes4(EMPTY), EMPTY);
        if (error != BaseErrors.NO_ERROR()) return "$1";
        error = registry.addApplication(serviceApp1Id, BpmModel.ApplicationType.SERVICE, app1, bytes4(EMPTY), EMPTY);
        if (error != BaseErrors.RESOURCE_ALREADY_EXISTS()) return "$1";
        error = registry.addApplication(serviceApp2Id, BpmModel.ApplicationType.SERVICE, app2, customCompletionFunction, EMPTY);
        if (error != BaseErrors.NO_ERROR()) return "$1";

        if (registry.getNumberOfApplications() != 2) return "There should be 2 applications registered";

        error = registry.addAccessPoint(serviceApp1Id, app1AccessPoint1, DataTypes.BYTES32(), BpmModel.Direction.IN);
        if (error != BaseErrors.NO_ERROR()) return "$1";
        error = registry.addAccessPoint(serviceApp1Id, app1AccessPoint2, DataTypes.STRING(), BpmModel.Direction.OUT);
        if (error != BaseErrors.NO_ERROR()) return "$1";
        error = registry.addAccessPoint(serviceApp1Id, app1AccessPoint1, DataTypes.UINT(), BpmModel.Direction.IN);
        if (error != BaseErrors.RESOURCE_ALREADY_EXISTS()) return "$1";
        
        if (registry.getNumberOfAccessPoints(serviceApp1Id) != 2) return "Wrong access point count for ServiceApp1";

        uint8 dataType;
        BpmModel.Direction direction;

        (dataType, direction) = registry.getAccessPointData(serviceApp1Id, app1AccessPoint1);
        if (dataType != DataTypes.BYTES32()) return "$1";
        if (direction != BpmModel.Direction.IN) return "$1";

        uint8 myType;
        address location;
        bytes4 method;
        bytes32 webForm;
        uint accessPointCount;

        (myType, location, method, webForm, accessPointCount) = registry.getApplicationData(serviceApp1Id);
        if (myType != uint8(BpmModel.ApplicationType.SERVICE)) return "app1 wrong applicationType";
        if (location != address(app1)) return "app1 wrong location";
        if (method != bytes4(EMPTY)) return "app1 wrong completion function";
        if (webForm != "") return "app1 wrong webForm";
        if (accessPointCount != 2) return "app1 wrong accessPointCount";

        (myType, location, method, webForm, accessPointCount) = registry.getApplicationData(serviceApp2Id);
        if (myType != uint8(BpmModel.ApplicationType.SERVICE)) return "app2 wrong applicationType";
        if (location != address(app2)) return "app2 wrong location";
        if (method != customCompletionFunction) return "app2 wrong completion function";
        if (webForm != "") return "app2 wrong webForm";
        if (accessPointCount != 0) return "app1 wrong accessPointCount";

        return SUCCESS;
    }
    
}

contract TestApplication is Application {

	function complete(bytes32, bytes32, address) public {
	}
}