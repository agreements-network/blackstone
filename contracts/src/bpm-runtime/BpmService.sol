pragma solidity ^0.5;

import "commons-management/Upgradeable.sol";
import "bpm-model/ProcessModelRepository.sol";

import "bpm-runtime/ApplicationRegistry.sol";
import "bpm-runtime/ProcessInstance.sol";
import "bpm-runtime/BpmServiceDb.sol";

/**
 * @title BpmService Interface
 * @dev Manages manual tasks, processes, and their data.
 */
contract BpmService is ObjectFactory, Upgradeable {

    string public constant OBJECT_CLASS_PROCESS_INSTANCE = "bpm.runtime.ProcessInstance";

	/**
	 * @dev Gets the ProcessModelRepository address for this BpmService
	 * @return the address of the repository
	 */
	function getProcessModelRepository() external view returns (ProcessModelRepository);

	/**
	 * @dev Returns a reference to the ApplicationRegistry currently used by this BpmService
	 * @return the ApplicationRegistry
	 */
    function getApplicationRegistry() external view returns (ApplicationRegistry);

	/**
	 * @dev Creates a new ProcessInstance based on the specified ProcessDefinition and starts its execution
	 * @param _processDefinition the address of a ProcessDefinition
	 * @param _activityInstanceId the ID of a subprocess activity instance that initiated this ProcessInstance (optional)
	 * @return error code indicating success or failure
	 * @return instance the address of a ProcessInstance, if successful
	 */
	function startProcess(address _processDefinition, bytes32 _activityInstanceId) public returns (uint error, address);

	/**
	 * @dev Creates a new ProcessInstance based on the specified IDs of a ProcessModel and ProcessDefinition and starts its execution
	 * @param _modelId the model that qualifies the process ID, if multiple models are deployed, otherwise optional
	 * @param _processDefinitionId the ID of the process definition
	 * @param _activityInstanceId the ID of a subprocess activity instance that initiated this ProcessInstance (optional)
	 * @return error code indicating success or failure
	 * @return instance the address of a ProcessInstance, if successful
	 */
	function startProcessFromRepository(bytes32 _modelId, bytes32 _processDefinitionId, bytes32 _activityInstanceId) public returns (uint error, address);

	/**
	 * @dev Initializes, registers, and executes a given ProcessInstance
	 * @param _pi the ProcessInstance
	 * @return BaseErrors.NO_ERROR() if successful or an error code from initializing or executing the ProcessInstance
	 */
	function startProcessInstance(ProcessInstance _pi) public returns (uint error);

	/**
	 * @dev Creates a new ProcessInstance initiated with the provided parameters. This ProcessInstance can be further customized and then
	 * submitted to the #startProcessInstance(ProcessInstance) function for execution.
	 * @param _processDefinition the address of a ProcessDefinition
	 * @param _startedBy the address of an account that regarded as the starting user
     * @param _activityInstanceId the ID of a subprocess activity instance that initiated this ProcessInstance (optional)
	 */
	function createDefaultProcessInstance(address _processDefinition, address _startedBy, bytes32 _activityInstanceId) public returns (ProcessInstance);

	/**
	 * @dev Returns the number of Process Instances.
	 * @return the process instance count as size
	 */
	function getNumberOfProcessInstances() external view returns (uint size);

	/**
	 * @dev Returns the process instance address at the specified index
	 * @param _pos the index
	 * @return the process instance address or or BaseErrors.INDEX_OUT_OF_BOUNDS(), 0x0
	 */
	function getProcessInstanceAtIndex(uint _pos) external view returns (address processInstanceAddress);

	/**
	 * @dev Returns information about the process intance with the specified address
	 * @param _address the process instance address
	 * @return processDefinition the address of the ProcessDefinition
	 * @return state the BpmRuntime.ProcessInstanceState as uint8
	 * @return startedBy the address of the account who started the process
	 */
	function getProcessInstanceData(address _address) external view returns (address processDefinition, uint8 state, address startedBy);

	/**
	 * @dev Returns the number of activity instances.
	 * @return the activity instance count as size
	 */
	function getNumberOfActivityInstances(address _address) external view returns (uint size);

	/**
	 * @dev Returns the ActivityInstance ID at the specified index
	 * @param _address the process instance address
	 * @param _pos the activity instance index
	 * @return the ActivityInstance ID
	 */
	function getActivityInstanceAtIndex(address _address, uint _pos) external view returns (bytes32 activityId);

 	/**
 	 * @dev Returns ActivityInstance data for the given ActivityInstance ID
	 * @param _processInstance the process instance address to which the ActivityInstance belongs
	 * @param _id the global ID of the activity instance
	 * @return activityId - the ID of the activity as defined by the process definition
	 * @return created - the creation timestamp
	 * @return completed - the completion timestamp
	 * @return performer - the account who is performing the activity (for interactive activities only)
	 * @return completedBy - the account who completed the activity (for interactive activities only) 
	 * @return state - the uint8 representation of the BpmRuntime.ActivityInstanceState of this activity instance
	 */
	function getActivityInstanceData(address _processInstance, bytes32 _id) external view returns (
        bytes32 activityId, 
        uint created,
        uint completed,
        address performer,
        address completedBy,
        uint8 state);

	/**
	 * @dev Returns the number of process data entries.
	 * @return the process data size
	 */
	function getNumberOfProcessData(address _address) external view returns (uint size);

	/**
	 * @dev Returns the process data ID at the specified index
	 * @param _pos the index
	 * @return the data ID
	 */
	function getProcessDataAtIndex(address _address, uint _pos) external view returns (bytes32 dataId);

	/**
	 * @dev Returns information about the process data entry for the specified process and data ID
	 * @param _address the process instance
	 * @param _dataId the data ID
	 * @return (process,id,uintValue,bytes32Value,addressValue,boolValue)
	 */
	function getProcessDataDetails(address _address, bytes32 _dataId)
		external view
		returns (uint uintValue,
				 int intValue,
				 bytes32 bytes32Value,
				 address addressValue,
				 bool boolValue);

	/**
	 * @dev Returns the number of address scopes for the given ProcessInstance.
	 * @param _processInstance the address of a ProcessInstance
	 * @return the number of scopes
	 */
	function getNumberOfAddressScopes(address _processInstance) external view returns (uint size);

	/**
	 * @dev Returns the address scope key at the given index position of the specified ProcessInstance.
	 * @param _processInstance the address of a ProcessInstance
	 * @param _index the index position
	 * @return the bytes32 scope key
	 */
	function getAddressScopeKeyAtIndex(address _processInstance, uint _index) external view returns (bytes32);

	/**
	 * @dev Returns detailed information about the address scope with the given key in the specified ProcessInstance
	 * @param _processInstance the address of a ProcessInstance
	 * @param _key a scope key
	 * @return keyAddress - the address encoded in the key
	 * @return keyContext - the context encoded in the key
	 * @return fixedScope - a bytes32 representing a fixed scope
	 * @return dataPath - the dataPath of a ConditionalData defining the scope
	 * @return dataStorageId - the dataStorageId of a ConditionalData defining the scope
	 * @return dataStorage - the dataStorgage address of a ConditionalData defining the scope
	 */
	function getAddressScopeDetails(address _processInstance, bytes32 _key)
		external view
		returns (address keyAddress,
				 bytes32 keyContext,
				 bytes32 fixedScope,
				 bytes32 dataPath,
				 bytes32 dataStorageId,
				 address dataStorage);

	/**
	 * @dev Returns the address of the ProcessInstance of the specified ActivityInstance ID
	 * @param _aiId the ID of an ActivityInstance
	 * @return the ProcessInstance address or 0x0 if it cannot be found
	 */
	function getProcessInstanceForActivity(bytes32 _aiId) external view returns (address);

	/**
	 * @dev Returns a reference to the BpmServiceDb currently used by this BpmService
	 * @return the BpmServiceDb
	 */
	function getBpmServiceDb() external view returns (BpmServiceDb);

}