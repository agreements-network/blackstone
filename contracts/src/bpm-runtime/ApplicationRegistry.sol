pragma solidity ^0.5;

import "bpm-model/BpmModel.sol";
import "commons-management/Upgradeable.sol";

/**
 * @title ApplicationRegistry Interface
 * @dev Interface for managing appliations.
 */
contract ApplicationRegistry is Upgradeable {

	bytes4 public constant DEFAULT_COMPLETION_FUNCTION = bytes4(keccak256(abi.encodePacked("complete(address,bytes32,bytes32,address)")));

	event LogApplicationCreation(
		bytes32 indexed eventId,
		bytes32 applicationId,
		uint8 applicationType,
		address location,
		bytes4 method,
		bytes32 webForm
	);

	event LogApplicationAccessPointCreation(
		bytes32 indexed eventId,
		bytes32 applicationId,
		bytes32 accessPointId,
		uint8 dataType,
		uint8 direction
	);

	bytes32 public constant EVENT_ID_APPLICATIONS = "AN://applications";
	bytes32 public constant EVENT_ID_APPLICATION_ACCESS_POINTS = "AN://applications/access-points";

	/**
	 * @dev Adds an application with the given parameters to this ApplicationRegistry
	 * @param _id the ID of the application
	 * @param _type the BpmModel.ApplicationType
	 * @param _location the location of the contract implementing the application
	 * @param _function the signature of the completion function
	 * @param _webForm the hash of a web form (only for web applications)
	 * @return an error code indicating success or failure
	 */
	function addApplication(bytes32 _id, BpmModel.ApplicationType _type, address _location, bytes4 _function, bytes32 _webForm) external returns (uint error);

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
	function addAccessPoint(bytes32 _id, bytes32 _accessPointId, uint8 _dataType, BpmModel.Direction _direction) external returns (uint error);

	/**
	 * @dev Returns the number of applications defined in this ProcessModel
	 * @return the number of applications
	 */
	function getNumberOfApplications() external view returns (uint size);

	/**
	 * @dev Returns the ID of the application at the given index
	 * @param _idx the index position
	 * @return the application ID, if it exists
	 */
	function getApplicationAtIndex(uint _idx) external view returns (bytes32);

	/**
	 * @dev Returns information about the application with the given ID
	 * @param _id the application ID
	 * @return applicationType the BpmModel.ApplicationType as uint8
	 * @return location the applications contract address
	 * @return method the function signature of the application's completion function
	 * @return webForm the form identifier (hash) of the web application (only for a web application)
	 * @return accessPointCount the count of access points of this application
	 */
	function getApplicationData(bytes32 _id) external view returns (uint8 applicationType, address location, bytes4 method, bytes32 webForm, uint accessPointCount);

	/**
	 * @dev Returns the number of application access points for given application
	 * @param _id the id of the application
	 * @return the number of access points for the application
	 */
	function getNumberOfAccessPoints(bytes32 _id) external view returns (uint size);

	/**
	 * @dev Returns the ID of the access point at the given index
	 * @param _id the application id
	 * @param _index the index position of the access point
	 * @return the access point id if it exists
	 */
	function getAccessPointAtIndex(bytes32 _id, uint _index) external view returns (bytes32 accessPointId);

	/**
	 * @dev Returns information about the access point with the given ID
	 * @param _id the application ID
	 * @param _accessPointId the access point ID
	 * @return dataType the data type
	 * @return direction the direction
	 */
	function getAccessPointData(bytes32 _id, bytes32 _accessPointId) external view returns (uint8 dataType, BpmModel.Direction direction);

}