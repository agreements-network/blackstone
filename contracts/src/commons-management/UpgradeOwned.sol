pragma solidity ^0.5;

import "commons-base/ErrorsLib.sol";
import "commons-management/StorageDefUpgradeOwner.sol";
import "commons-management/UpgradeOwnerTransferable.sol";

/**
 * @title UpgradeOwned
 * @dev A contract similar to Owned, but intended to be used for upgrade roles.
 */
contract UpgradeOwned is StorageDefUpgradeOwner, UpgradeOwnerTransferable {

    /**
     * @dev Modifier to only allow access by the system owner.
     */
    modifier pre_onlyByUpgradeOwner() {
        ErrorsLib.revertIf(msg.sender != upgradeOwner,
            ErrorsLib.UNAUTHORIZED(), "UpgradeOwned.pre_onlyByUpgradeOwner", "The msg.sender is not the upgrade owner");
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a new owner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferUpgradeOwnership(address _newOwner) external pre_onlyByUpgradeOwner {
        ErrorsLib.revertIf(_newOwner == address(0),
            ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "UpgradeOwned.transferUpgradeOwnership", "The new upgrade owner must not be NULL");
        if (upgradeOwner != _newOwner) {
            upgradeOwner = _newOwner;
            emit LogUpgradeOwnerChanged(upgradeOwner, _newOwner);
        }
    }

    function getUpgradeOwner() public view returns (address) {
        return upgradeOwner;
    }

}