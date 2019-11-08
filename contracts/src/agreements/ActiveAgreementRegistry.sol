pragma solidity ^0.5;

import "commons-management/Upgradeable.sol";
import "bpm-runtime/ProcessStateChangeListener.sol";

import "agreements/ActiveAgreement.sol";
import "agreements/Agreements.sol";

/**
 * @title ActiveAgreementRegistry Interface
 * @dev A contract interface to create and manage Active Agreements.
 */
contract ActiveAgreementRegistry is ObjectFactory, Upgradeable, ProcessStateChangeListener {

	event LogAgreementFormationProcessUpdate(
		bytes32 indexed eventId, 
		address agreementAddress,
		address formationProcessInstance
	);

	event LogAgreementExecutionProcessUpdate(
		bytes32 indexed eventId, 
		address agreementAddress,
		address executionProcessInstance
	);

	event LogAgreementCollectionCreation(
		bytes32 indexed eventId,
		bytes32 collectionId,
		address author,
		uint8 collectionType,
		bytes32 packageId
	);

	event LogAgreementToCollectionUpdate(
		bytes32 indexed eventId,
		bytes32 collectionId,
		address agreementAddress
	);

    string public constant OBJECT_CLASS_AGREEMENT = "agreements.ActiveAgreement";

	bytes32 public constant DATA_ID_AGREEMENT = "agreement";

	bytes32 public constant EVENT_ID_AGREEMENT_COLLECTIONS = "AN://agreement-collections";
	bytes32 public constant EVENT_ID_AGREEMENT_COLLECTION_MAP = "AN://agreement-to-collection";

	/**
	 * @dev Creates an Active Agreement with the given parameters
	 * @param _archetype archetype
	 * @param _creator address
	 * @param _owner address
	 * @param _privateParametersFileReference the file reference of the private parametes of this agreement
	 * @param _isPrivate agreement is private
	 * @param _parties parties array
	 * @param _collectionId id of agreement collection (optional)
	 * @param _governingAgreements array of agreement addresses which govern this agreement (optional)
	 * @return activeAgreement - the new ActiveAgreement's address, if successfully created, 0x0 otherwise
	 */
	function createAgreement(
		address _archetype,
		address _creator, 
		address _owner, 
		string calldata _privateParametersFileReference,
		bool _isPrivate,
		address[] calldata _parties, 
		bytes32 _collectionId, 
		address[] calldata _governingAgreements) 
		external returns (address activeAgreement);

	/**
	 * @dev Sets the max number of events for this agreement
	 */
	function setMaxNumberOfEvents(address _agreement, uint32 _maxNumberOfEvents) external;

	/**
	 * @dev Adds an agreement to given collection
	 * @param _collectionId the bytes32 collection id
	 * @param _agreement agreement address
	 * Reverts if collection is not found
	 */
	function addAgreementToCollection(bytes32 _collectionId, address _agreement) public;

	/**
	 * @dev Creates and starts a ProcessInstance to handle the workflows as defined by the given agreement's archetype.
	 * Depending on the configuration in the archetype, the returned address could be a formation process or
	 * execution process.
	 * @param _agreement an ActiveAgreement
	 * @return error - an error code indicating success or failure
	 * @return the address of a ProcessInstance, if successful
	 */
	function startProcessLifecycle(ActiveAgreement _agreement) external returns (uint error, address processInstance);

	/**
	 * @dev Sets address scopes on the given ProcessInstance based on the scopes defined in the ActiveAgreement referenced in the ProcessInstance.
	 * Address scopes relying on a ConditionalData configuration are translated, so they work from the POV of the ProcessInstance.
	 * This function ensures that any scopes (roles) set for user/organization addresses on the agreement are adhered to in the process.
	 * @param _processInstance the ProcessInstance being configured
	 */
	function transferAddressScopes(ProcessInstance _processInstance) public;

	/**
	 * @dev Returns the BpmService address
	 * @return address the BpmService
	 */
	function getBpmService() external returns (address);

	/**
	 * @dev Returns the ArchetypeRegistry address
	 * @return address the ArchetypeRegistry
	 */
	function getArchetypeRegistry() external returns (address);

	/**
	 * @dev Gets number of activeAgreements
	 * @return size size
	 */
	function getActiveAgreementsSize() external view returns (uint size);

	/**
	 * @dev Gets activeAgreement address at given index
	 * @param _index index
	 * @return the Active Agreement address
	 */
	function getActiveAgreementAtIndex(uint _index) external view returns (address activeAgreement);

	/**
	 * @dev Gets parties size for given Active Agreement
	 * @param _activeAgreement Active Agreement
	 * @return size size
	 */
	function getPartiesByActiveAgreementSize(address _activeAgreement) external view returns (uint size);

	/**
	 * @dev Gets getPartyByActiveAgreementAtIndex
	 * @param _activeAgreement Active Agreement
	 * @param _index index
	 * @return party party
	 */
	function getPartyByActiveAgreementAtIndex(address _activeAgreement, uint _index) public view returns (address party);

    /**
     * @dev Returns data about the ActiveAgreement at the specified address
	 * @param _activeAgreement Active Agreement
	 * @return archetype - the agreement's archetype adress
	 * @return creator - the creator of the agreement
	 * @return privateParametersFileReference - the file reference to the private agreement parameters (only used when agreement is private)
	 * @return eventLogFileReference - the file reference to the agreement's event log
	 * @return maxNumberOfEvents - the maximum number of events allowed to be stored for this agreement
	 * @return isPrivate - whether there are private agreement parameters, i.e. stored off-chain
	 * @return legalState - the agreement's Agreement.LegalState as uint8
	 * @return formationProcessInstance - the address of the process instance representing the formation of this agreement
	 * @return executionProcessInstance - the address of the process instance representing the execution of this agreement
	 */
	function getActiveAgreementData(address _activeAgreement) external view returns (address archetype, address creator, string memory privateParametersFileReference, string memory eventLogFileReference, uint maxNumberOfEvents, bool isPrivate, uint8 legalState, address formationProcessInstance, address executionProcessInstance);

    /**
	 * @dev Returns the number of agreement parameter entries.
	 * @return the number of parameters
	 */
	function getNumberOfAgreementParameters(address _address) external view returns (uint size);

    /**
	 * @dev Returns the process data ID at the specified index
	 * @param _pos the index
	 * @return the data ID
	 */
	function getAgreementParameterAtIndex(address _address, uint _pos) external view returns (bytes32 dataId);

    /**
	 * @dev Returns information about the process data entry for the specified process and data ID
	 * @param _address the active agreement
	 * @param _dataId the data ID
	 * @return (process,id,uintValue,bytes32Value,addressValue,boolValue)
	 */
	function getAgreementParameterDetails(address _address, bytes32 _dataId) external view returns (
			address process,
			bytes32 id,
			uint uintValue,
			int intValue,
			bytes32 bytes32Value,
			address addressValue,
			bool boolValue);

    /**
     * @dev Returns data about the given party's signature on the specified agreement.
	 * @param _activeAgreement the ActiveAgreement
	 * @param _party the signing party
	 * @return signedBy the actual signature authorized by the party
	 * @return signatureTimestamp the timestamp when the party has signed, or 0 if not signed yet
	 */
	function getPartyByActiveAgreementData(address _activeAgreement, address _party) external view returns (address signedBy, uint signatureTimestamp);

	/**
	 * @dev Updates the file reference for the event log of the specified agreement
	 * @param _activeAgreement the address of active agreement
	 * @param _eventLogFileReference the file reference of the event log of this agreement
	 */
	 function setEventLogReference(address _activeAgreement, string calldata _eventLogFileReference) external;

	/**
	 * @dev Updates the file reference for the signature log of the specified agreement
	 * @param _activeAgreement the address of active agreement
	 * @param _signatureLogFileReference the file reference of the signature log of this agreement
	 */
	 function setSignatureLogReference(address _activeAgreement, string calldata _signatureLogFileReference) external;

	/**
	 * @dev Creates a new agreement collection
	 * @param _author address of the author
	 * @param _collectionType the Agreements.CollectionType
	 * @param _packageId the ID of an archetype package
	 * @return an error code indicating success or failure
	 * @return id bytes32 id of package
	 */
	function createAgreementCollection(address _author, Agreements.CollectionType _collectionType, bytes32 _packageId) external returns (uint error, bytes32 id);

	/**
	 * @dev Gets number of agreement collections
	 * @return size size
	 */
	function getNumberOfAgreementCollections() external view returns (uint size);

	/**
	 * @dev Gets collection id at index
	 * @param _index uint index
	 * @return id bytes32 id
	 */
	function getAgreementCollectionAtIndex(uint _index) external view returns (bytes32 id);
	
	/**
	 * @dev Gets collection data by id
	 * @param _id bytes32 collection id
	 * @return author address
	 * @return collectionType type of collection
	 * @return packageId id of the archetype package
	 */
	function getAgreementCollectionData(bytes32 _id) external view returns (address author, uint8 collectionType, bytes32 packageId);

	/**
	 * @dev Gets number of agreements in given collection
	 * @param _id id of the collection
	 * @return size agreement count
	 */
	function getNumberOfAgreementsInCollection(bytes32 _id) external view returns (uint size);

	/**
	 * @dev Gets agreement address at index in colelction
	 * @param _id id of the collection
	 * @param _index uint index
	 * @return agreement address of archetype
	 */
	function getAgreementAtIndexInCollection(bytes32 _id, uint _index) external view returns (address agreement);

	/**
	 * @dev Returns the number governing agreements for given agreement
	 * @return the number of governing agreements
	 */
	function getNumberOfGoverningAgreements(address _agreement) external view returns (uint size);

	/**
	 * @dev Retrieves the address for the governing agreement at the specified index
	 * @param _agreement the address of the agreement
	 * @param _index the index position
	 * @return the address for the governing agreement
	 */
	function getGoverningAgreementAtIndex(address _agreement, uint _index) external view returns (address governingAgreement);

}
