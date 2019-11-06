pragma solidity ^0.5;

import "commons-base/ErrorsLib.sol";
import "commons-utils/ArrayUtilsLib.sol";
import "commons-utils/TypeUtilsLib.sol";
import "commons-collections/Mappings.sol";
import "commons-collections/MappingsLib.sol";
import "commons-collections/AbstractDataStorage.sol";
import "commons-collections/AbstractAddressScopes.sol";
import "commons-events/DefaultEventEmitter.sol";
import "commons-management/AbstractDelegateTarget.sol";

import "agreements/Agreements.sol";
import "agreements/AgreementsAPI.sol";
import "agreements/Archetype.sol";
import "agreements/ActiveAgreement_v1_0_1.sol";

/**
 * @title Abstract ActiveAgreement v1.0.1
 * @dev Legacy version of the DefaultActiveAgreement implementation that was separated out to secure backwards compatibility by versionizing a snapshot of the contract and allowing future versions to extend it.
 * Note that this legacy version is an abstract contract due to not inheriting AbstractVersionedArtifact which must be inherited and initialized with a version at the current DefaultActiveAgreement contract.
 */
contract AbstractActiveAgreement_v1_0_1 is AbstractDelegateTarget, AbstractDataStorage, AbstractAddressScopes, DefaultEventEmitter, ActiveAgreement_v1_0_1 {
	
	using ArrayUtilsLib for address[];
	using TypeUtilsLib for bytes32;
	using MappingsLib for Mappings.Bytes32StringMap;

	bytes32 constant fileKeyPrivateParameters = keccak256(abi.encodePacked("fileKey.privateParameters"));
	bytes32 constant fileKeyEventLog = keccak256(abi.encodePacked("fileKey.eventLog"));
	bytes32 constant fileKeySignatureLog = keccak256(abi.encodePacked("fileKey.signatureLog"));

	address archetype;
	address creator;
	bool privateFlag;
	uint32 maxNumberOfEvents;
	Agreements.LegalState legalState;

	Mappings.Bytes32StringMap fileReferences;
	mapping(address => Agreements.Signature) signatures;
	mapping(address => Agreements.Signature) cancellations;
	address[] parties;
	address[] governingAgreements;

	/**
	 * @dev Checks the valid state transitions according to the below rules.
	 * The modifer will simply return if the current state already equals the new state.
	 * It is allowed to "jump" to any legal state, if the current state is UNDEFINED.
	 * 
	 * Allowed legal state changes:
	 * UNDEFINED -> *ANY*
	 * DRAFT <-> FORMULATED
	 * FORMULATED -> EXECUTED
	 * EXECUTED -> FULFILLED | DEFAULT
	 * DRAFT | FORMULATED | EXECUTED -> CANCELED

	 * REVERTS if:
	 * - the transition from the current state to the new state is not valid
	 * @param _newState the target legal state
	 */
	modifier pre_validateNextLegalState(Agreements.LegalState _newState) {
		if (legalState == _newState) {
			return;
		}
		if (legalState == Agreements.LegalState.UNDEFINED
			|| (legalState == Agreements.LegalState.DRAFT &&
			  (_newState == Agreements.LegalState.FORMULATED || _newState == Agreements.LegalState.CANCELED))
			|| (legalState == Agreements.LegalState.FORMULATED &&
			  (_newState == Agreements.LegalState.EXECUTED || _newState == Agreements.LegalState.DRAFT || _newState == Agreements.LegalState.CANCELED))
			|| (legalState == Agreements.LegalState.EXECUTED &&
			  (_newState == Agreements.LegalState.FULFILLED || _newState == Agreements.LegalState.DEFAULT || _newState == Agreements.LegalState.CANCELED))
		) {
			_;
		}
		else {
			revert(ErrorsLib.format(
				ErrorsLib.INVALID_PARAMETER_STATE(),
				"DefaultActiveAgreement.pre_isValidNextLegalState",
				"The transition from the current legal state to the target legal state is not valid"));
		}
	}

    /**
     * @dev non-public constructor
     */
    constructor() internal {}

	/**
	 * @dev Initializes this ActiveAgreement with the provided parameters. This function replaces the
	 * contract constructor, so it can be used as the delegate target for an ObjectProxy.
	 * @param _archetype archetype address
	 * @param _creator the account that created this agreement
	 * @param _privateParametersFileReference the file reference to the private parameters (optional)
	 * @param _isPrivate if agreement is private
	 * @param _parties the signing parties to the agreement
	 * @param _governingAgreements array of agreement addresses which govern this agreement (optional)
	 */
	function initialize(
		address _archetype, 
		address _creator, 
		string calldata _privateParametersFileReference, 
		bool _isPrivate, 
		address[] calldata _parties, 
		address[] calldata _governingAgreements)
		external
		pre_post_initialize
	{
		ErrorsLib.revertIf(_archetype == address(0),
			ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultActiveAgreement.initialize", "Archetype address must not be empty");
		ErrorsLib.revertIf(!Archetype(_archetype).isActive(),
			ErrorsLib.INVALID_PARAMETER_STATE(), "DefaultActiveAgreement.initialize", "Archetype must be active");
		
		validateGoverningAgreements(_governingAgreements, Archetype(_archetype).getGoverningArchetypes());

		archetype = _archetype;
		creator = _creator;
		if (bytes(_privateParametersFileReference).length > 0) {
			fileReferences.insertOrUpdate(fileKeyPrivateParameters, _privateParametersFileReference);
		}
		privateFlag = _isPrivate;
		parties = _parties;
		governingAgreements = _governingAgreements;
		legalState = Agreements.LegalState.FORMULATED; //TODO we currently don't support a negotiation phase in the AN, so the agreement's prose contract is already formulated when the agreement is created.
		// NOTE: some of the parameters for the event must be read from storage, otherwise "stack too deep" compilation errors occur
		emit LogAgreementCreation(
			EVENT_ID_AGREEMENTS,
			address(this),
			_archetype,
			_creator,
			_isPrivate,
			uint8(legalState),
			maxNumberOfEvents,
			_privateParametersFileReference,
			""
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
	 * @dev Validates the provided governing agreements against the given governing archetypes by checking that each
	 * governing agreement's archetype corresponds to one of the governing archetypes.
	 * This function makes sure that all governing agreements that are required were passed.
	 */
	function validateGoverningAgreements(address[] memory _governingAgreements, address[] memory _governingArchetypes) internal view {
	
		// _governingAgreements length must match governingArchetypes length. This is a shortcut verification to avoid expensive looping
		ErrorsLib.revertIf(_governingAgreements.length != _governingArchetypes.length,
			ErrorsLib.INVALID_INPUT(), "DefaultActiveAgreement.validateGoverningAgreements", "The number of provided governing agreements does not match the required number of governing archetypes");

		uint verifiedArchetypesCount = 0;
		// each of _governingAgreement's archetypes should have a match in governingArchetypes array
		for (uint i = 0; i < _governingAgreements.length; i++) {
			for (uint j=0; j < _governingArchetypes.length; j++) {
				if (_governingArchetypes[j] == address(0))
					continue;
				else if (_governingArchetypes[j] == ActiveAgreement_v1_0_1(_governingAgreements[i]).getArchetype()) {
					delete _governingArchetypes[j]; // marking as found by deleting the entry
					verifiedArchetypesCount++;
					break;
				}
			}
		}

		ErrorsLib.revertIf(_governingArchetypes.length > 0 && verifiedArchetypesCount != _governingArchetypes.length,
			ErrorsLib.INVALID_INPUT(), "DefaultActiveAgreement.validateGoverningAgreements", 
				"The provided governing agreements do not match all of the governing archetypes required by the archetype of this agreement");
 	}

	/**
	 * @dev Returns the number governing agreements for this agreement
	 * @return the number of governing agreements
	 */
	function getNumberOfGoverningAgreements() external view returns (uint size) {
		return governingAgreements.length;
	}

	/**
	 * @dev Retrieves the address for the governing agreement at the specified index
	 * @param _index the index position
	 * @return the address for the governing agreement
	 */
	function getGoverningAgreementAtIndex(uint _index) external view returns (address agreementAddress) {
		return governingAgreements[_index];
	}

	/**
	 * @dev Gets number of parties
	 * @return size number of parties
	 */
	function getNumberOfParties() external view returns (uint size) {
		return parties.length;
	}

	/**
	 * @dev Returns the party at the given index
	 * @param _index the index position
	 * @return the party's address or 0x0 if the index is out of bounds
	 */
	function getPartyAtIndex(uint _index) external view returns (address party) {
		if (_index < parties.length)
			return parties[_index];
	}

	/**
	 * @dev Returns the archetype
	 * @return the archetype address 
	 */
	function getArchetype() external view returns (address) {
		return archetype;
	}

	/**
	 * @dev Returns the reference to the private parameters of this ActiveAgreement
	 * @return the reference to an external document containing private parameters
	 */
	function getPrivateParametersReference() external view returns (string memory){
		return fileReferences.get(fileKeyPrivateParameters);
	}

	/**
	 * @dev Sets the max number of events for this agreement
	 */
	function setMaxNumberOfEvents(uint32 _maxNumberOfEvents) external {
		maxNumberOfEvents = _maxNumberOfEvents;
		emit LogAgreementMaxEventCountUpdate(EVENT_ID_AGREEMENTS, address(this), _maxNumberOfEvents);
	}

	/**
	 * @dev Updates the file reference for the event log of this agreement
	 * @param _eventLogFileReference the file reference to the event log
	 */
	function setEventLogReference(string calldata _eventLogFileReference) external {
		fileReferences.insertOrUpdate(fileKeyEventLog, _eventLogFileReference);
		emit LogAgreementEventLogReference(EVENT_ID_AGREEMENTS, address(this), _eventLogFileReference);
	}

	/**
	 * @dev Returns the reference for the event log of this ActiveAgreement
	 * @return the reference to an external document containing the event log
	 */
	function getEventLogReference() external view returns (string memory) {
		return fileReferences.get(fileKeyEventLog);
	}

	/**
	 * @dev Updates the file reference for the signature log of this agreement
	 * @param _signatureLogFileReference the file reference to the signature log
	 */
	function setSignatureLogReference(string calldata _signatureLogFileReference) external {
		fileReferences.insertOrUpdate(fileKeySignatureLog, _signatureLogFileReference);
		emit LogAgreementSignatureLogReference(EVENT_ID_AGREEMENTS, address(this), _signatureLogFileReference);
	}

	/**
	 * @dev Returns the reference for the signature log of this ActiveAgreement
	 * @return the reference to an external document containing the signature log
	 */
	function getSignatureLogReference() external view returns (string memory) {
		return fileReferences.get(fileKeySignatureLog);
	}

	/**
	 * @dev Returns the max number of events for the event log
	 * @return the max number of events for the event log
	 */
	function getMaxNumberOfEvents() external view returns (uint32) {
		return maxNumberOfEvents;
	}

	/**
	 * @dev Returns the creator
	 * @return the creator address
	 */
	function getCreator() external view returns (address) {
		return creator;
	}

	/**
	 * @dev Returns the private flag
	 * @return the private flag 
	 */
	function isPrivate() external view returns (bool) {
		return privateFlag;
	}

	/**
	 * @dev Returns the signee of the signature of the given party.
	 * @param _party the signing party
	 * @return the address of the signee (if the party authorized a signee other than itself)
	 */
	function getSignee(address _party) external view returns (address signee) {
		signee = signatures[_party].signee;
	}

	/**
	 * @dev Returns the timestamp of the signature of the given party.
	 * @param _party the signing party
	 * @return the time of signing or 0 if the address is not a party to this agreement or has not signed yet
	 */
	function getSignatureTimestamp(address _party) external view returns (uint signatureTimestamp) {
		signatureTimestamp = signatures[_party].timestamp;
	}

	/**
	 * @dev Returns the signee and timestamp of the signature of the given party.
	 * @param _party the signing party
	 * @return the address of the signee (if the party authorized a signee other than itself)
	 * @return the time of signing or 0 if the address is not a party to this agreement or has not signed yet
	 */
	function getSignatureDetails(address _party) external view returns (address signee, uint signatureTimestamp) {
		signee = signatures[_party].signee;
		signatureTimestamp = signatures[_party].timestamp;
	}

	/**
	 * @dev Returns whether the given account's signature is on the agreement.
	 * @param _signee The account to check
	 * @return true if the provided address is a recorded signature on the agreement, false otherwise
	 */
	function isSignedBy(address _signee) external view returns (bool) {
		// check the signedBy of all parties
		for (uint i=0; i<parties.length; i++) {
			if (signatures[parties[i]].signee == _signee)
				return true;
		}
		return false;
	}

	/**
	 * @dev Overriden method of DataStorage to return the agreement parties for special ID DATA_FIELD_AGREEMENT_PARTIES.
	 * @param _id the bytes32 ID of an address array
	 * @return the address array
	 */
	function getDataValueAsAddressArray(bytes32 _id) external view returns (address[] memory) {
		if (_id == DATA_FIELD_AGREEMENT_PARTIES) {
			return parties;
		}
		else {
			return dataStorageMap.get(_id).addressArrayValue;
		}
	}

	/**
	 * @dev Overrides DataStorage.getArrayLength(bytes32).
	 * Returns the number of parties for special ID DATA_FIELD_AGREEMENT_PARTIES. Otherwise behaves identical to DataStorage.getArrayLength(bytes32).
	 * @param _id the ID of the data field
	 * @return the size of the specified array
	 */
	function getArrayLength(bytes32 _id) public view returns (uint) {
		if (_id == DATA_FIELD_AGREEMENT_PARTIES) {
			return parties.length;
		}
		return super.getArrayLength(_id);
	}

	/**
	 * @dev Returns the legal state of this agreement
	 * @return the Agreements.LegalState as a uint
	 */
	function getLegalState() external view returns (uint8) {
		return uint8(legalState);
	}

	/**
     * @dev Sets the legal state of this agreement to Agreements.LegalState.FULFILLED.
	 * !deprecated! use #setLegalState(Agreements.LegalState) instead 
	 */
	function setFulfilled() external {
        legalState = Agreements.LegalState.FULFILLED;
        emit LogAgreementLegalStateUpdate(EVENT_ID_AGREEMENTS, address(this), uint8(legalState));
	}

	/**
	 * @dev Registers the msg.sender as having canceled the agreement.
	 * During formation (legal states DRAFT and FORMULATED), the agreement can canceled unilaterally by one of the parties to the agreement.
	 * During execution (legal state EXECUTED), the agreement can only be canceled if all parties agree to do so by invoking this function.
	 * REVERTS if:
	 * - the caller could not be authorized (see AgreementsAPI.authorizePartyActor())
	 */ 
	function cancel() external {

		address actor;
		address party;

		(actor, party) = AgreementsAPI.authorizePartyActor(address(this));

		// if the actor is empty at this point, the authorization is regarded as failed
		ErrorsLib.revertIf(actor == address(0),
			ErrorsLib.UNAUTHORIZED(), "DefaultActiveAgreement.cancel()", "The caller is not authorized to cancel");

		if (legalState == Agreements.LegalState.DRAFT ||
			legalState == Agreements.LegalState.FORMULATED) {
			// unilateral cancellation is allowed before execution phase
			legalState = Agreements.LegalState.CANCELED;
			emit LogActiveAgreementToPartyCancelationsUpdate(EVENT_ID_AGREEMENT_PARTY_MAP, address(this), party, actor, block.timestamp);
			emit LogAgreementLegalStateUpdate(EVENT_ID_AGREEMENTS, address(this), uint8(legalState));
			emitEvent(EVENT_ID_STATE_CHANGED, address(this)); // for cancellations we need to inform the registry
		}
		else if (legalState == Agreements.LegalState.EXECUTED) {
			// multilateral cancellation
			if (cancellations[party].timestamp == 0) {
				cancellations[party].signee = actor;
				cancellations[party].timestamp = block.timestamp;
			  emit LogActiveAgreementToPartyCancelationsUpdate(EVENT_ID_AGREEMENT_PARTY_MAP, address(this), party, actor, block.timestamp);
				for (uint i=0; i<parties.length; i++) {
					if (cancellations[parties[i]].timestamp == 0) {
						break;
					}
					if (i == parties.length-1) {
						legalState = Agreements.LegalState.CANCELED;
						emit LogAgreementLegalStateUpdate(EVENT_ID_AGREEMENTS, address(this), uint8(legalState));
						emitEvent(EVENT_ID_STATE_CHANGED, address(this)); // for cancellations we need to inform the registry
					}
				}
			}
		}
	}

}