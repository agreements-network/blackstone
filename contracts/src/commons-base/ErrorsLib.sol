pragma solidity ^0.5;

/**
 * @title Errors Library
 * @dev Provides basic error codes and allows for creating error messages in a standardized format
 */
library ErrorsLib {

    event LogError(bytes32 indexed eventId, string code, string location, string message);

    function DELIMITER() internal pure returns (string memory) {
        return "::";
    }

    // HTTP-error-inspired error codes (400-600 range)
    function UNAUTHORIZED() internal pure returns (string memory) {
        return "ERR403";
    }

    function RESOURCE_NOT_FOUND() internal pure returns (string memory) {
        return "ERR404";
    }

    function RESOURCE_ALREADY_EXISTS() internal pure returns (string memory) {
        return "ERR409";
    }

    function INVALID_INPUT() internal pure returns (string memory) {
        return "ERR422";
    }

    function RUNTIME_ERROR() internal pure returns (string memory) {
        return "ERR500";
    }

    // Data- / State-related errors (600-700 range)
    function INVALID_STATE() internal pure returns (string memory) {
        return "ERR600";
    }

    function INVALID_PARAMETER_STATE() internal pure returns (string memory) {
        return "ERR601";
    }

    function OVERWRITE_NOT_ALLOWED() internal pure returns (string memory) {
        return "ERR610";
    }

    function NULL_PARAMETER_NOT_ALLOWED() internal pure returns (string memory) {
        return "ERR611";
    }

    function DEPENDENCY_NOT_FOUND() internal pure returns (string memory) {
        return "ERR704";
    }

    /**
     * @dev Format the provided parameters into an error string
     * @param _code an error code
     * @param _location a string identifying to origin of the error
     * @param _message an error message
     * @return a concatenated string consisting of the three parameters delimited by the DELIMITER()
     */
    function format(string memory _code, string memory _location, string memory _message) public pure returns (string memory) {
        if (bytes(_code).length == 0) {
            _code = RUNTIME_ERROR();
        }
        return string(abi.encodePacked(_code, DELIMITER(), _location, DELIMITER(), _message));
    }

    /**
     * @dev Wrapper function around a revert that avoids assembling the error message if the condition is false.
     * This function is meant to replace require(condition, ErrorsLib.format(...)) to avoid the cost of assembling an error string before the condition is checked.
     * @param _code an error code
     * @param _location a string identifying to origin of the error
     * @param _message an error message
     */
    function revertIf(bool _condition, string memory _code, string memory _location, string memory _message) public pure {
        if (_condition) {
            // logError("AN://transaction-rollback", _code, _location, _message);
            revert(format(_code, _location, _message));
        }
    }

    /**
     * @dev Logs an error event
     * @param _eventId the identifier to use for the indexed event ID
     * @param _code an error code
     * @param _location a string identifying to origin of the error
     * @param _message an error message
     */
    function logError(bytes32 _eventId, string memory _code, string memory _location, string memory _message) public {
        emit LogError(_eventId, _code, _location, _message);
    }
}
