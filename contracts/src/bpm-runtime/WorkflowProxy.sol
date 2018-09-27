pragma solidity ^0.4.23;

import "commons-base/BaseErrors.sol";

import "bpm-runtime/BpmService.sol";

/**
 * @title WorkflowProxy
 * @dev Represents a proxy contract to interact with a ProcessInstance on behalf of a user account, e.g. to complete activities assigned to this proxy contract.
 */
contract WorkflowProxy {

	/**
	 * @dev Completes the specified activity using the given BpmService to locate the relevant ProcessInstance.
	 * This sets the msg.sender of the call to the address of this proxy contract, so that it can be used to authorize the task completion.
	 * @param _activityInstanceId the task ID
	 * @param _service the BpmService required for lookup and access to the BpmServiceDb
	 * @return error code if the completion failed
	 */
    function completeActivity(bytes32 _activityInstanceId, BpmService _service) public returns (uint error);

	/**
	 * @dev Writes data via BpmService and then completes the specified activity.
	 * @param _activityInstanceId the task ID
	 * @param _service the BpmService required for lookup and access to the BpmServiceDb
	 * @param _dataMappingId the id of the dataMapping that points to data storage slot
	 * @param _value the bool value of the data
	 * @return error code if the completion failed
	 */
    function completeActivityWithBoolData(bytes32 _activityInstanceId, BpmService _service, bytes32 _dataMappingId, bool _value) external returns (uint error);

	/**
	 * @dev Writes data via BpmService and then completes the specified activity.
	 * @param _activityInstanceId the task ID
	 * @param _service the BpmService required for lookup and access to the BpmServiceDb
	 * @param _dataMappingId the id of the dataMapping that points to data storage slot
	 * @param _value the string value of the data
	 * @return error code if the completion failed
	 */
    function completeActivityWithStringData(bytes32 _activityInstanceId, BpmService _service, bytes32 _dataMappingId, string _value) external returns (uint error);

	/**
	 * @dev Writes data via BpmService and then completes the specified activity.
	 * @param _activityInstanceId the task ID
	 * @param _service the BpmService required for lookup and access to the BpmServiceDb
	 * @param _dataMappingId the id of the dataMapping that points to data storage slot
	 * @param _value the bytes32 value of the data
	 * @return error code if the completion failed
	 */
    function completeActivityWithBytes32Data(bytes32 _activityInstanceId, BpmService _service, bytes32 _dataMappingId, bytes32 _value) external returns (uint error);

	/**
	 * @dev Writes data via BpmService and then completes the specified activity.
	 * @param _activityInstanceId the task ID
	 * @param _service the BpmService required for lookup and access to the BpmServiceDb
	 * @param _dataMappingId the id of the dataMapping that points to data storage slot
	 * @param _value the uint value of the data
	 * @return error code if the completion failed
	 */
    function completeActivityWithUintData(bytes32 _activityInstanceId, BpmService _service, bytes32 _dataMappingId, uint _value) external returns (uint error);

	/**
	 * @dev Writes data via BpmService and then completes the specified activity.
	 * @param _activityInstanceId the task ID
	 * @param _service the BpmService required for lookup and access to the BpmServiceDb
	 * @param _dataMappingId the id of the dataMapping that points to data storage slot
	 * @param _value the int value of the data
	 * @return error code if the completion failed
	 */
    function completeActivityWithIntData(bytes32 _activityInstanceId, BpmService _service, bytes32 _dataMappingId, int _value) external returns (uint error);

	/**
	 * @dev Writes data via BpmService and then completes the specified activity.
	 * @param _activityInstanceId the task ID
	 * @param _service the BpmService required for lookup and access to the BpmServiceDb
	 * @param _dataMappingId the id of the dataMapping that points to data storage slot
	 * @param _value the address value of the data
	 * @return error code if the completion failed
	 */
    function completeActivityWithAddressData(bytes32 _activityInstanceId, BpmService _service, bytes32 _dataMappingId, address _value) external returns (uint error);

}