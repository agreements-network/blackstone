pragma solidity ^0.5;

import "commons-base/BaseErrors.sol";

import "commons-auth/SecureNativeAuthorizations.sol";
import "commons-auth/ChainAuthorizations.sol";

/**
* Test ChainAuthorizations.
*/
contract ChainAuthorizationsTest {

    ChainAuthorizations chainAuthorizations;

    uint error;
    bytes32 constant ROLE = "role1";

    // Constructor
    constructor() public {
        chainAuthorizations = new ChainAuthorizations();
    }

    /**
     * @dev Returns address of tested contract.
     * @return address tested contract
     */
    function getTestedContract() external view returns (address) {
        return chainAuthorizations;
    }

    /**
     * @dev Tests `ChainAuthorizations` functions
     * @return error string or "success"
     */
    function testFunctions() external returns (string memory) {
    	    	
        // Test `hasRole`
        if (chainAuthorizations.hasRole(this, ROLE)) return "Expected hasRole on start: false";

        // Test `addRole`
        error = chainAuthorizations.addRole(this, ROLE);
        if (error != BaseErrors.NO_ERROR()) return "Expected addRole: NO_ERROR";
        if (!chainAuthorizations.hasRole(this, ROLE)) return "Expected hasRole after adding: true";

        // Test `removeRole`
        error = chainAuthorizations.removeRole(this, ROLE);
        if (error != BaseErrors.NO_ERROR()) return "Expected removeRole: NO_ERROR";
        if (chainAuthorizations.hasRole(this, ROLE)) return "Expected hasRole after removal: false";

        return "success";
    }
}