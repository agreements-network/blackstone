pragma solidity ^0.5;

import "commons-base/ErrorsLib.sol";
import "commons-base/BaseErrors.sol";
import "commons-management/AbstractObjectFactory.sol";
import "commons-management/ObjectProxy.sol";
import "commons-management/AbstractDbUpgradeable.sol";
import "commons-management/ArtifactsFinderEnabled.sol";

import "commons-auth/Ecosystem.sol";
import "commons-auth/ParticipantsManager.sol";
import "commons-auth/ParticipantsManagerDb.sol";
import "commons-auth/UserAccount.sol";
import "commons-auth/DefaultUserAccount.sol";
import "commons-auth/Organization.sol";

/**
 * @title DefaultParticipantsManager
 * @dev Default implementation of the ParticipantsManager interface.
 */
contract DefaultParticipantsManager is AbstractVersionedArtifact(1,0,0), AbstractObjectFactory, ArtifactsFinderEnabled, AbstractDbUpgradeable, ParticipantsManager {

    /**
     * @dev Creates and registers a UserAccount, and optionally establishes the connection of the user to an ecosystem, if an address is provided
     * REVERTS if:
     * - neither owner nor ecosystem addresses are provided
     * @param _id id (required)
     * @param _owner owner (optional)
     * @param _ecosystem owner (optional)
     * @return the address of the created UserAccount
     */
    function createUserAccount(bytes32 _id, address _owner, address _ecosystem) external returns (address userAccount) {
        userAccount = address(new ObjectProxy(address(artifactsFinder), OBJECT_CLASS_USER_ACCOUNT));
        UserAccount(userAccount).initialize(_owner, _ecosystem);
        uint error = ParticipantsManagerDb(database).addUserAccount(userAccount);
        if (error == BaseErrors.NO_ERROR()) {
            if (_id != "" && _ecosystem != address(0)) {
                Ecosystem(_ecosystem).addUserAccount(_id, userAccount);
            }
        }
    }

	/**
	 * @dev Creates and adds a new Organization with the specified parameters
     * REVERTS if:
     * - The Organization was created, but cannot be added to the this ParticipantsManager.
	 * @param _initialApprovers the initial owners/admins of the Organization. If left empty, the msg.sender will be set as an approver.
	 * @param _defaultDepartmentId an optional custom ID for the default department of this organization.
	 * @return BaseErrors.NO_ERROR() if successful
	 * @return the address of the newly created Organization, or 0x0 if not successful
	 */
    function createOrganization(address[] calldata _initialApprovers, bytes32 _defaultDepartmentId) external returns (uint error, address organization) {
        address[] memory approvers;
        if (_initialApprovers.length == 0) {
            approvers = new address[](1);
            approvers[0] = msg.sender;
        }
        else {
            approvers = _initialApprovers;
        }

        organization = address(new ObjectProxy(address(artifactsFinder), OBJECT_CLASS_ORGANIZATION));
        Organization(address(organization)).initialize(approvers, _defaultDepartmentId);
        error = ParticipantsManagerDb(database).addOrganization(organization);
        ErrorsLib.revertIf(error != BaseErrors.NO_ERROR(),
            ErrorsLib.INVALID_STATE(), "DefaultParticipantsManager.createOrganization", "Unable to add the new Organization to the database");
    }

    /**
     * @dev Indicates whether the specified UserAccount exists in this ParticipantsManager
     * @param _userAccount user account address
     * @return true if the given address belongs to a known UserAccount, false otherwise
     */
    function userAccountExists(address _userAccount) external view returns (bool) {
        return ParticipantsManagerDb(database).userAccountExists(_userAccount);
    }

 	/**
     * @dev Indicates whether the specified organization in this ParticipantsManager
	 * @param _address organization address
	 * @return true if the given address belongs to a known Organization, false otherwise
     */
    function organizationExists(address _address) external view returns (bool) {
        return ParticipantsManagerDb(database).organizationExists(_address);
    }

	/**
	 * @dev Returns the number of registered organizations.
	 * @return the number of organizations
	 */
    function getNumberOfOrganizations() external view returns (uint size) {
        return ParticipantsManagerDb(database).getNumberOfOrganizations();
    }
    	
	/**
	 * @dev Returns the address of the Organization at the given index.
	 * @param _pos the index position
	 * @return the address of the Organization or 0x0 if the index position does not exist
	 */
    function getOrganizationAtIndex(uint _pos) external view returns (address organization) {
        return ParticipantsManagerDb(database).getOrganizationAtIndex(_pos);
    }

    /**
	 * @dev Returns the public data of the organization at the specified address
	 * @param _organization the address of an organization
	 * @return the organization's ID and name
	 */
    function getOrganizationData(address _organization) external view returns (uint numApprovers, bytes32 organizationKey) {
        return Organization(_organization).getOrganizationDetails();
    }

    function departmentExists(address _organization, bytes32 _departmentId) external view returns (bool) {
        return Organization(_organization).departmentExists(_departmentId);
    }
    
    function getNumberOfDepartments(address _organization) external view returns (uint size) {
        return Organization(_organization).getNumberOfDepartments();
    }

    function getDepartmentAtIndex(address _organization, uint _index) external view returns (bytes32 id) {
        return Organization(_organization).getDepartmentAtIndex(_index);
    }

    function getDepartmentData(address _organization, bytes32 _id) external view returns (uint userCount) {
        return Organization(_organization).getDepartmentData(_id);
    }

    function getNumberOfDepartmentUsers(address _organization, bytes32 _depId) external view returns (uint size) {
        return Organization(_organization).getNumberOfDepartmentUsers(_depId);
    }

    function getDepartmentUserAtIndex(address _organization, bytes32 _depId, uint _index) external view returns (address departmentMember) {
        return Organization(_organization).getDepartmentUserAtIndex(_depId, _index);
    }

	/**
	 * @dev Returns the number of registered approvers in the specified organization.
	 * @param _organization the organization's address
	 * @return the number of approvers
	 */
    function getNumberOfApprovers(address _organization) external view returns (uint size) {
        return Organization(_organization).getNumberOfApprovers();
    }
	
	/**
	 * @dev Returns the approver's address at the given index position of the specified organization.
	 * @param _organization the organization's address
	 * @param _pos the index position
	 * @return the approver's address, if the position exists
	 */
    function getApproverAtIndex(address _organization, uint _pos) external view returns (address) {
        return Organization(_organization).getApproverAtIndex(_pos);
    }

	/**
	 * @dev Function supports SQLsol, but only returns the approver address parameter.
	 * Unused parameter `address` refers to the Organization and is required by SQLsol
	 * @param _approver the approver's address
	 * @return the approver address
	 */
    function getApproverData(address /*_organization*/, address _approver) external view returns (address approverAddress) {
        approverAddress = _approver;
    }

	/**
	 * @dev returns the number of users associated with the specified organization
	 * @param _organization the organization's address
	 * @return the number of users
	 */
    function getNumberOfUsers(address _organization) external view returns (uint size) {
        return Organization(_organization).getNumberOfUsers();
    }

	/**
	 * @dev Returns the user's address at the given index position in the specified organization.
	 * @param _organization the organization's address
	 * @param _pos the index position
	 * @return the address or 0x0 if the position does not exist
	 */
    function getUserAtIndex(address _organization, uint _pos) external view returns (address) {
        return Organization(_organization).getUserAtIndex(_pos);
    }

	/**
	 * @dev Returns information about the specified user in the context of the given organization (only address is stored)
	 * Unused parameter `address` refers to the Organization and is required by SQLsol
	 * @param _user the user's address
	 * @return userAddress - the user's address
	 */
    function getUserData(address /*_organization*/, address _user) external view returns (address userAddress) {
        return _user;
    }

    /**
     * @dev Gets user accounts size.
     * @return size size
     */
    function getUserAccountsSize() external view returns (uint size) {
        size = ParticipantsManagerDb(database).getNumberOfUserAccounts();
    }

}
