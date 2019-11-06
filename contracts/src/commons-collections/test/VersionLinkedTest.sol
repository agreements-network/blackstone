pragma solidity ^0.5;

import "commons-base/BaseErrors.sol";

import "commons-collections/VersionLinked.sol";

/**
 * @dev Auxiliary factory contract to create a VersionLinked instance with this ForeignOwner being the owner.
 */
contract ForeignOwner {
	
	function createLink(uint8[3] calldata _v) external returns (VersionLinked) {
		return new VersionLinked(_v);
	}
}

/**
 * @dev Special VersionLinked contract to be able to call another VersionLinked instance through this contract, i.e. as this msg.sender
 */
contract DelegateVersionLinked is VersionLinked {
	
	constructor(uint8[3] memory _v) VersionLinked(_v) public {}
	
	function delegateAcceptVersionLink(VersionLinked _target, VersionLinked _link) external returns (uint) {
		return _target.acceptVersionLink(_link);
	}
}

contract VersionLinkedTest {
	
	ForeignOwner otherLinkList = new ForeignOwner();
		
	function testVersionLinking() external returns (string memory) {

		VersionLinked v100 = new VersionLinked([1,0,0]);
		VersionLinked v100_1 = new VersionLinked([1,0,0]);
		VersionLinked v110 = new VersionLinked([1,1,0]);
		VersionLinked v250 = new VersionLinked([2,5,0]);
		VersionLinked v301 = new VersionLinked([3,0,1]);
		VersionLinked v302 = new VersionLinked([3,0,2]);
		VersionLinked v327 = new VersionLinked([3,2,7]);

		if (v100.acceptVersionLink(VersionLinked(0x0)) != BaseErrors.NULL_PARAM_NOT_ALLOWED()) return "Expected error when registering NULL.";
		if (v100.acceptVersionLink(v100_1) != BaseErrors.INVALID_PARAM_VALUE()) return "Expected error when registering same version.";
		if (v100.acceptVersionLink(v100) != BaseErrors.INVALID_PARAM_VALUE()) return "Expected error when registering same address.";
		if (v100.acceptVersionLink(otherLinkList.createLink([9,9,9])) != BaseErrors.INVALID_STATE()) return "Expected error when registering foreign owned link.";
		if (v100.acceptVersionLink(v110) != BaseErrors.NO_ERROR()) return "Failed to link versions 100 and 110";
		if (v100.getPredecessor() != address(0)) return "Predecessor to v100 should be empty!";
		if (v110.getSuccessor() != address(0)) return "Successor to v110 should be empty!";
		if (v100.getSuccessor() != address(v110)) return "v110 should be successor to v100.";
		if (v110.getPredecessor() != address(v100)) return "v100 should be predecessor to v110.";
		
		if (v100.acceptVersionLink(v327) != BaseErrors.NO_ERROR()) return "Failed to link versions 327 into existing 100->110";
		if (v100.getSuccessor() != address(v110) ||
			v110.getSuccessor() != address(v327) ||
			v327.getPredecessor() != address(v110) ||
			v110.getPredecessor() != address(v100)) return "v327 and existing 100->110 did not link as expected.";

		if (v327.acceptVersionLink(v301) != BaseErrors.NO_ERROR()) return "Failed to link versions 301 into existing 100->110->327";
		if (v100.getSuccessor() != address(v110) ||
			v110.getSuccessor() != address(v301) ||
			v301.getSuccessor() != address(v327) ||
			v327.getPredecessor() != address(v301) ||
			v301.getPredecessor() != address(v110) ||
			v110.getPredecessor() != address(v100)) return "v301 and existing 100->110->327 did not link as expected.";
		
		if (v327.acceptVersionLink(v250) != BaseErrors.NO_ERROR()) return "Failed to link versions 250 into existing 100->110->301->327";
		if (v100.getSuccessor() != address(v110) ||
			v110.getSuccessor() != address(v250) ||
			v250.getSuccessor() != address(v301) ||
			v301.getSuccessor() != address(v327) ||
			v327.getPredecessor() != address(v301) ||
			v301.getPredecessor() != address(v250) ||
			v250.getPredecessor() != address(v110) ||
			v110.getPredecessor() != address(v100)) return "v250 and existing 100->110->301->327 did not link as expected.";
		
		if (v250.acceptVersionLink(v302) != BaseErrors.NO_ERROR()) return "Failed to link versions 302 into existing 100->110->250->301->327";
		if (v100.getSuccessor() != address(v110) ||
			v110.getSuccessor() != address(v250) ||
			v250.getSuccessor() != address(v301) ||
			v301.getSuccessor() != address(v302) ||
			v302.getSuccessor() != address(v327) ||
			v327.getPredecessor() != address(v302) ||
			v302.getPredecessor() != address(v301) ||
			v301.getPredecessor() != address(v250) ||
			v250.getPredecessor() != address(v110) ||
			v110.getPredecessor() != address(v100)) return "v302 and existing 100->110->250->301->327 did not link as expected.";

		return "success";
	}

}