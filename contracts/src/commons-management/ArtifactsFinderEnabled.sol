pragma solidity ^0.5;

import "commons-base/ErrorsLib.sol";
import "commons-standards/AbstractERC165.sol";

import "commons-management/ArtifactsFinder.sol";

/**
 * @title ArtifactsFinderEnabled
 * @dev To be inherited by contracts that need to look up other contracts by name, e.g. for dependency resolution.
 */
contract ArtifactsFinderEnabled is AbstractERC165 {
	
	bytes4 public constant ERC165_ID_ArtifactsFinderEnabled = bytes4(keccak256(abi.encodePacked("setArtifactsFinder(address)")));

	ArtifactsFinder artifactsFinder;
	
	/**
	 * @dev Internal constructor to enforce abstract character of the contract.
	 */
	constructor() internal {
		addInterfaceSupport(ERC165_ID_ArtifactsFinderEnabled);
	}

	/**
 	 * @dev Sets the ArtifactsFinder address.
	 * @param _artifactsFinder the address of an ArtifactsFinder
	 */
	function setArtifactsFinder(address _artifactsFinder) public {
        ErrorsLib.revertIf(address(_artifactsFinder) == address(0),
			ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "ArtifactsFinderEnabled.setArtifactsFinder", "The ArtifactsFinder address must not be null");
		artifactsFinder = ArtifactsFinder(_artifactsFinder);
	}
    
}