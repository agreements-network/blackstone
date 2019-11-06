pragma solidity ^0.5;

import "commons-base/ErrorsLib.sol";
import "commons-base/BaseErrors.sol";
import "commons-collections/Mappings.sol";
import "commons-collections/MappingsLib.sol";
import "commons-events/AbstractEventListener.sol";
import "commons-management/ArtifactsFinder.sol";
import "commons-management/ArtifactsFinderEnabled.sol";
import "commons-management/AbstractDbUpgradeable.sol";
import "commons-management/AbstractObjectFactory.sol";
import "commons-management/ObjectProxy.sol";
import "commons-utils/ArrayUtilsLib.sol";
import "bpm-runtime/BpmRuntime.sol";
import "bpm-runtime/BpmService.sol";
import "bpm-runtime/ProcessInstance.sol";

import "agreements/Agreements.sol";
import "agreements/ActiveAgreement.sol";
import "agreements/DefaultActiveAgreement.sol";
import "agreements/ActiveAgreementRegistry.sol";
import "agreements/ActiveAgreementRegistryDb.sol";
import "agreements/Archetype.sol";
import "agreements/ArchetypeRegistry.sol";

/**
 * @title DefaultActiveAgreementRegistry Interface
 * @dev A contract interface to create and manage Active Agreements.
 */
contract DefaultActiveAgreementRegistry is AbstractVersionedArtifact(1,1,0), AbstractObjectFactory, ArtifactsFinderEnabled, AbstractEventListener, AbstractDbUpgradeable, ActiveAgreementRegistry {

	using ArrayUtilsLib for address[];

	/**
	 * verifies that the msg.sender is an agreement known to this registry
	 */
	modifier pre_OnlyByRegisteredAgreements() {
		ErrorsLib.revertIf(!ActiveAgreementRegistryDb(database).isAgreementRegistered(msg.sender),
			ErrorsLib.UNAUTHORIZED(), "DefaultActiveAgreementRegistry.pre_OnlyByRegisteredAgreements", "The msg.sender must be a registered ActiveAgreement");
		_;
	}

	string serviceIdArchetypeRegistry;
	string serviceIdBpmService;

	/**
	 * @dev Creates a new DefaultActiveAgreementsRegistry that uses the specified service IDs to resolve dependencies at runtime.
	 * REVERTS if:
	 * - any of the service ID dependencies are empty
	 * @param _serviceIdArchetypeRegistry the ID with which to resolve the ArchetypeRegistry dependency
	 * @param _serviceIdBpmService the ID with which to resolve the BpmService dependency
	 */
	constructor (string memory _serviceIdArchetypeRegistry, string memory _serviceIdBpmService) public {
		ErrorsLib.revertIf(bytes(_serviceIdArchetypeRegistry).length == 0,
			ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultActiveAgreementRegistry.constructor", "_serviceIdArchetypeRegistry parameter must not be empty");
		ErrorsLib.revertIf(bytes(_serviceIdBpmService).length == 0,
			ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultActiveAgreementRegistry.constructor", "_serviceIdBpmService parameter must not be empty");
		serviceIdArchetypeRegistry = _serviceIdArchetypeRegistry;
		serviceIdBpmService = _serviceIdBpmService;
	}

	/**
	 * @dev Creates an Active Agreement with the given parameters
	 * REVERTS if:
	 * - Archetype address is empty
	 * - Duplicate governing agreements are passed
	 * - Agreement address is already registered
	 * - Given collectionId does not exist
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
		external returns (address agreementAddress)
	{
    agreementAddress = address(new ObjectProxy(address(artifactsFinder), OBJECT_CLASS_AGREEMENT));
		ActiveAgreement agreement = ActiveAgreement(agreementAddress);
    agreement.initialize(_archetype, _creator, _owner, _privateParametersFileReference, _isPrivate, _parties, _governingAgreements);
		uint error = ActiveAgreementRegistryDb(database).registerActiveAgreement(agreementAddress);
		ErrorsLib.revertIf(error != BaseErrors.NO_ERROR(),
			ErrorsLib.RESOURCE_ALREADY_EXISTS(), "DefaultActiveAgreementRegistry.createAgreement", "Active Agreement already exists");
		agreement.addEventListener(agreement.EVENT_ID_STATE_CHANGED());
		if (_collectionId != "") {
			addAgreementToCollection(_collectionId, agreementAddress);
		}
	}

	/**
	 * @dev Sets the max number of events for this agreement
	 */
	function setMaxNumberOfEvents(address _agreement, uint32 _maxNumberOfEvents) external {
		ActiveAgreement(_agreement).setMaxNumberOfEvents(_maxNumberOfEvents);
	}

	/**
	 * @dev Adds an agreement to given collection
	 * REVERTS if:
	 * - the ArchetypeRegistry dependency cannot be found via the ArtifactsFinder
	 * - a collection with the given ID is not found
	 * - the agreement's archetype is part of the collection's package
	 * @param _collectionId the bytes32 collection id
	 * @param _agreement agreement address
	 */
	function addAgreementToCollection(bytes32 _collectionId, address _agreement) public {
		bytes32 packageId;
		address registryAddress;
		// we deliberately accept the fact that the artifactsFinder could still be 0x0, if the contract was never initialized correctly
		// However, when deployed through DOUG, the artifactsFinder is set, so we avoid having to check every time.
		(registryAddress, ) = artifactsFinder.getArtifact(serviceIdArchetypeRegistry);
		ErrorsLib.revertIf(registryAddress == address(0),
			ErrorsLib.DEPENDENCY_NOT_FOUND(), "DefaultActiveAgreementsRegistry.addAgreementToCollection", "ArchetypeRegistry dependency not found in ArtifactsFinder");
		address archetype = ActiveAgreement(_agreement).getArchetype();
		( , , packageId) = ActiveAgreementRegistryDb(database).getCollectionData(_collectionId);
		ErrorsLib.revertIf(packageId == "",
			ErrorsLib.RESOURCE_NOT_FOUND(), "DefaultActiveAgreementRegistry.addAgreementToCollection", "No packageId found for given collection");
		ErrorsLib.revertIf(!ArchetypeRegistry(registryAddress).packageHasArchetype(packageId, archetype),
			ErrorsLib.INVALID_INPUT(), "DefaultActiveAgreementRegistry.addAgreementToCollection", "Agreement archetype not found in given collection's package");
		uint error = ActiveAgreementRegistryDb(database).addAgreementToCollection(_collectionId, _agreement);
		ErrorsLib.revertIf(error != BaseErrors.NO_ERROR(),
			ErrorsLib.RESOURCE_NOT_FOUND(), "DefaultActiveAgreementRegistry.addAgreementToCollection", "Collection not found");
		emit LogAgreementToCollectionUpdate(
			EVENT_ID_AGREEMENT_COLLECTION_MAP,
			_collectionId,
			_agreement
		);
	}

	/**
	 * @dev Creates and starts a ProcessInstance to handle the workflows as defined by the given agreement's archetype.
	 * Depending on the configuration in the archetype, the returned address can be either a formation process or an execution process.
	 * An execution process will only be started if *no* formation process is defined for the archetype. Otherwise,
	 * the execution process will automatically start after the formation process (see #processStateChanged(ProcessInstance))
	 * REVERTS if:
	 * - the provided ActiveAgreement is a 0x0 address
	 * - a formation process should be started, but the legal state of the agreement is not FORMULATED
	 * - a formation process should be started, but there is already an ongoing formation ProcessInstance registered for this agreement
	 * - an execution process should be started, but the legal state of the agreement is not EXECUTED
	 * - an execution process should be started, but there is already an ongoing execution ProcessInstance registered for this agreement
	 * @param _agreement an ActiveAgreement
	 * @return error - BaseErrors.NO_ERROR() if a ProcessInstance was started successfully, or a different error code if there were problems in the process
	 * @return the address of a ProcessInstance, if successful
	 */
	function startProcessLifecycle(ActiveAgreement _agreement)
		external
		returns (uint error, address)
	{
		ErrorsLib.revertIf(address(_agreement) == address(0),
			ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultActiveAgreementRegistry.startProcessLifecycle", "The provided ActiveAgreement must exist");
		// we deliberately accept the fact that the artifactsFinder could still be 0x0, if the contract was never initialized correctly
		// However, when deployed through DOUG, the artifactsFinder is set, so we avoid having to check every time.
		(address serviceAddress, ) = artifactsFinder.getArtifact(serviceIdBpmService);
		ErrorsLib.revertIf(serviceAddress == address(0),
			ErrorsLib.DEPENDENCY_NOT_FOUND(), "DefaultActiveAgreementsRegistry.startProcessLifecycle", "BpmService dependency not found in ArtifactsFinder");

		ProcessInstance pi;

		// FORMATION PROCESS
		if (Archetype(_agreement.getArchetype()).getFormationProcessDefinition() != address(0)) {
			ErrorsLib.revertIf(_agreement.getLegalState() != uint8(Agreements.LegalState.FORMULATED),
				ErrorsLib.INVALID_PARAMETER_STATE(), "DefaultActiveAgreementRegistry.startProcessLifecycle", "The ActiveAgreement must be in state FORMULATED to start the formation process");
			ErrorsLib.revertIf(ActiveAgreementRegistryDb(database).getAgreementFormationProcess(address(_agreement)) != address(0),
				ErrorsLib.OVERWRITE_NOT_ALLOWED(), "DefaultActiveAgreementRegistry.startProcessLifecycle", "The provided agreement already has an ongoing formation ProcessInstance");
			
			pi = createFormationProcess(_agreement);
			// keep track of the process for the agreement, regardless of whether the start (below) actually succeeds, because the PI is created
			ActiveAgreementRegistryDb(database).setAgreementFormationProcess(address(_agreement), address(pi));
			error = BpmService(serviceAddress).startProcessInstance(pi);
			return(error, address(pi));
		}
		// EXECUTION PROCESS
		else if (Archetype(_agreement.getArchetype()).getExecutionProcessDefinition() != address(0)) {
			ErrorsLib.revertIf(_agreement.getLegalState() != uint8(Agreements.LegalState.EXECUTED),
				ErrorsLib.INVALID_PARAMETER_STATE(), "DefaultActiveAgreementRegistry.startProcessLifecycle", "The ActiveAgreement must be in state EXECUTED to start the execution process");
			ErrorsLib.revertIf(ActiveAgreementRegistryDb(database).getAgreementExecutionProcess(address(_agreement)) != address(0),
				ErrorsLib.OVERWRITE_NOT_ALLOWED(), "DefaultActiveAgreementRegistry.startProcessLifecycle", "The provided agreement already has an ongoing execution ProcessInstance");

			pi = createExecutionProcess(_agreement);
			ActiveAgreementRegistryDb(database).setAgreementExecutionProcess(address(_agreement), address(pi));
			error = BpmService(serviceAddress).startProcessInstance(pi);
			return(error, address(pi));
		}
	}

	/**
	 * @dev Creates a ProcessInstance to handle the given agreement's formation process
	 * REVERTS if:
	 * - no Processdefinition can be found via the agreement's archetype
	 * @param _agreement an ActiveAgreement
	 * @return a ProcessInstance
	 */
	function createFormationProcess(ActiveAgreement _agreement) internal returns (ProcessInstance processInstance) {
		address pd = Archetype(_agreement.getArchetype()).getFormationProcessDefinition();
		ErrorsLib.revertIf(pd == address(0),
			ErrorsLib.RESOURCE_NOT_FOUND(), "DefaultActiveAgreementRegistry.createFormationProcess", "No ProcessDefinition found on the agreement's archetype");
		// we deliberately accept the fact that the artifactsFinder could still be 0x0, if the contract was never initialized correctly
		// However, when deployed through DOUG, the artifactsFinder is set, so we avoid having to check every time.
		(address serviceAddress, ) = artifactsFinder.getArtifact(serviceIdBpmService);
		ErrorsLib.revertIf(serviceAddress == address(0),
			ErrorsLib.DEPENDENCY_NOT_FOUND(), "DefaultActiveAgreementsRegistry.createFormationProcess", "BpmService dependency not found in ArtifactsFinder");
		processInstance = BpmService(serviceAddress).createDefaultProcessInstance(pd, msg.sender, bytes32(""));
		processInstance.addProcessStateChangeListener(this);
		processInstance.setDataValueAsAddress(DATA_ID_AGREEMENT, address(_agreement));
		transferAddressScopes(processInstance);
		emit LogAgreementFormationProcessUpdate(_agreement.EVENT_ID_AGREEMENTS(), address(_agreement), address(processInstance));
	}

	/**
	 * @dev Creates a ProcessInstance to handle the given agreement's execution process
	 * REVERTS if:
	 * - no Processdefinition can be found via the agreement's archetype
	 * @param _agreement an ActiveAgreement
	 * @return a ProcessInstance
	 */
	function createExecutionProcess(ActiveAgreement _agreement) internal returns (ProcessInstance processInstance) {
		address pd = Archetype(_agreement.getArchetype()).getExecutionProcessDefinition();
		ErrorsLib.revertIf(pd == address(0),
			ErrorsLib.RESOURCE_NOT_FOUND(), "DefaultActiveAgreementRegistry.createExecutionProcess", "No ProcessDefinition found on the agreement's archetype");
		// we deliberately accept the fact that the artifactsFinder could still be 0x0, if the contract was never initialized correctly
		// However, when deployed through DOUG, the artifactsFinder is set, so we avoid having to check every time.
		(address serviceAddress, ) = artifactsFinder.getArtifact(serviceIdBpmService);
		ErrorsLib.revertIf(serviceAddress == address(0),
			ErrorsLib.DEPENDENCY_NOT_FOUND(), "DefaultActiveAgreementsRegistry.createExecutionProcess", "BpmService dependency not found in ArtifactsFinder");
		processInstance = BpmService(serviceAddress).createDefaultProcessInstance(pd, msg.sender, bytes32(""));
		processInstance.addProcessStateChangeListener(this);
		processInstance.setDataValueAsAddress(DATA_ID_AGREEMENT, address(_agreement));
		transferAddressScopes(processInstance);
		emit LogAgreementExecutionProcessUpdate(_agreement.EVENT_ID_AGREEMENTS(), address(_agreement), address(processInstance));
	}

	/**
	 * @dev Sets address scopes on the given ProcessInstance based on the scopes defined in the ActiveAgreement referenced in the ProcessInstance.
     * Address scopes relying on a ConditionalData configuration are translated, so they work from the POV of the ProcessInstance.
     * This function ensures that any scopes (roles) set for user/organization addresses on the agreement are available and adhered to in the process
	 * in the context of activities.
	 * Each scope on the agreement is examined whether its data field context is connected to a model participant (swimlane)
	 * in the ProcessDefinition/ProcessModel that guides the ProcessInstance. If a match is found, the activity definitions in the
	 * ProcessInstance that are connected (assigned) to the participant are used as contexts to set up address scopes on the ProcessInstance.
	 * This function performs a crucial translation of role restrictions specified on the agreement to make sure the same qualifications
	 * are available when performing user tasks using organizational scopes (departments).
	 * Example (address + context = scope):
	 * Address scope on the agreement using a data field context: 0x94EcB18404251B0C8E88B0D8fbde7145c72AEC22 + "Buyer" = "LogisticsDepartment"
	 * Address scope on the ProcessInstance using an activity context: 0x94EcB18404251B0C8E88B0D8fbde7145c72AEC22 + "ApproveOrder" = "LogisticsDepartment"
	 * REVERTS if:
	 * - the ProcessInstance is not in state CREATED
	 * - the provided ProcessInstance does not have an ActiveAgreement set under DATA_ID_AGREEMENT
	 * @param _processInstance the ProcessInstance being configured
	 */
	function transferAddressScopes(ProcessInstance _processInstance)
		public
	{
		ErrorsLib.revertIf(_processInstance.getState() != uint8(BpmRuntime.ProcessInstanceState.CREATED),
			ErrorsLib.INVALID_PARAMETER_STATE(), "DefaultActiveAgreementRegistry.transferAddressScopes", "Cannot set role qualifiers on a ProcessInstance that has already started");
		ActiveAgreement agreement = ActiveAgreement(_processInstance.getDataValueAsAddress(DATA_ID_AGREEMENT));
		ErrorsLib.revertIf(address(agreement) == address(0),
			ErrorsLib.INVALID_PARAMETER_STATE(), "DefaultActiveAgreementRegistry.transferAddressScopes", "The provided ProcessInstance does not have an ActiveAgreement set");
		bytes32[] memory keys = agreement.getAddressScopeKeys();
		if (keys.length > 0) {
			ProcessModel model = ProcessDefinition(_processInstance.getProcessDefinition()).getModel();
			for (uint i=0; i<keys.length; i++) {
				transferAddressScope(keys[i], agreement, _processInstance, model);
			}
		}
	}

	/**
	 * @dev Transfers a single address scope with the given key from the ActiveAgreement to the ProcessInstance using the provided ProcessModel.
	 * This function is an extension of the transferAddressScopes(ProcessInstance) function to avoid running into stack issues due ot the amount of local variables.
	 * @param _scopeKey a bytes32 scope key
	 * @param _agreement an ActiveAgreement as the source of existing address scopes
	 * @param _processInstance a ProcessInstance as the target to which to transfer the address scopes
	 * @param _model a ProcessModel to lookup additional information about participants connected to the agreement scopes
	 */
	function transferAddressScope(bytes32 _scopeKey, ActiveAgreement _agreement, ProcessInstance _processInstance, ProcessModel _model)
		internal
	{
		(address scopeAddress, bytes32 scopeContext, bytes32 fixedScope, bytes32 dataPath, bytes32 dataStorageId, address dataStorage) = _agreement.getAddressScopeDetailsForKey(_scopeKey);
		// check on the model if the context was used as a dataPath on the agreement to define a participant
		bytes32 participant = _model.getConditionalParticipant(scopeContext, DATA_ID_AGREEMENT, address(_agreement));
		if (participant != "") {
			// retrieve all activities connected to that participant
			bytes32[] memory activityIds = ProcessDefinition(_processInstance.getProcessDefinition()).getActivitiesForParticipant(participant);
			if (activityIds.length > 0) {
				// conditional address scopes using dataStorageId are relative to the agreement and need to be replaced with the absolute address to remain valid in the PI
				if (dataStorageId != "" || dataStorage == address(0)) {
					dataStorage = DataStorageUtils.resolveDataStorageAddress(dataStorageId, dataStorage, _agreement);
					delete dataStorageId;
				}
				for (uint j=0; j<activityIds.length; j++) {
					// This is where the scope context of the agreement (using field IDs) is replaced with a context of activity IDs
					_processInstance.setAddressScope(scopeAddress, activityIds[j], fixedScope, dataPath, dataStorageId, dataStorage);
				}
			}
		}
	}

    /**
     * @dev Gets number of activeAgreements
     * @return size size
     */
    function getActiveAgreementsSize() external view returns (uint size) {
        return ActiveAgreementRegistryDb(database).getNumberOfActiveAgreements();
    }

    /**
     * @dev Gets the ActiveAgreement address at given index
     * @param _index the index position
     * @return the Active Agreement address
     */
	function getActiveAgreementAtIndex(uint _index) external view returns (address activeAgreement) {
    	return ActiveAgreementRegistryDb(database).getActiveAgreementAtIndex(_index);
    }

    /**
     * @dev Gets parties size for given Active Agreement
     * @param _activeAgreement Active Agreement
     * @return the number of parties
     */
	function getPartiesByActiveAgreementSize(address _activeAgreement) external view returns (uint size) {
    	return ActiveAgreement(_activeAgreement).getNumberOfParties();
    }

    /**
     * @dev Gets getPartyByActiveAgreementAtIndex
     * @param _activeAgreement Active Agreement
     * @param _index index
     * @return the party address or 0x0 if the index is out of bounds
     */
	function getPartyByActiveAgreementAtIndex(address _activeAgreement, uint _index) public view returns (address party) {
		return ActiveAgreement(_activeAgreement).getPartyAtIndex(_index);
    }

    /**
     * @dev Returns data about the ActiveAgreement at the specified address, if it is an agreement known to this registry.
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
	function getActiveAgreementData(address _activeAgreement) external view returns (
		address archetype,
		address creator,
		string memory privateParametersFileReference,
		string memory eventLogFileReference,
		uint maxNumberOfEvents,
		bool isPrivate,
		uint8 legalState,
		address formationProcessInstance,
		address executionProcessInstance)
	{
		if (ActiveAgreementRegistryDb(database).isAgreementRegistered(_activeAgreement)) {
			archetype = ActiveAgreement(_activeAgreement).getArchetype();
			creator = ActiveAgreement(_activeAgreement).getCreator();
			privateParametersFileReference = ActiveAgreement(_activeAgreement).getPrivateParametersReference();
			eventLogFileReference = ActiveAgreement(_activeAgreement).getEventLogReference();
			maxNumberOfEvents = ActiveAgreement(_activeAgreement).getMaxNumberOfEvents();			
			isPrivate = ActiveAgreement(_activeAgreement).isPrivate();
			legalState = ActiveAgreement(_activeAgreement).getLegalState();
			//TODO currently the references to process instances are being tracked in the registry, so they can be added
			// here for external data collection. Once the "Update..." events move into the individual agreements,
			// the agreement can track its own processes. Note: Questions arise over ownership of the processes for aborting;
			// the registry could transfer ownership to the agreement when starting the process instances, for example.
			formationProcessInstance = ActiveAgreementRegistryDb(database).getAgreementFormationProcess(_activeAgreement);
			executionProcessInstance = ActiveAgreementRegistryDb(database).getAgreementExecutionProcess(_activeAgreement);
		}
	}

  /**
	 * @dev Returns the number of agreement parameter values.
	 * @return the number of parameters
	 */
	function getNumberOfAgreementParameters(address _address) external view returns (uint size) {
			size = ActiveAgreement(_address).getNumberOfData();
	}

  /**
	 * @dev Returns the ID of the agreement parameter value at the given index.
	 * @param _pos the index
	 * @return the parameter ID
	 */
	function getAgreementParameterAtIndex(address _address, uint _pos) external view returns (bytes32 dataId) {
			uint error;
			(error, dataId) = ActiveAgreement(_address).getDataIdAtIndex(_pos);
	}

  /**
	 * @dev Returns information about the process data entry for the specified process and data ID
	 * @param _address the active agreement
	 * @param _dataId the parameter ID
	 * @return (process,id,uintValue,bytes32Value,addressValue,boolValue)
	 */
	function getAgreementParameterDetails(address _address, bytes32 _dataId) external view returns (
			address process,
			bytes32 id,
			uint uintValue,
			int intValue,
			bytes32 bytes32Value,
			address addressValue,
			bool boolValue) {

			process = _address;
			id = _dataId;
			uintValue = ActiveAgreement(_address).getDataValueAsUint(_dataId);
			intValue = ActiveAgreement(_address).getDataValueAsInt(_dataId);
			bytes32Value = ActiveAgreement(_address).getDataValueAsBytes32(_dataId);
			addressValue = ActiveAgreement(_address).getDataValueAsAddress(_dataId);
			boolValue = ActiveAgreement(_address).getDataValueAsBool(_dataId);
	}

    /**
     * @dev Returns data about the given party's signature on the specified agreement.
	 * @param _activeAgreement the ActiveAgreement
	 * @param _party the signing party
	 * @return signedBy the actual signature authorized by the party
	 * @return signatureTimestamp the timestamp when the party has signed, or 0 if not signed yet
	 */
	function getPartyByActiveAgreementData(address _activeAgreement, address _party) external view returns (address signedBy, uint signatureTimestamp) {
		(signedBy, signatureTimestamp) = ActiveAgreement(_activeAgreement).getSignatureDetails(_party);
	}

	/**
	 * @dev Creates a new agreement collection
	 * @param _author address of the author
	 * @param _collectionType the Agreements.CollectionType
	 * @param _packageId the ID of an archetype package
	 * @return error BaseErrors.NO_ERROR(), BaseErrors.NULL_PARAM_NOT_ALLOWED(), BaseErrors.RESOURCE_ALREADY_EXISTS()
	 * @return id bytes32 id of package
	 */
	function createAgreementCollection(address _author, Agreements.CollectionType _collectionType, bytes32 _packageId) external returns (uint error, bytes32 id) {
		if (_author == address(0) || _packageId == "") return (BaseErrors.NULL_PARAM_NOT_ALLOWED(), "");
		id = keccak256(abi.encodePacked(abi.encodePacked(ActiveAgreementRegistryDb(database).getNumberOfCollections(), _packageId, block.timestamp)));
		error = ActiveAgreementRegistryDb(database).createCollection(id, _author, _collectionType, _packageId);
		if (error == BaseErrors.NO_ERROR()) {
			emit LogAgreementCollectionCreation(
				EVENT_ID_AGREEMENT_COLLECTIONS,
				id,
				_author,
				uint8(_collectionType),
				_packageId
			);
		}
	}

	/**
	 * @dev Gets number of agreement collections
	 * @return size size
	 */
	function getNumberOfAgreementCollections() external view returns (uint size) {
		return ActiveAgreementRegistryDb(database).getNumberOfCollections();
	}

	/**
	 * @dev Gets collection id at index
	 * @param _index uint index
	 * @return id bytes32 id
	 */
	function getAgreementCollectionAtIndex(uint _index) external view returns (bytes32 id) {
		return ActiveAgreementRegistryDb(database).getCollectionAtIndex(_index);
	}

	/**
	 * @dev Gets collection data by id
	 * @param _id bytes32 collection id
	 * @return author address
	 * @return collectionType type of collection
	 * @return packageId id of the archetype package
	 */
	function getAgreementCollectionData(bytes32 _id) external view returns (address author, uint8 collectionType, bytes32 packageId) {
		(author, collectionType, packageId) = ActiveAgreementRegistryDb(database).getCollectionData(_id);
	}

	/**
	 * @dev Gets number of agreements in given collection
	 * @param _id id of the collection
	 * @return size agreement count
	 */
	function getNumberOfAgreementsInCollection(bytes32 _id) external view returns (uint size) {
		return ActiveAgreementRegistryDb(database).getNumberOfAgreementsInCollection(_id);
	}

	/**
	 * @dev Gets agreement address at index in colelction
	 * @param _id id of the collection
	 * @param _index uint index
	 * @return agreement address of archetype
	 */
	function getAgreementAtIndexInCollection(bytes32 _id, uint _index) external view returns (address agreement) {
		return ActiveAgreementRegistryDb(database).getAgreementAtIndexInCollection(_id, _index);
	}

	/**
	 * @dev Returns the number governing agreements for given agreement
	 * @return the number of governing agreements
	 */
	function getNumberOfGoverningAgreements(address _agreement) external view returns (uint size) {
		return ActiveAgreement(_agreement).getNumberOfGoverningAgreements();
	}

	/**
	 * @dev Retrieves the address for the governing agreement at the specified index
	 * @param _agreement the address of the agreement
	 * @param _index the index position
	 * @return the address for the governing agreement
	 */
	function getGoverningAgreementAtIndex(address _agreement, uint _index) external view returns (address governingAgreement) {
		return ActiveAgreement(_agreement).getGoverningAgreementAtIndex(_index);
	}

	/**
	 * @dev Overwrites AbstractEventListener function to receive state updates from ActiveAgreements that are registered in this registry.
	 * Currently supports AGREEMENT_STATE_CHANGED
	 */
	function eventFired(bytes32 _event, address /*_source*/) external pre_OnlyByRegisteredAgreements {
		if (_event == ActiveAgreement(msg.sender).EVENT_ID_STATE_CHANGED()) {
			// CANCELED and DEFAULT trigger aborting any running processes for this agreement
			if (ActiveAgreement(msg.sender).getLegalState() == uint8(Agreements.LegalState.CANCELED) ||
				ActiveAgreement(msg.sender).getLegalState() == uint8(Agreements.LegalState.DEFAULT)) {
					if (ActiveAgreementRegistryDb(database).getAgreementFormationProcess(msg.sender) != address(0)) {
						ProcessInstance(ActiveAgreementRegistryDb(database).getAgreementFormationProcess(msg.sender)).abort();
					}
					if (ActiveAgreementRegistryDb(database).getAgreementExecutionProcess(msg.sender) != address(0)) {
						ProcessInstance(ActiveAgreementRegistryDb(database).getAgreementExecutionProcess(msg.sender)).abort();
					}
			}
		}
	}

	/**
	 * Implements the listener function which updates agreements linked to the given process instance
	 * @param _processInstance the process instance whose state has changed
	 */
	function processStateChanged(ProcessInstance _processInstance) external {
		if (_processInstance.getState() == uint8(BpmRuntime.ProcessInstanceState.COMPLETED)) {
			address agreementAddress = _processInstance.getDataValueAsAddress(DATA_ID_AGREEMENT);
			// check if this is an agreement managed in this registry
			if (!ActiveAgreementRegistryDb(database).isAgreementRegistered(agreementAddress)) {
				return;
			}
			ActiveAgreement agreement = ActiveAgreement(agreementAddress);

			// FORMATION PROCESS
			// the agreement must be in legal state EXECUTED to trigger the execution process
			if (_processInstance.getProcessDefinition() == Archetype(agreement.getArchetype()).getFormationProcessDefinition() &&
				agreement.getLegalState() == uint8(Agreements.LegalState.EXECUTED)) {
				// if the archetype has an execution process defined, start it
				if (Archetype(agreement.getArchetype()).getExecutionProcessDefinition() != address(0)) {
					ProcessInstance newPi = createExecutionProcess(agreement);
					// keep track of the execution process for the agreement
					// NOTE: we're currently not checking if there is already a tracked execution process, because no execution path can currently lead to that situation
					ActiveAgreementRegistryDb(database).setAgreementExecutionProcess(address(agreement), address(newPi));
					// we deliberately accept the fact that the artifactsFinder could still be 0x0, if the contract was never initialized correctly
					// However, when deployed through DOUG, the artifactsFinder is set, so we avoid having to check every time.
					(address serviceAddress, ) = artifactsFinder.getArtifact(serviceIdBpmService);
					ErrorsLib.revertIf(serviceAddress == address(0),
						ErrorsLib.DEPENDENCY_NOT_FOUND(), "DefaultActiveAgreementsRegistry.createFormationProcess", "BpmService dependency not found in ArtifactsFinder");
					BpmService(serviceAddress).startProcessInstance(newPi); // Note: Disregarding the error code here. If there was an error in the execution process, it should either REVERT or leave the PI in INTERRUPTED state
				}
			}
			// EXECUTION PROCESS
			// the agreement must NOT be in legal states DEFAULT or CANCELED in order to be regarded as FULFILLED
			else if (_processInstance.getProcessDefinition() == Archetype(agreement.getArchetype()).getExecutionProcessDefinition() &&
					 agreement.getLegalState() != uint8(Agreements.LegalState.DEFAULT) &&
					 agreement.getLegalState() != uint8(Agreements.LegalState.CANCELED)) {
				agreement.setFulfilled();
			}
		}
	}

	/**
	 * @dev Updates the file reference for the event log of the specified agreement
	 * @param _activeAgreement Address of active agreement
	 * @param _eventLogFileReference the file reference of the event log of this agreement
	 */
	function setEventLogReference(address _activeAgreement, string calldata _eventLogFileReference) external {
		ActiveAgreement(_activeAgreement).setEventLogReference(_eventLogFileReference);
	}

	/**
	 * @dev Updates the file reference for the signature log of the specified agreement
	 * @param _activeAgreement the address of active agreement
	 * @param _signatureLogFileReference the file reference of the signature log of this agreement
	 */
	function setSignatureLogReference(address _activeAgreement, string calldata _signatureLogFileReference) external {
		ActiveAgreement(_activeAgreement).setSignatureLogReference(_signatureLogFileReference);
	}

	/**
	 * @dev Returns the BpmService address
	 * @return address the BpmService
	 */
	function getBpmService() external returns (address location) {
    (location, ) = artifactsFinder.getArtifact(serviceIdBpmService);
	}

	/**
	 * @dev Returns the ArchetypeRegistry address
	 * @return address the ArchetypeRegistry
	 */
	function getArchetypeRegistry() external returns (address location) {
    (location, ) = artifactsFinder.getArtifact(serviceIdArchetypeRegistry);
	}

}
