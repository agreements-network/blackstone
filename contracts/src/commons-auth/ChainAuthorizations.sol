pragma solidity ^0.5;

import "commons-base/BaseErrors.sol";
import "commons-base/Owned.sol";

import "commons-auth/AuthorizationsRepository.sol";
import "commons-auth/SecureNativeAuthorizations.sol";

/**
 * @title ChainAutorizations
 * @dev SecureNativeAuthorizations-based implementation of AuthorizationsRepository.
 */
contract ChainAuthorizations is Owned, AuthorizationsRepository {

    SecureNativeAuthorizations sNativeAuthorizations;

    // Constructor
    constructor() public {
        owner = msg.sender;
        sNativeAuthorizations = SecureNativeAuthorizations(address(uint256(keccak256("Permissions"))));
    }

    /**
     * @dev Indicates whether the given account has the specified role
	 * @param _account account
	 * @param _role role
     * @return true if the account has the role, false otherwise
     */
    function hasRole(address _account, bytes32 _role) external view returns (bool result) {
        return sNativeAuthorizations.hasRole(_account, _role);
    }

    /**
     * @dev Associates the given account with the specified role
	 * @param _account account
	 * @param _role role
     * @return error NO_ERROR or RUNTIME_ERROR
     */
	function addRole(address _account, bytes32 _role) pre_onlyByOwner external returns (uint error) {
        return sNativeAuthorizations.addRole(_account, _role) ? BaseErrors.NO_ERROR() : BaseErrors.RUNTIME_ERROR();
    }

    /**
     * @dev Removes the given account from the specified role
     * @param _account account
     * @param _role role
     * @return error NO_ERROR or RUNTIME_ERROR
     */
    function removeRole(address _account, bytes32 _role) pre_onlyByOwner external returns (uint error) {
        return sNativeAuthorizations.removeRole(_account, _role) ? BaseErrors.NO_ERROR() : BaseErrors.RUNTIME_ERROR();
    }
}
