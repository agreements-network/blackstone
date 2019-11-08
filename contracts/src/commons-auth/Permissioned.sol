pragma solidity ^0.5;

/**
 * @title Permissioned Interface
 * A contract with permissioning capabilities.
 */
contract Permissioned {

    /**
     * @dev Sets the administator permission holder to the specified address. This is a convenience function to provide flexibility around
     * initializing the object administrator, e.g. outside of the constructor.
     * If the given address is empty, the msg.sender should be set as the object admin.
     */
    function initializeObjectAdministrator(address _admin) public;

    /**
     * @dev Creates a new permission with the specified identifier and attributes
     * @param _permission the permission identifier
     * @param _multiHolder determines whether the permission can be granted to multiple people at the same time
     * @param _revocable determines whether the permission can be revoked by the object administrator
     * @param _transferable determines whether holders of the permission are allowed to transfer their grant to someone else
     */
    function createPermission(bytes32 _permission, bool _multiHolder, bool _revocable, bool _transferable) external;

    /**
     * @dev Grants the specified permission to the given holder.
     * @param _permission the permission identifier
     * @param _newHolder the address being granted the permission
     */
    function grantPermission(bytes32 _permission, address _newHolder) external;

    /**
     * @dev Transfers the specified permission from the sender to the given holder.
     * @param _permission the permission identifier
     * @param _newHolder the address the permission is to be transfered to
     */
    function transferPermission(bytes32 _permission, address _newHolder) external;

    /**
     * @dev Revokes the specified permission from the given holder.
     * @param _permission the permission identifier
     * @param _holder the address having the permission revoked
     */
    function revokePermission(bytes32 _permission, address _holder) external;

    /**
     * @dev Indicates whether the specified permission is held by the given holder.
     * @param _permission the permission identifier
     * @param _holder the address holding the permission
     * @return true if the given address is included in the holders of the specified permission
     */
    function hasPermission(bytes32 _permission, address _holder) public view returns (bool);

    /**
     * @dev Returns the holder address of the given permission at the specified index
     * @param _permission the permission identifier
     * @param _index the index in the list of holders (always 0 for single-holder permissions)
     * @return the address of the holder at the given index position
     */
    function getHolder(bytes32 _permission, uint _index) external view returns (address);

    /**
     * @dev Returns detailed information about the specified permission
     * @param _permission the permission identifier
     * @return exists - whether the permission exists
     * @return multiHolder - whether the permission allows multiple holders
     * @return revocable - whether the permission is revocable
     * @return transferable - whether the permission is transferable
     * @return holderSize - the number of current holders of the permission
     */
    function getPermissionDetails(bytes32 _permission) external view returns (bool exists, bool multiHolder, bool revocable, bool transferable, uint holderSize);

}