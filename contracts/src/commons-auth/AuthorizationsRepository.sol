pragma solidity ^0.5;

/**
 * @title AuthorizationsRepository Interface
 * @dev API for interaction with an authorizations repository.
 */
interface AuthorizationsRepository {
    /**
     * @dev This function allows detection of whether the given address is associated with the specified role in the implementing repository.
     */
    function hasRole(address, bytes32) external view returns (bool);

    /**
     * @dev This function associates the given address with the specified role in the implementing repository. The function should return an error code indicating success or failure.
     */
    function addRole(address, bytes32) external returns (uint);

    /**
     * @dev This function disassociates the given address from the specified role in the implementing repository. The function should return an error code indicating success or failure.
     */
    function removeRole(address, bytes32) external returns (uint);
}
