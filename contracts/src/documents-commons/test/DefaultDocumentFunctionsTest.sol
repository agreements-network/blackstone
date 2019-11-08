pragma solidity ^0.5;

import "documents-commons/DefaultDocument.sol";

/**
 * @dev Contract tests the AbstractDocument contract.
 */
contract DefaultDocumentFunctionsTest {
    TestDefaultDocument defaultDocument;
    Foil foil;

    // Constructor
    constructor() public {
        defaultDocument = new TestDefaultDocument("default");
        foil = new Foil();
    }

    /**
     * @dev Tests `canAddVersion` creation.
     *
     * @return "success", if successful or an explanatory message if not successful.
     */
    function pubCanAddVersion() external view returns (bytes32) {
        if (!defaultDocument.pubCanAddVersion()) return "Expected true";
        if (foil.pubCanAddVersion(address(defaultDocument))) return "Expected false";
        return "success";
    }
}

/**
 * @dev Contract provides a foil to `DefaultDocumentFunctionsTest`.
 */
contract Foil {
    /**
     * @dev Calls `pubCanAddVersion` on `TestDefaultDocument`.
     *
     * @return `pubCanAddVersion` return.
     */
    function pubCanAddVersion(address _document) external view returns (bool) {
        return TestDefaultDocument(_document).pubCanAddVersion();
    }
}

/**
 * @dev Contract provides implementation of DefaultDocument with public-ized internal functions.
 */
contract TestDefaultDocument is DefaultDocument {
    // Constructor
    constructor(string memory _name) DefaultDocument(_name) public {}

    /**
     * @dev Implements public `canAddVersion` to permit testing `canAddVersion`.
     *
     * @return `canAddVersion` return.
     */
    function pubCanAddVersion() external view returns (bool) {
        return canAddVersion();
    }
}
