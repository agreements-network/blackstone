pragma solidity ^0.5;

import "commons-base/ErrorsLib.sol";
import "commons-collections/Mappings.sol";
import "commons-collections/MappingsLib.sol";
import "commons-standards/AbstractERC165.sol";
import "commons-management/AbstractDelegateTarget.sol";
import "commons-management/AbstractVersionedArtifact.sol";

import "commons-auth/UserAccount.sol";
import "commons-auth/Ecosystem.sol";
import "commons-auth/Governance.sol";

/**
 * @title DefaultUserAccount
 * @dev The default implementation of a UserAccount
 */
contract DefaultUserAccount is AbstractVersionedArtifact(1,0,0), AbstractDelegateTarget, UserAccount {

    using MappingsLib for Mappings.AddressBoolMap;

    Governance.UserAccount account;

    /**
     * @dev Modifier that restricts the function access to the owner address or one of the address known to belong to an ecosystem that this account is connected to.
     * REVERTS if:
     * - the msg.sender is not the owner and not one of the addresses associated with one of the account's ecosystems
     */
    modifier pre_onlyAuthorizedCallers() {
        bool authorized = msg.sender == owner;
        if (!authorized) {
            for (uint i=0; i<account.ecosystems.keys.length; i++) {
                if (Ecosystem(account.ecosystems.keys[i]).isKnownExternalAddress(msg.sender)) {
                    authorized = true;
                    break;
                }
            }
        }
        ErrorsLib.revertIf(!authorized, ErrorsLib.UNAUTHORIZED(), "DefaultUserAccount.pre_onlyAuthorizedCallers", "Caller is neither owner nor known ecosystem");
        _;
    }

	/**
	 * @dev Initializes this DefaultOrganization with the specified owner and/or ecosystem . This function replaces the
	 * contract constructor, so it can be used as the delegate target for an ObjectProxy.
     * One or both owner/ecosystem are required to be set to guarantee another entity has control over this UserAccount
     * REVERTS if:
     * - both owner and ecosystem are empty.
     * @param _owner public external address of individual owner (optional)
     * @param _ecosystem address of an ecosystem (optional)
     */
    function initialize(address _owner, address _ecosystem)
        external
        pre_post_initialize
    {
        ErrorsLib.revertIf(_owner == address(0) && _ecosystem == address(0),
            ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultUserAccount.constructor", "One of owner or ecosystem must be provided");
        owner = _owner;
        if (_ecosystem != address(0)) {
            account.ecosystems.insertOrUpdate(_ecosystem, true);
        }
        account.exists = true;
        emit LogUserCreation(
            EVENT_ID_USER_ACCOUNTS,
            address(this),
            _owner
        );

    }
    
    /**
     * @dev Forwards a call to the specified target using the given bytes message.
     * @param _target the address to call
     * @param _payload the function payload consisting of the 4-bytes function hash and the abi-encoded function parameters which is typically created by
     * calling abi.encodeWithSelector(bytes4, args...) or abi.encodeWithSignature(signatureString, args...) 
     * @return returnData - the bytes returned from calling the target function, if successful.
     * REVERTS if:
     * - the target address is empty (0x0)
     * - the target contract threw an exception (reverted). In this case this function will revert using the same reason
     */
    function forwardCall(address _target, bytes calldata _payload)
        external
        pre_onlyAuthorizedCallers
        returns (bytes memory returnData)
    {
        ErrorsLib.revertIf(_target == address(0),
            ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultUserAccount.forwardCall", "Target address must not be empty");
        bool success;
        bytes memory data = _payload;
        assembly {
            let freeMemSlot := mload(0x40)
            success := call(gas, _target, 0, add(data, 0x20), mload(data), freeMemSlot, 0)
        }
        uint returnSize;
        assembly {
            returnSize := returndatasize
        }
        returnData = new bytes(returnSize); // allocates a new byte array with the right size
        assembly {
            returndatacopy(add(returnData, 0x20), 0, returnSize) // copies the returned bytes from the function call into the return variable
        }
        if (!success) {
            if (returnData.length > 0) {
                assembly {
                    revert(add(returnData, 0x20), returnSize) // a revert(string(returnData)) would add add another 4 bytes for this functions signature to the beginning of the reason, so we'll use assembly here
                }
            }
            else
                revert(ErrorsLib.format(ErrorsLib.RUNTIME_ERROR(), "DefaultUserAccount.forwardCall", "The target function of the forward call reverted without a reason"));
        }
    }
}
