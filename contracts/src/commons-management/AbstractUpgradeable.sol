pragma solidity ^0.5;

import "commons-base/ErrorsLib.sol";

import "commons-management/Upgradeable.sol";
import "commons-management/Migratable.sol";
import "commons-management/UpgradeOwned.sol";
import "commons-management/AbstractVersionedArtifact.sol";

/**
 * @title AbstractUpgradeable
 * @dev An abstract contract that supports the lifecycle of products.
 */
contract AbstractUpgradeable is AbstractVersionedArtifact, UpgradeOwned, Upgradeable, Migratable {

    /**
     * @dev Checks if the supplied Versioned contract address is higher than this contract's version.
     * REVERTS if:
     * - the supplied Versioned contract does not have a higher version than this contract.
     */
    modifier pre_higherVersionOnly(address _newVersion) {
        ErrorsLib.revertIf(compareArtifactVersion(_newVersion) < 1,
            ErrorsLib.INVALID_INPUT(), "AbstractUpgradeable.pre_higherVersionOnly", "The upgrade successor must have a higher version than the current contract.");
        _;
    }

    /**
     * @dev Creates a new AbstractUpgradeable and sets the msg.sender to be the upgradeOwner.
     */
    constructor() internal {
        upgradeOwner = msg.sender;
        addInterfaceSupport(ERC165_ID_Upgradeable);
    }

    /**
     * @dev Checks the version and invokes migrateTo and migrateFrom in order to transfer state (push then pull)
     * REVERTS if:
     * - Either migrateTo or migrateFrom were not successful
     * @param _successor the address of a Versioned contract that replaces this one
     * @return true if the upgrade was successful, otherwise a REVERT is triggered to rollback any changes from the upgrade
     */
    function upgrade(address _successor)
        public
        pre_onlyByUpgradeOwner
        pre_higherVersionOnly(_successor)
        returns (bool success)
    {
        // First 'push' state to the new contract
        // Then allow the other contract to 'pull' state.
        success = (migrateTo(_successor) && Migratable(_successor).migrateFrom(address(this)));
        ErrorsLib.revertIf(!success,
            ErrorsLib.INVALID_STATE(), "AbstractUpgradeable.upgrade", "One of migrateTo / migrateFrom returned false. Aborting upgrade.");
    }

}