pragma solidity ^0.5;

import "commons-base/BaseErrors.sol";
import "commons-base/SystemOwned.sol";
import "bpm-model/BpmModel.sol";

/**
 * @title ApplicationRegistryDb
 * @dev DB contract to manage the data for an ApplicationRegistry
 */
contract ApplicationRegistryDb is SystemOwned {
  
  BpmModel.ApplicationMap applications;

  constructor() public {
    systemOwner = msg.sender;
  }

  function addApplication(bytes32 _id, BpmModel.ApplicationType _type, address _location, bytes4 _function, bytes32 _webForm) external pre_onlyBySystemOwner returns (uint) {
    if (applications.rows[_id].exists)
			return BaseErrors.RESOURCE_ALREADY_EXISTS();
		applications.rows[_id].keyIdx = applications.keys.push(_id);
		applications.rows[_id].value.id = _id;
		applications.rows[_id].value.applicationType = _type;
		applications.rows[_id].value.location = _location;
		applications.rows[_id].value.method = _function;
		applications.rows[_id].value.webForm = _webForm;
		applications.rows[_id].exists = true;
    return BaseErrors.NO_ERROR();
  }

  function applicationExists(bytes32 _id) external view returns (bool) {
    return applications.rows[_id].exists;
  }

  function addAccessPoint(bytes32 _id, bytes32 _accessPointId, uint8 _dataType, BpmModel.Direction _direction) external pre_onlyBySystemOwner returns (uint) {
    if (applications.rows[_id].value.accessPoints[_accessPointId].exists) {
      return BaseErrors.RESOURCE_ALREADY_EXISTS();
    }
    applications.rows[_id].value.accessPointKeys.push(_accessPointId);
    applications.rows[_id].value.accessPoints[_accessPointId].id = _accessPointId;
    applications.rows[_id].value.accessPoints[_accessPointId].dataType = _dataType;
    applications.rows[_id].value.accessPoints[_accessPointId].direction = _direction;
    applications.rows[_id].value.accessPoints[_accessPointId].exists = true;
    return BaseErrors.NO_ERROR();
  }

  function getNumberOfApplications() external view returns (uint size) {
    return applications.keys.length;
  }

  function getApplicationAtIndex(uint _index) external view returns (bytes32) {
    return applications.keys[_index];
  }

  function getApplicationData(bytes32 _id) external view returns (uint8 applicationType, address location, bytes4 method, bytes32 webForm, uint accessPointCount) {
		applicationType = uint8(applications.rows[_id].value.applicationType);
		location = applications.rows[_id].value.location;
		method = applications.rows[_id].value.method;
		webForm = applications.rows[_id].value.webForm;
    accessPointCount = applications.rows[_id].value.accessPointKeys.length;
	}

  function getNumberOfAccessPoints(bytes32 _id) external view returns (uint size) {
    return applications.rows[_id].value.accessPointKeys.length;
  }

  function getAccessPointAtIndex(bytes32 _id, uint _index) external view returns (bytes32 accessPointId) {
    return applications.rows[_id].value.accessPointKeys[_index];
  }

  function getAccessPointData(bytes32 _id, bytes32 _accessPointId) external view returns (uint8 dataType, BpmModel.Direction direction) {
    dataType = uint8(applications.rows[_id].value.accessPoints[_accessPointId].dataType);
    direction = applications.rows[_id].value.accessPoints[_accessPointId].direction;
  }
}