pragma solidity ^0.5;

import "commons-base/ErrorsLib.sol";

/**
 * @title AbstractDelegateTarget
 * @dev Abstract contract providing a common base to control the initialization of contracts used as delegate targets.
 */
contract AbstractDelegateTarget {
	/**
	 * @dev The initialized flag signals whether this contract has been initialized.
	 */
	bool initialized;

	/**
	 * @dev Internal constructor to enforce abstract contract
	 */
	constructor() internal {}

	/**
	 * @dev Guards an initialization function by reverting if the contract has already been initialized and also
	 * guaranteeing that the initialized flag is set to true at the end.
	 */
	modifier pre_post_initialize() {
		ErrorsLib.revertIf(initialized,
			ErrorsLib.INVALID_STATE(), "AbstractDelegateTarget.pre_post_initialize", "The contract has already been initialized");
		_;
		initialized = true;
	}

}