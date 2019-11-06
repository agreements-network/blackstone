pragma solidity ^0.5;

import "commons-base/BaseErrors.sol";

import "commons-auth/SecureNativeAuthorizations.sol";
import "commons-auth/AuthorizationsManager.sol";

/**
* Test AuthorizationsManager.
*/
contract AuthorizationsManagerTest {

    AuthorizationsManager authorizationsManager;
    address account;

    uint error;
    bytes32 constant ROLE = "role1";

    // Constructor
    constructor() public {
        authorizationsManager = new AuthorizationsManager();
        account = address(new TestAccount());
    }

    /**
     * @dev Returns address of chainAuthorizations repository
     * @return address chainAuthorizations repository
     */
    function getChainAuthorizations() external view returns (address) {
        return authorizationsManager.getRepository(authorizationsManager.REPOSITORY_CHAIN_AUTHORIZATIONS());
    }

    /**
     * @dev Tests `AuthorizationsManager` functions
     * @return bytes32 result
     */
    function testFunctions() external returns (string memory) {
        // Test `hasRole`
        if (authorizationsManager.hasRole(account, ROLE)) return "Expected hasRole: false";

        // Test `addRole`
        error = authorizationsManager.addRole("", account, ROLE);
        if (error != BaseErrors.RESOURCE_NOT_FOUND()) return "Expected addRole: RNF";

        error = authorizationsManager.addRole(authorizationsManager.REPOSITORY_CHAIN_AUTHORIZATIONS(), account, ROLE);
        if (error != BaseErrors.NO_ERROR()) return "Expected addRole: NE";
        if (!authorizationsManager.hasRole(account, ROLE)) return "Expected hasRole: true";

        // Test `removeRole`
        error = authorizationsManager.removeRole("", account, ROLE);
        if (error != BaseErrors.RESOURCE_NOT_FOUND()) return "Expected removeRole: RNF";

        error = authorizationsManager.removeRole(authorizationsManager.REPOSITORY_CHAIN_AUTHORIZATIONS(), account, ROLE);
        if (error != BaseErrors.NO_ERROR()) return "Expected removeRole: NE";
        if (authorizationsManager.hasRole(account, ROLE)) return "Expected hasRole: false";

        return "success";
    }
}

/**
* Provides valid chain account.
*/
contract TestAccount { }
