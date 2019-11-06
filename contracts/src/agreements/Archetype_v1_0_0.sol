pragma solidity ^0.5;

import "commons-utils/DataTypes.sol";
import "commons-management/VersionedArtifact.sol";


/**
 * @title Archetype Interface v1.0.0
 * @dev Legacy version of the Archetype interface that was separated out to secure backwards compatibility by versionizing a snapshot of the interface and allowing future versions to extend it.
 */
contract Archetype_v1_0_0 is VersionedArtifact {

	event LogArchetypeCreation(
		bytes32 indexed eventId,
		address archetypeAddress,
		uint price,
		address author,
		bool active,
		bool isPrivate,
		address successor,
		address formationProcessDefinition,
		address executionProcessDefinition
	);

	event LogGoverningArchetypeUpdate(
		bytes32 indexed eventId,
		address archetypeAddress,
		address governingArchetypeAddress
	);

	event LogArchetypeSuccessorUpdate(
		bytes32 indexed eventId,
		address archetypeAddress,
		address successor
	);

	event LogArchetypePriceUpdate(
		bytes32 indexed eventId,
		address archetypeAddress,
		uint price
	);

	event LogArchetypeActivation(
		bytes32 indexed eventId,
		address archetypeAddress,
		bool active
	);

	event LogArchetypeParameterUpdate(
		bytes32 indexed eventId,
		address archetypeAddress,
		bytes32 parameterName,
		uint8 parameterType,
		uint position
	);

	event LogArchetypeDocumentUpdate(
		bytes32 indexed eventId,
		address archetypeAddress,
		bytes32 documentKey,
		string documentReference
	);

	event LogArchetypeJurisdictionUpdate(
		bytes32 indexed eventId,
		address archetypeAddress,
		bytes2 country,
		bytes32 region
	);

	bytes32 public constant EVENT_ID_ARCHETYPES = "AN://archetypes";
	bytes32 public constant EVENT_ID_ARCHETYPE_PARAMETERS = "AN://archetypes/parameters";
	bytes32 public constant EVENT_ID_ARCHETYPE_DOCUMENTS = "AN://archetypes/documents";
	bytes32 public constant EVENT_ID_ARCHETYPE_JURISDICTIONS = "AN://archetypes/jurisdictions";
	bytes32 public constant EVENT_ID_GOVERNING_ARCHETYPES = "AN://governing-archetypes";

	/**
	 * @dev Initializes this ActiveAgreement with the provided parameters. This function replaces the
	 * contract constructor, so it can be used as the delegate target for an ObjectProxy.
	 * @param _author author
	 * @param _isPrivate determines if this archetype's documents are encrypted
	 * @param _active determines if this archetype is active
	 * @param _formationProcess the address of a ProcessDefinition that orchestrates the agreement formation
	 * @param _executionProcess the address of a ProcessDefinition that orchestrates the agreement execution
	 * @param _governingArchetypes array of governing archetype addresses
	 */
	function initialize(
		uint _price,
		bool _isPrivate,
		bool _active,
		address _author,
		address _formationProcess,
		address _executionProcess,
		address[] calldata _governingArchetypes)
		external;

	/**
	 * @dev Adds the document specified by the external reference to this Archetype
	 * @param _fileReference the external reference to the document
	 */
	function addDocument(string calldata _fileReference) external;

	/**
	 * @dev Adds a parameter to this Archetype
	 * @param _parameterType parameter type (enum)
	 * @param _parameterName parameter name
	 * @return error - code indicating success or failure
	 * @return position - the position at which the parameter was added, if successful
	 */
	function addParameter(DataTypes.ParameterType _parameterType, bytes32 _parameterName) external returns (uint error, uint position);

	/**
	 * @dev Adds the given jurisdiction in the form of a country code and region identifier to this archetype.
	 * References codes defined via IsoCountries interface implementations.
	 * @param _country a ISO- code, e.g. 'US'
	 * @param _region a region identifier from a IsoCountries contract
	 * @return error code indicating success or failure
	 * 				 key of the jurisdiction just added
	 */
	function addJurisdiction(bytes2 _country, bytes32 _region) external returns (uint error, bytes32 key);

	/**
	 * @dev Gets price
	 * @return price
	 */
	function getPrice() external view returns (uint);

	/**
	 * @dev Sets price
	 * @param _price price of archetype
	 */
	function setPrice(uint _price) external;

	/**
	 * @dev Gets Author
	 * @return author author
	 */
	function getAuthor() external view returns (address author);

	/**
	 * @dev Gets document reference with given key
	 * @param _key document key
	 * @return fileReference - the reference to the external document
	 */
	function getDocument(bytes32 _key) external view returns (string memory fileReference);

	/**
	 * @dev Gets number of parameters
	 * @return size number of parameters
	 */
	function getNumberOfParameters() external view returns (uint size);

	/**
	 * @dev Gets parameter at index
	 * @param _index index
	 * @return customField parameter
	 */
	function getParameterAtIndex(uint _index) external view returns (bytes32 parameter);

	/**
	 * @dev Gets parameter data type
	 * @param _parameter parameter
	 * @return error error TBD
	 * @return position index of parameter
	 * @return parameterType parameter type
	 */
	function getParameterDetails(bytes32 _parameter) external view returns (uint position, DataTypes.ParameterType parameterType);

	/**
	 * @dev Gets number of documents
	 * @return size number of documents
	 */
	function getNumberOfDocuments() external view returns (uint size);

	/**
	 * @dev Returns the document key at the given index
	 * @param _index index
	 * @return key - the document key
	 */
	function getDocumentKeyAtIndex(uint _index) external view returns (bytes32 key);

	/**
	 * @dev Returns the number jurisdictions for this archetype
	 * @return the number of jurisdictions
	 */
	function getNumberOfJurisdictions() external view returns (uint size);

	/**
	 * @dev Retrieves the key for the jurisdiction at the specified index
	 * @param _index the index position
	 * @return error BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS() if index is out of bounds
	 * @return the key of the jurisdiction or an empty bytes32 if the index was out of bounds
	 */
	function getJurisdictionAtIndex(uint _index) external view returns (uint error, bytes32 key);

	/**
	 * @dev Returns information about the jurisdiction with the specified key
	 * @param _key the key identifying the jurisdiction
	 * @return the country and region identifiers (see IsoCountries), if the jurisdiction exists
	 */
	function getJurisdictionData(bytes32 _key) external view returns (bytes2 country, bytes32 region);

	/**
	 * @dev Returns the number governing archetypes for this archetype
	 * @return the number of governing archetypes
	 */
	function getNumberOfGoverningArchetypes() external view returns (uint size);

	/**
	 * @dev Retrieves the address for the governing archetype at the specified index
	 * @param _index the index position
	 * @return the address for the governing archetype
	 */
	function getGoverningArchetypeAtIndex(uint _index) external view returns (address archetypeAddress);

	/**
	 * @dev Returns all governing archetype address for this archetype
	 * @return the address array containing all governing archetypes
	 */
	function getGoverningArchetypes() external view returns (address[] memory);

	/**
	 * @dev Returns the address of the ProcessDefinition that orchestrates the agreement formation.
	 * @return the address of a ProcessDefinition
	 */
	function getFormationProcessDefinition() external view returns (address);

	/**
	 * @dev Returns the address of the ProcessDefinition that orchestrates the agreement execution.
	 * @return the address of a ProcessDefinition
	 */
	function getExecutionProcessDefinition() external view returns (address);

	/**
	 * @dev Returns the active state
	 * @return true if active, false otherwise
	 */
	function isActive() external view returns (bool);

	/**
	 * @dev Returns the private state
	 * @return true if private, false otherwise
	 */
	function isPrivate() external view returns (bool);

	/**
	 * @dev Sets the successor this archetype. Setting a successor automatically deactivates this archetype.
	 * Fails if given successor is the same address as itself. 
	 * Fails if intended action will lead to two archetypes with their successors pointing to each other.
	 * @param _successor address of successor archetype
	 */
	function setSuccessor(address _successor) external;
	
	/**
	 * @dev Returns the successor of this archetype
	 * @return address of successor archetype
	 */
	function getSuccessor() external view returns (address);

	/**
	 * @dev Activates this archetype
	 */
	function activate() external;

	/**
	 * @dev Deactivates this archetype
	 */
	function deactivate() external;
}