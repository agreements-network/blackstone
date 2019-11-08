pragma solidity ^0.5;

import "commons-base/BaseErrors.sol";

import "documents-commons/AbstractDocument.sol";

/**
 * @title Agreement
 * @dev A basic Agreement based on a versioned document that allows the configuration of signatories and their endorsement of
 * a document version as effective. The Agreement is aware when all required endorsements are present for a particular
 * version and expresses this fact through state variables.
 */
contract Agreement is AbstractDocument {

	string confirmedVersion;
	bool effective;
	mapping(address => Endorsement) endorsements;
	mapping(address => Signatory) signatories;
	address[] signatoriesList;

    // represents the endorsement of a version of this document
	struct Endorsement {
		uint date;
		bytes32 version;
	}

    // represents a registered signatory
	struct Signatory {
	    bool exists;
	    uint index;
	}

    /**
     * @dev Checks that msg.sender is a signatory.
     */
	modifier onlyBySignatory(address party) {
		if (signatories[party].exists) _;
	}

    /**
     * @dev Checks that msg.sender is an owner or a signatory.
     */
	modifier onlyByOwnerOrSignatory(address party) {
		if (owner == party || signatories[party].exists) _;
	}

	/**
	 * @dev Creates a new Agreement with the given name.
	 */
	constructor(string memory _name) AbstractDocument(_name) public {}

    /**
     * @dev Adds the specified signatories to this agreement, if they are valid, and returns the number of added signatories.
     * Empty addresses and already registered signatories are rejected.
     *
	 * @param _addresses the signatories
	 * @return the number of added signatories
     */
	function addSignatories(address[] calldata _addresses) external pre_onlyByOwner returns (uint numAdded) {
		for (uint i = 0; i < _addresses.length; i++) {
		    if (BaseErrors.NO_ERROR() == addSignatory(_addresses[i])) {
		        numAdded++;
		    }
		}
	}

    /**
     * @dev Adds a single signatory to this agreement
     * @param _address the address to add
     * @return NO_ERROR, INVALID_PARAM_VALUE if address is empty, RESOURCE_ALREADY_EXISTS if address has already been registered
     */
    function addSignatory(address _address) public pre_onlyByOwner returns (uint) {
        if (_address == address(0)) return BaseErrors.INVALID_PARAM_VALUE();
        if (signatories[_address].exists) return BaseErrors.RESOURCE_ALREADY_EXISTS();
        uint index = signatoriesList.push(_address) - 1;
        signatories[_address] = Signatory({exists: true, index: index});
        return BaseErrors.NO_ERROR();
    }

    /**
     * @dev Registers the msg.sender as having confirmed/endorsed the specified document version as the execution version.
     *
	 * @param _version the version
	 * @return BaseErrors.NO_ERROR(), BaseErrors.INVALID_PARAM_VALUE() if given version is empty, or BaseErrors.RESOURCE_NOT_FOUND() if the version does not exist
     */
	function confirmExecutionVersion(string calldata _version) external onlyBySignatory(msg.sender) returns (uint) {
		if (keccak256(abi.encodePacked(_version)) == keccak256(abi.encodePacked(""))) return BaseErrors.INVALID_PARAM_VALUE(); // TODO: refactor once a string util lib that permits comparison is incorporated
        if (versions[keccak256(abi.encodePacked(_version))].created <= 0) return BaseErrors.RESOURCE_NOT_FOUND();

        endorsements[msg.sender] = Endorsement({date: now, version: keccak256(abi.encodePacked(_version))});

        if (isFullyConfirmed(_version)) {
        	confirmedVersion = _version;
        	effective = true;
        }

        return BaseErrors.NO_ERROR();
	}

    /**
     * @dev Determines if the submitted version has been signed by all signatories.
     *
	 * @param _version the version
	 * @return true if all configured signatories have signed that version, false otherwise
     */
	function isFullyConfirmed(string memory _version) public view returns (bool fullyConfirmed) {
		for (uint i; i < signatoriesList.length; i++) {
			if (endorsements[signatoriesList[i]].version != keccak256(abi.encodePacked(_version))) {
			    return false;
			}
		}
		return true;
	}

    /**
     * @dev Indicates if the msg.sender is allowed to add a version.
     * @return true if the msg.sender is either the document owner or one of the signatories.
     */
    function canAddVersion() internal view onlyByOwnerOrSignatory(msg.sender) returns (bool) {
        return true;
    }

    /**
     * @dev Returns the number of signatories of this agreement.
     * @return the number of signatories
     */
    function getSignatoriesSize() external view returns (uint) {
        return signatoriesList.length;
    }

    /**
     * @dev Returns the confirmed version of this agreement, if it has been set.
     * @return 
     */
    function getConfirmedVersion() external view returns (string memory) {
        return confirmedVersion;
    }

    /**
     * @dev Returns whether this agreement is effective or not
     */
    function isEffective() external view returns (bool) {
        return effective;
    }

    /**
     * @dev Get the document version endorsed by the specified signatory.
     *
     * @param _signatory the signatory
     * @return the version hash, if an endorsed version exists, or an uninitialized string
     */
    function getEndorsedVersion(address _signatory) external view returns (string memory) {
        return versions[endorsements[_signatory].version].hash;
    }

    /**
     * @dev Verify if the specified version hash is the confirmed version.
     *
     * @param _version the version
     * @return true if the version matches the confirmed one, false otherwise
     */
    function isConfirmedVersion(string calldata _version) external view returns (bool) {
        return keccak256(abi.encodePacked(confirmedVersion)) == keccak256(abi.encodePacked(_version));
    }

}