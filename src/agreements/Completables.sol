pragma solidity ^0.5;

import "agreements/AgreementsAPI.sol";
import "commons-base/ErrorsLib.sol";
import "commons-utils/Strings.sol";
import "commons-management/AbstractUpgradeable.sol";
import "commons-management/AbstractVersionedArtifact.sol";


contract CompletableOptions {
    // Completable options
    uint public constant DEFAULT = 0;
    /**
    * Set: Automatically call complete on the Completable when ratified
    * Not set: Wait for Complete to be called externally
    */
    uint public constant COMPLETE_ON_RATIFICATION = 1;

    function enabled(uint options, uint option) public pure returns (bool) {
        return options & option > 0;
    }
}

// Notes on upgrading/design of this contract: we need to play back the events emitted by this contract in order to
// do a full upgrade in the future since we do not store complete state int the completables mapping - we just store enough to do
// book keeping (e.g. metadata). This is by design (the idea was 'events are primary state'/don't store history twice -
// sorry if that was a bad decision) and assumes that we can provide a mechanism (via Burrow or Vent DB)
// to play back the events to a migration contract
contract Completables is CompletableOptions, AbstractVersionedArtifact(1,0,0), AbstractUpgradeable {
    using Strings for *;

    bytes32 constant EVENT_ID_AGREEMENT_COMPLETABLE = "AN://agreement-completable";

    event LogAgreementCompletableInit(
        bytes32 indexed eventId,
        bytes32 indexed intervalId,
        address agreementAddress,
        string namespace,
        string name,
        address controller,
        uint threshold,
        string metadata
    );

    event LogAgreementCompletableInitFranchisee(
        bytes32 indexed eventId,
        bytes32 indexed intervalId,
        address agreementAddress,
        address franchisee
    );

    event LogAgreementCompletableBegin(
        bytes32 indexed eventId,
        bytes32 indexed intervalId,
        address agreementAddress,
        int timestamp
    );

    event LogAgreementCompletableAttest(
        bytes32 indexed eventId,
        bytes32 indexed intervalId,
        address agreementAddress,
        address franchisee,
        // Is the completable ratified after this attestation?
        bool ratified,
        int timestamp
    );

    event LogAgreementCompletableComplete(
        bytes32 indexed eventId,
        bytes32 indexed intervalId,
        address agreementAddress,
        bool ratified,
        int timestamp
    );

    event LogAgreementCompletableMetaUpdate(
        bytes32 indexed eventId,
        bytes32 indexed intervalId,
        string metadata
    );

    struct Franchisee {
        address franchiseeAddress;
        bool ratified;
    }

    struct Completable {
        // External identifier that must be globally unique
        bytes32 intervalId;
        // Index in the intervals storage variable to provide iterability
        uint index;
        // Note: currently all Completables are scoped to an agreement but this is intended to be relaxed to allow
        // completables to describe relations between agreements
        address agreementAddress;
        // Addresses Those who may vote in the implicit ballot of a Completable
        Franchisee[] franchisees;
        // Number of elements in franchisees list
        uint threshold;
        address controller;
        uint options;
        // Timestamps
        int begun;
        int completed;
        int ratified;
        bool exists;
    }

    // intervalId => franchisees
    mapping(bytes32 => Completable) completables;

    modifier completableExists(bytes32 intervalId) {
        if (!completables[intervalId].exists) {
            revert("Completable ".concat(intervalId.quote(), " does not exist"));
        }
        _;
    }

    modifier onlyController(bytes32 intervalId) {
        // Allow self calls for COMPLETE_ON_RATIFICATION
        if (msg.sender != address(this) && completables[intervalId].controller != msg.sender) {
            revert(Strings.concat("caller is not Completable controller: ", msg.sender.toHex(),
                " (msg.sender) != ", completables[intervalId].controller.toHex(), " (controller) ",
                " for Completable ", intervalId.toHex()));
        }
        _;
    }

    modifier intervalOpen(bytes32 intervalId, int instant) {
        if (!completables[intervalId].exists) {
            revert("Completable ".concat(intervalId.toHex(), " is undefined"));
        }
        if (instant == 0) {
            instant = int(block.timestamp);
        }
        if (completables[intervalId].begun == 0) {
            revert("Completable ".concat(intervalId.toHex(), " has not yet begun"));
        }
        if (instant < completables[intervalId].begun) {
            revert("Completable ".concat(intervalId.toHex(), " begins later (at ",
                completables[intervalId].begun.toString(), ") than instant ", instant.toString()));
        }
        if (completables[intervalId].completed != 0 && completables[intervalId].completed < instant) {
            revert("Completable ".concat(intervalId.toHex(), " is not open: it completed at ",
                completables[intervalId].completed.toString(), " before the instant ", instant.toString()));
        }
        _;
    }

    /**
    * @notice Configures and registers a new Completable. This reserves the `intervalId` and allows it to participate
    *         in relations. The caller (msg.sender) of init becomes the 'controller' of this Completable and is
    *         the only identity permitted to call `begin` and `complete`
    * @param namespace is a categorical identifier for this Completable for the purpose of querying and separating names
    * @param name is a human-readable name for the completable
    * @param franchisees contains the addresses of all agreement parties that are able to ratify ('vote on') this
    *        Completable. If a franchisee appears multiple times then their vote counts that many times (contributes
    *        that many times to the threshold).
    * @param threshold sets the number of ratifications (votes from franchisees counted as above) required for the
             Completable to be 'ratified'. The alternative is that the Completable 'defaults'
    * @param options sets various options for how Completables operate, see constants above
    * @param metadata an opaque datum that is meaningful to the Completable controller
    */
    function init(bytes32 intervalId,
        string calldata namespace,
        string calldata name,
        address agreementAddress,
        address[] calldata franchisees,
        uint threshold,
        uint options,
        string calldata metadata)
    external
    {
        if (completables[intervalId].exists) {
            revert(Strings.concat("Completable ", intervalId.toHex(), " already exists"));
        }
        if (threshold > franchisees.length) {
            revert(Strings.concat("Cannot create a completable with ratification threshold (", threshold.toString(),
                ") greater than number of franchisees (", franchisees.length.toString(), ")"));
        }
        if (intervalId[0] == 0) {
            revert("Completable intervalId must be non-empty");
        }
        completables[intervalId].intervalId = intervalId;
        completables[intervalId].agreementAddress = agreementAddress;
        completables[intervalId].threshold = threshold;
        completables[intervalId].options = options;
        completables[intervalId].controller = msg.sender;
        completables[intervalId].exists = true;

        emit LogAgreementCompletableInit(EVENT_ID_AGREEMENT_COMPLETABLE,
            intervalId,
            agreementAddress,
            namespace,
            name,
            msg.sender,
            threshold,
            metadata);

        for (uint i = 0; i < franchisees.length; i++) {
            completables[intervalId].franchisees.push(Franchisee(franchisees[i], false));

            emit LogAgreementCompletableInitFranchisee(EVENT_ID_AGREEMENT_COMPLETABLE,
                intervalId,
                agreementAddress,
                franchisees[i]);
        }
    }

    function begin(bytes32 intervalId, int timestamp)
    external
    completableExists(intervalId)
    onlyController(intervalId)
    {
        if (completables[intervalId].completed != 0) {
            // This allows us to institute a 'whichever comes first' race and not worry about late reports
            return;
        }
        if (completables[intervalId].begun != 0) {
            // We could revert here but it's nicer if we can provide idempotence - TODO: review WRT lair
            return;
        }
        if (timestamp == 0) {
            timestamp = int(block.timestamp);
        }
        completables[intervalId].begun = timestamp;
        emit LogAgreementCompletableBegin(EVENT_ID_AGREEMENT_COMPLETABLE,
            intervalId,
            completables[intervalId].agreementAddress,
            timestamp);
    }

    /**
     * @notice attest to this this completable, deriving the franchisee from the caller via the agreement associated with the completable
     * @return whether the Completable is ratified after this invocation
     */
    function attest(bytes32 intervalId, int timestamp)
    external
    completableExists(intervalId)
    intervalOpen(intervalId, timestamp)
    returns (bool)
    {
        address actor;
        address party;
        (actor, party) = AgreementsAPI.authorizePartyActor(completables[intervalId].agreementAddress);
        ErrorsLib.revertIf(actor == address(0),
            ErrorsLib.UNAUTHORIZED(), "Completables.ratify()",
            Strings.concat("The caller is not authorized to ratify ", intervalId.toHex()));

        if (timestamp == 0) {
            timestamp = int(block.timestamp);
        }
        if (ratifyAndCount(intervalId, actor, party) >= completables[intervalId].threshold) {
            completables[intervalId].ratified = timestamp;
        }
        // Avoid stack too deep issues with local variables
        Completable memory completable = completables[intervalId];

        bool isRatified = completable.ratified != 0;
        emit LogAgreementCompletableAttest(EVENT_ID_AGREEMENT_COMPLETABLE,
            intervalId,
            completable.agreementAddress,
            party,
            isRatified,
            timestamp);

        if (isRatified && enabled(completable.options, COMPLETE_ON_RATIFICATION)) {
            this.complete(intervalId, timestamp);
        }

        return isRatified;
    }

    function complete(bytes32 intervalId, int timestamp)
    external
    completableExists(intervalId)
    onlyController(intervalId)
    returns (bool isRatified) {
        if (!completables[intervalId].exists) {
            revert(Strings.concat("complete(): ", intervalId.toHex(), " is not defined"));
        }
        if (completables[intervalId].begun == 0) {
            revert(Strings.concat("complete(): ", intervalId.toHex(), " has not begun"));
        }
        isRatified = completables[intervalId].ratified != 0;
        if (completables[intervalId].completed != 0) {
            return isRatified;
        }
        if (timestamp == 0) {
            timestamp = int(block.timestamp);
        }
        completables[intervalId].completed = timestamp;
        emit LogAgreementCompletableComplete(EVENT_ID_AGREEMENT_COMPLETABLE,
            intervalId,
            completables[intervalId].agreementAddress,
            isRatified,
            timestamp
        );
    }

    /**
    * @return the timestamp when this Completable was ratified, or 0 if it has not yet been ratified, or -1 if it is
    *   complete and will never be ratified (it defaulted)
    */
    function ratifiedAt(bytes32 intervalId)
    external
    completableExists(intervalId)
    view
    returns (int ratified){
        ratified = completables[intervalId].ratified;
        if (ratified == 0 && completables[intervalId].completed != 0) {
            // Will never be ratified
            ratified = - 1;
        }
    }

    function ratifyAndCount(bytes32 intervalId, address actor, address party) internal returns (uint ratifications) {
        bool found;
        for (uint256 i; i < completables[intervalId].franchisees.length; i++) {
            // Note the same franchisee may appear multiple times, we could normalise this into a single franchisee but we don't
            if (completables[intervalId].franchisees[i].franchiseeAddress == actor || completables[intervalId].franchisees[i].franchiseeAddress == party) {
                completables[intervalId].franchisees[i].ratified = true;
                found = true;
            }
            if (completables[intervalId].franchisees[i].ratified) {
                ratifications++;
            }
        }
        if (!found) {
            revert(Strings.concat("Neither actor ", actor.toHex(), " or party ", party.toHex(), "is not a franchisee of interval ", intervalId.toHex()));
        }
        return ratifications;
    }

    function updateMeta(bytes32 intervalId, string calldata metadata)
        external
        completableExists(intervalId)
        onlyController(intervalId) {
        emit LogAgreementCompletableMetaUpdate(EVENT_ID_AGREEMENT_COMPLETABLE,
            intervalId,
            metadata
        );
    }

    // Migrations - we need to implement these functions if DOUG is to attempt to upgrade this way at any time in the future
    function migrateFrom(address) public returns (bool success) {
        success = true;
    }

    function migrateTo(address) public returns (bool success) {
        // Who knows?
        success = true;
    }
}
