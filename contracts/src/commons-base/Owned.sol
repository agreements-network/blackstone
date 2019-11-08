pragma solidity ^0.5;

import "commons-base/ErrorsLib.sol";
import "commons-base/StorageDefOwner.sol";
import "commons-base/OwnerTransferable.sol";

/**
 * @title Owned
 * @dev Standard contract to be inherited when a contract is associated with an owner address and wants to
 * restrict access to function invocations to that owner.
 */
contract Owned is StorageDefOwner, OwnerTransferable {

    /**
     * @dev Modifier to only allow access by the owner.
     * REVERTS if:
     * - the msg.sender is not the owner
     */
    modifier pre_onlyByOwner() {
        ErrorsLib.revertIf(msg.sender != owner,
            ErrorsLib.UNAUTHORIZED(), "Owned.pre_onlyByOwner", "The msg.sender is not the owner");
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a new owner.
     * REVERTS if:
     * - the new owner is empty
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) external pre_onlyByOwner {
        ErrorsLib.revertIf(_newOwner == address(0),
            ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "Owned.transferOwnership", "The new owner must not be NULL");
        if (owner != _newOwner) {
            owner = _newOwner;
            emit LogOwnerChanged(owner, _newOwner);
        }
    }

    /**
     * @dev Returns the owner of this contract
     * @return the owner's address
     */
    function getOwner() public view returns (address) {
        return owner;
    }
}