pragma solidity ^0.5;

/**
 * @title UpgradeOwnerTransferable
 * @dev Interface to transfer upgrade ownership.
 */
interface UpgradeOwnerTransferable {

    event LogUpgradeOwnerChanged(address previousOwner, address newOwner);

    /**
     * @dev Allows the current owner to transfer control of the contract to a new owner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferUpgradeOwnership(address _newOwner) external;

}