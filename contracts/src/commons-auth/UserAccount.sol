pragma solidity ^0.5;

import "commons-base/Owned.sol";
import "commons-management/VersionedArtifact.sol";

/**
 * @title UserAccount Interface
 * @dev API for interacting with a user account
 */
contract UserAccount is VersionedArtifact, Owned {

   event LogUserCreation(
        bytes32 indexed eventId,
        address userAccountAddress,
        address owner
    );

    bytes32 public constant EVENT_ID_USER_ACCOUNTS = "AN://user-accounts";

	/**
	 * @dev Initializes this DefaultOrganization with the specified owner and/or ecosystem . This function replaces the
	 * contract constructor, so it can be used as the delegate target for an ObjectProxy.
     * @param _owner public external address of individual owner
     * @param _ecosystem address of an ecosystem
     */
    function initialize(address _owner, address _ecosystem) external;

    /**
     * @dev Forwards a call to the specified target using the given bytes message.
     * @param _target the address to call
     * @param _payload the function payload consisting of the 4-bytes function hash and the abi-encoded function parameters
     * @return returnData - the bytes returned from calling the target function, if successful
     */
    function forwardCall(address _target, bytes calldata _payload) external returns (bytes memory returnData);

}
