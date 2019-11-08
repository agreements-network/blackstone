pragma solidity ^0.5;

import "commons-auth/Permissioned.sol";

import "agreements/Archetype_v1_0_0.sol";

/**
 * @title Archetype Interface
 * @dev API for interaction with an Archetype. This contract represents the latest "version" of the interface by inheriting from past versions and guaranteeing
 * the existence of past event and function signatures.
 */
contract Archetype is Archetype_v1_0_0, Permissioned {

	// v1.1.0 LogArchetypeCreation event with added field 'owner'
	event LogArchetypeCreation_v1_1_0(
		bytes32 indexed eventId,
		address archetypeAddress,
		uint price,
		address author,
		address owner,
		bool active,
		bool isPrivate,
		address successor,
		address formationProcessDefinition,
		address executionProcessDefinition
	);

	// LogArchetypeOwnerUpdate is used when retrofitting Archetype contracts < v1.1.0 with an owner value
	// see also #upgradeOwnerPermission(address)
	event LogArchetypeOwnerUpdate(
		bytes32 indexed eventId,
		address archetypeAddress,
		address owner
	);

	bytes32 public constant ROLE_ID_OWNER = keccak256(abi.encodePacked("archetype.owner"));

	/**
	 * @dev Initializes this ActiveAgreement with the provided parameters. This function replaces the
	 * contract constructor, so it can be used as the delegate target for an ObjectProxy.
	 * @param _price a price indicator for creating agreements from this archetype
	 * @param _isPrivate determines if this archetype's documents are encrypted
	 * @param _active determines if this archetype is active
	 * @param _author author
	 * @param _owner owner
	 * @param _formationProcess the address of a ProcessDefinition that orchestrates the agreement formation
	 * @param _executionProcess the address of a ProcessDefinition that orchestrates the agreement execution
	 * @param _governingArchetypes array of governing archetype addresses (optional)
	 */
	function initialize(
		uint _price,
		bool _isPrivate,
		bool _active,
		address _author,
		address _owner,
		address _formationProcess,
		address _executionProcess,
		address[] calldata _governingArchetypes)
		external;

	/**
	 * @dev Returns the owner
	 * @return the owner address
	 */
	function getOwner() external view returns (address);

	/**
	 * @dev Creates the "owner" permission and sets the owner of the Archetype to the specified address.
	 * This function is used to retrofit older (< v1.1.0) contracts that did not get the owner field set in their initialize() function
	 * and emit an appropriate event that can be used to update external data systems
	 * @param _owner the owner of this Archetype
	 */
	function upgradeOwnerPermission(address _owner) external;
}
