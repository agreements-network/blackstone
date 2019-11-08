pragma solidity ^0.5;

import "commons-management/Upgradeable.sol";
import "commons-management/ObjectFactory.sol";

import "bpm-model/ProcessModel.sol";
import "bpm-model/BpmModel.sol";

/**
 * @title ProcessModelRepository Interface
 * @dev Manages registered ProcessModel instances with their past and active versions.
 */
contract ProcessModelRepository is ObjectFactory, Upgradeable {
	
	event LogProcessModelActivation(
		bytes32 indexed eventId,
		address modelAddress,
		bool active
	);

    string public constant OBJECT_CLASS_PROCESS_MODEL = "bpm.model.ProcessModel";
    string public constant OBJECT_CLASS_PROCESS_DEFINITION = "bpm.model.ProcessDefinition";

	/**
	 * @dev Factory function to instantiate a ProcessModel. The model is automatically added to this repository.
	 * @param _id the model ID
	 * @param _version the model version
	 * @param _author the model author
	 * @param _isPrivate indicates if the model is private
	 * @param _modelFileReference the reference to the external model file from which this ProcessModel originated
	 */
	function createProcessModel(bytes32 _id, uint8[3] calldata _version, address _author, bool _isPrivate, string calldata _modelFileReference) external returns (uint error, address modelAddress);

	/**
	 * @dev Creates a new process definition with the given parameters in the provided ProcessModel.
	 * @param _processModelAddress the ProcessModel in which to create the ProcessDefinition
	 * @param _processDefinitionId the process definition ID
	 * @return newAddress - the address of the new ProcessDefinition when successful
	 */
	function createProcessDefinition(address _processModelAddress, bytes32 _processDefinitionId) external returns (address newAddress);

	/**
	 * @dev Activates the given ProcessModel and deactivates any previously activated model version of the same ID
	 * @param _model the ProcessModel to activate
	 * @return an error indicating success or failure
	 */
	function activateModel(ProcessModel _model) external returns (uint error);
	
	/**
	 * @dev Returns the address of the activated model with the given ID, if it exists and is activated
	 * @param _id the model ID
	 * @return the model address, if found
	 */
	function getModel(bytes32 _id) external view returns (address);

	/**
	 * @dev Returns the address of the model with the given ID and version
	 * @param _id the model ID
	 * @param _version the model version
	 * @return the model address, if found
	 */	
	function getModelByVersion(bytes32 _id, uint8[3] calldata _version) external view returns (uint error, address modelAddress);

	/**
	 * @dev Returns the number of models in this repository.
	 * @return size - the number of models
	 */
	function getNumberOfModels() external view returns (uint size);

	/**
	 * @dev Returns the address of the ProcessModel at the given index position, if it exists
	 * @param _idx the index position
	 * @return the model address
	 */
	function getModelAtIndex(uint _idx) external view returns (address);

	/**
	 * @dev Returns the process definition address when the model ID and process definition ID are provided
	 * @param _modelId - the ProcessModel ID
	 * @return _processId - the ProcessDefinition ID
	 * @return address - the ProcessDefinition address
	 */
	function getProcessDefinition (bytes32 _modelId, bytes32 _processId) external view returns (address);

	/**
	 * @dev Returns the number of process definitions in the specified model
	 * @param _model a ProcessModel address
	 * @return size - the number of process definitions
	 */
	function getNumberOfProcessDefinitions(address _model) external view returns (uint size);

	/**
	 * @dev Returns the address of the ProcessDefinition at the specified index position of the given model
	 * @param _model a ProcessModel address
	 * @param _idx the index position
	 * @return the ProcessDefinition address, if it exists
	 */
	function getProcessDefinitionAtIndex(address _model, uint _idx) external view returns (address);

	/**
	 * @dev Returns the number of Activity Definitions in the specified Process 
	 * @param _model the model address
	 * @param _processDefinition a Process Definition address
	 * @return uint - the number of Activity Definitions
	 */
	function getNumberOfActivities(address _model, address _processDefinition) external view returns (uint size);

	/**
	 * @dev Returns the ID of the ActivityDefinition at the specified index position of the given Process Definition
	 * @param _model the model address
	 * @param _processDefinition a Process Definition address
	 * @param _index the index position
	 * @return bytes32 the ActivityDefinition ID, if it exists
	 */
	function getActivityAtIndex(address _model, address _processDefinition, uint _index) external view returns (bytes32);

	/**
	 * @dev Returns information about the activity definition with the given ID.
	 * @param _model the model address
	 * @param _processDefinition a Process Definition address
	 * @param _id the bytes32 id of the activity definition
	 * @return activityType the BpmModel.ActivityType as uint8
	 * @return taskType the BpmModel.TaskType as uint8
	 * @return taskBehavior the BpmModel.TaskBehavior as uint8
	 * @return assignee the ID of the activity's assignee (for interactive activities)
	 * @return multiInstance whether the activity is a multi-instance
	 * @return application the activity's application
	 * @return subProcessModelId the ID of a process model (for subprocess activities)
	 * @return subProcessDefinitionId the ID of a process definition (for subprocess activities)
	 */
	function getActivityData(address _model, address _processDefinition, bytes32 _id) external view returns (uint8 activityType, uint8 taskType, uint8 taskBehavior, bytes32 assignee, bool multiInstance, bytes32 application, bytes32 subProcessModelId, bytes32 subProcessDefinitionId);

}