pragma solidity ^0.5;

import "commons-management/VersionedArtifact.sol";

/**
 * @title Organization Interface
 * @dev Describes functionality of a contract representing an organization in an ecosystem application.
 * Also provides access to constants required when dealing with organizations.
 */
contract Organization is VersionedArtifact {
	// The *Removal events are interpreted as delete event by vent because the __DELETE__ field
	// is specified as DeleteMarkerField. When emitting the event, solidity requires that we provide
	// a value for __DELETE__. It's actual value is ignored by vent.
	int constant NOTHING = 0;

    event LogOrganizationCreation(
        bytes32 indexed eventId,
        address organizationAddress,
        uint approverCount,
        bytes32 organizationId
    );

    event LogOrganizationUserUpdate(
        bytes32 indexed eventId,
        address organizationAddress,
        address userAddress
    );

    event LogOrganizationUserRemoval(
        bytes32 indexed eventId,
        int __DELETE__,
        address organizationAddress,
        address userAddress
    ); 

    event LogDepartmentUserUpdate(
        bytes32 indexed eventId,
        address organizationAddress,
        bytes32 departmentId,
        address userAddress
    );

    event LogDepartmentUserRemoval(
        bytes32 indexed eventId,
        int __DELETE__,
        address organizationAddress,
        bytes32 departmentId,
        address userAddress
    );

    event LogOrganizationDepartmentUpdate(
        bytes32 indexed eventId,
        address organizationAddress,
        bytes32 departmentId,
        uint userCount     
    );

    event LogOrganizationDepartmentRemoval(
        bytes32 indexed eventId,
        int __DELETE__,
        address organizationAddress,
        bytes32 departmentId
    );

    event LogOrganizationApproverUpdate(
        bytes32 indexed eventId,
        address organizationAddress,
        address approverAddress
    );

    event LogOrganizationApproverRemoval(
        bytes32 indexed eventId,
        int __DELETE__,
        address organizationAddress,
        address approverAddress
    );

    bytes32 public constant EVENT_ID_ORGANIZATION_ACCOUNTS = "AN://organization-accounts";
    bytes32 public constant EVENT_ID_ORGANIZATION_USERS = "AN://organizations/users";
    bytes32 public constant EVENT_ID_DEPARTMENT_USERS = "AN://departments/users";
    bytes32 public constant EVENT_ID_ORGANIZATION_DEPARTMENTS = "AN://organizations/departments";
    bytes32 public constant EVENT_ID_ORGANIZATION_APPROVERS = "AN://organizations/approvers";

	// The ERC165 ID only comprises the core Organization functions
	bytes4 public constant ERC165_ID_Organization = bytes4(keccak256(abi.encodePacked("addUser(address)"))) ^
													bytes4(keccak256(abi.encodePacked("removeUser(address)"))) ^
													bytes4(keccak256(abi.encodePacked("authorizeUser(address,bytes32)")));

	/**
	 * @dev Initializes this DefaultOrganization with the provided list of initial approvers. This function replaces the
	 * contract constructor, so it can be used as the delegate target for an ObjectProxy.
	 * @param _initialApprovers an array of addresses that should be registered as approvers for this Organization
	 * @param _defaultDepartmentId an optional ID for the default department of this organization
	 */
	function initialize(address[] calldata _initialApprovers, bytes32 _defaultDepartmentId) external;

	/**
	 * @dev Adds the department with the specified ID to this Organization.
	 * @param _id the department ID (must be unique)
	 * @return true if the department was added successfully, false otherwise
	 */
	function addDepartment(bytes32 _id) public returns (bool);

	function getNumberOfDepartments() external view returns (uint size);

	function getDepartmentAtIndex(uint _index) external view returns (bytes32 id);

	function getDepartmentData(bytes32 _id) external view returns (uint userCount);
	
	function departmentExists(bytes32 _id) external view returns (bool);

	/**
	 * @dev Returns the ID of this Organization's default department
	 * @return the ID of the default department
	 */
	function getDefaultDepartmentId() external view returns (bytes32);

	/**
	 * @dev Returns the number of registered approvers.
	 * @return the number of approvers
	 */
	function getNumberOfApprovers() external view returns (uint);
	
	/**
	 * @dev Returns the approver's address at the given index position.
	 * @param _pos the index position
	 * @return the address, if the position exists
	 */
	function getApproverAtIndex(uint _pos) external view returns (address);

	/**
	 * @dev returns the number of users associated with this organization
	 * @return the number of users
	 */
	function getNumberOfUsers() external view returns (uint);

	/**
	 * @dev Returns the user's address at the given index position.
	 * @param _pos the index position
	 * @return the address or 0x0 if the position does not exist
	 */
	function getUserAtIndex(uint _pos) external view returns (address);

	/**
	 * @dev Returns the number of users in a given department of the organization.
	 * @param _depId the id of the department
	 * @return size the number of users
	 */
	function getNumberOfDepartmentUsers(bytes32 _depId) external view returns (uint size);

	/**
	 * @dev Returns the user's address at the given index of the department.
	 * @param _depId the id of the department
	 * @param _index the index position
	 * @return userAccount the address of the user or 0x0 if the position does not exist
	 */
	function getDepartmentUserAtIndex(bytes32 _depId, uint _index) external view returns (address userAccount);

	/**
	 * @dev Adds the specified user to this organization as an approver.
	 * @param _userAccount the user to add as an approver.
	 */
	function addApprover(address _userAccount) external;

	/**
	 * @dev Removes the specified user from this organization as an approver, if at least 1 approver will remain after the removal.
	 * @param _userAccount the user to remove from the approvers.
	 */
	function removeApprover(address _userAccount) external;

	/**
	 * @dev Adds the specified user to this organization as an active user. If the user already exists, the function ensures the account is active.
	 * @param _userAccount the user to add
	 * @return bool true if successful
	 */
	function addUser(address _userAccount) public returns (bool successful);

	/**
	 * @dev Adds the specified user to the organization if they aren't already registered, then adds the user to the department if they aren't already in it.
	 * @param _userAccount the user to add
	 * @param _department department id to which the user should be added
	 * @return bool true if successful
	 */
	function addUserToDepartment(address _userAccount, bytes32 _department) external returns (bool successful);

	/**
	 * @dev Removes the user in this organization.
	 * @param _userAccount the account to remove
	 * @return bool indicating success or failure
	 */
	function removeUser(address _userAccount) external returns (bool successful);

	/**
	 * @dev Removes the department in this organization.
	 * @param _depId the department to remove
	 * @return bool indicating success or failure
	 */
	function removeDepartment(bytes32 _depId) external returns (bool successful);

	/**
	 * @dev Removes the user from the department in this organization
	 * @param _userAccount the user to remove
	 * @param _depId the department to remove the user from
	 * @return bool indicating success or failure
	 */
	function removeUserFromDepartment(address _userAccount, bytes32 _depId) public returns (bool);

	/**
	 * @dev Returns whether the given user account is active in this organization and is authorized.
	 * The optional department/role identifier can be used to provide an additional authorization scope
	 * against which to authorize the user.
	 * @param _userAccount the user account
	 * @param _department an optional department/role context
	 * @return true if authorized, false otherwise
	 */
	function authorizeUser(address _userAccount, bytes32 _department) external view returns (bool);

	/**
	 * @dev Returns the organization key of this Organization.
	 * @return a globaly unique identifier for the Organization
	 */
	function getOrganizationKey() public view returns (bytes32);

	/**
	 * @dev Returns detailed information about this Organization
	 * @return numberOfApprovers - the number of approvers in the organization
	 * @return organizationKey - a globaly unique identifier for the organization
	 */
	function getOrganizationDetails() external view returns (uint numberOfApprovers, bytes32 organizationKey);
}
