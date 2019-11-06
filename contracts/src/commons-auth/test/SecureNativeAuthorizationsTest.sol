pragma solidity ^0.5;

// Tested Contracts
import "commons-auth/SecureNativeAuthorizations.sol";

/**
* Test SecureNativeAuthorizations.
*/
contract SecureNativeAuthorizationsTest {
    SecureNativeAuthorizations sNativeAuthorizations;

    uint64 constant HAS_BASE_AUTHORIZATION = 128; // Default is true
    uint64 constant SET_BASE_AUTHORIZATION = 256; // Default is false, set to true in EPM for testing purposes
    uint64 constant UNSET_BASE_AUTHORIZATION = 512; // Default is false
    uint64 constant SET_GLOBAL_AUTHORIZATION = 1024; // Default is false
    uint64 constant HAS_ROLE_AUTHORIZATION = 2048; // Default is true
    uint64 constant ADD_ROLE_AUTHORIZATION = 4096; // Default is false
    uint64 constant RM_ROLE_AUTHORIZATION = 8192; // Default is false

    bool result;
    bytes32 constant ROLE = "role1";

    // Constructor
    constructor() public {
        sNativeAuthorizations = SecureNativeAuthorizations(address(keccak256(abi.encodePacked("Permissions"))));
    }

    /**
     * @dev Tests `SecureNativeAuthorizations` functions
     * @return error string or "success"
     */
    function testFunctions() external returns (string memory) {
        // Confirm contract has correct initial authorizations
        
       
//        if (sNativeAuthorizations.hasBase(this, SET_BASE_AUTHORIZATION)) return "Expected setBase: true";
//        if (sNativeAuthorizations.hasBase(this, HAS_ROLE_AUTHORIZATION)) return "Expected hasRole: true";
//
//        if (sNativeAuthorizations.hasBase(this, UNSET_BASE_AUTHORIZATION)) return "Expected unsetBase: false";
//        if (sNativeAuthorizations.hasBase(this, SET_GLOBAL_AUTHORIZATION)) return "Expected setGlobal: false";
//        if (sNativeAuthorizations.hasBase(this, ADD_ROLE_AUTHORIZATION)) return "Expected addRole: false";
//        if (sNativeAuthorizations.hasBase(this, RM_ROLE_AUTHORIZATION)) return "Expected removeRole: false";

        // Test `setBase`
        sNativeAuthorizations.setBase(this, UNSET_BASE_AUTHORIZATION, true);
        sNativeAuthorizations.setBase(this, SET_GLOBAL_AUTHORIZATION, true);
        sNativeAuthorizations.setBase(this, ADD_ROLE_AUTHORIZATION, true);
        sNativeAuthorizations.setBase(this, RM_ROLE_AUTHORIZATION, true);

//        if (sNativeAuthorizations.hasBase(this, UNSET_BASE_AUTHORIZATION)) return "Expected unsetBase: true";
//        if (sNativeAuthorizations.hasBase(this, SET_GLOBAL_AUTHORIZATION)) return "Expected setGlobal: true";
//        if (sNativeAuthorizations.hasBase(this, ADD_ROLE_AUTHORIZATION)) return "Expected addRole: true";
//        if (sNativeAuthorizations.hasBase(this, RM_ROLE_AUTHORIZATION)) return "Expected removeRole: true";

        // Test `hasRole`
        if (sNativeAuthorizations.hasRole(this, ROLE)) return "Expected hasRole result: false";

        // Test `addRole`
        if (!sNativeAuthorizations.addRole(this, ROLE)) return "Expected addRole result: true";
        if (!sNativeAuthorizations.hasRole(this, ROLE)) return "Expected hasRole result: true";

        // Test `removeRole`
        if (!sNativeAuthorizations.removeRole(this, ROLE)) return "Expected removeRole result: true";
        if (sNativeAuthorizations.hasRole(this, ROLE)) return "Expected hasRole result: false";

        // Test `unsetBase`
        sNativeAuthorizations.unsetBase(this, ADD_ROLE_AUTHORIZATION);
//        if (sNativeAuthorizations.hasBase(this, ADD_ROLE_AUTHORIZATION)) return "Expected addRole: false after unsetBase";

        // Test `set_global`
        // TODO following if statement cannot be true since perm was unset in test above!
//         if (!sNativeAuthorizations.hasBase(this, ADD_ROLE_AUTHORIZATION)) return "Expected addRole: true before removing with setGlobal";
         sNativeAuthorizations.setGlobal(ADD_ROLE_AUTHORIZATION, false); // return to default to not impact other chain activity

        return "success";
    }
}