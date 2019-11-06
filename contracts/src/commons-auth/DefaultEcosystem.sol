pragma solidity ^0.5;

import "commons-base/ErrorsLib.sol";
import "commons-auth/Ecosystem.sol";
import "commons-collections/Mappings.sol";
import "commons-collections/MappingsLib.sol";
import "commons-management/AbstractVersionedArtifact.sol";
import "commons-management/AbstractDelegateTarget.sol";

/**
 * @title DefaultEcosystem
 * @dev The default Ecosystem implementation
 */
contract DefaultEcosystem is AbstractVersionedArtifact(1,0,0), AbstractDelegateTarget, Ecosystem {

    using MappingsLib for Mappings.Bytes32AddressMap;
    
    mapping (address => bool) publicKeys;
    Mappings.Bytes32AddressMap userAccounts;

	/**
	 * @dev Initializes this DefaultOrganization with the provided parameters. This function replaces the
	 * contract constructor, so it can be used as the delegate target for an ObjectProxy.
     * Sets the msg.sender as the owner of the Ecosystem
     */
    function initialize()
        external
        pre_post_initialize
    {
        owner = msg.sender;
    }

    function addExternalAddress(address _address)
        external
        pre_onlyByOwner
    {
        publicKeys[_address] = true;
    }

    function removeExternalAddress(address _address)
        external
        pre_onlyByOwner
    {
        delete publicKeys[_address];
    }

    function isKnownExternalAddress(address _address)
        external view
        returns (bool)
    {
        return publicKeys[_address];
    }

    // TODO protect function with modifier for owner or public key only

    function addUserAccount(bytes32 _id, address _userAccount) 
        external
    {
        ErrorsLib.revertIf(
            (_id == ""), 
            ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(),
            "DefaultEcosystem.addUserAccount",
            "User ID cannot be empty"
        );
        ErrorsLib.revertIf(
            (_userAccount == address(0)), 
            ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(),
            "DefaultEcosystem.addUserAccount",
            "User account address cannot be empty"
        );
        ErrorsLib.revertIf(
            userAccounts.exists(_id), 
            ErrorsLib.RESOURCE_ALREADY_EXISTS(),
            "DefaultEcosystem.addUserAccount",
            "User with same ID already exists in given ecosystem"
        );
        uint error = userAccounts.insert(_id, _userAccount);
        ErrorsLib.revertIf(
            error != BaseErrors.NO_ERROR(), 
            ErrorsLib.RUNTIME_ERROR(),
            "DefaultEcosystem.addUserAccount",
            "User with same ID already exists in given ecosystem"
        );
    }

    function getUserAccount(bytes32 _id)
        external
        view
        returns (address userAccount) 
    {
        userAccount = userAccounts.get(_id);
        ErrorsLib.revertIf(
            userAccount == address(0),
            ErrorsLib.RESOURCE_NOT_FOUND(),
            "DefaultEcosystem.getUserAccount",
            "User account with given Id does not exist"
        );
    }
}