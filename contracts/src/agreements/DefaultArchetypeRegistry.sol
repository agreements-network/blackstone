pragma solidity ^0.5;

import "commons-base/BaseErrors.sol";
import "commons-base/ErrorsLib.sol";
import "commons-collections/Mappings.sol";
import "commons-collections/MappingsLib.sol";
import "commons-management/ArtifactsFinder.sol";
import "commons-management/ArtifactsFinderEnabled.sol";
import "commons-management/AbstractDbUpgradeable.sol";
import "commons-management/AbstractObjectFactory.sol";
import "commons-management/ObjectProxy.sol";
import "bpm-model/ProcessDefinition.sol";

import "agreements/ArchetypeRegistry.sol";
import "agreements/ArchetypeRegistryDb.sol";
import "agreements/DefaultArchetype.sol";
import "agreements/Agreements.sol";

/**
 * @title DefaultArchetypeRegistry
 * @dev Creates and tracks archetypes
 */
contract DefaultArchetypeRegistry is AbstractVersionedArtifact(1,1,1), AbstractObjectFactory, ArtifactsFinderEnabled, AbstractDbUpgradeable, ArchetypeRegistry {
	
	/**
	 * @dev Creates a new archetype
	 * REVERTS if:
	 * - if archetype initialization fails
4	 * @param _price price
	 * @param _isPrivate determines if the archetype's documents are encrypted
	 * @param _active determines if this archetype is active
	 * @param _author author
	 * @param _owner owner
	 * @param _formationProcess the address of a ProcessDefinition that orchestrates the agreement formation
	 * @param _executionProcess the address of a ProcessDefinition that orchestrates the agreement execution
	 * @param _packageId id of package this archetype is part of (optional)
	 * @param _governingArchetypes array of archetype addresses which govern this archetype (optional)
	 * @return archetype - the new archetype's address, if successfully created
	 */
	function createArchetype(
		uint _price, 
		bool _isPrivate, 
		bool _active, 
		address _author,
		address _owner,
		address _formationProcess, 
		address _executionProcess, 
		bytes32 _packageId, 
		address[] calldata _governingArchetypes) 
		external
		returns (address archetype)
	{
		ErrorsLib.revertIf(_author == address(0),
			ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultArchetypeRegistry.createArchetype", "Archetype author address must not be empty");
		archetype = address(new ObjectProxy(address(artifactsFinder), OBJECT_CLASS_ARCHETYPE));
		Archetype(archetype).initialize(_price, _isPrivate, _active, _author, _owner, _formationProcess, _executionProcess, _governingArchetypes);
		// since this is a newly created archetype address, we can safely ignore the return value of the DB.addArchetype() function
		ArchetypeRegistryDb(database).addArchetype(archetype);
		if (_packageId != "")
			addArchetypeToPackage(_packageId, archetype);
	}

	/**
	 * @dev Adds archetype to package
	 * @param _packageId the bytes32 package id
	 * @param _archetype the archetype address
	 * Reverts if package is not found
	 */
	function addArchetypeToPackage(bytes32 _packageId, address _archetype) public {
		uint error = ArchetypeRegistryDb(database).addArchetypeToPackage(_packageId, _archetype);
		ErrorsLib.revertIf(error != BaseErrors.NO_ERROR(),
			ErrorsLib.RESOURCE_NOT_FOUND(), "DefaultArchetypeRegistry.addArchetypeToPackage", "Specified package not found");
		emit LogArchetypeToPackageUpdate(
			EVENT_ID_ARCHETYPE_PACKAGE_MAP,
			_packageId,
			_archetype
		);
	}

	/**
	 * @dev Adds parameter to archetype
	 * @param _archetype the archetype address
	 * @param _parameterType data type (enum)
	 * @param _parameterName the parameter name
	 * @return BaseErrors.NO_ERROR() if successful
	 * @return BaseErrors.RESOURCE_NOT_FOUND() if archetype is not found
	 * @return any error returned from the Archetype.addParameter() function
	 */
	function addParameter(address _archetype, DataTypes.ParameterType _parameterType, bytes32 _parameterName) public returns (uint error) {
		uint position;
		if (!ArchetypeRegistryDb(database).archetypeExists(_archetype))
			return BaseErrors.RESOURCE_NOT_FOUND();
		(error, position) = Archetype(_archetype).addParameter(_parameterType, _parameterName);
	}

	/**
	 * @dev Adds the specified parameters to the archetype. If one of the parameters cannot be added, the operation aborts and returns that error code.
	 * @param _archetype the archetype address
	 * @param _parameterTypes the parameter types
	 * @param _parameterNames the parameter names
	 * @return BaseErrors.NO_ERROR() if succesful
	 * @return BaseErrors.RESOURCE_NOT_FOUND() if archetype is not found
	 * @return BaseErrors.INVALID_PARAM_STATE() if the lengths of the two arrays don't match
	 */
	function addParameters(address _archetype, DataTypes.ParameterType[] calldata _parameterTypes, bytes32[] calldata _parameterNames) external returns (uint error) {
		if (_parameterTypes.length != _parameterNames.length)
			return BaseErrors.INVALID_PARAM_STATE();
		for (uint i=0; i<_parameterTypes.length; i++) {
			error = addParameter(_archetype, _parameterTypes[i], _parameterNames[i]);
			if (error != BaseErrors.NO_ERROR())
				return (error);
		}
		return BaseErrors.NO_ERROR();
	}

	/**
	 * @dev Adds the given jurisdiction in the form of a country code and region identifier to this archetype.
	 * References codes defined via IsoCountries interface implementations.
	 * @param _country a ISO-3166-1 code, e.g. 'US'
	 * @param _region a region identifier from a IsoCountries contract
	 * @return BaseErrors.NO_ERROR() if succesful
	 * @return BaseErrors.RESOURCE_NOT_FOUND() if archetype is not found
	 * @return any error returned from the Archetype.addJurisdiction() function
	 */
	function addJurisdiction(address _archetype, bytes2 _country, bytes32 _region) public returns (uint error) {
		if (!ArchetypeRegistryDb(database).archetypeExists(_archetype))
			return BaseErrors.RESOURCE_NOT_FOUND();
		bytes32 key;
		(error, key) = Archetype(_archetype).addJurisdiction(_country, _region);
	}

	/**
	 * @dev Adds the given jurisdictions in the form of a country codes and region identifiers to this archetype.
	 * References codes defined via IsoCountries interface implementations.
	 * @param _countries an array of a ISO-3166-1 code, e.g. 'US'
	 * @param _regions an array of region identifiers from a IsoCountries contract
	 * @return BaseErrors.NO_ERROR() if succesful
	 * @return BaseErrors.RESOURCE_NOT_FOUND() if archetype is not found
	 * @return BaseErrors.INVALID_PARAM_STATE() if the lengths of the two arrays don't match
	 */
	function addJurisdictions(address _archetype, bytes2[] calldata _countries, bytes32[] calldata _regions) external returns (uint error) {
		if (_countries.length != _regions.length)
			return BaseErrors.INVALID_PARAM_STATE();
		for (uint i=0; i<_countries.length; i++) {
			error = addJurisdiction(_archetype, _countries[i], _regions[i]);
			if (error != BaseErrors.NO_ERROR())
				return (error);
		}
		return BaseErrors.NO_ERROR();
	}

	/**
	 * @dev Returns archetype successor
	 * @param _archetype address of archetype
	 * @return address address of successor
	 */
	function getArchetypeSuccessor(address _archetype) external view returns (address) {
		ErrorsLib.revertIf(_archetype == address(0), ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultArchetypeRegistry.getArchetypeSuccessor", "Archetype address must be supplied");
		return Archetype(_archetype).getSuccessor();
	}

	/**
		* @dev Gets number of archetypes
		* @return size size
		*/
	function getArchetypesSize() external view returns (uint size) {
			return ArchetypeRegistryDb(database).getNumberOfArchetypes();
	}

	/**
		* @dev Gets archetype address at given index
		* @param _index index
		* @return archetype archetype
		*/
	function getArchetypeAtIndex(uint _index) external view returns (address archetype) {
		uint error;
		(error, archetype) = ArchetypeRegistryDb(database).getArchetypeAtIndex(_index);
	}

  /**
    * @dev Returns data about an archetype
		* @param _archetype the archetype address
		* @return price price
		* @return author author address
		* @return active bool
		* @return isPrivate bool
		* @return successor address
		* @return formationProcessDefinition
		* @return executionProcessDefinition
		*/
	function getArchetypeData(address _archetype) external view returns (
		uint price,
		address author,
		address owner,
		bool active,
		bool isPrivate,
		address successor,
		address formationProcessDefinition,
		address executionProcessDefinition
	) {
		if (ArchetypeRegistryDb(database).archetypeExists(_archetype)) {
			price = Archetype(_archetype).getPrice();
			author = Archetype(_archetype).getAuthor();
			owner = Archetype(_archetype).getOwner();
			active = Archetype(_archetype).isActive();
			isPrivate = Archetype(_archetype).isPrivate();
			successor = Archetype(_archetype).getSuccessor();
			formationProcessDefinition = Archetype(_archetype).getFormationProcessDefinition();
			executionProcessDefinition = Archetype(_archetype).getExecutionProcessDefinition();
		}
	}

	/**
	 * @dev Adds a file reference to the given Archetype
	 * REVERTS if:
	 * - the given archetype is not registered in this ArchetypeRegistry
	 * @param _archetype archetype
	 * @param _fileReference the external reference to the document
	 */
	function addDocument(address _archetype, string calldata _fileReference) external {
		ErrorsLib.revertIf(!ArchetypeRegistryDb(database).archetypeExists(_archetype),
			ErrorsLib.RESOURCE_NOT_FOUND(), "DefaultArchetypeRegistry.addDocument", "The specified archetype address is not known to this ArchetypeRegistry");
		Archetype(_archetype).addDocument(_fileReference);
	}

	/**
	 * @dev Sets price of given archetype
	 * @param _archetype archetype
	 * @param _price price
	 */
	function setArchetypePrice(address _archetype, uint _price) external {
		Archetype(_archetype).setPrice(_price);
	}

	/**
	 * @dev Adds a new archetype package
	 * @param _author address of author (user account of organization)
	 * @param _isPrivate makes it a private package visible to only the author
	 * @param _active makes it a inactive package
	 * @return error BaseErrors.NO_ERROR(), BaseErrors.NULL_PARAM_NOT_ALLOWED(), BaseErrors.RESOURCE_ALREADY_EXISTS()
	 * @return id bytes32 id of package
	 */
	function createArchetypePackage(address _author, bool _isPrivate, bool _active) external returns (uint error, bytes32 id) {
		ErrorsLib.revertIf(_author == address(0),
			ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultArchetypeRegistry.createArchetypePackage", "Package author must not be empty");
		id = keccak256(abi.encodePacked(ArchetypeRegistryDb(database).getNumberOfPackages(), _author, block.timestamp));
		error = ArchetypeRegistryDb(database).createPackage(id, _author, _isPrivate, _active);
		ErrorsLib.revertIf(error != BaseErrors.NO_ERROR(),
			ErrorsLib.INVALID_STATE(), "DefaultArchetypeRegistry.createArchetypePackage", "A package with the same ID already exists");
		emit LogArchetypePackageCreation(EVENT_ID_ARCHETYPE_PACKAGES, id, _author, _isPrivate, _active);
	}

	/**
	 * @dev Sets active to true for given archetype package
	 * @param _id bytes32 id of archetype package
	 * @param _author address of author (must match the author of the archetype package in order to activate)
	 */
	function activatePackage(bytes32 _id, address _author) external {
		ErrorsLib.revertIf(!ArchetypeRegistryDb(database).packageExists(_id),
			ErrorsLib.RESOURCE_NOT_FOUND(), "DefaultArchetypeRegistry.activatePackage", "Package with given id not found");
		address packageAuthor;
		(packageAuthor, , ) = ArchetypeRegistryDb(database).getPackageData(_id);
		ErrorsLib.revertIf(_author != packageAuthor,
			ErrorsLib.UNAUTHORIZED(), "DefaultArchetypeRegistry.activatePackage", "Given address is not authorized to activate archetype package");
		ArchetypeRegistryDb(database).activatePackage(_id);
		emit LogArchetypePackageActivation(EVENT_ID_ARCHETYPE_PACKAGES, _id, true);
	}

	/**
	 * @dev Sets active to false for given archetype package
	 * @param _id bytes32 id of archetype package
	 * @param _author address of author (must match the author of the archetype package in order to deactivate)
	 */
	function deactivatePackage(bytes32 _id, address _author) external {
		ErrorsLib.revertIf(!ArchetypeRegistryDb(database).packageExists(_id),
			ErrorsLib.RESOURCE_NOT_FOUND(), "DefaultArchetypeRegistry.activatePackage", "Package with given id not found");
		address packageAuthor;
		(packageAuthor, , ) = ArchetypeRegistryDb(database).getPackageData(_id);
		ErrorsLib.revertIf(_author != packageAuthor,
			ErrorsLib.UNAUTHORIZED(), "DefaultArchetypeRegistry.activatePackage", "Given address is not authorized to deactivate archetype package");
		ArchetypeRegistryDb(database).deactivatePackage(_id);
		emit LogArchetypePackageActivation(EVENT_ID_ARCHETYPE_PACKAGES, _id, false);
	}

	/**
	 * @dev Gets number of archetype packages
	 * @return size size
	 */
	function getNumberOfArchetypePackages() external view returns (uint size) {
		return ArchetypeRegistryDb(database).getNumberOfPackages();
	}

	/**
	 * @dev Gets package id at index
	 * @param _index uint index
	 * @return id bytes32 id
	 */
	function getArchetypePackageAtIndex(uint _index) external view returns (bytes32 id) {
		return ArchetypeRegistryDb(database).getPackageAtIndex(_index);
	}

	/**
	 * @dev Gets package data by id
	 * @param _id bytes32 package id
	 * @return author address
	 * @return isPrivate bool
	 * @return active bool
	 */
	function getArchetypePackageData(bytes32 _id) external view returns (address author, bool isPrivate, bool active) {
		return ArchetypeRegistryDb(database).getPackageData(_id);
	}

	/**
	 * @dev Gets number of archetypes in given package
	 * @param _id id of the package
	 * @return size archetype count
	 */
	function getNumberOfArchetypesInPackage(bytes32 _id) external view returns (uint size) {
		return ArchetypeRegistryDb(database).getNumberOfArchetypesInPackage(_id);
	}

	/**
	 * @dev Gets archetype address at index in package
	 * @param _id id of the package
	 * @param _index uint index
	 * @return archetype address of archetype
	 */
	function getArchetypeAtIndexInPackage(bytes32 _id, uint _index) external view returns (address archetype) {
		return ArchetypeRegistryDb(database).getArchetypeAtIndexInPackage(_id, _index);
	}

	/**
	 * @dev Determines whether given archetype address is in the package identified by the packageId
	 * @param _packageId id of the package
	 * @param _archetype address of archetype
	 * @return hasArchetype bool representing if archetype is in package
	 */
	function packageHasArchetype(bytes32 _packageId, address _archetype) external view returns (bool hasArchetype) {
		hasArchetype = false;
		uint count = ArchetypeRegistryDb(database).getNumberOfArchetypesInPackage(_packageId);
		for (uint i=0; i<count; i++) {
			if (ArchetypeRegistryDb(database).getArchetypeAtIndexInPackage(_packageId, i) == _archetype) {
				hasArchetype = true;
				break;
			}
		}
	}

    /**
     * @dev Gets parameter count for given Archetype
     * @param _archetype archetype
     * @return size size
     */
	function getParametersByArchetypeSize(address _archetype) external view returns (uint size) {
		return Archetype(_archetype).getNumberOfParameters();
	}

    /**
     * @dev Gets parameter name by Archetype At index
     * @param _archetype archetype
     * @param _index index
     * @return name name
     */
	function getParameterByArchetypeAtIndex(address _archetype, uint _index) external view returns (bytes32 name) {
		return Archetype(_archetype).getParameterAtIndex(_index);
	}

    /**
     * @dev Returns data about the parameter at with the specified name
	 * @param _archetype archetype
	 * @param _name name
	 * @return position index of parameter
	 * @return parameterType parameter type
	 */
    function getParameterByArchetypeData(address _archetype, bytes32 _name) external view returns (uint position, DataTypes.ParameterType parameterType) {
        return Archetype(_archetype).getParameterDetails(_name);
    }

    /**
     * @dev Returns the number of jurisdictions for the given Archetype
     * @param _archetype archetype address
     * @return the number of jurisdictions
     */
	function getNumberOfJurisdictionsForArchetype(address _archetype) external view returns (uint size) {
		return Archetype(_archetype).getNumberOfJurisdictions();
	}

    /**
     * @dev Returns the jurisdiction key at the specified index for the given archetype
     * @param _archetype archetype address
     * @param _index the index of the jurisdiction
     * @return the jurisdiction primary key
     */
	function getJurisdictionAtIndexForArchetype(address _archetype, uint _index) external view returns (bytes32 key) {
		uint error;
		(error, key) = Archetype(_archetype).getJurisdictionAtIndex(_index);
	}

    /**
     * @dev Returns data about the jurisdiction with the specified key in the given archetype
	 * @param _archetype archetype address
	 * @param _key the jurisdiction key
	 * @return country the jurisdiction's country
	 * @return region the jurisdiction's region
	 */
	function getJurisdictionDataForArchetype(address _archetype, bytes32 _key) external view returns (bytes2 country, bytes32 region) {
		return Archetype(_archetype).getJurisdictionData(_key);
	}

	/**
	 * @dev Returns the number governing archetypes for the given archetype
	 * @param _archetype address of the archetype
	 * @return the number of governing archetypes
	 */
	function getNumberOfGoverningArchetypes(address _archetype) external view returns (uint size) {
		return Archetype(_archetype).getNumberOfGoverningArchetypes();
	}

	/**
	 * @dev Retrieves the address of governing archetype at the specified index
	 * @param _archetype the address of the archetype
	 * @param _index the index position of its governing archetype
	 * @return the address for the governing archetype
	 */
	function getGoverningArchetypeAtIndex(address _archetype, uint _index) external view returns (address governingArchetype) {
		return Archetype(_archetype).getGoverningArchetypeAtIndex(_index);
	}

}
