pragma solidity ^0.5;

import "commons-base/SystemOwned.sol";
import "commons-collections/Mappings.sol";
import "commons-collections/MappingsLib.sol";

/**
 * @title BpmServiceDb
 * @dev Stores the ProcessInstances and ActivityInstances for a BPM runtime environment and provides access to them.
 * The DB should be 'owned' by the main BPM service and only the owner can add process instances. Afterwards
 * the registered process instances can add their activity instances to this storage storage as the processes are executed.
 */
contract BpmServiceDb is SystemOwned {

    using MappingsLib for Mappings.AddressAddressMap;
    using MappingsLib for Mappings.Bytes32AddressMap;

    Mappings.AddressAddressMap processInstances;
    Mappings.Bytes32AddressMap activityInstances;

    // modifier to only allow calls to come from a registered ProcessInstance
    modifier pre_onlyRegisteredProcess () {
        if (!processInstances.exists(msg.sender))
            return;
        _;
    }
    
    /**
     * @dev Creates a new BpmServiceDb and registers the msg.sender as the owner
     */
    constructor() public {
        systemOwner = msg.sender;
    }

    /**
     * @dev Adds the given address to the registered process instances. Can only be invoked by the owner of this BpmServiceDb.
     * @param _address the address of a ProcessInstance
     */
    function addProcessInstance(address _address) external pre_onlyBySystemOwner {
        processInstances.insertOrUpdate(_address, _address);
    }

    /**
     * @dev Adds the given ActivityInstance ID to the registered activity instances. Can only be invoked by an already registered ProcessInstance.
     * The sending ProcessInstance (msg.sender) is recorded as well.
     * @param _id the globally unique ID of an ActivityInstance
     */
    function addActivityInstance(bytes32 _id) external pre_onlyRegisteredProcess {
        activityInstances.insertOrUpdate(_id, msg.sender); // TODO need to prevent that the same ID can be registered by different processes.
    }

    /**
     * @dev Returns the number of registered process instances.
     * @return the number of process instances
     */
    function getNumberOfProcessInstances() external view returns (uint size) {
        return processInstances.keys.length;
    }

    /**
	 * @dev Returns the process instance address at the specified index
	 * @param _pos the index
	 * @return the process instance address
	 */
    function getProcessInstanceAtIndex(uint _pos) external view returns (address processInstanceAddress) {
        uint error;
        (error, processInstanceAddress) = processInstances.keyAtIndex(_pos);
    }

    /**
     * @dev Returns the number of registered activity instances.
     * @return the number of activity instances
     */
    function getNumberOfActivityInstances() external view returns (uint size) {
        return activityInstances.keys.length;
    }

    /**
     * @dev Returns the address of the ProcessInstance of the specified ActivityInstance ID
     * @param _aiId the ID of an ActivityInstance
     * @return the ProcessInstance address or 0x0 if it cannot be found
     */
    function getProcessInstanceForActivity(bytes32 _aiId) external view returns (address) {
        return activityInstances.get(_aiId);
    }
}