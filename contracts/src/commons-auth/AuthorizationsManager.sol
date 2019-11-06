pragma solidity ^0.5;

// Libraries
import "commons-base/BaseErrors.sol";
import "commons-collections/Mappings.sol";
import "commons-collections/MappingsLib.sol";

// Referenced Contracts
import "commons-auth/ChainAuthorizations.sol";
import "commons-auth/SecureNativeAuthorizations.sol";

/**
 * @title AuthorizationsManager
 * @dev The AuthorizationsManager by default comes with a pre-registered AuthorizationsRepository of
 * type ChainAuthorizations that can be accessed under the key "chainAuthorizations".
 */
contract AuthorizationsManager {

    using MappingsLib for Mappings.Bytes32AddressMap;

    // the reserved key for the default chain authorizations repository
    bytes32 public constant REPOSITORY_CHAIN_AUTHORIZATIONS = "chainAuthorizations";

    Mappings.Bytes32AddressMap repositories;

    /// @dev Constructor
    constructor() public {
        repositories.insert(REPOSITORY_CHAIN_AUTHORIZATIONS, address(new ChainAuthorizations()));
    }

    /**
     * @dev Indicates whether an account has a role in any known `AuthorizationsRepository`
     * @param _account account
	 * @param _role role
     * @return true if the role-account association can be found in a registered repository, false otherwise
     */
    function hasRole(address _account, bytes32 _role) external view returns (bool result) {
        uint error;
        uint idx = 0;
        uint nextIdx = 1;
        address addr;
        while (nextIdx > 0) {
            (error, addr, nextIdx) = repositories.valueAtIndexHasNext(idx);
            if (error == BaseErrors.NO_ERROR()) {
                result = AuthorizationsRepository(addr).hasRole(_account, _role);
                if (result) return result;
            }
            idx = nextIdx;
        }
    }

    /**
     * @dev Adds a role to an account in a `AuthorizationsRepository`
     * @param _repository AuthorizationsRepository
     * @param _account account
     * @param _role role
     * @return error NO_ERROR, RESOURCE_ERROR, or RESOURCE_NOT_FOUND
     */
    function addRole(bytes32 _repository, address _account, bytes32 _role) external returns (uint error) {
        return repositories.exists(_repository) ? AuthorizationsRepository(repositories.get(_repository)).addRole(_account, _role) : BaseErrors.RESOURCE_NOT_FOUND();
    }

    /**
     * @dev Removes a role from an account in a `AuthorizationsRepository`
     * @param _repository AuthorizationsRepository
     * @param _account account
     * @param _role role
     * @return error NO_ERROR, RESOURCE_ERROR, or RESOURCE_NOT_FOUND
     */
    function removeRole(bytes32 _repository, address _account, bytes32 _role) external returns (uint error) {
        return repositories.exists(_repository) ? AuthorizationsRepository(repositories.get(_repository)).removeRole(_account, _role) : BaseErrors.RESOURCE_NOT_FOUND();
    }

    /**
     * @dev Returns the address of the repository with the specified key, if it exists
     * @param _key the repository identifier
     * @return the address or 0x0, if the repository does not exist
     */
    function getRepository(bytes32 _key) external view returns (address) {
        return repositories.get(_key);
    }
}
