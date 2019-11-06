pragma solidity ^0.5;

/**
 * @title SystemOwnerTransferable
 * @dev Interface to transfer system ownership.
 */
interface SystemOwnerTransferable {

    event LogSystemOwnerChanged(address previousOwner, address newOwner);

    /**
     * @dev Allows the current owner to transfer control of the contract to a new owner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferSystemOwnership(address _newOwner) external;

}