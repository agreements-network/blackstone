# Changelog - Blackstone Smart Contract Framework

## Release History

- Version [2.2.0](#v2.2.0)
- Version [2.1.0](#v2.1.0)
- Version [2.0.1](#v2.0.1)
- Version [2.0.0](#v2.0.0)
- Version [1.2.0](#v1.2.0)
- Version [1.1.0](#v1.1.0)
- Version [1.0.0](#v1.0.0)
- Version [0.10.0](#v0.10.0)
- Version [0.9.1](#v0.9.1)
- Version [0.9.0](#v0.9.0)
- Version [0.8.0](#v0.8.0)
- Version [0.7.0](#v0.7.0)
- Version [0.6.1](#v0.6.1)
- Version [0.6.0](#v0.6.0)
- Version [0.5.2](#v0.5.2)
- Version [0.5.1](#v0.5.1)

## <a name="v2.2.0">Release 2.2.0</a>

### Changed

- Remove default department from organizations
- Remove organization id
- workaround for function(address,bytes32) signature breaking with empty bytes32:
  `AddressScopes.resolveAddressScope` returns a marker for an empty value rather than "".

## <a name="v2.1.0">Release 2.1.0</a>

### Changed

- `triggerIntermediateEvent` and `setIntermediateEventTimerTarget` are now idempotent to support at-least once delivery

## <a name="v2.0.1">Release 2.0.1</a>

### Changed

- Merged two renewal events

## <a name="v2.0.0">Release 2.0.0</a>

### Added

- Intermediate events (timers)
- Renewal management (events and windows manger)

## <a name="v1.2.0">Release 1.2.0</a>

### Fixed
- Use pg-listen and throw error on sync failure
- Fix deployment pushes

## <a name="v1.1.0">Release 1.1.0</a>

### Added

- Approvers and representative parameters


## <a name="v1.0.0">Release 1.0.0</a>

### Features / Changes / Bug Fixes

#### solts

##### Build
In order to bridge Solidity with Typescript, we not rely on a custom code-gen library named solts. In src/build.ts we use solc to compile our contracts, providing abis and bytecode to solts. This generates special contract classes which takes a client interface satisfied by src/lib/client.ts for burrow. Executing npm run build in the root of this repository will ensure that the typescript library is up-to-date - this should always be run before publishing, as it will also compile and copy over the static assets.

##### Deploy
Instead of burrow deploy, the contract suite can now be deployed through src/deploy.ts which uses promise chaining to ensure all dependencies are met, without slowing the process. We still require our 'playbooks' until vent can be adapted to use on-chain ABIs or we can provide additional support through code-gen.

##### Other
There are now several typescript types corresponding to the Solidity equivalent, though we have no way to ensure synchronicity through code-gen currently.

#### Agreement Redaction
Added an additional agreement legal state (REDACTED) and support for moving the legal state of a canceled agreement to redacted.

#### Timers
Added support for defining BPMN intermediate and boundary events in the ProcessModel and execution support for these constructs in the runtime.

#### yarn
Moved from npm to yarn.

### Compatibility

This release was tested with the following software and versions:

|                    |        |
| :----------------- | :----- |
| Hyperledger Burrow | 0.30.2 |
| Solc               | 0.5.12 |

## <a name="v0.10.0">Release 0.10.0</a>

This release removes the HTTP API and most JS controllers from the project in order to turn blackstone into a (smart contract + JavaScript) library that can be embedded into other projects.

### Compatibility

This release was tested with the following software and versions:

|                    |        |
| :----------------- | :----- |
| Hyperledger Burrow | 0.28.2 |
| Solc               | 0.5.12 |

### Features / Bug Fixes

- Removed all HTTP endpoints and all JS controllers from the project. Only the `contracts-controller` remains as the lowest level interface to provide a JS API to communicate with the smart contracts.
- Exposed the `ActiveAgreement.isSignedBy(address)` function as a JS function in the contracts-controller.


## <a name="v0.9.1">Release 0.9.1</a>

This is a patch release to upgrade the Hoard document system to version 6 and make all smart contracts compatible with Solidity 0.5.x.

### Compatibility

This release was tested with the following software and versions:

|                    |        |
| :----------------- | :----- |
| Hyperledger Burrow | 0.28.2 |
| Solc               | 0.5.12 |

### Features / Bug Fixes

- Added support for Hyperledger Burrow's Hoard version 6.
- Migrated all smart contracts to be compatible with Solidity version 0.5.x


## <a name="v0.9.0">Release 0.9.0</a>

This release fixes a critical bug of Release 0.8.0 which affected existing deployments < 0.8.0 resulting in an incompatibility in contract storage for Agreement and Archetype contracts. A feature was added to allow an agreement's legal state to be controlled from an external address.

### Compatibility

This release was tested with the following software and versions:

|                    |        |
| :----------------- | :----- |
| Hyperledger Burrow | 0.28.2 |
| Solc               | 0.4.25 |

### Breaking Changes

- The API for creating an archetype will now return an error if the process model contains and uses agreement parameters that are missing in the `Archetype`.
- CRITICAL: Refactored `ActiveAgreement` v1.1.0 inheritance to fix storage incompatibility problem on existing deployments. The original ActiveAgreement v.1.0.1 was separated out into its own legacy smart contract and slightly modified to be usable as a base to be inherited by later versions, specifically, the DefaultActiveAgreement_v1_0_1 does not inherit AbstractVersionedArtifact anymore as the artifact version must be initialized in DefaultActiveAgreement. DefaultActiveAgreement now inherits its core behavior from DefaultActiveAgreement_v1_0_1 and only adds the delta on top. The same was done for the interface hierarchy: ActiveAgreement inherits from ActiveAgreement_v1_0_1.
- CRITICAL: Refactored `Archetype` v1.1.0 inheritance to fix storage incompatibility problem on existing deployments. The original Archetype v.1.0.0 was separated out into its own legacy smart contract and slightly modified to be usable as a base to be inherited by later versions, specifically, the DefaultArchetype_v1_0_0 does not inherit AbstractVersionedArtifact anymore as the artifact version must be initialized in DefaultArchetype. DefaultArchetype now inherits its core behavior from DefaultArchetype_v1_0_0 and only adds the delta on top. The same was done for the interface hierarchy: Archetype inherits from Archetype_v1_0_0.

### Features / Bug Fixes

- Added support for Hyperledger Burrow 0.28.2
- Integrated a new mode in Burrow's Vent to produce append-only log tables that can be used to feed into message queues or other event processing systems
- Added the permissioned capability for an agreement to have its legal state controlled from another address. This will support the use case of relegating control over an agreement's legal state to a `ProcessInstance`. If no external permission is set, the `Agreement` behaves as before and changes its state to Executed after all signatures are applied.
- The `AgreementsAPI` library was updated and requires an upgrade in DOUG on existing deployments.
- Added additional `DataTypes.ParameterTypes` DURATION and CYCLE
- Added new functions `getHolder` and `getPermissionDetails` to commons-auth/`Permissioned`
- Added .gitattributes file for sol syntax highlighting on github


## <a name="v0.8.0">Release 0.8.0</a>

This release adds improvements on Agreement smart contracts to handle arbitrary numbers of file reference as well as the introduction of the AbstractPermissioned contract to manage bytes32 based permissions on objects. Wet signatures are now recorded via the API, referenced in an external file, and hashed into the Agreement smart contract. Also, approvers of an Organization can now add other approvers.

### Compatibility

This release was tested with the following software and versions:

|                    |        |
| :----------------- | :----- |
| Hyperledger Burrow | 0.25.0 |
| Solc               | 0.4.25 |

### Features / Bug Fixes

- Added support for Hyperledger Burrow 0.25.0
- Versionized event definitions to provide old definitions in ABIs required e.g. for Vent running against older chains. The original event definitions `LogArchetypeCreation` and `LogAgreementCreation` were restored and v1_0_0 was appended to the new event definitions.
- Added an owner field to the `Archetype` contract.
- `Archetype` and `Agreement` are now capable of handling arbitrary permissions.
- Improved handling of approvers for `Organization` contracts
- Added support for wet-signatures that are recorded in a file and hashed into the `Agreement`.
- The `Agreement` contract now possesses a mapping for file references to record any number of files
- Added missing setSignatureLogReference function in ActiveAgreementRegistry. For previous installations it is required to run an upgrade yaml file for ActiveAgreementsRegistry.
- The API now supports downloading a ZIP file containing a summary of the `Agreement` and all its attached files
- The parity license was upgraded to v6.0.0
- Changed the API to allow access to private process models by parties of an agreement that runs on these processes. This fixes a bug in the UI to be able to render diagrams for templates based on these models.
- Added support for an arbitrary number of agreement attachments. A single file is referenced in the smart contract containing an array of raw text entries or references to other files.


## <a name="v0.7.0">Release 0.7.0</a>

This release introduces breaking changes around the management of contracts via the DOUG contract and a major refactoring of all "object"-type contracts for which the storage and implementation have been separated using an "unstructured delegate proxy" approach to make them upgradeable.

### Compatibility

This release was tested with the following software and versions:

|                    |        |
| :----------------- | :----- |
| Hyperledger Burrow | 0.24.3 |
| Solc               | 0.4.25 |

### Breaking Changes

- Refactoring to store file references as string instead of two bytes32 fields. All external file references in the smart contracts using two bytes32 fields to store an address (file hash) and secret key have been replaced with a single string field to hold an arbitrary type of reference in a serialized form, like a Hoard symmetric grant.
- The `DOUG` interface was refactored to provide a cleaner approach to contract management and maintenance and now supports three functions: `deploy`, `register`, and `lookup`. The `ContractManager` inside DOUG was replaced with a new contract `ArtifactsRegistry` which uses the unstructured proxy pattern to be upgradeable. This `ArtifactsRegistry` supports keeping track of all versions of a contract over time. Also, the dependency injection has been changed such that contracts no longer register to be informed of changes to an artifact (`ContractChangeListener was removed`), but use the `ArtifactsFinder` reference at runtime to lookup the current dependency reference.
- All "object"-type contracts (ActiveAgreement, Archetype, ProcessModel, ProcessDefinition, ProcessInstance, UserAccount, Organization, Ecosystem) now are created as ObjectProxy objects linking to an implementation contract that is upgradeable through `DOUG` and the `ArtifactsFactory`.
- A new table ENTITIES_ADDRESS_SCOPES replaces the AGREEMENT_ADDRESS_SCOPES table to now contain address scopes for any contract that implements `AbstractAddressScopes`, e.g. at the moment agreements and process instances.
- The following smart contract storage fields were removed to prevent real-world-identifiable data to be stored on chain: Archetype name and description, Agreement name, Package name and description, Collection name, Department name.
- The department ID is now a generated bytes32 ID and stored as hex value in the Vent database to match the special *organization key* and *default department ID* formats.
- The `DefaultUserAccount` contract's `forwardCall(...)` function was changed  to only return the payload and no additional bool to signal success. The bool is no longer required as the contract now *re-throws* an exception (revert) that originated in the forward target contract.
- The function signatures around adding and handling the document references of an `Archetype` were refactored no longer support an external name for the file to be passed in. Instead, a generated `bytes32` key is used. This avoids using a filename as key and accidentally revealing real-world identifiable information.

### Features / Bug Fixes

- Added support for Hyperledger Burrow 0.24.3
- The AGREEMENT_TO_PARTY table now contains information about cancellations in addition to signatures.
- Bug fixed in API layer which caused boolean-based transition conditions that used a `= false` condition to be recorded as `= true`.


## <a name="v0.6.1">Release 0.6.1</a>

Release 0.6.1 is a patch release on top of the 0.6.0 release to add address the following issues:

- add an environment variable for the Postgres DB schema
- fix a gap in the API that prevented support of the new parameter type `POSITIVE_NUMBER` that was added in release 0.6.0.
- fixed the version of Node module "helmet" which had problems getting installed
- locked all Node dependency versions in package.json


## <a name="v0.6.0">Release 0.6.0</a>

This release contains larger changes around data mappings and process model parameters. Process models using the `NUMBER` parameter type must be upgraded under certain conditions (see Breaking Changes below).

### Compatibility

This release was tested with the following software and versions:

|                    |        |
| :----------------- | :----- |
| Hyperledger Burrow | 0.23.3 |
| Solc               | 0.4.25 |

### Breaking Changes

- The modifier `AbstractUpgradeable.pre_higherVersionOnly(address)` was changed to revert rather than simply return if the passed Versioned contract is of a smaller version.
- Deleted contract `agreements/ParameterTypesAccess.sol` and moved the enum for parameter types into `commons-utils/DataTypesAccess.sol`.
- Changed the XML process model and bpm-parser.js to use different format for activity data mapping IDs. Added new INOUT direction value to make it easier to use a single data mapping for connecting the same data field as input and output.
- Changed the GET /bpm/activity-instances response attribute for data mappings `accessPointId` to `dataMappingId` and enhanced the data information with the `parameterType`.
- Changed the API to translate `NUMBER` parameter types into `int` instead of `uint`. The new `POSITIVE_NUMBER` parameter type now connect to `uint`. Process models that used NUMBER parameters in data mappings to applications requiring a `uint` (e.g. TotalCounterCheck, NumberIncrementor, NumberDecrementor) must be upgraded to use POSITIVE_NUMBER or they will not work as expected!

### Features / Bug Fixes

- Added support for Hyperledger Burrow 0.23.3
- Fixed a bug in contracts.js to use the completeActivityWithData function correctly and complete an ActivityInstance with single data in one transaction
- Added performer name to GET /bpm/activity-instances response
- Allow external users to register for an account address only via email
- Updated GET /bpm/process-definitions route to add optional query params
- Added storage of data definitions access functions in `bpm-model/DefaultProcessModel.sol`. The data parameters from the XML process model are now persisted in the ProcessModel and exported to a new Vent table PROCESS_MODEL_DATA
- Added 4 new parameter types to `common/constants.js` and `commons-utils/DataTypesAccess.sol`: BYTES32, DOCUMENT, LARGE_TEXT, POSITIVE_NUMBER
- Improved API with ability to add your custom middleware to the blackstone API. Also added the ability to accept a custom passport config.
- Added support for external users to execute IN/OUT data mappings on activities
- Upgraded `bpm-model/DefaultProcessModelRepository.sol` to version 1.1.0 in order to support an upgrade to changed contracts `DefaultProcessModel` and `DefaultProcessDefinition` which adds events for data-mapping information that populates the new Vent table `DATA_MAPPINGS`. An upgrade script for existing deployments `contracts/upgrade/ProcessModelRepository-1.1.0.yaml` was added.


## <a name="v0.5.2">Release 0.5.2</a>

### Compatibility

This release was tested with the following software and versions:

|                    |        |
| :----------------- | :----- |
| Hyperledger Burrow | 0.23.1 |
| Solc               | 0.4.25 |

### Breaking Changes

- The function `ActiveAgreementRegistry.startFormation(ActiveAgreement)` was renamed to `startProcessLifecycle(ActiveAgreement)` and the returned ProcessInstance address can now represent a started Formation or Execution process or be empty, depending on the setup of the Archetype (see Features below).

### Features

- The `DefaultArchetypeRegistry.createArchetype` function now allows the `_formationProcess` and `_executionProcess` parameters to be empty, thus adding support for archetypes with optional business process setups. IMPORTANT: Agreements created from archetypes that do not have Formation and/or Execution processes are responsible for their legal state changes. Especially for agreements without an execution process, these agreements will no longer switch their legal state to "fulfilled" automatically!</br>
Agreements without a formation process who want to run an execution process must be fully executed (which can be achieved by all signatories calling the `sign()` function on the agreement) **before** calling `ActiveAgreementRegistry.startProcessLifecycle(ActiveAgreement)`.
- User activation via email for new user accounts has been added. A new user signing up via the API is by default "deactivated" and has to click on the activation link in an email before being able to login for the first time. This serves to validate the user's email account used for notifications, etc.


## <a name="v0.5.1">Release 0.5.1</a>

### Compatibility

This release was tested with the following software and versions:

|                    |        |
| :----------------- | :----- |
| Hyperledger Burrow | 0.23.1 |
| Solc               | 0.4.25 |

### Breaking Changes

- The `UserAccount` contract has been turned into a DelegateProxy capable of forwarding calls. No longer needed specialized contracts `WorkflowUserAccount` and `AgreementPartyAccount` have been removed.
- Several functions (`getInData...`, `setOutData...`, `completeActivityWith...`) have been moved from BpmService (and former `WorkflowUserAccount`) to the `ProcessInstance`. This greatly improves application building since it's no longer required to wire the BpmService into an application and deploy it in DOUG like a service. 
-  The function signature of the complete function of an `Application` has been changed to include the address of the `ProcessInstance`: `function complete(address _processInstance, bytes32 _activityInstanceId, bytes32 _activityId, address _txPerformer)`.
-  The use of fixed-size arrays has been replaced with dynamic arrays in contracts `DataStorage` and `Organization`.

### Features

- Removed SQLsol mechanism using a memory database (SQLite) as object cache and replaced it with a Postgres DB that is populated via Vent, a query/filter mechanism reading events directly from blocks retrieved from Burrow.
- The Blackstone Node app now provides a way to pass an existing HTTP server upon startup to which all routes and endpoints are added. This allows to use Blackstone embedded in other applications.
- The BPM model now supports process diagrams with two gateways connected directly to each other with the explicit addition of an empty activity between them.
- The JSON response of the API endpoint `GET /agreements/:address` has been enhanced to resemble more closely the data of an archetype by adding documents, parameter type, and process definitions.


### Bug Fixes

- Fixed bug in API layer where transition conditions in the BPM Model based on uint values were skewed due to passing the value to burrow.js as string.
- Fixed problem in `BpmRuntimeLib` contract regarding the treatment a process graph with a loop where an already traversed node was not reset to be used again.
- Fixed a bug in the API when parsing and deploying a process model and the placeholder `PROCESS_INSTANCE` in the model was not removed as a dataStorageId prior to setting transition conditions in the smart contracts leading transition conditions relying on the ProcessInstance's data storage to revert.
