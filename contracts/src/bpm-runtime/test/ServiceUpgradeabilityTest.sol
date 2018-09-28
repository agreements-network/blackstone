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

contract ServiceUpgradeabilityTest {

	string constant SUCCESS = "success";
	bytes32 EMPTY = "";

	bytes32 serviceApp1Id = "ServiceApp1";
	bytes32 serviceApp2Id = "ServiceApp2";

	bytes4 customCompletionFunction = bytes4(keccak256(abi.encodePacked("customComplete(address,bytes32,address)")));

	function testServiceUpgradeability() external returns (string) {

			uint error;

			ApplicationRegistry registryV1 = new DefaultApplicationRegistry();
			ApplicationRegistryDb registryDb = new ApplicationRegistryDb();
			SystemOwned(registryDb).transferSystemOwnership(registryV1);
			AbstractDbUpgradeable(registryV1).acceptDatabase(registryDb);

			TestApplication app1 = new TestApplication();
			TestApplication app2 = new TestApplication();

			error = registryV1.addApplication(serviceApp1Id, BpmModel.ApplicationType.SERVICE, app1, bytes4(EMPTY), EMPTY);
			if (error != BaseErrors.NO_ERROR()) return "$1";
			error = registryV1.addApplication(serviceApp2Id, BpmModel.ApplicationType.SERVICE, app2, customCompletionFunction, EMPTY);
			if (error != BaseErrors.NO_ERROR()) return "$1";
			if (registryV1.getNumberOfApplications() != 2) return "$1";

			ApplicationRegistry registryV2 = new  DefaultApplicationRegistry();
			if (!AbstractDbUpgradeable(registryV1).migrateTo(registryV2)) return "$1";
			if (registryV2.getNumberOfApplications() != 2) return "$1";
			if (registryDb.getSystemOwner() != address(registryV2)) return "$1";

			return SUCCESS;
	}
}

contract TestApplication is Application {
	function complete(bytes32, bytes32, address) public {
	}
}