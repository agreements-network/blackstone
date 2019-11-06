pragma solidity ^0.5;

import "commons-base/ErrorsLib.sol";
import "commons-base/StorageDefSystemOwner.sol";
import "commons-base/SystemOwnerTransferable.sol";

/**
 * @title SystemOwned
 * @dev A contract similar to Owned, but intended to be used by contracts to form ownership hierarchies rather than an external account being the owner.
 * The separation into its own contract is meant to support the combination of Owned and SystemOwned.
 */
contract SystemOwned is StorageDefSystemOwner, SystemOwnerTransferable {

    /**
     * @dev Modifier to only allow access by the system owner.
     */
    modifier pre_onlyBySystemOwner() {
        ErrorsLib.revertIf(msg.sender != systemOwner,
            ErrorsLib.UNAUTHORIZED(), "SystemOwned.pre_onlyBySystemOwner", "The msg.sender is not the system owner");
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a new owner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferSystemOwnership(address _newOwner) external pre_onlyBySystemOwner {
        ErrorsLib.revertIf(_newOwner == address(0),
            ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "SystemOwned.transferSystemOwnership", "The new system owner must not be NULL");
        if (systemOwner != _newOwner) {
            emit LogSystemOwnerChanged(systemOwner, _newOwner);
            systemOwner = _newOwner;
        }
    }

    /**
     * @dev Returns the system owner
     * @return the address of the system owner
     */
    function getSystemOwner() public view returns (address) {
        return systemOwner;
    }

}