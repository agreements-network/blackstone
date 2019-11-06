pragma solidity ^0.5;

import "commons-base/BaseErrors.sol";

import "commons-collections/VersionLinkedAppendOnly.sol";

/**
 * @dev Auxiliary factory contract to create a VersionLinked instance with this ForeignOwner being the owner.
 */
contract ForeignOwner {
	
	function createLink(uint8[3] calldata _v) external returns (VersionLinkedAppendOnly) {
		return new VersionLinkedAppendOnly(_v);
	}
}

/**
 * @dev Special VersionLinked contract to be able to call another VersionLinked instance through this contract, i.e. as this msg.sender
 */
contract DelegateVersionLinked is VersionLinkedAppendOnly {
	
	constructor(uint8[3] memory _v) VersionLinkedAppendOnly(_v) public {}
	
	function delegateAcceptVersionLink(VersionLinkedAppendOnly _target, VersionLinkedAppendOnly _link) external returns (uint) {
		return _target.appendNewVersion(_link);
	}
}

contract VersionLinkedAppendOnlyTest {
	
	ForeignOwner otherLinkList = new ForeignOwner();

	// function in order to test setPredecessor()
	function getOwner() public pure returns (address) {}
	
	function testAppendOnlyLinking() external returns (string memory) {
		VersionLinkedAppendOnly v100 = new VersionLinkedAppendOnly([1,0,0]);
		VersionLinkedAppendOnly v100_1 = new VersionLinkedAppendOnly([1,0,0]);
		VersionLinkedAppendOnly v110 = new VersionLinkedAppendOnly([1,1,0]);
		VersionLinkedAppendOnly v250 = new VersionLinkedAppendOnly([2,5,0]);
		VersionLinkedAppendOnly v115 = new VersionLinkedAppendOnly([1,1,5]);		
		VersionLinkedAppendOnly v300 = new VersionLinkedAppendOnly([3,0,0]);
		VersionLinkedAppendOnly v350 = new VersionLinkedAppendOnly([3,5,0]);
		VersionLinkedAppendOnly v350_2 = new VersionLinkedAppendOnly([3,5,0]);

		if (v100.appendNewVersion(VersionLinkedAppendOnly(0x0)) != BaseErrors.NULL_PARAM_NOT_ALLOWED()) {
			return "Expected error when registering NULL.";
		}
		if (v100.appendNewVersion(v100_1) != BaseErrors.INVALID_PARAM_STATE()) {
			return "Expected error when registering same version.";
		}
		if (v100.appendNewVersion(v100) != BaseErrors.INVALID_PARAM_STATE()) {
			return "Expected error when registering same address.";
		}
		if (v100.appendNewVersion(otherLinkList.createLink([9,9,9])) != BaseErrors.INVALID_PARAM_STATE()) {
			return "Expected error when registering foreign owned link.";
		}
		if (v100.appendNewVersion(v110) != BaseErrors.NO_ERROR()) {
			return "Failed to link versions 100 and 110";
		}

		if (v100.getPredecessor() != address(0)) {
			return "Predecessor to v100 should be empty!";
		}
		if (v110.getSuccessor() != address(0)) {
			return "Successor to v110 should be empty!";
		} 
		if (v100.getSuccessor() != address(v110)) {
			return "v110 should be successor to v100.";
		}
		if (v110.getPredecessor() != address(v100)) {
			return "v100 should be predecessor to v110.";
		}
		
		if (v100.appendNewVersion(v250) != BaseErrors.NO_ERROR()) {
			return "Failed to link versions 250 into existing 100->110";
		}
		if (v100.getSuccessor() != address(v110) || v110.getSuccessor() != address(v250) ||
			v250.getPredecessor() != address(v110) || v110.getPredecessor() != address(v100)) {
			return "v250 and existing 100 -> 110 did not link as expected.";
		}

		if (v250.appendNewVersion(v115) != BaseErrors.INVALID_PARAM_STATE()) {
			return "100 -> 110 -> 250 -> 115 should have resulted in error";
		}
		if (v100.getSuccessor() != address(v110) || v110.getSuccessor() != address(v250) ||
			v250.getSuccessor() != address(0) || v250.getPredecessor() != address(v110) ||
			v110.getPredecessor() != address(v100)) {
			return "version chain does not match 100 -> 110 -> 250";
		}

		if (v100.appendNewVersion(v350) != BaseErrors.NO_ERROR()) {
			return "v350 should have been passed on to v250 and appended";
		}
		if (v100.getSuccessor() != address(v110) || v110.getSuccessor() != address(v250) ||
			v250.getSuccessor() != address(v350) || v350.getPredecessor() != address(v250) ||
			v250.getPredecessor() != address(v110) || v110.getPredecessor() != address(v100)) {
			return "v350 and existing 100 -> 110 -> 250 did not link as expected.";
		}

		// current chain = 100 -> 110 -> 250 -> 350
		if (v100.appendNewVersion(v300) != BaseErrors.INVALID_PARAM_STATE()) {
			return "v300 should not have been appended since it falls between two existing versions";
		}
		if (v100.getSuccessor() != address(v110) || v110.getSuccessor() != address(v250) ||
			v250.getSuccessor() != address(v350) || v350.getPredecessor() != address(v250) ||
			v250.getPredecessor() != address(v110) || v110.getPredecessor() != address(v100)) {
			return "v300 append request should not have changed the existing version chain";
		}

		// current chain = 100 -> 110 -> 250 -> 350
		if (v100.appendNewVersion(v350_2) != BaseErrors.INVALID_PARAM_STATE()) {
			return "v350_2 should not have been appended";
		}
		if (v100.getSuccessor() != address(v110) || v110.getSuccessor() != address(v250) ||
			v250.getSuccessor() != address(v350) || v350.getPredecessor() != address(v250) ||
			v250.getPredecessor() != address(v110) || v110.getPredecessor() != address(v100)) {
			return "v350_2 append request should not have changed the existing version chain";
		}

		if (v100.getLatest() != address(v350) || v110.getLatest() != address(v350) ||
				v250.getLatest() != address(v350) || v350.getLatest() != address(v350)) {
			return "all versions should have their latest property point to v350";
		}

		// current chain = 100 -> 110 -> 250 -> 350
		address tempPre = v350.getPredecessor();
		if (v350.setPredecessor() != BaseErrors.INVALID_PARAM_STATE()) {
			return "attempting to change predecessor from external contract should fail";
		}
		if (tempPre != v350.getPredecessor()) { return "attempting to set predecessor from external contract should have no effect"; }
		
		address tempLatest = v100.getLatest();
		if (v100.setLatest(v110)) { return "should not be able to set latest by a non-successor"; }
		if (tempLatest != v100.getLatest()) { return "attempting to set latest by a non-successor should have no effect"; }
		
		// current chain = 100 -> 110 -> 250 -> 350
		address addr;
		
		addr = v100.getTargetVersion([2,5,0]);
		if (addr != address(v250)) {
			return "v250 was not found in version chain";
		}

		addr = v350.getTargetVersion([1,1,0]);
		if (addr != address(v110)) {
			return "v110 was not found in version chain";
		}

		addr = v110.getTargetVersion([4,0,0]);
		if (addr != address(0)) {
			return "v400 should return empty address";
		}

		addr = v250.getTargetVersion([0,5,0]);
		if (addr != address(0)) {
			return "v050 should return empty address";
		}

		return "success";
	}

}