pragma solidity ^0.5;

import "commons-management/Upgradeable.sol";
import "commons-management/ObjectFactory.sol";

/**
 * @title ParticipantsManager Interface
 * @dev Manages organizational structures.
 */
contract ParticipantsManager is ObjectFactory, Upgradeable {

    string public constant OBJECT_CLASS_ORGANIZATION = "commons.auth.Organization";
    string public constant OBJECT_CLASS_USER_ACCOUNT = "commons.auth.UserAccount";

    /**
     * @dev Creates and adds a user account, and optionally registers the user with an ecosystem if an address is provided
     * @param _id id (required)
     * @param _owner owner (optional)
     * @param _ecosystem owner (optional)
     * @return userAccount user account
     */
    function createUserAccount(bytes32 _id, address _owner, address _ecosystem) external returns (address userAccount);

	/**
	 * @dev Creates and adds a new Organization with the specified parameters
	 * @param _initialApprovers the initial owners/admins of the Organization.
	 * @param _defaultDepartmentId an optional custom name/label for the default department of this organization.
	 * @return error code and the address of the newly created organization, if successful
	 */
    function createOrganization(address[] calldata _initialApprovers, bytes32 _defaultDepartmentId) external returns (uint, address);

    /**
     * @dev Indicates whether the specified UserAccount exists in this ParticipantsManager
     * @param _userAccount user account address
     * @return true if the given address belongs to a known UserAccount, false otherwise
     */
    function userAccountExists(address _userAccount) external view returns (bool);

	/**
     * @dev Indicates whether the specified organization in this ParticipantsManager
	 * @param _address organization address
	 * @return true if the given address belongs to a known Organization, false otherwise
	 */
    function organizationExists(address _address) external view returns (bool);

	/**
	 * @dev Returns the number of registered organizations.
	 * @return the number of organizations
	 */
    function getNumberOfOrganizations() external view returns (uint size);

	/**
	 * @dev Returns the organization at the specified index.
	 * @param _pos the index position
	 * @return the address of the organization
	 */
    function getOrganizationAtIndex(uint _pos) external view returns (address organization);
	
	/**
	 * @dev Returns the public data of the organization at the specified address
	 * @param _organization the address of an organization
	 * @return the organization's ID and name
	 */
    function getOrganizationData(address _organization) external view returns (uint numApprovers, bytes32 organizationKey);

    function departmentExists(address _organization, bytes32 _departmentId) external view returns (bool);

    function getNumberOfDepartments(address _organization) external view returns (uint size);

    function getDepartmentAtIndex(address _organization, uint _index) external view returns (bytes32 id);

    function getDepartmentData(address _organization, bytes32 _id) external view returns (uint userCount);

    function getNumberOfDepartmentUsers(address _organization, bytes32 _depId) external view returns (uint size);

    function getDepartmentUserAtIndex(address _organization, bytes32 _depId, uint _index) external view returns (address departmentMember);

    /**
	 * @dev Returns the number of registered approvers in the specified organization.
	 * @param _organization the organization's address
	 * @return the number of approvers
	 */
    function getNumberOfApprovers(address _organization) external view returns (uint size);
	
	/**
	 * @dev Returns the approver's address at the given index position of the specified organization.
	 * @param _organization the organization's address
	 * @param _pos the index position
	 * @return the approver's address, if the position exists
	 */
    function getApproverAtIndex(address _organization, uint _pos) external view returns (address);

	/**
	 * @dev Function supports SQLsol, but only returns the approver address parameter.
	 * @param _organization the organization's address
	 * @param _approver the approver's address
	 */
    function getApproverData(address _organization, address _approver) external view returns (address approverAddress);

	/**
	 * @dev returns the number of users associated with the specified organization
	 * @param _organization the organization's address
	 * @return the number of users
	 */
    function getNumberOfUsers(address _organization) external view returns (uint size);

	/**
	 * @dev Returns the user's address at the given index position in the specified organization.
	 * @param _organization the organization's address
	 * @param _pos the index position
	 * @return the address or 0x0 if the position does not exist
	 */
    function getUserAtIndex(address _organization, uint _pos) external view returns (address);

	/**
	 * @dev Returns information about the specified user in the context of the given organization (only address is stored)
	 * @param _organization the organization's address
	 * @param _user the user's address
	 * @return userAddress - address of the user
	 */
    function getUserData(address _organization, address _user) external view returns (address userAddress);

    /**
     * SQLSOL support functions
     */

    function getUserAccountsSize() external view returns (uint size);
}