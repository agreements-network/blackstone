pragma solidity ^0.5;

import "commons-base/ErrorsLib.sol";
import "commons-base/Versioned.sol";
import "commons-base/Owned.sol";
import "commons-base/SystemOwned.sol";
import "commons-base/StorageDefOwner.sol";
import "commons-standards/ERC165Utils.sol";

import "commons-management/StorageDefProxied.sol";
import "commons-management/StorageDefRegistry.sol";
import "commons-management/DOUG.sol";
import "commons-management/VersionedArtifact.sol";
import "commons-management/ArtifactsRegistry.sol";
import "commons-management/ArtifactsFinderEnabled.sol";
import "commons-management/UpgradeOwned.sol";
import "commons-management/Upgradeable.sol";

/**
 * @title DefaultDoug
 * @dev Standard DOUG implementation.
 * NOTE: This contract is intended to by used in conjunction with a DougProxy.
 * Therefore, the order of storage variables _must_ match the one in the DougProxy. This is
 * partly achieved by using the same StorageDef* contracts as a basis.
 */
contract DefaultDoug is StorageDefProxied, StorageDefOwner, StorageDefRegistry, Owned, DOUG {

	/**
	 * @dev Creates a new DefaultDoug with the msg.sender set to be the owner
	 */
	constructor () public {
		owner = msg.sender;
	}

	/**
     * @dev Registers the contract with the given address under the specified ID and performs a deployment
     * procedure which involves dependency injection and upgrades from previously deployed contracts with
     * the same ID.
	 * This function is a convenience wrapper around the #deployVersion(string,address,uint8[3]) function.
	 * If the contract implements VersionedArtifact, that version will be used for registration, otherwise the contract
	 * will get registered with version 0.0.0.
     * @param _id the ID under which to register the contract
     * @param _address the address of the contract
     * @return true if successful, false otherwise
	 */
    function deploy(string calldata _id, address _address) external pre_onlyByOwner returns (bool success) {
		return deployVersion(_id, _address, [0,0,0]);
	}

	/**
     * @dev Registers the contract with the given address under the specified ID and performs a deployment
     * procedure which involves dependency injection and upgrades from previously deployed contracts with
     * the same ID.
	 * Note that if the contract implements VersionedArtifact, that version will be used for registration and
	 * the provided version will be ignored!
	 * If the given contract implements ArtifactsFinderEnabled, it will be passed an instance of the ArtifactsRegistry, so that
	 * it can perform dependency lookups and register for changes.
	 * If the contract implements Upgradeable and it replaces an existing active version of the same ID that is also Upgradeable,
	 * the upgrade function will be invoked.
	 * REVERTS if:
	 * - the provided contract is Upgradeable, but this DOUG contract is not the upgradeOwner
	 * - a contract with the same ID is being replaced, but the upgrade between predecessor and successor failed (see Upgradeable.upgrade(address))
     * @param _id the ID under which to register the contract
     * @param _address the address of the contract
     * @return true if successful, false otherwise
	 */
    function deployVersion(string memory _id, address _address, uint8[3] memory _version) public pre_onlyByOwner returns (bool success) {
        ErrorsLib.revertIf(bytes(_id).length == 0 || _address == address(0),
            ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultDoug.deployVersion", "_id and _address must not be empty");

		// For VersionedArtifact contracts we enforce using that version over the provided one
		uint8[3] memory version = ERC165Utils.implementsInterface(_address, getERC165IdVersionedArtifact()) ?
			VersionedArtifact(_address).getArtifactVersion() : _version;

		// Upgradeable contracts need to relinquish upgrade ownership to this contract
		if (ERC165Utils.implementsInterface(_address, getERC165IdUpgradeable())) {
			ErrorsLib.revertIf(UpgradeOwned(_address).getUpgradeOwner() != address(this),
				ErrorsLib.INVALID_PARAMETER_STATE(), "DefaultDoug.deploy", "DOUG must be upgradeOwner of the provided contract");
		}

        // setting ArtifactsFinder
        if (ERC165Utils.implementsInterface(_address, getERC165ArtifactsFinderEnabled())) {
            ArtifactsFinderEnabled(_address).setArtifactsFinder(registry);
        }

		(address existingActiveLocation, uint8[3] memory existingActiveVersion) = ArtifactsRegistry(registry).getArtifact(_id);
		// artifacts are automatically activated, if they're a new deployment or higher than an existing version
		bool activateArtifact = existingActiveLocation == address(0) ||
								(existingActiveLocation != _address && compareVersions(existingActiveVersion, version) > 0);

		// to trigger an automatic upgrade procedure, both contracts must be Upgradeable, VersionedArtifact contracts
		// and the version being deployed must be higher.
		if (existingActiveLocation != address(0) &&
			isHigherArtifactVersion(existingActiveLocation, _address) &&
			ERC165Utils.implementsInterface(existingActiveLocation, getERC165IdUpgradeable()) &&
			ERC165Utils.implementsInterface(_address, getERC165IdUpgradeable()))
		{
			ErrorsLib.revertIf(!Upgradeable(existingActiveLocation).upgrade(_address),
				ErrorsLib.INVALID_STATE(), "DefaultDoug.deploy", "Automatic upgrade from an existing contract with the same ID and lower version failed.");
		}

		ArtifactsRegistry(registry).registerArtifact(_id, _address, version, activateArtifact);
		success = true;
	}

    /**
     * @dev Registers the contract with the given address under the specified ID in DOUG's ArtifactsRegistry.
	 * This function is a convenience wrapper around the #registerVersion(string,address,uint8[3]) function.
	 * If the contract implements VersionedArtifact, that version will be used for registration, otherwise the contract
	 * will get registered with version 0.0.0.
     * @param _id the ID under which to register the contract
     * @param _address the address of the contract
	 * @return version - the version under which the contract was registered.
     */
    function register(string calldata _id, address _address) external pre_onlyByOwner returns (uint8[3] memory version) {
		return registerVersion(_id, _address, [0,0,0]);
	}

    /**
     * @dev Registers the contract with the given address under the specified ID in DOUG's ArtifactsRegistry.
	 * Note that if the contract implements VersionedArtifact, that version will be used for registration and
	 * the provided version will be ignored!
	 * REVERTS if:
	 * - the ArtifactRegistry rejects the artifact, most commonly because an artifact with the same ID
	 * and version, but a different address is already registered.
     * @param _id the ID under which to register the contract
     * @param _address the address of the contract
	 * @return version - the version under which the contract was registered.
     */
    function registerVersion(string memory _id, address _address, uint8[3] memory _version) public pre_onlyByOwner returns (uint8[3] memory version) {
        ErrorsLib.revertIf(bytes(_id).length == 0 || _address == address(0),
            ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultDoug.registerVersion", "_id and _address must not be empty");

		// For VersionedArtifact contracts we enforce using that version over the provided one
		version = ERC165Utils.implementsInterface(_address, getERC165IdVersionedArtifact()) ?
			VersionedArtifact(_address).getArtifactVersion() : _version;

		(address existingActiveLocation, uint8[3] memory existingActiveVersion) = ArtifactsRegistry(registry).getArtifact(_id);
		// artifacts are automatically activated, if they're a new deployment or higher than an existing version
		bool activateArtifact = existingActiveLocation == address(0) ||
								(existingActiveLocation != _address && compareVersions(existingActiveVersion, version) > 0);

		ArtifactsRegistry(registry).registerArtifact(_id, _address, version, activateArtifact);
	}

    /**
     * @dev Returns the address of the active version of a contract registered under the given ID.
	 * If a specific (or non-active) version of a registered contract needs to be retrieved, please use
	 * #getArtifactsRegistry().getArtifactVersion(string,uint8[3])
     * @param _id the ID under which the contract is registered
     * @return the contract's address of 0x0 if no active version for the given ID is registered.
     */
    function lookup(string calldata _id) external view returns (address contractAddress) {
		(contractAddress, ) = ArtifactsRegistry(registry).getArtifact(_id);
	}

    /**
     * @dev Returns the address of the active version of a contract registered under the given ID.
	 * If a specific (or non-active) version of a registered contract needs to be retrieved, please use
	 * #getArtifactsRegistry().getArtifactVersion(string,uint8[3])
     * @param _id the ID under which the contract is registered
     * @return the contract's address of 0x0 if no active version for the given ID is registered.
     */
    function lookupVersion(string calldata _id, uint8[3] calldata _version) external view returns (address contractAddress) {
		contractAddress = ArtifactsRegistry(registry).getArtifactByVersion(_id, _version);
	}

	/**
	 * @dev Returns the address of the ArtifactsRegistry used in this DefaultDoug
	 * @return the address of the ArtifactsRegistry
	 */
	function getArtifactsRegistry() external view returns (address) {
		return registry;
	}

	/**
	 * @dev Sets the given address to be this DOUG's ArtifactsRegistry.
	 * REVERTS if:
	 * - the ArtifactsRegistry is not a SystemOwned contract or if the system owner is not set to this DOUG.
	 * @param _artifactsRegistry the address of an ArtifactsRegistry contract
	 */
	function setArtifactsRegistry(address _artifactsRegistry) external pre_onlyByOwner {
		ErrorsLib.revertIf(SystemOwned(_artifactsRegistry).getSystemOwner() != address(this),
	    	ErrorsLib.INVALID_PARAMETER_STATE(), "DefaultDoug.setArtifactsRegistry", "DOUG must be the system owner of the ArtifactsRegistry");
		registry = _artifactsRegistry;
	}

	/**
	 * @dev Returns true if both address are VersionedArtifact contracts and the successor version is higher than the existing
	 */
	function isHigherArtifactVersion(address existing, address successor) private returns (bool) {
		return ERC165Utils.implementsInterface(existing, getERC165IdVersionedArtifact()) &&
			   ERC165Utils.implementsInterface(successor, getERC165IdVersionedArtifact()) &&
			   VersionedArtifact(existing).compareArtifactVersion(successor) > 0;
	}

    /**
     * @dev Compares the two specified versions.
     *
     * @param _a version A
     * @param _b version B
     * @return 0 (equal), -1 (B version is lower), or 1 (B version is higher).
     * //TODO move to a math library
     */
	function compareVersions(uint8[3] memory _a, uint8[3] memory _b) private pure returns (int result) {
        result = compareUint8Values(_a[0], _b[0]);
        if (result != 0) { return result; }
        result = compareUint8Values(_a[1], _b[1]);
        if (result != 0) { return result; }
        result = compareUint8Values(_a[2], _b[2]);
	}
	
    /**
     * @dev returns 0 (equal), -1 (b is lower), or 1 (b is higher).
     * //TODO move to a math library
     */
    function compareUint8Values(uint8 _a, uint8 _b) private pure returns (int) {
        if (_b == _a) { return 0; }
        else if (_b < _a) { return -1; }
        else { return 1; }
    }

	/**
	 * @dev Internal pure function to return the ERC165 ID for the Upgreadable interface
	 * This avoids storing and initializing the ID as a field in this contract which would not be usable in a proxied scenario.
	 */
	function getERC165IdUpgradeable() private pure returns (bytes4) {
		return bytes4(keccak256(abi.encodePacked("upgrade(address)")));
	}

	/**
	 * @dev Internal pure function to return the ERC165 ID for the ArtifactVersioned interface
	 * This avoids storing and initializing the ID as a field in this contract which would not be usable in a proxied scenario.
	 */
	function getERC165IdVersionedArtifact() private pure returns (bytes4) {
		return bytes4(keccak256(abi.encodePacked("getArtifactVersion()")));
	}

	/**
	 * @dev Internal pure function to return the ERC165 ID for the ArtifactsFinderEnabled interface
	 * This avoids storing and initializing the ID as a field in this contract which would not be usable in a proxied scenario.
	 */
	function getERC165ArtifactsFinderEnabled() private pure returns (bytes4) {
		return bytes4(keccak256(abi.encodePacked("setArtifactsFinder(address)")));
	}

}