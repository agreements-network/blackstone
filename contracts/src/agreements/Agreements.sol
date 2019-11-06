pragma solidity ^0.5;

/**
 * @title Agreements
 * @dev Library to define data structures used across agreements.
 */
library Agreements {

  enum LegalState {DRAFT, FORMULATED, EXECUTED, FULFILLED, DEFAULT, CANCELED, UNDEFINED}

  enum CollectionType {CASE, DEAL, DOSSIER, FOLDER, MATTER, PACKAGE, PROJECT}

  struct Signature {
    address signee;
    uint timestamp;
  }

  struct ArchetypePackage {
    bytes32 id;
    address author;
    bool isPrivate;
    bool active;
    address[] archetypes;
  }

  struct ArchetypePackageMap {
    mapping(bytes32 => ArchetypePackageElement) rows;
    bytes32[] keys;
  }

  struct ArchetypePackageElement {
    uint keyIdx;
    ArchetypePackage value;
    bool exists;
  }

  struct AgreementCollection {
    bytes32 id;
    address author;
    CollectionType collectionType;
    bytes32 packageId;
    address[] agreements;
  }

  struct AgreementCollectionMap {
    mapping(bytes32 => AgreementCollectionElement) rows;
    bytes32[] keys;
  }

  struct AgreementCollectionElement {
    uint keyIdx;
    AgreementCollection value;
    bool exists;
  }

}