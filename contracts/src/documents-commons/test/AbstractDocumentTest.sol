pragma solidity ^0.5;

import "commons-base/BaseErrors.sol";

import "documents-commons/Document.sol";
import "documents-commons/AbstractDocument.sol";

/**
 * @dev Contract tests the AbstractDocument contract.
 */
contract AbstractDocumentTest {

    /**
     * @dev Tests document creation.
     *
     * @return "success", if successful or an explanatory message if not successful.
     */
    function testDocumentCreation() external returns (string memory) {

        Document doc1 = new TestDocument("doc1");

        // TODO name comparison will be enabled via string utils library
//        if (doc1.getName() != "doc1") { return "Doc1 name not set."; }
        if (doc1.getNumberOfVersions() != 0) { return "There should be no versions for a freshly created document."; }

        return "success";
    }

    /**
     * @dev Tests document versioning.
     *
     * @return "success", if successful or an explanatory message if not successful.
     */
    function testDocumentVersioning() external returns (string memory) {

        string memory docHash = "8jH87gYUV78jHBghuyuf543Rd";

        Document doc = new TestDocument("myDoc");

        // Add version
        if (BaseErrors.NO_ERROR() != doc.addVersion(docHash)) { return "Unexpected error adding version."; }

        if (doc.getNumberOfVersions() != 1) { return "Number of versions should be 1."; }

        // Test version attribute storage
        if (doc.getVersionCreated(docHash) <= 0 || doc.getVersionCreated(docHash) > now) { return "Version created date illegal."; }
        if (doc.getVersionCreator(docHash) != address(this)) { return "Version creator mismatch."; }

        return "success";
    }

}

/**
 * @dev Implementation of the AbstractDocument contract for the purposes of this test.
 */
contract TestDocument is AbstractDocument {
    // Constructor
    constructor(string memory _name) AbstractDocument(_name) public {}

    /**
     * @dev Implement `canAddVersion` to permit testing versioning capabilities.
     *
     * @return true.
     */
    function canAddVersion() internal view returns (bool) {
        return true;
    }
}
