pragma solidity ^0.5;

import "commons-base/Versioned.sol";
import "commons-base/Bytes32Identifiable.sol";
import "commons-management/VersionedArtifact.sol";

import "bpm-model/BpmModel.sol";

/**
 * @title ProcessModel Interface
 * @dev Versionized container providing a namespace for a set of business process definitions and their artifacts. 
 */
contract ProcessModel is VersionedArtifact, Versioned, Bytes32Identifiable {

	event LogProcessModelCreation(
		bytes32 indexed eventId,
		address modelAddress,
		bytes32 id,
		uint versionMajor,
		uint versionMinor,
		uint versionPatch,
		address author,
		bool isPrivate,
		bool active,
		string modelFileReference
	);

	event LogProcessModelDataCreation(
		bytes32 indexed eventId,
		bytes32 dataId,
		bytes32 dataPath,
		address modelAddress,
		uint parameterType
	);

	bytes32 public constant EVENT_ID_PROCESS_MODELS = "AN://process-models";
	bytes32 public constant EVENT_ID_PROCESS_DEFINITIONS = "AN://process-definitions";
	bytes32 public constant EVENT_ID_PROCESS_MODEL_DATA = "AN://process-model-data";

    string public constant OBJECT_CLASS_PROCESS_DEFINITION = "bpm.model.ProcessDefinition";

	/**
	 * @dev Initializes this DefaultOrganization with the provided parameters. This function replaces the
	 * contract constructor, so it can be used as the delegate target for an ObjectProxy.
	 * @param _id the model ID
	 * @param _version the model version
	 * @param _author the model author
	 * @param _isPrivate indicates if model is visible only to creator
	 * @param _modelFileReference the reference to the external model file from which this ProcessModel originated
	 */
	function initialize(bytes32 _id, uint8[3] calldata _version, address _author, bool _isPrivate, string calldata _modelFileReference) external;

	/**
	 * @dev Creates a new process definition with the given parameters in this ProcessModel
	 * @param _id the process ID
	 * @param _artifactsFinder the address of an ArtifactsFinder
	 * @return the address of the new ProcessDefinition when successful
	 */
	function createProcessDefinition(bytes32 _id, address _artifactsFinder) external returns (address newAddress);
	
	/**
	 * @dev Returns the address of the ProcessDefinition with the specified ID
	 * @param _id the process ID
	 * @return the address of the process definition, if it exists
	 */
	function getProcessDefinition(bytes32 _id) external view returns (address);

	/**
	 * @dev Returns the file reference for the model file
	 * @return the external file reference
	 */
	function getModelFileReference() external view returns (string memory);

	/**
	 * @dev Returns model author address
	 * @return the model author
	 */
	function getAuthor() external view returns (address);

	/**
	 * @dev Returns whether the model is private
	 * @return true if the model is private, false otherwise
	 */
	function isPrivate() external view returns (bool);

	/**
	 * @dev Adds a process interface declaration to this ProcessModel that process definitions can refer to
	 * @param _interfaceId the ID of the interface
	 * @return an error code indicating success of failure
	 */
	function addProcessInterface(bytes32 _interfaceId) external returns (uint error);

	/**
	 * @dev Adds a participant with the specified ID and attributes to this ProcessModel
	 * @param _id the participant ID
	 * @param _account the address of a participant account
	 * @param _dataStorage the address of a DataStorage contract to find a conditional participant
	 * @param _dataStorageId a field key in a known DataStorage containing an address of another DataStorage contract
	 * @param _dataPath the field key under which to locate the conditional participant
	 * @return an error code indicating success or failure
	 */
	function addParticipant(bytes32 _id, address _account, bytes32 _dataPath, bytes32 _dataStorageId, address _dataStorage) external returns (uint error);

	/**
	 * @dev Returns the participant ID in this model that matches the given ConditionalData parameters.
	 * @param _dataPath a data path
	 * @param _dataStorageId the path to a DataStorage
	 * @param _dataStorage the address of a DataStorage
	 * @return the ID of a participant or an empty bytes32, if no matching participant exists
	 */
	function getConditionalParticipant(bytes32 _dataPath, bytes32 _dataStorageId, address _dataStorage) external view returns (bytes32);
	
	/**
	 * @dev Returns the number of process interfaces declared in this ProcessModel
	 * @return the number of process interfaces
	 */
	function getNumberOfProcessInterfaces() external view returns (uint);

	/**
	 * @dev Returns whether a process interface with the specified ID exists in this ProcessModel
	 * @param _interfaceId the interface ID
	 * @return true if it exists, false otherwise
	 */
	function hasProcessInterface(bytes32 _interfaceId) external view returns (bool);

	/**
	 * @dev Returns the number of process definitions in this ProcessModel
	 * @return the number of process definitions
	 */
	function getNumberOfProcessDefinitions() external view returns (uint);

	/**
	 * @dev Returns the address for the ProcessDefinition at the given index
	 * @param _idx the index position
	 * @return the address of the ProcessDefinition, if it exists
	 */
	function getProcessDefinitionAtIndex(uint _idx) external view returns (address);

	/**
	 * @dev Returns the number of participants defined in this ProcessModel
	 * @return the number of participants
	 */
	function getNumberOfParticipants() external view returns (uint size);

	/**
	 * @dev Returns the ID of the participant at the given index
	 * @param _idx the index position
	 * @return the participant ID, if it exists
	 */
	function getParticipantAtIndex(uint _idx) external view returns (bytes32);

	/**
	 * @dev Returns information about the participant with the given ID
	 * @param _id the participant ID
	 * @return location the applications contract address, only available for a service participant
	 * @return method the function signature of the participant, only available for a service participant
	 * @return webForm the form identifier (formHash) of the web participant, only available for a web participant
	 */
	function getParticipantData(bytes32 _id) external view returns (address account, bytes32 dataPath, bytes32 dataStorageId, address dataStorage);

	/**
	 * @dev Returns whether a participant with the specified ID exists in this ProcessModel
	 * @param _id the participant ID
	 * @return true if it exists, false otherwise
	 */
	function hasParticipant(bytes32 _id) external view returns (bool);

	/**
	 * @dev Adds a data definition to this ProcessModel
	 * @param _dataId the ID of the data object
	 * @param _dataPath the path to a data value
	 * @param _parameterType the DataTypes.ParameterType of the data object
	 */
	function addDataDefinition(bytes32 _dataId, bytes32 _dataPath, DataTypes.ParameterType _parameterType) external;

	/**
	 * @dev Returns the number of data definitions in the ProcessModel
	 * @return the number of data definitions
	 */
	function getNumberOfDataDefinitions() external view returns (uint);

	/**
	 * @dev Returns details about the data definition at the given index position
	 * @param _index the index position
	 * @return key - the key of the data definition
	 * @return parameterType - the uint representation of the DataTypes.ParameterType
	 */
	function getDataDefinitionDetailsAtIndex(uint _index) external view returns (bytes32 key, uint parameterType);

}