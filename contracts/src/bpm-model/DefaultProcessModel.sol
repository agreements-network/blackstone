pragma solidity ^0.5;

import "commons-base/BaseErrors.sol";
import "commons-base/ErrorsLib.sol";
import "commons-base/AbstractVersioned.sol";
import "commons-collections/Mappings.sol";
import "commons-collections/MappingsLib.sol";
import "commons-management/ObjectProxy.sol";
import "commons-management/AbstractVersionedArtifact.sol";
import "commons-management/AbstractDelegateTarget.sol";

import "bpm-model/BpmModel.sol";
import "bpm-model/DefaultProcessDefinition.sol";

/**
 * @title DefaultProcessModel
 * @dev Default implementation of the ProcessModel interface 
 */
contract DefaultProcessModel is AbstractVersionedArtifact(1,0,0), AbstractDelegateTarget, AbstractVersioned, ProcessModel {

	using MappingsLib for Mappings.Bytes32AddressMap;
	using MappingsLib for Mappings.Bytes32UintMap;

	bytes32 id;
	address author;
	bool privateFlag;
	string modelFileReference;

	bytes32[] processInterfaceKeys;
	mapping(bytes32 => bool) processInterfaces;
	Mappings.Bytes32UintMap dataDefinitions;
	Mappings.Bytes32AddressMap processDefinitions;
	BpmModel.ParticipantMap participants;

	/**
	 * @dev Initializes this DefaultProcessModel with the provided parameters. This function replaces the
	 * contract constructor, so it can be used as the delegate target for an ObjectProxy.
	 * @param _id the model ID
	 * @param _version the model version
	 * @param _author the model author
	 * @param _isPrivate indicates if model is visible only to creator
	 * @param _modelFileReference the reference to the external model file from which this ProcessModel originated
	 */
	function initialize(bytes32 _id, uint8[3] calldata _version, address _author, bool _isPrivate, string calldata _modelFileReference)
		external
		pre_post_initialize
	{
		id = _id;
		semanticVersion = _version;
		modelFileReference = _modelFileReference;
		author = _author;
		modelFileReference = _modelFileReference;
		emit LogProcessModelCreation(
			EVENT_ID_PROCESS_MODELS,
			address(this),
			_id,
			_version[0],
			_version[1],
			_version[2],
			_author,
			_isPrivate,
			false,
			_modelFileReference
		);
	}
	
	/**
	 * @dev Creates a new process definition with the given parameters in this ProcessModel.
	 * REVERTS if:
	 * - a ProcessDefinition with the same ID already exists in the ProcessModel
	 * - the new ProcessDefinition cannot be added to the #definitions mapping
	 * @param _processDefinitionId the process definition ID
	 * @param _artifactsFinder an ArtifactFinder instance to create the ObjectProxy
	 * @return newAddress - the address of the new ObjectProxy for the ProcessDefinition when successful
	 */
	function createProcessDefinition(bytes32 _processDefinitionId, address _artifactsFinder) external returns (address newAddress) {
		ErrorsLib.revertIf(processDefinitions.exists(_processDefinitionId),
			ErrorsLib.RESOURCE_ALREADY_EXISTS(), "DefaultProcessModel.createProcessDefinition", "A ProcessDefinition with the same ID already exists in this ProcessModel");
		newAddress = address(new ObjectProxy(_artifactsFinder, OBJECT_CLASS_PROCESS_DEFINITION));
		ProcessDefinition(newAddress).initialize(_processDefinitionId, address(this));
		ErrorsLib.revertIf(processDefinitions.insert(_processDefinitionId, newAddress) != BaseErrors.NO_ERROR(),
			ErrorsLib.INVALID_STATE(), "DefaultProcessModel.createProcessDefinition", "Unable to add the new ProcessDefinition to the collection");
	}
	
	/**
	 * @dev Returns the address of the ProcessDefinition with the specified ID
	 * @param _id the process ID
	 * @return the address of the process definition, if it exists
	 */
	function getProcessDefinition(bytes32 _id) external view returns (address) {
		return processDefinitions.rows[_id].value;
	}

	/**
	 * @dev Returns the file reference for the model file
	 * @return the external file reference
	 */
	function getModelFileReference() external view returns (string memory) {
		return modelFileReference;
	}

	/**
	 * @dev Returns model author address
	 * @return the model author
	 */
	function getAuthor() external view returns (address) {
		return author;
	}

	/**
	 * @dev Returns this model's ID
	 * @return the model ID
	 */
	function getId() external view returns (bytes32) {
		return id;
	}

	/**
	 * @dev Returns whether the model is private
	 * @return true if the model is private, false otherwise
	 */
	function isPrivate() external view returns (bool) {
		return privateFlag;
	}

	/**
	 * @dev Adds a process interface declaration to this ProcessModel that process definitions can refer to
	 * @param _interfaceId the ID of the interface
	 * @return BaseErrors.RESOURCE_ALREADY_EXISTS() if an interface with the given ID already exists, BaseErrors.NO_ERROR() otherwise
	 */
	function addProcessInterface(bytes32 _interfaceId) external returns (uint) {
		if (processInterfaces[_interfaceId]) return BaseErrors.RESOURCE_ALREADY_EXISTS();
		processInterfaces[_interfaceId] = true;
		processInterfaceKeys.push(_interfaceId);
		return BaseErrors.NO_ERROR();
	}

	/**
	 * @dev Adds a participant with the specified ID and attributes to this ProcessModel
	 * @param _id the participant ID
	 * @param _account the address of a participant account
	 * @param _dataStorage the address of a DataStorage contract to find a conditional participant
	 * @param _dataStorageId a field key in a known DataStorage containing an address of another DataStorage contract
	 * @param _dataPath the field key under which to locate the conditional participant
	 * @return BaseErrors.INVALID_PARAM_VALUE() if both participant and conditional participant are being attempted to be set or if the config for a conditional participant is missing the _dataPath
	 * @return BaseErrors.NO_ERROR() if successful
	 */
	function addParticipant(bytes32 _id, address _account, bytes32 _dataPath, bytes32 _dataStorageId, address _dataStorage) external returns (uint error) {
		if (participants.rows[_id].exists) {
			return BaseErrors.RESOURCE_ALREADY_EXISTS();
		}
		// 1. single participant and conditional participant configs are mutually exclusive
		// 2. conditional participant must have a dataPath set
		if ((_account != address(0) && (_dataStorage != address(0) || _dataStorageId != "")) ||
			(_account == address(0) && _dataPath == "")) {
			return BaseErrors.INVALID_PARAM_VALUE();
		}

		participants.rows[_id].keyIdx = participants.keys.push(_id);
		participants.rows[_id].value.id = _id;
		if (_account != address(0)) {
			participants.rows[_id].value.account = _account;
		} else {
			participants.rows[_id].value.conditionalPerformer = DataStorageUtils.ConditionalData({dataStorage: _dataStorage, dataStorageId: _dataStorageId, dataPath: _dataPath, exists: true});
		}
		participants.rows[_id].exists = true;

		return BaseErrors.NO_ERROR();
	}

	/**
	 * @dev Returns the participant ID in this model that matches the given ConditionalData parameters.
	 * @param _dataPath a data path
	 * @param _dataStorageId the path to a DataStorage
	 * @param _dataStorage the address of a DataStorage
	 * @return the ID of a participant or an empty bytes32, if no matching participant exists
	 */
	function getConditionalParticipant(bytes32 _dataPath, bytes32 _dataStorageId, address _dataStorage) external view returns (bytes32) {
		for (uint i=0; i<participants.keys.length; i++) {
			if (participants.rows[participants.keys[i]].value.conditionalPerformer.exists &&
				participants.rows[participants.keys[i]].value.conditionalPerformer.dataPath == _dataPath &&
			    ((participants.rows[participants.keys[i]].value.conditionalPerformer.dataStorageId != "" &&
			      participants.rows[participants.keys[i]].value.conditionalPerformer.dataStorageId == _dataStorageId) ||
			     (participants.rows[participants.keys[i]].value.conditionalPerformer.dataStorage != address(0) &&
			      participants.rows[participants.keys[i]].value.conditionalPerformer.dataStorage == _dataStorage))) {
					  
					return participants.rows[participants.keys[i]].value.id;
				}
		}
	}

	/**
	 * @dev Returns the number of process interfaces declared in this ProcessModel
	 * @return the number of process interfaces
	 */
	function getNumberOfProcessInterfaces() external view returns (uint) {
		return processInterfaceKeys.length;
	}

	/**
	 * @dev Returns whether a process interface with the specified ID exists in this ProcessModel
	 * @param _interfaceId the interface ID
	 * @return true if it exists, false otherwise
	 */
	function hasProcessInterface(bytes32 _interfaceId) external view returns (bool) {
		return processInterfaces[_interfaceId];
	}

	/**
	 * @dev Returns the number of process definitions in this ProcessModel
	 * @return the number of process definitions
	 */
	function getNumberOfProcessDefinitions() external view returns (uint) {
		return processDefinitions.keys.length;
	}

	/**
	 * @dev Returns the address for the ProcessDefinition at the given index
	 * @param _idx the index position
	 * @return the address of the ProcessDefinition, if it exists
	 */
	function getProcessDefinitionAtIndex(uint _idx) external view returns (address) {
		return processDefinitions.get(processDefinitions.keys[_idx]);
	}

	/**
	 * @dev Returns the number of participants defined in this ProcessModel
	 * @return the number of participants
	 */
	function getNumberOfParticipants() external view returns (uint) {
		return participants.keys.length;
	}

	/**
	 * @dev Returns the ID of the participant at the given index
	 * @param _idx the index position
	 * @return the participant ID, if it exists
	 */
	function getParticipantAtIndex(uint _idx) external view returns (bytes32) {
		return participants.keys[_idx];
	}

	/**
	 * @dev Returns information about the participant with the given ID
	 * @param _id the participant ID
	 * @return location the applications contract address, only available for a service participant
	 * @return method the function signature of the participant, only available for a service participant
	 * @return webForm the form identifier (formHash) of the web participant, only available for a web participant
	 */
	function getParticipantData(bytes32 _id) external view returns (address account, bytes32 dataPath, bytes32 dataStorageId, address dataStorage) {
		account = participants.rows[_id].value.account;
		dataPath = participants.rows[_id].value.conditionalPerformer.dataPath;
		dataStorageId = participants.rows[_id].value.conditionalPerformer.dataStorageId;
		dataStorage = participants.rows[_id].value.conditionalPerformer.dataStorage;
	}

	/**
	 * @dev Returns whether a participant with the specified ID exists in this ProcessModel
	 * @param _id the participant ID
	 * @return true if it exists, false otherwise
	 */
	function hasParticipant(bytes32 _id) external view returns (bool) {
		return participants.rows[_id].exists;
	}

	/**
	 * @dev Adds a data definition to this ProcessModel
	 * The data definitions are stored under an artificial key derived as the hash of the _dataId and _dataPath parameter values.
	 * @param _dataId the ID of the data object
	 * @param _dataPath the path to a data value
	 * @param _parameterType the DataTypes.ParameterType of the data object
	 */
	function addDataDefinition(bytes32 _dataId, bytes32 _dataPath, DataTypes.ParameterType _parameterType) external {
		dataDefinitions.insertOrUpdate(keccak256(abi.encodePacked(_dataId, _dataPath)), uint(_parameterType));
		emit LogProcessModelDataCreation(EVENT_ID_PROCESS_MODEL_DATA, _dataId, _dataPath, address(this), uint(_parameterType));
	}

	/**
	 * @dev Returns the number of data definitions in the ProcessModel
	 * @return the number of data definitions
	 */
	function getNumberOfDataDefinitions() external view returns (uint) {
		return dataDefinitions.keys.length;
	}

	/**
	 * @dev Returns details about the data definition at the given index position
	 * REVERTS if:
	 * - the index is out of bounds
	 * @param _index the index position
	 * @return key - the key of the data definition
	 * @return parameterType - the uint representation of the DataTypes.ParameterType
	 */
	function getDataDefinitionDetailsAtIndex(uint _index) external view returns (bytes32 key, uint parameterType) {
		ErrorsLib.revertIf(_index >= dataDefinitions.keys.length,
			ErrorsLib.INVALID_INPUT(), "DefaultProcessModel.getDataDefinitionDetailsAtIndex", "The given index value is out-of-bounds of the data definitions collection");
		key = dataDefinitions.keys[_index];
		parameterType = dataDefinitions.get(key);
	}

}