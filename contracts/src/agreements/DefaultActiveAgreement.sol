pragma solidity ^0.5;

import "commons-base/ErrorsLib.sol";
import "commons-management/AbstractVersionedArtifact.sol";
import "commons-auth/AbstractPermissioned.sol";

import "agreements/Archetype.sol";
import "agreements/ActiveAgreement.sol";
import "agreements/AbstractActiveAgreement_v1_0_1.sol";

/**
 * @title DefaultActiveAgreement
 * @dev Default implementation of the ActiveAgreement interface. This contract represents the latest "version" of the artifact by inheriting from past versions to guarantee the order
 * of storage variable declarations. It also inherits and instantiates AbstractVersionedArtifact.
 */
contract DefaultActiveAgreement is AbstractVersionedArtifact(1,3,0), AbstractActiveAgreement_v1_0_1, AbstractPermissioned, ActiveAgreement {

	/**
	 * @dev Legacy initialize function that is not supported anymore in this version of DefaultArchetype and will always revert.
	 * param _archetype archetype address
	 * param _creator the account that created this agreement
	 * param _privateParametersFileReference the file reference to the private parameters (optional)
	 * param _isPrivate if agreement is private
	 * param _parties the signing parties to the agreement
	 * param _governingAgreements array of agreement addresses which govern this agreement (optional)
	 */
	function initialize(
		address /*_archetype*/,
		address /*_creator*/,
		string calldata /*_privateParametersFileReference*/,
		bool /*_isPrivate*/,
		address[] calldata /*_parties*/,
		address[] calldata /*_governingAgreements*/)
		external
	{
		revert(ErrorsLib.format(ErrorsLib.INVALID_STATE(),
		"DefaultActiveAgreement.initialize(address,address,string,bool,address[],address[])",
		"This version of initialize is no longer supported. Please use DefaultActiveAgreement.initialize(address,address,address,string,bool,address[],address[])"));
	}

	/**
	 * @dev Initializes this ActiveAgreement with the provided parameters. This function replaces the
	 * contract constructor, so it can be used as the delegate target for an ObjectProxy.
	 * @param _archetype archetype address
	 * @param _creator the account that created this agreement
	 * @param _owner the account that owns this agreement
	 * @param _privateParametersFileReference the file reference to the private parameters (optional)
	 * @param _isPrivate if agreement is private
	 * @param _parties the signing parties to the agreement
	 * @param _governingAgreements array of agreement addresses which govern this agreement (optional)
	 */
	function initialize(
		address _archetype, 
		address _creator, 
		address _owner, 
		string calldata _privateParametersFileReference, 
		bool _isPrivate, 
		address[] calldata _parties, 
		address[] calldata _governingAgreements)
		external
		pre_post_initialize
	{
		ErrorsLib.revertIf(_creator == address(0),
			ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultActiveAgreement.initialize", "The provided creator address must not be empty");
		ErrorsLib.revertIf(_owner == address(0),
			ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultActiveAgreement.initialize", "The provided owner address must not be empty");
		ErrorsLib.revertIf(_archetype == address(0),
			ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultActiveAgreement.initialize", "Archetype address must not be empty");
		ErrorsLib.revertIf(!Archetype(_archetype).isActive(),
			ErrorsLib.INVALID_PARAMETER_STATE(), "DefaultActiveAgreement.initialize", "Archetype must be active");
		
		validateGoverningAgreements(_governingAgreements, Archetype(_archetype).getGoverningArchetypes());

    	addInterfaceSupport(ERC165_ID_Address_Scopes);

		archetype = _archetype;
		creator = _creator;
		if (bytes(_privateParametersFileReference).length > 0) {
			fileReferences.insertOrUpdate(fileKeyPrivateParameters, _privateParametersFileReference);
		}
		privateFlag = _isPrivate;
		parties = _parties;
		governingAgreements = _governingAgreements;
		legalState = Agreements.LegalState.FORMULATED; //TODO we currently don't support a negotiation phase in the AN, so the agreement's prose contract is already formulated when the agreement is created.

		permissions[ROLE_ID_OWNER].multiHolder = false;
		permissions[ROLE_ID_OWNER].revocable = false;
		permissions[ROLE_ID_OWNER].transferable = true;
		permissions[ROLE_ID_OWNER].exists = true;
		permissions[ROLE_ID_OWNER].holders.length = 1;
		permissions[ROLE_ID_OWNER].holders[0] = _owner;

		permissions[ROLE_ID_LEGAL_STATE_CONTROLLER].multiHolder = false;
		permissions[ROLE_ID_LEGAL_STATE_CONTROLLER].revocable = true;
		permissions[ROLE_ID_LEGAL_STATE_CONTROLLER].transferable = true;
		permissions[ROLE_ID_LEGAL_STATE_CONTROLLER].exists = true;

		// NOTE: some of the parameters for the event must be read from storage, otherwise "stack too deep" compilation errors occur
		emit LogAgreementCreation_v1_1_0(
			EVENT_ID_AGREEMENTS,
			address(this),
			_archetype,
			_creator,
      		_owner,
			_privateParametersFileReference,
			"",
			_isPrivate,
			uint8(legalState),
			maxNumberOfEvents
		);
		uint i;
		for (i = 0; i < _parties.length; i++) {
			emit LogActiveAgreementToPartySignaturesUpdate(EVENT_ID_AGREEMENT_PARTY_MAP, address(this), _parties[i], address(0), uint(0));
		}
		for (i = 0; i < _governingAgreements.length; i++) {
			emit LogGoverningAgreementUpdate(EVENT_ID_GOVERNING_AGREEMENT, address(this), _governingAgreements[i]);
		}
	}

	/**
	 * @dev Applies the msg.sender or tx.origin as a signature to this agreement, if it can be authorized as a valid signee.
	 * The timestamp of an already existing signature is not overwritten in case the agreement is signed again by the
	 * same signatory!
	 * Once the agreement is fully signed (all signatures applied), its legal state automatically switches to EXECUTED,
	 * unless an external controller (see permissions[ROLE_ID_LEGAL_STATE_CONTROLLER]) is set.
	 * REVERTS if:
	 * - the caller could not be authorized (see AgreementsAPI.authorizePartyActor())
	 */
	function sign() external {

		address signee;
		address party;

		(signee, party) = AgreementsAPI.authorizePartyActor(address(this));

		// if the signee is empty at this point, the authorization is regarded as failed
		ErrorsLib.revertIf(signee == address(0),
			ErrorsLib.UNAUTHORIZED(), "DefaultActiveAgreement.sign()", "The caller is not authorized to sign");

		// the signature is only applied, if no previous signature for the party exists
		if (signatures[party].timestamp == 0) {
			signatures[party].signee = signee;
			signatures[party].timestamp = block.timestamp;
			emit LogActiveAgreementToPartySignaturesUpdate(EVENT_ID_AGREEMENT_PARTY_MAP, address(this), party, signee, block.timestamp);
			// if the legal state is not controlled externally and the agreement is executed, change the legal state here
			if (AgreementsAPI.isFullyExecuted(address(this)) &&
			   permissions[ROLE_ID_LEGAL_STATE_CONTROLLER].holders.length == 0) {
				legalState = Agreements.LegalState.EXECUTED;
				emit LogAgreementLegalStateUpdate(EVENT_ID_AGREEMENTS, address(this), uint8(legalState));
			}
		}
	}

	/**
	 * @dev Sets the legal state of this agreement
	 * Note: The modifier pre_validateNextLegalState is currently not applied on this function to allow
	 * the ROLE_ID_LEGAL_STATE_CONTROLLER to jump to any legal state in order to support importing legacy
	 * agreements into the system.
	 * REVERTS if:
	 * - the msg.sender does not have the ROLE_ID_LEGAL_STATE_CONTROLLER permission
	 * @param _legalState the Agreements.LegalState
	 */
	function setLegalState(Agreements.LegalState _legalState)
		pre_requiresPermission(ROLE_ID_LEGAL_STATE_CONTROLLER)
		external
	{
		legalState = _legalState;
		emit LogAgreementLegalStateUpdate(EVENT_ID_AGREEMENTS, address(this), uint8(legalState));
	}

	/**
	 * @dev Returns the owner
	 * @return the owner address or an empty address if not set
	 */
	function getOwner() external view returns (address) {
    	return permissions[ROLE_ID_OWNER].holders.length > 0 ? permissions[ROLE_ID_OWNER].holders[0] : address(0);
	}

}
