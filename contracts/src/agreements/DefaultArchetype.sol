pragma solidity ^0.5;

import "commons-base/ErrorsLib.sol";
import "commons-management/AbstractVersionedArtifact.sol";
import "commons-auth/AbstractPermissioned.sol";

import "agreements/Archetype.sol";
import "agreements/AbstractArchetype_v1_0_0.sol";

/**
 * @title DefaultArchetype
 * @dev Default implementation of the Archetype interface. This contract represents the latest "version" of the artifact by inheriting from past versions to guarantee the order
 * of storage variable declarations. It also inherits and instantiates AbstractVersionedArtifact.
 */
contract DefaultArchetype is AbstractVersionedArtifact(1,2,1), AbstractArchetype_v1_0_0, AbstractPermissioned, Archetype {

	/**
	 * @dev Legacy initialize function that is not supported anymore in this version of DefaultArchetype and will always revert.
	 * param _price a price indicator for creating agreements from this archetype
	 * param _isPrivate determines if this archetype's documents are encrypted
	 * param _active determines if this archetype is active
	 * param _author author
	 * param _formationProcess the address of a ProcessDefinition that orchestrates the agreement formation
	 * param _executionProcess the address of a ProcessDefinition that orchestrates the agreement execution
	 * param _governingArchetypes array of governing archetype addresses (optional)
	 */
	function initialize(
		uint /*_price*/,
		bool /*_isPrivate*/,
		bool /*_active*/,
		address /*_author*/,
		address /*_formationProcess*/,
		address /*_executionProcess*/,
		address[] calldata /*_governingArchetypes*/)
		external
	{
		revert(ErrorsLib.format(ErrorsLib.INVALID_STATE(),
		"DefaultArchetype.initialize(uint256,bool,bool,address,address,address,address[])",
		"This version of initialize is no longer supported. Please use DefaultArchetype.initialize(uint256,bool,bool,address,address,address,address,address[])"));
	}

	/**
	 * @dev Initializes this DefaultArchetype with the provided parameters. This function replaces the
	 * contract constructor, so it can be used as the delegate target for an ObjectProxy.
	 * REVERTS if:
	 * - the author address is empty
	 * - the owner address is empty
	 * - the list of governing archetypes has duplicate entries
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
		external
		pre_post_initialize
	{
		ErrorsLib.revertIf(_author == address(0),
			ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultArchetype.initialize", "The provided author address must not be empty");
		ErrorsLib.revertIf(_owner == address(0),
			ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultArchetype.initialize", "The provided owner address must not be empty");
		ErrorsLib.revertIf(_governingArchetypes.hasDuplicates(),
			ErrorsLib.INVALID_INPUT(), "DefaultArchetype.initialize", "Governing archetypes must not contain duplicates");

		price = _price;
		privateFlag = _isPrivate;
		active = _active;
		author = _author;
		formationProcessDefinition = _formationProcess;
		executionProcessDefinition = _executionProcess;
		governingArchetypes = _governingArchetypes;

		// create the built-in owner permission and set it
		permissions[ROLE_ID_OWNER].multiHolder = false;
		permissions[ROLE_ID_OWNER].revocable = false;
		permissions[ROLE_ID_OWNER].transferable = true;
		permissions[ROLE_ID_OWNER].exists = true;
		permissions[ROLE_ID_OWNER].holders.length = 1;
		permissions[ROLE_ID_OWNER].holders[0] = _owner;

		// NOTE: some of the parameters for the event must be read from storage, otherwise "stack too deep" compilation errors occur
		emit LogArchetypeCreation_v1_1_0(
			EVENT_ID_ARCHETYPES,
			address(this),
			_price,
			_author,
			_owner,
			_active,
			_isPrivate,
			successor,
			formationProcessDefinition,
			executionProcessDefinition
		);
		for (uint i = 0; i < _governingArchetypes.length; i++) {
			emit LogGoverningArchetypeUpdate(
				EVENT_ID_GOVERNING_ARCHETYPES, 
				address(this), 
				_governingArchetypes[i]
			);
		}
	}

	/**
	 * @dev Returns the owner
	 * @return the owner address or an empty address if not set
	 */
	function getOwner() external view returns (address) {
    	return permissions[ROLE_ID_OWNER].holders.length > 0 ? permissions[ROLE_ID_OWNER].holders[0] : address(0);
	}

	/**
	 * @dev Creates the "owner" permission and sets the owner of the Archetype to the specified address.
	 * This function is used to retrofit older (< v1.1.0) contracts that did not get the owner field set in their initialize() function
	 * and emit an appropriate event that can be used to update external data systems
 	 * REVERTS if:
	 * - The provided owner address is empty
	 * - The owner permission already exists (which indicates that the contract has been upgraded already)
	 * @param _owner the owner of this Archetype
	 */
	function upgradeOwnerPermission(address _owner) external {
		ErrorsLib.revertIf(_owner == address(0),
			ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultArchetype.upgradeOwnerPermission", "The provided address must not be empty");
		ErrorsLib.revertIf(permissions[ROLE_ID_OWNER].exists,
			ErrorsLib.INVALID_STATE(), "DefaultArchetype.upgradeOwnerPermission", "The owner permission already exists. This contract's storage might already have been upgraded");
		permissions[ROLE_ID_OWNER].multiHolder = false;
		permissions[ROLE_ID_OWNER].revocable = false;
		permissions[ROLE_ID_OWNER].transferable = true;
		permissions[ROLE_ID_OWNER].exists = true;
		// Note: there currently is no code path that would lead to the permission marked as "exists" (see above) while a holder is already registered,
		// so is is not explicitly checked if an existing holder is overwritten
		permissions[ROLE_ID_OWNER].holders.length = 1;
		permissions[ROLE_ID_OWNER].holders[0] = _owner;
		emit LogArchetypeOwnerUpdate(EVENT_ID_ARCHETYPES, address(this), _owner);
	}

	/**
	 * @dev Sets the successor this archetype. Setting a successor automatically deactivates this archetype.
	 * REVERTS if:
	 * - msg.sender is not the owner or a member of the owner organization
	 * - given successor is the same address as itself.
	 * - intended action will lead to two archetypes with their successors pointing to each other.
	 * @param _successor address of successor archetype
	 */
	function setSuccessor(address _successor)
		external
		pre_requiresPermissionWithContext(ROLE_ID_OWNER, "")
	{
		ErrorsLib.revertIf(_successor == address(this),
			ErrorsLib.INVALID_INPUT(), "DefaultArchetype.setSuccessor", "Archetype cannot be its own successor");
		ErrorsLib.revertIf(Archetype_v1_0_0(_successor).getSuccessor() == address(this),
			ErrorsLib.INVALID_INPUT(), "DefaultArchetype.setSuccessor", "Successor circular dependency not allowed");
		active = false;
		successor = _successor;
		emit LogArchetypeSuccessorUpdate(EVENT_ID_ARCHETYPES, address(this), _successor);
	}

	/**
	 * @dev Activates this archetype
   	 * REVERTS if:
	 * - msg.sender is not the owner or a member of the owner organization
	 */
	function activate()
		external
		pre_requiresPermissionWithContext(ROLE_ID_OWNER, "")
	{
		ErrorsLib.revertIf(successor != address(0), ErrorsLib.INVALID_STATE(), "DefaultArchetype.activate", "Archetype with a successor cannot be activated");
		active = true;
		emit LogArchetypeActivation(EVENT_ID_ARCHETYPES, address(this), true);
	}

	/**
	 * @dev Deactivates this archetype
	 * REVERTS if:
	 * - msg.sender is not the owner or a member of the owner organization
	 */
	function deactivate()
		external
		pre_requiresPermissionWithContext(ROLE_ID_OWNER, "")
	{
		active = false;
		emit LogArchetypeActivation(EVENT_ID_ARCHETYPES, address(this), false);
	}
}
