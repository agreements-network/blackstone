pragma solidity ^0.5;

import "commons-standards/ERC165.sol";

/**
 * @title AbstractERC165
 * @dev Abstract implementation of the ERC165 interface to declare and query interface support for ERC165-based interface signatures.
 * Based on ERC165MappingImplementation example documented in https://github.com/ethereum/EIPs/pull/881
 */
contract AbstractERC165 is ERC165 {

    mapping(bytes4 => bool) private supportedInterfaces;

    /**
     * @dev non-public constructor
     */
    constructor() internal {
        // Setting the interface ID value directly to avoid compiler warnings for using "this" in constructor.
        // The more elegant way is commented out below, but the compiler warnings are detrimental to spotting errors in compiler output!
        supportedInterfaces[0x01ffc9a7] = true;
        // supportedInterfaces[this.supportsInterface.selector] = true;
    }

    /**
     * @dev Returns whether the declared interface signature is supported by this contract
     * @param _interfaceId the signature of the ERC165 interface
     * @return true if supported, false otherwise
     */
    function supportsInterface(bytes4 _interfaceId) external view returns (bool) {
        return supportedInterfaces[_interfaceId];
    }

    /**
     * @dev Adds a declaration of support for the specified ERC165 interface. Throws if the interface ID is 0xffffffff.
     * @param _interfaceId the signature of the ERC165 interface
     */
    function addInterfaceSupport(bytes4 _interfaceId) internal {
        require(_interfaceId !=  0xffffffff, "Forbidden value 0xffffffff for ERC165 interface");
        supportedInterfaces[_interfaceId] = true;
    }
}