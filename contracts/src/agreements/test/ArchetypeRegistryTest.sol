pragma solidity ^0.5;

import "commons-base/SystemOwned.sol";
import "commons-utils/TypeUtilsLib.sol";
import "commons-standards/IsoCountries100.sol";
import "commons-management/AbstractDbUpgradeable.sol";
import "commons-management/ArtifactsRegistry.sol";
import "commons-management/DefaultArtifactsRegistry.sol";

import "agreements/Agreements.sol";
import "agreements/DefaultArchetype.sol";
import "agreements/ArchetypeRegistry.sol";
import "agreements/ArchetypeRegistryDb.sol";
import "agreements/DefaultArchetypeRegistry.sol";

contract ArchetypeRegistryTest {

	string constant SUCCESS = "success";
	bytes32 EMPTY = "";
	string constant functionRegistryAddArchetypeToPackage = "addArchetypeToPackage(bytes32,address)";
	string constant functionRegistryCreateArchetype = "createArchetype(uint256,bool,bool,address,address,address,address,bytes32,address[])";
	string constant functionRegistryCreateArchetypePackage = "createArchetypePackage(address,bool,bool)";
	string constant functionRegistryAddDocument = "addDocument(address,string)";
	string constant functionUpgradeOwnerPermission = "upgradeOwnerPermission(address)";

	IsoCountries100 isoCountries;

	address falseAddress = 0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa;

	string fileReference = "{json grant}";
	bytes32 parameter = "parameter";
	DataTypes.ParameterType parameterType = DataTypes.ParameterType.BOOLEAN;

	address droneArchetype = address(0);
	address droneArchetype2 = address(0);
	bytes32 fakePackageId = "ABC123";
	bytes32 dronePackageId = "";
	bytes32 buildingPackageId = "";
	address packageAuthor = 0xaBAbAbaABAbAbAaBabbbBbBbbAAAaaaaaaaAaAaA;

	address employmentArchetype;
	address ndaArchetype;

	address[] addrArrayWithDupes;
	address[] addrArrayWithoutDupes;
	address[] ndaGovArchetypes;
	address[] emptyArray;

	DefaultArchetype defaultArchetypeImpl = new DefaultArchetype();
	ArtifactsRegistry artifactsRegistry;
	
	constructor (address _isoCountries) public {
		require(_isoCountries != address(0), "The test contract requires an instance of IsoCountries");
		isoCountries = IsoCountries100(_isoCountries);
		// ArtifactsRegistry
		artifactsRegistry = new DefaultArtifactsRegistry();
        DefaultArtifactsRegistry(address(artifactsRegistry)).initialize();
	}

	/**
	 * @dev Creates and returns a new ArchetypeRegistry using an existing ArchetypeRegistry and BpmService.
	 * This function can be used in the beginning of a test to have a fresh BpmService instance.
	 */
	function createNewArchetypeRegistry() internal returns (ArchetypeRegistry) {
		DefaultArchetypeRegistry newRegistry = new DefaultArchetypeRegistry();
		ArchetypeRegistryDb registryDb = new ArchetypeRegistryDb();
		SystemOwned(registryDb).transferSystemOwnership(address(newRegistry));
		AbstractDbUpgradeable(newRegistry).acceptDatabase(address(registryDb));
		newRegistry.setArtifactsFinder(address(artifactsRegistry));
        artifactsRegistry.registerArtifact(newRegistry.OBJECT_CLASS_ARCHETYPE(), address(defaultArchetypeImpl), defaultArchetypeImpl.getArtifactVersion(), true);
		return newRegistry;
	}

	/**
	 * @dev Covers the creation and setup of an archetype
	 */
	function testArchetypeCreation() external returns (string memory) {

		ArchetypeRegistry registry = createNewArchetypeRegistry();
		address archetype;
		uint error;
		bool success;

		// test positive creation first to confirm working function signature
		(success, ) = address(registry).call(abi.encodeWithSignature(functionRegistryCreateArchetype, uint256(0), false, true, falseAddress, falseAddress, falseAddress, falseAddress, EMPTY, emptyArray));
		if (!success) return "Creating an archetype with valid parameters should succeed";

		// test failures
		(success, ) = address(registry).call(abi.encodeWithSignature(functionRegistryCreateArchetype, uint256(0), false, true, address(0), falseAddress, falseAddress, falseAddress, EMPTY, emptyArray));
		if (success) return "Creating archetype with empty author should revert";
		(success, ) = address(registry).call(abi.encodeWithSignature(functionRegistryCreateArchetype, uint256(0), false, true, falseAddress, address(0), falseAddress, falseAddress, EMPTY, emptyArray));
		if (success) return "Creating archetype with empty owner should revert";

		archetype = registry.createArchetype(10, false, true, falseAddress, address(this), falseAddress, falseAddress, EMPTY, addrArrayWithDupes);
		if (archetype == address(0)) return "Archetype address is empty after creation";

		if (registry.getArchetypesSize() != 2) return "There should be 2 archetypes in the registry";
		if (registry.getArchetypeAtIndex(1) != archetype) return "Archetype in registry at index 1 should match last created address";

		Archetype(archetype).activate();
		if (!Archetype(archetype).isActive()) return "Archetype should be active";

		Archetype(archetype).deactivate();
		if (Archetype(archetype).isActive()) return "Archetype should be deactivated";

		if (Archetype(archetype).getAuthor() != falseAddress) return "Archetype author should be returned";
		if (Archetype(archetype).getOwner() != address(this)) return "Archetype owner should be returned";

		// Parameter

		if (registry.addParameter(falseAddress, parameterType, parameter) != BaseErrors.RESOURCE_NOT_FOUND()) return "Adding parameter on non-existent archetype expected to fail with RESOURCE_NOT_FOUND";
		if (registry.addParameter(archetype, parameterType, EMPTY) != BaseErrors.NULL_PARAM_NOT_ALLOWED()) return "Adding parameter with empty name expected to fail with NULL_PARAM_NOT_ALLOWED";
		if (registry.addParameter(archetype, parameterType, parameter) != BaseErrors.NO_ERROR()) return "Adding parameter to archetype failed unexpectedly";
		if (registry.getParametersByArchetypeSize(archetype) != 1) return "Parameters on archetype expected to be 1";
		if (registry.getParameterByArchetypeAtIndex(archetype, 0) != parameter) return "parameter at index 0 does not match";
		(, DataTypes.ParameterType retParameterType) = registry.getParameterByArchetypeData(archetype, parameter);
		if (retParameterType != parameterType) return "parameterType of parameter does not match";

		// Document Attachments

		// First verify that the function signature works
		(success, ) = address(registry).call(abi.encodeWithSignature(functionRegistryAddDocument, archetype, fileReference));
		if (!success) {
			return "Using the addDocument function signature to add a document to a valid archetype should not fail";
		}
		(success, ) = address(registry).call(abi.encodeWithSignature(functionRegistryAddDocument, archetype, fileReference));
		if (success) {
			return "Adding a document with the same file reference twice should revert";
		}
		(success, ) = address(registry).call(abi.encodeWithSignature(functionRegistryAddDocument, falseAddress, fileReference));
		if (success) {
			return "Adding a document to non-existent archetype should revert";
		}
		if (Archetype(archetype).getNumberOfDocuments() != 1) return "Documents on archetype exptected to be 1";
		if (Archetype(archetype).getDocumentKeyAtIndex(0) != keccak256(abi.encodePacked(fileReference))) return "Archetype's document key at index 0 should match the hash of the file reference";

		string memory returnedFileRef;
		returnedFileRef = Archetype(archetype).getDocument(Archetype(archetype).getDocumentKeyAtIndex(0));
		if (keccak256(abi.encodePacked(returnedFileRef)) != keccak256(abi.encodePacked(fileReference))) return "Archetype's 1st document reference should match";

		// Jurisdictions
		bytes32 region = keccak256(abi.encodePacked("CA", "QC"));
		error = registry.addJurisdiction(falseAddress, "CA", region);
		if (error != BaseErrors.RESOURCE_NOT_FOUND()) return "Adding jurisdiction to non-existent archetype should have failed with RESOURCE_NOT_FOUND";
		// test a country/region combination
		error = registry.addJurisdiction(archetype, "CA", region);
		if (error != BaseErrors.NO_ERROR()) return "Adding CAN_QC jurisdiction to archetype failed unexpectedly";
		if (registry.getNumberOfJurisdictionsForArchetype(archetype) != 1) return "Jurisdictions on archetype exptected to be 1";
		if (registry.getJurisdictionAtIndexForArchetype(archetype, 0) != region) return "jurisdiction key at index 0 not returned correctly";
		bytes2 country;
		bytes32 retRegion;
		(country, retRegion) = registry.getJurisdictionDataForArchetype(archetype, region);
		if (country != "CA") return "jurisdiction country not returned correctly for CAN_QC";
		if (retRegion != region) return "jurisdiction region not returned correctly for CAN_QC";
		// test a country-ONLY jurisdiction
		error = registry.addJurisdiction(archetype, "US", EMPTY);
		if (error != BaseErrors.NO_ERROR()) return "Adding USA jurisdiction to archetype failed unexpectedly";
		if (registry.getNumberOfJurisdictionsForArchetype(archetype) != 2) return "Jurisdictions on archetype exptected to be 2";
		if (registry.getJurisdictionAtIndexForArchetype(archetype, 1) != keccak256(abi.encodePacked("US"))) return "jurisdiction key at index 1 not returned correctly";
		(country, retRegion) = registry.getJurisdictionDataForArchetype(archetype, keccak256(abi.encodePacked("US")));
		if (country != "US") return "jurisdiction country not returned correctly for USA";
		if (retRegion != "") return "jurisdiction region not returned correctly for USA";
		// test adding another region for existing country
		region = keccak256(abi.encodePacked("CA", "ON"));
		error = registry.addJurisdiction(archetype, "CA", region);
		if (error != BaseErrors.NO_ERROR()) return "Adding CAN_ON jurisdiction to archetype failed unexpectedly";
		if (registry.getNumberOfJurisdictionsForArchetype(archetype) != 3) return "Jurisdictions on archetype exptected to be 3";
		if (registry.getJurisdictionAtIndexForArchetype(archetype, 2) != region) return "jurisdiction key at index 2 not returned correctly";		
		// test overwriting (cleaning) a country/region with country-ONLY jurisdiction
		error = registry.addJurisdiction(archetype, "CA", EMPTY);
		if (error != BaseErrors.NO_ERROR()) return "Adding CAN jurisdiction country overwrite to archetype failed unexpectedly";

		if (registry.getNumberOfJurisdictionsForArchetype(archetype) != 2) return "Jurisdictions on archetype exptected to be 2 after country overwrite";
		if (registry.getJurisdictionAtIndexForArchetype(archetype, 2) != "") return "jurisdiction key at index 2 should return empty after country overwrite";		
		if (registry.getJurisdictionAtIndexForArchetype(archetype, 1) != keccak256(abi.encodePacked("CA"))) return "jurisdiction key at index 1 should return country hash after country overwrite";

		// test archetype upgrade scenarios < 1.1.0 to retrofit the owner permission
		DefaultArchetype_pre_v1_1_0 upgradeTestArchetype = new DefaultArchetype_pre_v1_1_0();
		upgradeTestArchetype.initialize(99, false, true, falseAddress, falseAddress, falseAddress, falseAddress, emptyArray);
		upgradeTestArchetype.downgrade();
		bool permExists;
		(permExists, , , , ) = upgradeTestArchetype.getPermissionDetails(upgradeTestArchetype.ROLE_ID_OWNER());
		if (permExists) return "The upgrade test archetype should not have the owner permission";
		// test positive permssission setting first to confirm a working function signature
		(success, ) = address(upgradeTestArchetype).call(abi.encodeWithSignature(functionUpgradeOwnerPermission, address(this)));
		if (!success) return "Upgrading the owner permission and setting it to the test contract should be successful";

		(permExists, , , , ) = upgradeTestArchetype.getPermissionDetails(upgradeTestArchetype.ROLE_ID_OWNER());
		if (!permExists) return "The owner permission should have been created in the upgrade";
		if (upgradeTestArchetype.getHolder(upgradeTestArchetype.ROLE_ID_OWNER(), 0) != address(this)) return "The upgrade test archetype should show the test contract as the owner after the upgrade";

		// test upgrade failures
		(success, ) = address(upgradeTestArchetype).call(abi.encodeWithSignature(functionUpgradeOwnerPermission, address(this)));
		if (success) return "Upgrading an already upgraded archetype should revert";

		// create a fresh archetype
		upgradeTestArchetype = new DefaultArchetype_pre_v1_1_0();
		upgradeTestArchetype.initialize(99, false, true, falseAddress, falseAddress, falseAddress, falseAddress, emptyArray);
		upgradeTestArchetype.downgrade();
		(success, ) = address(archetype).call(abi.encodeWithSignature(functionUpgradeOwnerPermission, address(0)));
		if (success) return "Upgrading the owner permission and setting it to 0x0 should revert";

		return SUCCESS;
	}

	function testArchetypeSuccessor() external returns (string memory) {

		ArchetypeRegistry registry = createNewArchetypeRegistry();

		address successor;

		droneArchetype = registry.createArchetype(10, false, true, falseAddress, address(this), falseAddress, falseAddress, EMPTY, addrArrayWithDupes);
		if (droneArchetype == address(0)) return "droneArchetype address empty after creation";

		droneArchetype2 = registry.createArchetype(10, false, true, falseAddress, falseAddress, falseAddress, falseAddress, EMPTY, addrArrayWithDupes);
		if (droneArchetype2 == address(0)) return "droneArchetype2 address empty after creation";

		Archetype(droneArchetype).setSuccessor(droneArchetype2);

		successor = registry.getArchetypeSuccessor(droneArchetype);
		if (successor != droneArchetype2) return "Successor of droneArchetype is not set to droneArchetype2";
		if (Archetype(droneArchetype).isActive()) return "droneArchetype is still active even with successor set";

		return SUCCESS;
	}

	function testArchetypePackages() external returns (string memory) {

		ArchetypeRegistry registry = createNewArchetypeRegistry();

		uint error;
		bool active;
		bool success;
	
		(success, ) = address(registry).call(abi.encodeWithSignature(functionRegistryCreateArchetypePackage, address(0), fakePackageId, droneArchetype));
		if (success)
			return "Creating an archetype package with an empty author should revert";

		droneArchetype = registry.createArchetype(10, false, true, falseAddress, falseAddress, falseAddress, falseAddress, EMPTY, addrArrayWithDupes);
		if (droneArchetype == address(0)) return "droneArchetype address empty after creation";

		(success, ) = address(registry).call(abi.encodeWithSignature(functionRegistryAddArchetypeToPackage, fakePackageId, droneArchetype));
		if (success) {
			return "Adding an archetype to a non-existent package ID should revert";
		}

		(error, dronePackageId) = registry.createArchetypePackage(packageAuthor, true, true);
		if (error != BaseErrors.NO_ERROR()) return "It should create a new package";
		if (dronePackageId == "") return "Package id should not be empty";

		registry.deactivatePackage(dronePackageId, packageAuthor);
		( , , active) = registry.getArchetypePackageData(dronePackageId);
		if (active) return "dronePackage should be inactive";

		registry.activatePackage(dronePackageId, packageAuthor);
		( , , active) = registry.getArchetypePackageData(dronePackageId);
		if (!active) return "dronePackage should be active";

		(error, buildingPackageId) = registry.createArchetypePackage(packageAuthor, false, true);
		if (error != BaseErrors.NO_ERROR()) return "It should create a new package";
		if (buildingPackageId == "") return "Package id should not be empty";

		if (registry.getNumberOfArchetypePackages() != 2) return "Registry should have 2 packages";

		registry.addArchetypeToPackage(dronePackageId, droneArchetype);

		if (registry.getNumberOfArchetypesInPackage(dronePackageId) != 1) return "Drone package should have 1 archetype";
		if (registry.getArchetypeAtIndexInPackage(dronePackageId, 0) != droneArchetype) return "Archetype at index 0 should match droneArchetype";

		droneArchetype2 = registry.createArchetype(10, false, true, falseAddress, falseAddress, falseAddress, falseAddress, dronePackageId, addrArrayWithDupes);

		if (registry.getNumberOfArchetypesInPackage(dronePackageId) != 2) return "Drone package should have 2 archetypes";
		if (registry.getArchetypeAtIndexInPackage(dronePackageId, 1) != droneArchetype2) return "Archetype at index 1 should match droneArchetype2";

		return SUCCESS;
	}

	function testGoverningArchetypes() external returns (string memory) {

		bool success;
		ArchetypeRegistry registry = createNewArchetypeRegistry();

		address archetype;

		archetype = registry.createArchetype(10, false, true, falseAddress, falseAddress, falseAddress, falseAddress, EMPTY, emptyArray);
		addrArrayWithDupes.push(archetype);
		archetype = registry.createArchetype(10, false, true, falseAddress, falseAddress, falseAddress, falseAddress, EMPTY, emptyArray);
		addrArrayWithDupes.push(archetype);
		addrArrayWithDupes.push(archetype); // duplicate
		archetype = registry.createArchetype(10, false, true, falseAddress, falseAddress, falseAddress, falseAddress, EMPTY, emptyArray);
		addrArrayWithDupes.push(archetype);
		archetype = registry.createArchetype(10, false, true, falseAddress, falseAddress, falseAddress, falseAddress, EMPTY, emptyArray);
		addrArrayWithDupes.push(archetype);
		
		(success, ) = address(registry).call(abi.encodeWithSignature(functionRegistryCreateArchetype, uint256(0), false, true, address(this), falseAddress, falseAddress, EMPTY, addrArrayWithDupes));
		if (success)
			return "Creating archetype with duplicate governing archetypes should revert";

		archetype = registry.createArchetype(10, false, true, falseAddress, falseAddress, falseAddress, falseAddress, EMPTY, emptyArray);
		addrArrayWithoutDupes.push(archetype);
		archetype = registry.createArchetype(10, false, true, falseAddress, falseAddress, falseAddress, falseAddress, EMPTY, emptyArray);
		addrArrayWithoutDupes.push(archetype);
		archetype = registry.createArchetype(10, false, true, falseAddress, falseAddress, falseAddress, falseAddress, EMPTY, addrArrayWithoutDupes);
		if (archetype == address(0)) return "Archetype with no duplicate gov archetypes has no address";

		// Create employment archetype
		employmentArchetype = registry.createArchetype(10, false, true, falseAddress, falseAddress, falseAddress, falseAddress, EMPTY, ndaGovArchetypes);
		if (archetype == address(0)) return "Employment archetype created with no errors, but empty address returned";

		ndaGovArchetypes.push(employmentArchetype);

		// Create NDA Archetype with employment archetype as its governing archetype
		ndaArchetype = registry.createArchetype(10, false, true, falseAddress, falseAddress, falseAddress, falseAddress, EMPTY, ndaGovArchetypes);
		if (archetype == address(0)) return "NDA archetype creation returned empty address";

		if (registry.getNumberOfGoverningArchetypes(ndaArchetype) != 1) return "ndaArchetype should have 1 governing archetype";
		if (registry.getGoverningArchetypeAtIndex(ndaArchetype, 0) != employmentArchetype) return "ndaArchetype's governing archetype should be set to employmentArchetype";
		
		return SUCCESS;
	}
}

/**
 * @dev This contract simulates the < v1.1.0 version of the contract which did not have the owner permission
 */
contract DefaultArchetype_pre_v1_1_0 is DefaultArchetype {

	function downgrade() external {
		delete permissions[ROLE_ID_OWNER];
	}

}
