pragma solidity ^0.5;

import "commons-base/BaseErrors.sol";
import "commons-base/ErrorsLib.sol";
import "commons-utils/ArrayUtilsLib.sol";
import "commons-utils/TypeUtilsLib.sol";
import "commons-utils/DataTypes.sol";
import "commons-collections/Mappings.sol";
import "commons-collections/MappingsLib.sol";
import "documents-commons/Documents.sol";
import "commons-management/AbstractDelegateTarget.sol";
import "commons-management/AbstractVersionedArtifact.sol";

import "agreements/Archetype_v1_0_0.sol";

/**
 * @title Abstract Archetype v1.0.0
 * @dev Legacy version of the DefaultArchetype implementation that was separated out to secure backwards compatibility by versionizing a snapshot of the contract and allowing future versions to extend it.
 * Note that this legacy version is an abstract contract due to not inheriting AbstractVersionedArtifact which must be inherited and initialized with a version at the current DefaultArchetype contract.
 */
contract AbstractArchetype_v1_0_0 is AbstractDelegateTarget, Archetype_v1_0_0 {

	using ArrayUtilsLib for bytes32[];
	using ArrayUtilsLib for address[];
	using TypeUtilsLib for string;
	using MappingsLib for Mappings.Bytes32StringMap;
	using MappingsLib for Mappings.Bytes32UintMap;

	struct Jurisdiction {
		bool exists;
		uint keyIdx;
		bytes2 country;
		bytes32 region;
	}

	uint price;
	address author;
	bool active;
	bool privateFlag;
	address successor;
	address formationProcessDefinition;
	address executionProcessDefinition;

	Mappings.Bytes32UintMap parameterTypes;
	Mappings.Bytes32StringMap documents;

	mapping(bytes32 => Jurisdiction) jurisdictions;
	bytes32[] jurisdictionKeys;
	mapping(bytes2 => bytes32[]) jurisdictionHierarchy; // TODO this could be replaced with Mappings.Bytes2Bytes32Array

	address[] governingArchetypes;

    /**
     * @dev non-public constructor
     */
    constructor() internal {}

	/**
	 * @dev Initializes this DefaultArchetype with the provided parameters. This function replaces the
	 * contract constructor, so it can be used as the delegate target for an ObjectProxy.
	 * REVERTS if:
	 * - the author address is empty
	 * - the list of governing archetypes has duplicate entries
	 * @param _price a price indicator for creating agreements from this archetype
	 * @param _isPrivate determines if this archetype's documents are encrypted
	 * @param _active determines if this archetype is active
	 * @param _author author
	 * @param _formationProcess the address of a ProcessDefinition that orchestrates the agreement formation
	 * @param _executionProcess the address of a ProcessDefinition that orchestrates the agreement execution
	 * @param _governingArchetypes array of governing archetype addresses (optional)
	 */
	function initialize(
		uint _price,
		bool _isPrivate,
		bool _active,
		address _author,
		address _formationProcess,
		address _executionProcess,
		address[] calldata _governingArchetypes)
		external
		pre_post_initialize
	{
		ErrorsLib.revertIf(_author == address(0),
			ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultArchetype.initialize", "The provided author address must not be empty");
		ErrorsLib.revertIf(_governingArchetypes.hasDuplicates(),
			ErrorsLib.INVALID_INPUT(), "DefaultArchetype.initialize", "Governing archetypes must not contain duplicates");

		price = _price;
		privateFlag = _isPrivate;
		active = _active;
		author = _author;
		formationProcessDefinition = _formationProcess;
		executionProcessDefinition = _executionProcess;
		governingArchetypes = _governingArchetypes;

		// NOTE: some of the parameters for the event must be read from storage, otherwise "stack too deep" compilation errors occur
		emit LogArchetypeCreation(
			EVENT_ID_ARCHETYPES,
			address(this),
			_price,
			_author,
			_active,
			_isPrivate,
			successor,
			_formationProcess,
			_executionProcess
		);
		for (uint i = 0; i < _governingArchetypes.length; i++) {
			emit LogGoverningArchetypeUpdate(
				EVENT_ID_GOVERNING_ARCHETYPES, 
				address(this), 
				_governingArchetypes[i]
			);
		}
	}

	/**
	 * @dev Adds the document specified by the external reference to the archetype under the given name
	 * REVERTS if:
	 * - a document with the same file reference already exists
	 * @param _fileReference the external reference to the document
	 */
	// TODO: determine access (presumably only author should be able to add documents)
	function addDocument(string calldata _fileReference) external {
		bytes32 docKey = keccak256(abi.encodePacked(_fileReference));
		ErrorsLib.revertIf(documents.exists(docKey),
			ErrorsLib.RESOURCE_ALREADY_EXISTS(), "DefaultArchetype.addDocument", "A document with the same file reference already exists");

		documents.insert(docKey, _fileReference);
		emit LogArchetypeDocumentUpdate(
			EVENT_ID_ARCHETYPE_DOCUMENTS,
			address(this),
			docKey,
			_fileReference
		);
	}

	/**
	 * @dev Adds a parameter to the Archetype
	 * @param _parameterType the DataTypes.ParameterType
	 * @param _parameterName the parameter name
	 * @return BaseErrors.NO_ERROR() and position of parameter, if successful,
	 * @return BaseErrors.NULL_PARAM_NOT_ALLOWED() if _parameter is empty,
	 * @return BaseErrors.RESOURCE_ALREADY_EXISTS() if _parameter already exists
	 */
	function addParameter(DataTypes.ParameterType _parameterType, bytes32 _parameterName) external returns (uint error, uint position) {
		if (_parameterName == "")
			return (BaseErrors.NULL_PARAM_NOT_ALLOWED(), 0);
		if (parameterTypes.exists(_parameterName))
			return (BaseErrors.RESOURCE_ALREADY_EXISTS(), 0);

		parameterTypes.insert(_parameterName, uint8(_parameterType));
		position = parameterTypes.rows[_parameterName].keyIdx;
		emit LogArchetypeParameterUpdate(
			EVENT_ID_ARCHETYPE_PARAMETERS,
			address(this),
			_parameterName,
			uint8(_parameterType),
			position
		);
		return (BaseErrors.NO_ERROR(), position);
	}

	/**
	 * @dev Adds the given jurisdiction in the form of a country code and region identifier to this archetype.
	 * References codes defined via IsoCountries interface implementations.
	 * If the region is empty, the jurisdiction will only reference the country and the regions will be emptied, i.e. any prior regions for that country will be removed.
	 * REVERTS if:
	 * - the provided country is empty
	 * @param _country a ISO-code, e.g. 'US'
	 * @param _region a region identifier from a IsoCountries contract
	 * @return BaseErrors.NO_ERROR() if successful, and key of jurisdiction was added
	 */
	function addJurisdiction(bytes2 _country, bytes32 _region) external returns (uint error, bytes32 key) {
		ErrorsLib.revertIf(_country == "",
			ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultArchetype.addJurisdiction", "Country must not be empty");

		if (_region == "") {
			// for a jurisdiction represented by a country ONLY, we need to use an artificial bytes32 key
			key = keccak256(abi.encodePacked(_country));
			// remove all existing jurisdictions previously registered for this country
			deleteRegionsForCountry(_country);
		} else {
			key = _region;
			// establish hierarchical relationship, if it did not exist
			if (!jurisdictionHierarchy[_country].contains(_region)) {
				jurisdictionHierarchy[_country].push(_region);
			}
		}

		if (!jurisdictions[key].exists) {
			jurisdictions[key].exists = true;
			jurisdictions[key].keyIdx = jurisdictionKeys.push(key);
		}
		jurisdictions[key].country = _country;
		jurisdictions[key].region = _region;

		emit LogArchetypeJurisdictionUpdate(
			EVENT_ID_ARCHETYPE_JURISDICTIONS,
			address(this),
			_country,
			_region
		);

		return (BaseErrors.NO_ERROR(), key);
	}

	/**
	 * @dev Private function to delete the regions of a country and also delete their "jurisdictionKeys" entries
	 * @param _country the country code 
	 */
	function deleteRegionsForCountry(bytes2 _country) private {
		uint lastPos;
		uint currentKeyIdx;
		for (uint i=0; i<jurisdictionHierarchy[_country].length; i++) {
			lastPos = jurisdictionKeys.length - 1;
			currentKeyIdx = jurisdictions[jurisdictionHierarchy[_country][i]].keyIdx;
			if (currentKeyIdx != lastPos) {
				// swap last element into position being deleted
				jurisdictionKeys[currentKeyIdx] = jurisdictionKeys[lastPos];
				// and update the swapped element's keyIdx
				jurisdictions[jurisdictionKeys[currentKeyIdx]].keyIdx = currentKeyIdx;
			}
			jurisdictionKeys.length--; // shortening the length also removes the last element, no need to specifically delete the entry (waste of gas)
			delete jurisdictions[jurisdictionHierarchy[_country][i]];
		}
		delete jurisdictionHierarchy[_country];
	}

	/**
	 * @dev Gets price
	 * @return price
	 */
	function getPrice() external view returns (uint) {
		return price;
	}

	/**
	 * @dev Sets price
	 * @param _price price of archetype
	 */
	function setPrice(uint _price) external {
		price = _price;
		emit LogArchetypePriceUpdate(EVENT_ID_ARCHETYPES, address(this), _price);
	}

	/**
	 * @dev Gets Author
	 * @return author author
	 */
	function getAuthor() external view returns (address) {
		return author;
	}

	/**
	 * @dev Gets document reference with given key
	 * REVERTS if:
	 * - a document with the provided key does not exist
	 * @param _key the document key
	 * @return fileReference - the reference to the external document
	 */
	function getDocument(bytes32 _key) external view returns (string memory fileReference) {
		ErrorsLib.revertIf(!documents.exists(_key),
			ErrorsLib.RESOURCE_NOT_FOUND(), "DefaultArchetype.getDocument", "A document reference for the given key does not exist");
		fileReference = documents.get(_key);
	}

	/**
	 * @dev Gets number of parameters
	 * @return size number of parameters
	 */
	function getNumberOfParameters() external view returns (uint size) {
		return parameterTypes.keys.length;
	}

	/**
	 * @dev Gets parameter at index
	 * @param _index index
	 * @return parameter parameter
	 */
	function getParameterAtIndex(uint _index) external view returns (bytes32 parameter) {
		ErrorsLib.revertIf(parameterTypes.keys.length < _index,
			ErrorsLib.INVALID_INPUT(), "DefaultArchetype.getParameterAtIndex", "The specified index is out of bounds");
		parameter = parameterTypes.keys[_index];
	}

	/**
	 * @dev Gets parameter data type
	 * @param _parameter parameter
	 * @return error error TBD
	 * @return position index of parameter
	 * @return parameterType parameter type
	 */
    function getParameterDetails(bytes32 _parameter) external view returns (uint position, DataTypes.ParameterType parameterType) {
        // the index of the parameterTypes Map correspond to the order of entry during creation and therefore can be used as an index for sorting
        position = parameterTypes.rows[_parameter].keyIdx;
        parameterType = DataTypes.ParameterType(parameterTypes.rows[_parameter].value);
    }

	/**
	 * @dev Gets number of documents
	 * @return size number of documents
	 */
	function getNumberOfDocuments() external view returns (uint size) {
		return documents.keys.length;
	}

	/**
	 * @dev Returns the document key at the given index
	 * REVERTS if:
	 * - the given index is out of bounds
	 * @param _index index
	 * @return key - the document key
	 */
	function getDocumentKeyAtIndex(uint _index) external view returns (bytes32 key) {
		ErrorsLib.revertIf(_index >= documents.keys.length,
			ErrorsLib.INVALID_INPUT(), "DefaultArchetype.getDocumentKeyAtIndex", "The specified index is out of bounds");
		( , key) = documents.keyAtIndex(_index);
	}

	/**
	 * @dev Returns the address of the ProcessDefinition that orchestrates the agreement formation.
	 * @return the address of a ProcessDefinition
	 */
	function getFormationProcessDefinition() external view returns (address) {
		return formationProcessDefinition;
	}

	/**
	 * @dev Returns the number jurisdictions for this archetype
	 * @return the number of jurisdictions
	 */
	function getNumberOfJurisdictions() external view returns (uint size) {
		size = jurisdictionKeys.length;
	}

	/**
	 * @dev Retrieves the key for the jurisdiction at the specified index
	 * @param _index the index position
	 * @return error BaseErrors.NO_ERROR() or BaseErrors.INDEX_OUT_OF_BOUNDS() if index is out of bounds
	 * @return the key of the jurisdiction or an empty bytes32 if the index was out of bounds
	 */
	function getJurisdictionAtIndex(uint _index) external view returns (uint error, bytes32 key) {
		error = BaseErrors.NO_ERROR();
		if (_index >= jurisdictionKeys.length)
			error = BaseErrors.INDEX_OUT_OF_BOUNDS();
		else
			key = jurisdictionKeys[_index];
	}

	/**
	 * @dev Returns information about the jurisdiction with the specified key
	 * @param _key the key identifying the jurisdiction
	 * @return the country and region identifiers (see IsoCountries), if the jurisdiction exists
	 */
	function getJurisdictionData(bytes32 _key) external view returns (bytes2 country, bytes32 region) {
		country = jurisdictions[_key].country;
		region = jurisdictions[_key].region;
	}

	/**
	 * @dev Returns the number governing archetypes for this archetype
	 * @return the number of governing archetypes
	 */
	function getNumberOfGoverningArchetypes() external view returns (uint size) {
		return governingArchetypes.length;
	}

	/**
	 * @dev Retrieves the address for the governing archetype at the specified index
	 * @param _index the index position
	 * @return the address for the governing archetype
	 */
	function getGoverningArchetypeAtIndex(uint _index) external view returns (address archetypeAddress) {
		return governingArchetypes[_index];
	}

	/**
	 * @dev Returns all governing archetype address for this archetype
	 * @return the address array containing all governing archetypes
	 */
	function getGoverningArchetypes() external view returns (address[] memory) {
		return governingArchetypes;
	}

	/**
	 * @dev Returns the address of the ProcessDefinition that orchestrates the agreement execution.
	 * @return the address of a ProcessDefinition
	 */
	function getExecutionProcessDefinition() external view returns (address) {
		return executionProcessDefinition;
	}

	/**
	 * @dev Returns the active state
	 * @return true if active, false otherwise
	 */
	function isActive() external view returns (bool) {
		return active;
	}

	/**
	 * @dev Returns the private state
	 * @return true if private, false otherwise
	 */
	function isPrivate() external view returns (bool) {
		return privateFlag;
	}

	/**
	 * @dev Returns the successor of this archetype
	 * @return address of successor archetype
	 */
	function getSuccessor() external view returns (address) {
		return successor;
	}

}
