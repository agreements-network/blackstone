pragma solidity ^0.5;

import "commons-base/Named.sol";
import "commons-base/Bytes32Identifiable.sol";

/**
 * @title NamedElement Interface
 * @dev Interface for an element with an ID and a name. 
 */
contract NamedElement is Named, Bytes32Identifiable { }