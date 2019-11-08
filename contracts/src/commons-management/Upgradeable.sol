pragma solidity ^0.5;

import "commons-management/VersionedArtifact.sol";

/**
 * @title Upgradeable
 * @dev Interface for contracts that support being upgraded.
 */
contract Upgradeable is VersionedArtifact {

	bytes4 public constant ERC165_ID_Upgradeable = bytes4(keccak256(abi.encodePacked("upgrade(address)")));

    /**
     * @dev Performs the necessary steps to upgrade from this contract to the specified new version.
     * @param _successor the address of a contract that replaces this one
     * @return true if successful, false otherwise
     */
    function upgrade(address _successor) public returns (bool success);

}