pragma solidity ^0.5;

import "commons-base/BaseErrors.sol";
import "bpm-model/BpmModel.sol";
import "commons-management/AbstractDbUpgradeable.sol";

import "bpm-runtime/ApplicationRegistry.sol";
import "bpm-runtime/ApplicationRegistryDb.sol";

/**
 * @title ApplicationRegistry
 * @dev Default implementation of the ApplicationRegistry interface
 */
contract DefaultApplicationRegistry is AbstractVersionedArtifact(1,0,0), AbstractDbUpgradeable, ApplicationRegistry {

	/**
	 * @dev Adds a Service application with the given parameters to this ApplicationRegistry
	 * @param _id the ID of the application
	 * @param _type the BpmModel.ApplicationType
	 * @param _location the location of the contract implementing the application
	 * @param _function the signature of the completion function
	 * @param _webForm the hash of a web form (only for web applications)
	 * @return BaseErrors.RESOURCE_ALREADY_EXISTS() if an application with the given ID already exists, BaseErrors.NO_ERROR() otherwise
	 */
	function addApplication(bytes32 _id, BpmModel.ApplicationType _type, address _location, bytes4 _function, bytes32 _webForm) external returns (uint error) {
		error = ApplicationRegistryDb(database).addApplication(
			_id,
			_type,
			_location,
			_function,
			_webForm
		);
		if (error == BaseErrors.NO_ERROR()) {
			emit LogApplicationCreation(
				EVENT_ID_APPLICATIONS,
				_id,
				uint8(_type),
				_location,
				_function,
				_webForm
			);
		}
	}

	/**
	 * @dev Creates an data access point for the given application
	 * @param _id the ID of the application to which to add the access point
	 * @param _accessPointId the ID of the new access point
	 * @param _dataType a DataTypes code
	 * @param _direction the BpmModel.Direction (IN/OUT) of the data flow
   * @return BaseErrors.RESOURCE_NOT_FOUND() if the application does not exist
	 *				 BaseBaseErrors.RESOUCE_ALREADY_EXISTS() if the access point already exists 
	 *				 BaseBaseErrors.NO_ERROR() if no errors
	 */
	function addAccessPoint(bytes32 _id, bytes32 _accessPointId, uint8 _dataType, BpmModel.Direction _direction) external returns (uint error) {
		if (!ApplicationRegistryDb(database).applicationExists(_id))
			return BaseErrors.RESOURCE_NOT_FOUND();
		error = ApplicationRegistryDb(database).addAccessPoint(_id, _accessPointId, _dataType, _direction);
		if (error == BaseErrors.NO_ERROR()) {
			emit LogApplicationAccessPointCreation(
				EVENT_ID_APPLICATION_ACCESS_POINTS,
				_id,
				_accessPointId,
				_dataType,
				uint8(_direction)
			);
		}
	}

	/**
	 * @dev Returns the number of applications defined in this ProcessModel
	 * @return the number of applications
	 */
	function getNumberOfApplications() external view returns (uint size) {
		return ApplicationRegistryDb(database).getNumberOfApplications();
	}

	/**
	 * @dev Returns the ID of the application at the given index
	 * @param _idx the index position
	 * @return the application ID, if it exists
	 */
	function getApplicationAtIndex(uint _idx) external view returns (bytes32) {
		return ApplicationRegistryDb(database).getApplicationAtIndex(_idx);
	}

	/**
	 * @dev Returns information about the application with the given ID
	 * @param _id the application ID
	 * @return applicationType the BpmModel.ApplicationType as uint8
	 * @return location the applications contract address
	 * @return method the function signature of the application's completion function
	 * @return webForm the form identifier (hash) of the web application (only for a web application)
	 * @return accessPointCount the count of access points of this application
	 */
	function getApplicationData(bytes32 _id) external view returns (uint8 applicationType, address location, bytes4 method, bytes32 webForm, uint accessPointCount) {
		(applicationType,
		location,
		method,
		webForm,
		accessPointCount) = ApplicationRegistryDb(database).getApplicationData(_id);
	}

	/**
	 * @dev Returns the number of application access points for given application
	 * @param _id the id of the application
	 * @return the number of access points for the application
	 */
	function getNumberOfAccessPoints(bytes32 _id) external view returns (uint size) {
		return ApplicationRegistryDb(database).getNumberOfAccessPoints(_id);
	}

	/**
	 * @dev Returns the ID of the access point at the given index
	 * @param _id the application id
	 * @param _index the index position of the access point
	 * @return the access point id if it exists
	 */
	function getAccessPointAtIndex(bytes32 _id, uint _index) external view returns (bytes32 accessPointId) {
		return ApplicationRegistryDb(database).getAccessPointAtIndex(_id, _index);
	}

	/**
	 * @dev Returns information about the access point with the given ID
	 * @param _id the application ID
	 * @param _accessPointId the access point ID
	 * @return dataType the data type
	 * @return direction the direction
	 */
	function getAccessPointData(bytes32 _id, bytes32 _accessPointId) external view returns (uint8 dataType, BpmModel.Direction direction) {
		(dataType,
		direction) = ApplicationRegistryDb(database).getAccessPointData(_id, _accessPointId);
	}

}