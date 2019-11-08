pragma solidity ^0.5;

/**
 * @title Documents Library
 * @dev Defines data structures common to documents
 */
library Documents {

	// enum State {DRAFT, FINAL, EFFECTIVE, CANCELED}

	struct DocumentVersion {
			string hash;
			uint created;
			address creator;
			// uint state;
	}
}