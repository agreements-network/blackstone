pragma solidity ^0.5;

/**
 * @title BaseErrors Library
 * @dev Basic Error Code constants to be used across an entire solution.
 * Categories are offset by 1000; each with a generic message at the start. Sub-categories offset by 100.
 * Note that the error value '0' is being avoided as this is the return value of an uninitialized uint.
 */
library BaseErrors {

    // ********************** Normal execution **********************

	/// @dev Return code indicating success
    function NO_ERROR() internal pure returns (uint) { return 1; }

    // ********************** Resources **********************

	/// @dev RESOURCE_ERROR
    function RESOURCE_ERROR() internal pure returns (uint) { return 1000; }
	/// @dev RESOURCE_NOT_FOUND
    function RESOURCE_NOT_FOUND() internal pure returns (uint) { return 1001; }
	/// @dev RESOURCE_ALREADY_EXISTS
    function RESOURCE_ALREADY_EXISTS() internal pure returns (uint) { return 1002; }

    // ********************** Access **********************

	/// @dev ACCESS_DENIED
    function ACCESS_DENIED() internal pure returns (uint) { return 2000; }

	/// @dev INSUFFICIENT_PRIVILEGES
    function INSUFFICIENT_PRIVILEGES() internal pure returns (uint) { return 2001; }

    // ********************** Input **********************

	/// @dev PARAMETER_ERROR
    function PARAMETER_ERROR() internal pure returns (uint) { return 3000; }
	/// @dev INVALID_PARAM_VALUE
    function INVALID_PARAM_VALUE() internal pure returns (uint) { return 3001; }
	/// @dev NULL_PARAM_NOT_ALLOWED
    function NULL_PARAM_NOT_ALLOWED() internal pure returns (uint) { return 3002; }
	/// @dev INTEGER_OUT_OF_BOUNDS
    function INTEGER_OUT_OF_BOUNDS() internal pure returns (uint) { return 3003; }

    // Collections
	/// @dev INDEX_OUT_OF_BOUNDS
    function INDEX_OUT_OF_BOUNDS() internal pure returns (uint) { return 3100; }

    // ********************** Contract states *******************

	/// @dev Catch-all for when the state of the contract does not allow the operation.
    function INVALID_STATE() internal pure returns (uint) { return 4000; }

	/// @dev INVALID_ACTION
    function INVALID_ACTION() internal pure returns (uint) { return 4100; }
	/// @dev INVALID_ACTION_STATUS
    function INVALID_ACTION_STATUS() internal pure returns (uint) { return 4101; }
	/// @dev INVALID_ACTION_TIME
    function INVALID_ACTION_TIME() internal pure returns (uint) { return 4102; }
	/// @dev INVALID_ACTOR
    function INVALID_ACTOR() internal pure returns (uint) { return 4103; }
	/// @dev OVERWRITE_NOT_ALLOWED
    function OVERWRITE_NOT_ALLOWED() internal pure returns (uint) { return 4104; }
	/// @dev INVALID_STATE_CHANGE
    function INVALID_STATE_CHANGE() internal pure returns (uint) { return 4105; }
    /// @dev Invalid state of a parameter
    function INVALID_PARAM_STATE() internal pure returns (uint) { return 4106; }

    // ********************** Runtime *******************

	/// @dev Catch-all for anything related to the invocation of an operation
    function RUNTIME_ERROR() internal pure returns (uint) { return 5000; }

	/// @dev CAST_ERROR
    function CAST_ERROR() internal pure returns (uint) { return 5001; }
	/// @dev INVALID_TYPE
    function INVALID_TYPE() internal pure returns (uint) { return 5002; }
	/// @dev UNSUPPORTED_OPERATION
    function UNSUPPORTED_OPERATION() internal pure returns (uint) { return 5003; }

    // ********************** Reserved - 6000-7999 *******************

    // ********************** Transfers *******************

    // Transferring some form of value from one account to another is very common,
    // so it should have default error codes.

	/// @dev TRANSFER_FAILED
    function TRANSFER_FAILED() internal pure returns (uint) { return 8000; }
	/// @dev NO_SENDER_ACCOUNT
    function NO_SENDER_ACCOUNT() internal pure returns (uint) { return 8001; }
	/// @dev NO_TARGET_ACCOUNT
    function NO_TARGET_ACCOUNT() internal pure returns (uint) { return 8002; }
	/// @dev TARGET_IS_SENDER
    function TARGET_IS_SENDER() internal pure returns (uint) { return 8003; }
	/// @dev TRANSFER_NOT_ALLOWED
    function TRANSFER_NOT_ALLOWED() internal pure returns (uint) { return 8004; }

    // Balance-related.
	/// @dev INSUFFICIENT_BALANCE
    function INSUFFICIENT_BALANCE() internal pure returns (uint) { return 8100; }
	/// @dev TRANSFERRED_AMOUNT_TOO_HIGH
    function TRANSFERRED_AMOUNT_TOO_HIGH() internal pure returns (uint) { return 8101; }

}
