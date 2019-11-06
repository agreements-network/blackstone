pragma solidity ^0.5;

/**
 * Interface for managing Secure Native authorizations.
 * @dev This Solidity interface describes the functions exposed by the SNative permissions layer in the Burrow blockchain.
 * These functions can be accessed as if this contract was deployed at a particular address.
 * This special address is defined as the last 20 bytes of the keccak256 hash of the the contract name "Permissions".
 * To instantiate the contract use:
 * SecureNativeAuthorizations authorizations = SecureNativeAuthorizations(address(keccak256(abi.encodePacked("Permissions"))));
 */
interface SecureNativeAuthorizations {

   /**
    * @dev Adds a role to an account
    * @param _account account address
    * @param _role role name
    * @return result whether role was added
    */
    function addRole(address _account, bytes32 _role) external returns (bool result);

    /**
    * @dev Removes a role from an account
    * @param _account account address
    * @param _role role name
    * @return result whether role was removed
    */
    function removeRole(address _account, bytes32 _role) external returns (bool result);

    /**
    * @dev Indicates whether an account has a role
    * @param _account account address
    * @param _role role name
    * @return result whether account has role
    */
    function hasRole(address _account, bytes32 _role) external view returns (bool result);

    /**
    * @dev Sets the permission flags for an account. Makes them explicitly set (on or off).
    * @param _account account address
    * @param _permission the base permissions flags to set for the account
    * @param _set whether to set or unset the permissions flags at the account level
    * @return result the effective permissions flags on the account after the call
    */
    function setBase(address _account, uint64 _permission, bool _set) external returns (uint64 result);

    /**
    * @dev Unsets the permissions flags for an account. Causes permissions being unset to fall through to global permissions.
    * @param _account account address
    * @param _permission the permissions flags to unset for the account
    * @return result the effective permissions flags on the account after the call
    */
    function unsetBase(address _account, uint64 _permission) external returns (uint64 result);

    /**
    * @dev Indicates whether an account has a subset of permissions set
    * @param _account account address
    * @param _permission the permissions flags (mask) to check whether enabled against base permissions for the account
    * @return result whether account has the passed permissions flags set
    */
    function hasBase(address _account, uint64 _permission) external view returns (uint64 result);

    /**
    * @dev Sets the global (default) permissions flags for the entire chain
    * @param _permission the permissions flags to set
    * @param _set whether to set (or unset) the permissions flags
    * @return result the global permissions flags after the call
    */
    function setGlobal(uint64 _permission, bool _set) external returns (uint64 result);
}
