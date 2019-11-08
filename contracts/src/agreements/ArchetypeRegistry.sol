pragma solidity ^0.5;

import "commons-management/ObjectFactory.sol";
import "commons-management/Upgradeable.sol";

import "agreements/Archetype.sol";
import "agreements/Agreements.sol";

/**
 * @title ArchetypeRegistry Interface
 * @dev A contract interface to create and manage Archetype objects.
 */
contract ArchetypeRegistry is ObjectFactory, Upgradeable {

	event LogArchetypePackageCreation(
		bytes32 indexed eventId,
		bytes32 packageId,
		address author,
		bool isPrivate,
		bool active
	);

	event LogArchetypePackageActivation(
		bytes32 indexed eventId,
		bytes32 packageId,
		bool active
	);

	event LogArchetypeToPackageUpdate(
		bytes32 indexed eventId,
		bytes32 packageId,
		address archetypeAddress
	);

    string public constant OBJECT_CLASS_ARCHETYPE = "agreements.Archetype";

	bytes32 public constant EVENT_ID_ARCHETYPES = "AN://archetypes";
	bytes32 public constant EVENT_ID_ARCHETYPE_PACKAGES = "AN://archetype-packages";
	bytes32 public constant EVENT_ID_ARCHETYPE_PACKAGE_MAP = "AN://archetype-to-package";

	/**
	 * @dev Creates a new archetype
	 * @param _price price
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
		external returns (address archetype);

	/**
	 * @dev Adds archetype to package
	 * @param _packageId the bytes32 package id
	 * @param _archetype the archetype address
	 * Reverts if package is not found
	 */
	function addArchetypeToPackage(bytes32 _packageId, address _archetype) public;

	/**
	 * @dev Adds the specified parameter to the archetype
	 * @param _parameterType parameter type (enum)
	 * @param _parameterName parameter name
	 * @return a return code indicating success or failure
	 */
	function addParameter(address _archetype, DataTypes.ParameterType _parameterType, bytes32 _parameterName) public returns (uint error);

	/**
	 * @dev Adds the specified parameters to the archetype
	 * @param _parameterTypes parameter type (enum) array
	 * @param _parameterNames parameter names array
	 * @return a return code indicating success or failure
	 */
	function addParameters(address _archetype, DataTypes.ParameterType[] calldata _parameterTypes, bytes32[] calldata _parameterNames) external returns (uint error);

	/**
	 * @dev Adds the given jurisdiction in the form of a country code and region identifier to this archetype.
	 * References codes defined via IsoCountries interface implementations.
	 * @param _country a ISO- code, e.g. 'US'
	 * @param _region a region identifier from a IsoCountries contract
	 * @return a return code indicating success or failure
	 */
	function addJurisdiction(address _archetype, bytes2 _country, bytes32 _region) public returns (uint error);

	/**
	 * @dev Adds the given jurisdictions in the form of a country codes and region identifiers to this archetype.
	 * References codes defined via IsoCountries interface implementations.
	 * @param _countries an array of a ISO- code, e.g. 'US'
	 * @param _regions an array of region identifiers from a IsoCountries contract
	 * @return a return code indicating success or failure
	 */
	function addJurisdictions(address _archetype, bytes2[] calldata _countries, bytes32[] calldata _regions) external returns (uint error);

	/**
	 * @dev Returns archetype successor
	 * @param _archetype address of archetype
	 * @return address address of successor
	 */
	function getArchetypeSuccessor(address _archetype) external view returns (address);

	/**
		* @dev Gets number of archetypes
		* @return size size
		*/
	function getArchetypesSize() external view returns (uint size);

	/**
		* @dev Gets archetype address at given index
		* @param _index index
		* @return the archetype address
		*/
	function getArchetypeAtIndex(uint _index) external view returns (address archetype);

	/**
    * @dev Returns data about an archetype
		* @param _archetype the archetype address
		* @return price price
		* @return author author address
		* @return owner owner address
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
	);

	/**
	 * @dev Adds a file reference to the given Archetype
	 * @param _archetype archetype
	 * @param _fileReference the external reference to the document
	 */
	function addDocument(address _archetype, string calldata _fileReference) external;

	/**
	 * @dev Sets price of given archetype
	 * @param _archetype archetype
	 * @param _price price
	 */
	function setArchetypePrice(address _archetype, uint _price) external;

	/**
	 * @dev Adds a new archetype package
	 * @param _author address of author (user account of organization)
	 * @param _isPrivate makes it a private package visible to only the author
	 * @param _active makes it a inactive package
	 * @return error BaseErrors.NO_ERROR(), BaseErrors.NULL_PARAM_NOT_ALLOWED(), BaseErrors.RESOURCE_ALREADY_EXISTS()
	 * @return id bytes32 id of package
	 */
	function createArchetypePackage(address _author, bool _isPrivate, bool _active) external returns (uint error, bytes32 id);

	/**
	 * @dev Sets active to true for given archetype package
	 * @param _id bytes32 id of archetype package
	 * @param _author address of author (must match the author of the archetype package in order to activate)
	 */
	function activatePackage(bytes32 _id, address _author) external;

	/**
	 * @dev Sets active to false for given archetype package
	 * @param _id bytes32 id of archetype package
	 * @param _author address of author (must match the author of the archetype package in order to deactivate)
	 */
	function deactivatePackage(bytes32 _id, address _author) external;

	/**
	 * @dev Gets number of archetype packages
	 * @return size size
	 */
	function getNumberOfArchetypePackages() external view returns (uint size);

	/**
	 * @dev Gets package id at index
	 * @param _index uint index
	 * @return id bytes32 id
	 */
	function getArchetypePackageAtIndex(uint _index) external view returns (bytes32 id);

	/**
	 * @dev Gets package data by id
	 * @param _id bytes32 package id
	 * @return author address
	 * @return isPrivate bool
	 * @return active bool
	 */
	function getArchetypePackageData(bytes32 _id) external view returns (address author, bool isPrivate, bool active);

	/**
	 * @dev Gets number of archetypes in given package
	 * @param _id id of the package
	 * @return size archetype count
	 */
	function getNumberOfArchetypesInPackage(bytes32 _id) external view returns (uint size);

	/**
	 * @dev Gets archetype address at index in package
	 * @param _id id of the package
	 * @param _index uint index
	 * @return archetype address of archetype
	 */
	function getArchetypeAtIndexInPackage(bytes32 _id, uint _index) external view returns (address archetype);

	/**
	 * @dev Determines whether given archetype address is in the package identified by the packageId
	 * @param _packageId id of the package
	 * @param _archetype address of archetype
	 * @return hasArchetype bool representing if archetype is in package
	 */
	function packageHasArchetype(bytes32 _packageId, address _archetype) external view returns (bool hasArchetype);

	/**
	 * @dev Gets parameters size for given Archetype
	 * @param _archetype archetype
	 * @return size size
	 */
	function getParametersByArchetypeSize(address _archetype) external view returns (uint size);

	/**
	 * @dev Gets parameter name by Archetype At index
	 * @param _archetype archetype
	 * @param _index index
	 * @return name name
	 */
	function getParameterByArchetypeAtIndex(address _archetype, uint _index) external view returns (bytes32 name);

	/**
	 * @dev Returns data about the parameter at with the specified name
	 * @param _archetype archetype
	 * @param _name name
	 * @return position index of parameter
	 * @return parameterType parameter type
	 */
	function getParameterByArchetypeData(address _archetype, bytes32 _name) external view returns (uint position, DataTypes.ParameterType parameterType);

	/**
	 * @dev Returns the number of jurisdictions for the given Archetype
	 * @param _archetype archetype address
	 * @return the number of jurisdictions
	 */
	function getNumberOfJurisdictionsForArchetype(address _archetype) external view returns (uint size);

	/**
	 * @dev Returns the jurisdiction key at the specified index for the given archetype
	 * @param _archetype archetype address
	 * @param _index the index of the jurisdiction
	 * @return the jurisdiction primary key
	 */
	function getJurisdictionAtIndexForArchetype(address _archetype, uint _index) external view returns (bytes32 key);

	/**
	 * @dev Returns data about the jurisdiction with the specified key in the given archetype
	 * @param _archetype archetype address
	 * @param _key the jurisdiction key
	 * @return country the jurisdiction's country
	 * @return region the jurisdiction's region
	 */
	function getJurisdictionDataForArchetype(address _archetype, bytes32 _key) external view returns (bytes2 country, bytes32 region);

	/**
	 * @dev Returns the number governing archetypes for the given archetype
	 * @param _archetype address of the archetype
	 * @return the number of governing archetypes
	 */
	function getNumberOfGoverningArchetypes(address _archetype) external view returns (uint size);
	
	/**
	 * @dev Retrieves the address of governing archetype at the specified index
	 * @param _archetype the address of the archetype
	 * @param _index the index position of its governing archetype
	 * @return the address for the governing archetype
	 */
	function getGoverningArchetypeAtIndex(address _archetype, uint _index) external view returns (address archetype);
	
}
