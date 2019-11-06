pragma solidity ^0.5;

/**
 * @title OwnerTransferable
 * @dev Interface for transferable ownership.
 */
interface OwnerTransferable {

    event LogOwnerChanged(address previousOwner, address newOwner);

    /**
     * @dev Allows to transfer control of the contract to a new owner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) external;

}