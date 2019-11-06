pragma solidity ^0.5;

/**
 * @title Signable
 * @dev Interface for something that can be signed or endorsed, e.g. an agreement, an approval, or a vote.
 */
interface Signable {

    /**
     * @dev Applies a signature to a signable entity.
     * The implementing contract has the msg.sender, or the tx.origin at its disposal to use as signature.
     * This function is therefore intended to be called directly from the account that is attempting to sign.
     */
    function sign() external;
}