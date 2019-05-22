const fs = require('fs');
const path = require('path');
const EventEmitter = require('events');
const util = require('util');
const boom = require('boom');

const logger = require(`${global.__common}/logger`);
const utils = require(`${global.__common}/utils`);
const burrowDB = require(`${global.__common}/burrow-db`);
const burrowApp = require(`${global.__common}/burrow-app`);
const {
  DATA_TYPES,
  ERROR_CODES: ERR,
} = global.__constants;

const NO_TRANSACTION_RESPONSE_ERR = 'No transaction response raw data received from burrow';

/**
 * This module provides the application-specific functions for Active Agreements
 */

const log = logger.getLogger('controllers.contracts');

const events = {
  NEW_MESSAGE: 'newMessage',
};

// Set up event emitter
function ChainEventEmitter() {
  EventEmitter.call(this);
}

util.inherits(ChainEventEmitter, EventEmitter);
const chainEvents = new ChainEventEmitter();

// Instantiate connection to node
const serverAccount = global.__settings.accounts.server;
const chainURL = global.__settings.chain.url || 'localhost:10997';
const db = new burrowDB.Connection(chainURL, serverAccount);

const ventHelper = require(`${global.__common}/VentHelper`)(global.db.connectionString, global.max_wait_for_vent_ms || 3000);
ventHelper.listen();

let appManager;

const boomify = (burrowError, message) => {
  const arr = burrowError.message ? burrowError.message.split('::') : [];
  if (arr.length < 3) {
    // Error is not the raw error from solidity
    return boom.badImplementation(`${message}: ${burrowError.stack}`);
  }
  const parsedError = {
    code: arr[0] || '',
    location: arr[1] || '',
    message: arr[2] || '',
  };
  let error;
  switch (parsedError.code) {
    case ERR.UNAUTHORIZED:
      error = boom.forbidden(`${message}: ${parsedError.message}. ${burrowError.stack}`);
      break;
    case ERR.RESOURCE_NOT_FOUND:
      error = boom.notFound(`${message}: ${parsedError.message}. ${burrowError.stack}`);
      break;
    case ERR.RESOURCE_ALREADY_EXISTS:
      error = boom.conflict(`${message}: ${parsedError.message}. ${burrowError.stack}`);
      break;
    case ERR.INVALID_INPUT:
    case ERR.INVALID_PARAMETER_STATE:
    case ERR.NULL_PARAMETER_NOT_ALLOWED:
    case ERR.OVERWRITE_NOT_ALLOWED:
      error = boom.badRequest(`${message}: ${parsedError.message}. ${burrowError.stack}`);
      break;
    case ERR.RUNTIME_ERROR:
    case ERR.INVALID_STATE:
    case ERR.DEPENDENCY_NOT_FOUND:
      error = boom.badImplementation(`${message}: ${parsedError.message}. ${burrowError.stack}`);
      break;
    default:
      error = boom.badImplementation(`${message}: ${burrowError ? parsedError.message : 'Unknown Error'}. ${burrowError.stack}`);
      break;
  }
  return error;
};

/**
 * Returns the JS representation of the deplopyed contract
 * @param {string} abiPath representing the location of the abi file
 * @param {*} contractName name of the contract with or without the .abi extension
 * @param {*} contractAddress address of the deployed contract
 */
const getContract = (abiPath, contractName, contractAddress) => {
  const abi = burrowApp.getAbi(abiPath, contractName);
  return db.burrow.contracts.new(abi, null, contractAddress);
};

// shortcut functions to retrieve often needed objects and services
// Note: contracts need to be loaded before invoking these functions. see load() function
const getBpmService = () => appManager.contracts['BpmService'];
const getUserAccount = userAddress => getContract(global.__abi, global.__bundles.COMMONS_AUTH.contracts.USER_ACCOUNT, userAddress);
const getOrganization = orgAddress => getContract(global.__abi, global.__bundles.PARTICIPANTS_MANAGER.contracts.ORGANIZATION, orgAddress);
const getProcessInstance = piAddress => getContract(global.__abi, global.__bundles.BPM_RUNTIME.contracts.PROCESS_INSTANCE, piAddress);
const getEcosystem = ecosystemAddress => getContract(global.__abi, global.__bundles.COMMONS_AUTH.contracts.ECOSYSTEM, ecosystemAddress);

/**
 * Returns a promise to call the forwardCall function of the given userAddress to invoke the function encoded in the given payload on the provided target address and return the result bytes representation
 * The 'payload' parameter must be the output of calling the 'encode(...)' function on a contract's function. E.g. <contract>.<function>.encode(param1, param2)
 * 'waitForVent' is a boolean parameter which indicates whether callOnBehalfOf should to wait for vent db to catch up to the block height in the forwardCall response, before resolving the promise.
 */
const callOnBehalfOf = (userAddress, targetAddress, payload, waitForVent) => new Promise((resolve, reject) => {
  const actingUser = getUserAccount(userAddress);
  log.debug('REQUEST: Call target %s on behalf of user %s with payload: %s', targetAddress, userAddress, payload);
  actingUser.forwardCall(targetAddress, payload)
    .then((data) => {
      if (!waitForVent) return new Promise(res => res(data));
      return ventHelper.waitForVent(data);
    })
    .then((data) => {
      if (!data.raw) throw boom.badImplementation(`The forwardCall function from user ${userAddress} to target ${targetAddress} returned no raw data!`);
      log.info('SUCCESS: ReturnData from target %s forwardCall on behalf of user %s: %s', targetAddress, userAddress, data.raw[0]);
      return resolve(data.raw[0]);
    })
    .catch((err) => {
      if (err.isBoom) reject(err);
      reject(boomify(err, `Unexpected error in forwardCall function on user ${userAddress} attempting to call target ${targetAddress}`));
    });
});

const createEcosystem = name => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Create new Ecosystem with name ${name}`);
  appManager.contracts['EcosystemRegistry'].factory.createEcosystem(name, (err, data) => {
    if (err || !data.raw) return reject(boomify(err, `Failed to create Ecosystem ${name}: ${err.stack}`));
    log.info(`SUCCESS: Created Ecosystem ${name} at ${data.raw[0]}`);
    return resolve(data.raw[0]);
  });
});

const addExternalAddressToEcosystem = (externalAddress, ecosystemAddress) => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Add external address ${externalAddress} to Ecosystem at ${ecosystemAddress}`);
  const ecosystem = getContract(global.__abi, global.__bundles.COMMONS_AUTH.contracts.ECOSYSTEM, ecosystemAddress);
  ecosystem.addExternalAddress(externalAddress, (err) => {
    if (err) return reject(boom.badImplementation(`Failed to add external address ${externalAddress} to ecosystem at ${ecosystemAddress}: ${err.stack}`));
    log.info(`SUCCESS: Added external address ${externalAddress} to ecosystem at ${ecosystemAddress}`);
    return resolve();
  });
});

const setToNameRegistry = (name, value, lease) => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Set to name registry: ${JSON.stringify({ name, value, lease })}`);
  db.burrow.namereg.set(name, value, lease, (err) => {
    if (err) {
      return reject(boom.badImplementation(`Error setting ${JSON.stringify({ name, value, lease })} to namereg: ${err.stack}`));
    }
    log.info(`SUCCESS: Set name-value pair ${name}:${value} to namereg`);
    return resolve();
  });
});

const getFromNameRegistry = name => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Get from name registry: ${name}`);
  db.burrow.namereg.get(name, (err, result) => {
    if (err && err.code !== 2) { // 2 UNKNOWN = entry does not exist
      return reject(boom.badImplementation(`Error getting entry for <${name}> from namereg: ${err.stack}`));
    }
    log.info(`SUCCESS: Retrieved name-value pair ${name}:${JSON.stringify(result)} from namereg`);
    return resolve((result && result.Data) ? result.Data : undefined);
  });
});

const registerEcosystem = ecosystemName => new Promise(async (resolve, reject) => {
  try {
    const address = await createEcosystem(ecosystemName);
    log.debug(`REQUEST: Add external address ${db.burrow.account} to ecosystem ${ecosystemName} at address ${address}`);
    await addExternalAddressToEcosystem(db.burrow.account, address);
    await setToNameRegistry(ecosystemName, address, 0);
    log.info(`SUCCESS: Added external address ${db.burrow.account} to ecosystem ${ecosystemName} at address ${address}`);
    return resolve(address);
  } catch (err) {
    return reject(new Error(`Failed to register ecosystem [ ${ecosystemName}]: ${err.stack}`));
  }
});

/**
 * Uses the configuration 'contracts.load' in the settings to create a number of promises, each loading one of the configured contracts from
 * the DOUG contract and populating the contracts[] in the appManager.
 */
const load = () => new Promise((resolve, reject) => {
  // Get DOUG address first
  db.burrow.namereg.get('DOUG', (error, DOUG) => {
    if (error) return reject(error);
    log.info(`Creating AppManager with DOUG at address: ${DOUG}`);
    appManager = new burrowApp.Manager(db, DOUG.Data);
    return resolve(DOUG);
  });
}).then(() => {
  // Then load the modules
  let modules = [];
  // load registered modules from settings
  if (global.__settings.contracts && global.__settings.contracts.load) {
    modules = utils.getArrayFromString(global.__settings.contracts.load);
    log.info(`Detected ${modules.length} contract modules to be loaded from DOUG: ${modules}`);
  }
  // create promises to load the contracts
  const loadPromises = [];
  modules.forEach(m => loadPromises.push(appManager.loadContract(m)));
  return Promise.all(loadPromises);
}).then(() => new Promise(async (resolve, reject) => {
  // Lastly, ensure Ecosystem setup
  // Resolve the Ecosystem address for this ContractsManager
  if (global.__settings.identity_provider) {
    const ecosystemName = global.__settings.identity_provider;
    log.info(`Validating if Ecosystem ${ecosystemName} is in NameReg`);
    try {
      appManager.ecosystemAddress = await getFromNameRegistry(ecosystemName);
      if (!appManager.ecosystemAddress) {
        appManager.ecosystemAddress = await registerEcosystem(ecosystemName);
        // This should not happen, but just in case, double-check the AppManager.ecosystemAddress
        if (!appManager.ecosystemAddress) {
          return reject(boom.badImplementation('Failed to configure the AppManager with an ecosystem address'));
        }
        log.info(`AppManager configured for Ecosystem ${ecosystemName} at address ${appManager.ecosystemAddress}`);
        return resolve();
      }
      return resolve();
    } catch (err) {
      return reject(err);
    }
  }
  return reject(boom.badImplementation('No Ecosystem name set. Unable to start API ...'));
}));

/**
 * Creates a promise to create a new organization and add to Accounts Manager.
 * @param organization
 */
const createOrganization = org => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Create organization with: ${JSON.stringify(org)}`);
  appManager.contracts['ParticipantsManager']
    .factory.createOrganization(org.approvers ? org.approvers : [], org.defaultDepartmentId)
    .then(data => ventHelper.waitForVent(data))
    .then((data) => {
      if (!data.raw) throw boom.badImplementation(NO_TRANSACTION_RESPONSE_ERR);
      if (parseInt(data.raw[0], 10) === 1002) throw boom.badRequest('Organization id must be unique');
      if (parseInt(data.raw[0], 10) !== 1) throw boom.badImplementation(`Error code creating new organization: ${data.raw[0]}`);
      log.info(`SUCCESS: Created new organization at address ${data.raw[1]}, with approvers ${org.approvers}`);
      return resolve(data.raw[1]);
    })
    .catch((error) => {
      if (error.isBoom) return reject(error);
      return reject(boom.badImplementation(`Failed to create organization: ${error.stack}`));
    });
});

const createArchetype = (type) => {
  const archetype = type;
  archetype.isPrivate = archetype.isPrivate || false;
  archetype.price = Math.floor(archetype.price * 100); // monetary unit conversion to cents which is the recorded unit on chain
  return new Promise((resolve, reject) => {
    log.debug(`REQEUST: Create archetype with: ${JSON.stringify(archetype)}`);
    appManager.contracts['ArchetypeRegistry']
      .factory.createArchetype(
        archetype.price,
        archetype.isPrivate,
        archetype.active,
        archetype.author,
        archetype.owner,
        archetype.formationProcessDefinition,
        archetype.executionProcessDefinition,
        archetype.packageId,
        archetype.governingArchetypes,
      )
      .then(data => ventHelper.waitForVent(data))
      .then((data) => {
        if (!data.raw) throw boom.badImplementation(NO_TRANSACTION_RESPONSE_ERR);
        log.info(`SUCCESS: Created new archetype by author ${archetype.author} at address ${data.raw[0]}`);
        return resolve(data.raw[0]);
      })
      .catch((err) => {
        if (err.isBoom) return reject(err);
        return reject(boomify(err, `Failed to create archetype ${archetype.name}`));
      });
  });
};

const isActiveArchetype = (archetypeAddress) => {
  log.debug(`REQUEST: Determine if archetype at ${archetypeAddress} is active`);
  const archetype = getContract(global.__abi, global.__bundles.AGREEMENTS.contracts.ARCHETYPE, archetypeAddress);
  return new Promise((resolve, reject) => {
    archetype.isActive((err, data) => {
      if (err || !data.raw) {
        return reject(boom.badImplementation(`Failed to determine if archetype at ${archetypeAddress} is active: ${err}`));
      }
      log.info(`SUCCESS: Archetype at ${archetypeAddress} has been found to be ${data.raw[0] ? 'active' : 'inactive'}`);
      return resolve(data.raw[0]);
    });
  });
};

const getArchetypeAuthor = (archetypeAddress) => {
  log.debug(`REQEUST: Get archetype author for archetype at ${archetypeAddress}`);
  const archetype = getContract(global.__abi, global.__bundles.AGREEMENTS.contracts.ARCHETYPE, archetypeAddress);
  return new Promise((resolve, reject) => {
    archetype.getAuthor((err, data) => {
      if (err || !data.raw) {
        return reject(boom.badImplementation(`Failed to get author of archetype at ${archetypeAddress}: ${err}`));
      }
      log.info(`SUCCESS: Retrieved archetype author for archetype at ${archetypeAddress}: ${data.raw[0]}`);
      return resolve(data.raw[0]);
    });
  });
};

const activateArchetype = (archetypeAddress, userAccount) => {
  log.debug(`REQUEST: Activate archetype at ${archetypeAddress} by user at ${userAccount}`);
  return new Promise((resolve, reject) => {
    appManager.contracts['ArchetypeRegistry'].factory.activate(archetypeAddress, userAccount, (err) => {
      if (err) return reject(boomify(err, `Failed to activate archetype at ${archetypeAddress} by user ${userAccount}`));
      log.info(`SUCCESS: Archetype at ${archetypeAddress} activated by user at ${userAccount}`);
      return resolve();
    });
  });
};

const deactivateArchetype = (archetypeAddress, userAccount) => {
  log.debug(`REQUEST: Deactivate archetype at ${archetypeAddress} by user at ${userAccount}`);
  return new Promise((resolve, reject) => {
    appManager.contracts['ArchetypeRegistry'].factory.deactivate(archetypeAddress, userAccount, (err) => {
      if (err) return reject(boomify(err, `Failed to activate archetype at ${archetypeAddress} by user ${userAccount}`));
      log.info(`SUCCESS: Archetype at ${archetypeAddress} deactivated by user at ${userAccount}`);
      return resolve();
    });
  });
};

const setArchetypeSuccessor = (archetypeAddress, successorAddress, userAccount) => {
  log.debug(`REQUEST: Set successor to ${successorAddress} for archetype at ${archetypeAddress} by user at ${userAccount}`);
  return new Promise((resolve, reject) => {
    appManager.contracts['ArchetypeRegistry'].factory.setArchetypeSuccessor(archetypeAddress, successorAddress, userAccount, (err) => {
      if (err) return reject(boomify(err, `Failed to set successor to ${successorAddress} for archetype at ${archetypeAddress} by user at ${userAccount}`));
      log.info(`SUCCESS: Successfully set successor to ${successorAddress} for archetype at ${archetypeAddress} by user at ${userAccount}`);
      return resolve();
    });
  });
};

const getArchetypeSuccessor = (archetypeAddress) => {
  log.debug(`REQUEST: Get successor for archetype at ${archetypeAddress}`);
  return new Promise((resolve, reject) => {
    appManager.contracts['ArchetypeRegistry'].factory.getArchetypeSuccessor(archetypeAddress, (err, data) => {
      if (err) return reject(boomify(err, `Failed to get successor for archetype at ${archetypeAddress}`));
      log.info(`SUCCESS: Retrieved successor for archetype at ${archetypeAddress}`);
      return resolve(data.raw[0]);
    });
  });
};

// TODO configuration currently not supported until new specification is clear, i.e. which fields will be included in the configuration
// const configureArchetype = (address, config) => {
//   return new Promise(function (resolve, reject) {
//     log.debug(`Configuring archetype at address ${address} with: ${JSON.stringify(config)}`);
//     appManager.contracts['ArchetypeRegistry'].factory.configure(
//       address,
//       config.numberOfParticipants,
//       config.termination,
//       config.fulfillment,
//       config.amount,
//       config.currency,
//       (error, data) => {
//         if (error) {
//           return reject(boom.badImplementation(
//             `Failed to configure archetype at ${address}: ${error}`));
//         }
//         if (data.raw[0] != 1) {
//           return reject(boom.badImplementation(
//             'Error code configuring archetype ' + address + ': ' + data.raw[0]));
//         }
//         return resolve();
//       });
//   });
// };

const addArchetypeParameters = (address, parameters) => new Promise((resolve, reject) => {
  const paramTypes = [];
  const paramNames = [];
  for (let i = 0; i < parameters.length; i += 1) {
    paramTypes[i] = parseInt(parameters[i].type, 10);
    paramNames[i] = global.stringToHex(parameters[i].name);
  }
  log.debug(`REQUEST: Add archetype parameters to archetype at address ${address}. ` +
    `Parameter Types: ${JSON.stringify(paramTypes)}, Parameter Names: ${JSON.stringify(paramNames)}`);
  appManager
    .contracts['ArchetypeRegistry']
    .factory.addParameters(address, paramTypes, paramNames, (error, data) => {
      if (error || !data.raw) {
        return reject(boom.badImplementation(`Failed to add parameters to archetype at ${address}: ${error}`));
      }
      if (parseInt(data.raw[0], 10) !== 1) {
        return reject(boom.badImplementation(`Error code adding parameter to archetype at ${address}: ${data.raw[0]}`));
      }
      log.info(`SUCCESS: Added parameters ${paramNames} to archetype at ${address}`);
      return resolve();
    });
});

const addArchetypeDocument = (address, fileReference) => new Promise((resolve, reject) => {
  log.debug('REQUEST: Add document to archetype at %s', address);
  appManager
    .contracts['ArchetypeRegistry']
    .factory.addDocument(address, fileReference, (error, data) => {
      if (error) {
        return reject(boomify(error, `Failed to add document to archetype ${address}`));
      }
      log.info('SUCCESS: Added document to archetype at %s', address);
      return resolve();
    });
});

const addArchetypeDocuments = async (archetypeAddress, documents) => {
  const names = documents.map(doc => doc.name).join(', ');
  log.debug(`REQUEST: Add archetype documents to archetype at ${archetypeAddress}: ${names}`);
  const resolvedDocs = await Promise.all(documents.map(async ({ grant }) => {
    const result = await addArchetypeDocument(archetypeAddress, grant);
    return result;
  }));
  log.info(`SUCCESS: Added documents to archetype at ${archetypeAddress}: ${names}`);
  return resolvedDocs;
};

const setArchetypePrice = (address, price) => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Set price to ${price} for archetype at ${address}`);
  const priceInCents = Math.floor(price * 100); // monetary unit conversion to cents which is the recorded unit on chain
  appManager.contracts['ArchetypeRegistry'].factory.setArchetypePrice(address, priceInCents, (err) => {
    if (err) return reject(boom.badImplementation(`Failed to set price to ${price} for archetype at ${address}`));
    log.info(`SUCCESS: Set price to ${price} for archetype at ${address}`);
    return resolve();
  });
});

const createArchetypePackage = (author, isPrivate, active) => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Create a ${(isPrivate ? 'private' : 'public')}, ${(active ? 'active' : 'inactive')} archetype package ` +
    `by user at ${author}`);
  appManager
    .contracts['ArchetypeRegistry']
    .factory.createArchetypePackage(author, isPrivate, active)
    .then(data => ventHelper.waitForVent(data))
    .then((data) => {
      if (!data.raw) throw boom.badImplementation(NO_TRANSACTION_RESPONSE_ERR);
      if (parseInt(data.raw[0], 10) !== 1) throw boom.badImplementation(`Error code adding archetype package by user ${author}: ${data.raw[0]}`);
      log.info(`SUCCESS: Created new archetype package by author ${author} with id ${data.raw[1]}`);
      return resolve(data.raw[1]);
    })
    .catch((err) => {
      if (err.isBoom) return reject(err);
      return reject(boom.badImplementation(`Failed to add archetype package by user ${author}: ${err.stack}`));
    });
});

const activateArchetypePackage = (packageId, userAccount) => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Activate archetype package with id ${packageId} by user at ${userAccount}`);
  appManager.contracts['ArchetypeRegistry'].factory.activatePackage(packageId, userAccount, (err) => {
    if (err) {
      return reject(boomify(err, `Failed to activate archetype package with id ${packageId} by user ${userAccount}`));
    }
    log.info(`SUCCESS: Archetype package with id ${packageId} activated by user at ${userAccount}`);
    return resolve();
  });
});

const deactivateArchetypePackage = (packageId, userAccount) => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Deactivate archetype package with id ${packageId} by user at ${userAccount}`);
  appManager
    .contracts['ArchetypeRegistry'].factory.deactivatePackage(packageId, userAccount, (err) => {
      if (err) {
        return reject(boomify(err, `Failed to deactivate archetype package with id ${packageId} by user ${userAccount}`));
      }
      log.info(`SUCCESS: Archetype package with id ${packageId} deactivated by user at ${userAccount}`);
      return resolve();
    });
});

const addArchetypeToPackage = (packageId, archetype) => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Add archetype at ${archetype} to package ${packageId}`);
  appManager
    .contracts['ArchetypeRegistry']
    .factory.addArchetypeToPackage(packageId, archetype, (err) => {
      if (err) {
        return reject(boomify(err, `Failed to add archetype at ${archetype} to package ${packageId}`));
      }
      log.info(`SUCCESS: Added archetype at ${archetype} to package with id ${packageId}`);
      return resolve();
    });
});

const addJurisdictions = (address, jurisdictions) => new Promise((resolve, reject) => {
  const countries = [];
  const regions = [];
  jurisdictions.forEach((item) => {
    if (item.regions.length > 0) {
      item.regions.forEach((region) => {
        countries.push(global.stringToHex(item.country));
        regions.push(region);
      });
    } else {
      countries.push(global.stringToHex(item.country));
      regions.push('');
    }
  });
  log.debug(`REQUEST: Add jurisdictions to archetype at ${address}. ` +
    `Countries: ${JSON.stringify(countries)}, Regions: ${JSON.stringify(regions)}`);
  appManager.contracts['ArchetypeRegistry'].factory.addJurisdictions(
    address,
    countries,
    regions,
    (error, data) => {
      if (error || !data.raw) {
        return reject(boom.badImplementation(`Failed to add juridictions to archetype at ${address}: ${error}`));
      }
      if (parseInt(data.raw[0], 10) !== 1) {
        return reject(boom.badImplementation(`Error code adding jurisdictions to archetype at ${address}: ${data.raw[0]}`));
      }
      log.info(`SUCCESS: Added jurisdictions to archetype at ${address}`);
      return resolve();
    },
  );
});

const createAgreement = agreement => new Promise((resolve, reject) => {
  const {
    archetype,
    creator,
    owner,
    privateParametersFileReference,
    parties,
    collectionId,
    governingAgreements,
  } = agreement;
  const isPrivate = agreement.isPrivate || false;
  log.debug(`REQUEST: Create agreement with following data: ${JSON.stringify(agreement)}`);
  appManager
    .contracts['ActiveAgreementRegistry']
    .factory.createAgreement(archetype, creator, owner, privateParametersFileReference, isPrivate,
      parties, collectionId, governingAgreements, (error, data) => {
        if (error || !data.raw) {
          return reject(boomify(error, `Failed to create agreement by ${creator} from archetype at ${agreement.archetype}`));
        }
        log.info(`SUCCESS: Created agreement by ${creator} at address ${data.raw[0]}`);
        return resolve(data.raw[0]);
      });
});

const initializeObjectAdministrator = agreementAddress => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Initializing agreement admin role for agreement: ${agreementAddress}`);
  const agreement = getContract(global.__abi, global.__bundles.AGREEMENTS.contracts.ACTIVE_AGREEMENT, agreementAddress);
  agreement.initializeObjectAdministrator(serverAccount, (error) => {
    if (error) {
      return reject(boomify(error, `Failed to initialize object admin for agreement ${agreementAddress}`));
    }
    log.info(`SUCCESS: Initialized agreement admin role for agreement ${agreementAddress}`);
    return resolve();
  });
});

const setMaxNumberOfAttachments = (agreementAddress, maxNumberOfAttachments) => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Set max number of events to ${maxNumberOfAttachments} for agreement at ${agreementAddress}`);
  appManager
    .contracts['ActiveAgreementRegistry']
    .factory.setMaxNumberOfEvents(agreementAddress, maxNumberOfAttachments, (error) => {
      if (error) {
        return reject(boom.badImplementation(`Failed to set max number of events to ${maxNumberOfAttachments} for agreement at ${agreementAddress}: ${error}`));
      }
      log.info(`SUCCESS: Set max number of events to ${maxNumberOfAttachments} for agreement at ${agreementAddress}`);
      return resolve();
    });
});

const setAddressScopeForAgreementParameters = async (agreementAddr, parameters) => {
  log.debug(`REQUEST: Add scopes to agreement ${agreementAddr} parameters: ${JSON.stringify(parameters)}`);
  const agreement = getContract(global.__abi, global.__bundles.AGREEMENTS.contracts.ACTIVE_AGREEMENT, agreementAddr);
  const promises = parameters.map(({ name, value, scope }) => new Promise((resolve, reject) => {
    agreement.setAddressScope(value, global.stringToHex(name), scope, '', '', '0x0', (error) => {
      if (error) {
        return reject(boomify(error, `Failed to add scope ${scope} to address ${value} in context ${name}`));
      }
      return resolve();
    });
  }));
  try {
    await Promise.all(promises);
    log.info(`SUCCESS: Added scopes to agreement ${agreementAddr} parameters`);
  } catch (err) {
    if (boom.isBoom(err)) throw err;
    throw boom.badImplementation(err);
  }
};

const updateAgreementFileReference = (fileKey, agreementAddress, hoardGrant) => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Update reference for  ${fileKey} for agreement at ${agreementAddress} with new reference ${hoardGrant}`);
  const handleResult = (error) => {
    if (error) {
      return reject(boom.badImplementation(`Failed to set new reference ${hoardGrant} for ${fileKey} for agreement at ${agreementAddress}: ${error}`));
    }
    log.info(`SUCCESS: File reference for ${fileKey} updated for agreement at ${agreementAddress}`);
    return resolve();
  };
  if (fileKey === 'EventLog') return appManager.contracts['ActiveAgreementRegistry'].factory.setEventLogReference(agreementAddress, hoardGrant, handleResult);
  if (fileKey === 'SignatureLog') return appManager.contracts['ActiveAgreementRegistry'].factory.setSignatureLogReference(agreementAddress, hoardGrant, handleResult);
  return reject(boom.badImplementation(`Did not recognize agreement file key: ${fileKey}`));
});

const createAgreementCollection = (author, collectionType, packageId) => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Create agreement collection by ${author} with type ${collectionType} ` +
    `and packageId ${packageId} created by user at ${author}`);
  appManager
    .contracts['ActiveAgreementRegistry']
    .factory.createAgreementCollection(author, collectionType, packageId, (error, data) => {
      if (error || !data.raw) {
        return reject(boom.badImplementation(`Failed to add agreement collection by ${author}: ${error}`));
      }
      if (parseInt(data.raw[0], 10) !== 1) {
        return reject(boom.badImplementation(`Error code adding agreement collection by ${author}: ${data.raw[0]}`));
      }
      log.info(`SUCCESS: Created new agreement collection by ${author} with id ${data.raw[1]}`);
      return resolve(data.raw[1]);
    });
});

const addAgreementToCollection = (collectionId, agreement) => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Add agreement at ${agreement} to collection ${collectionId}`);
  appManager
    .contracts['ActiveAgreementRegistry']
    .factory.addAgreementToCollection(collectionId, agreement, (error) => {
      if (error) {
        return reject(boomify(error, `Failed to add agreement at ${agreement} to collection ${collectionId}`));
      }
      log.info(`SUCCESS: Added agreement at ${agreement} to collection with id ${collectionId}`);
      return resolve();
    });
});

const createUserInEcosystem = (user, ecosystemAddress) => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Create a new user with ID: ${user.username} in ecosystem at ${ecosystemAddress}`);
  appManager
    .contracts['ParticipantsManager']
    .factory.createUserAccount(user.username, '0x0', ecosystemAddress)
    .then(data => ventHelper.waitForVent(data))
    .then((data) => {
      if (!data || !data.raw) throw new Error(NO_TRANSACTION_RESPONSE_ERR);
      log.info(`SUCCESS: Created new user ${user.username} at address ${data.raw[0]}`);
      return resolve(data.raw[0]);
    })
    .catch(error => reject(boom.badImplementation(`Failed to create user ${user.username}: ${error}`)));
});

const createUser = user => createUserInEcosystem(user, appManager.ecosystemAddress);

const getUserByUsernameAndEcosystem = (username, ecosystemAddress) => new Promise((resolve, reject) => {
  log.trace(`REQUEST: Get user by username: ${username} in ecosystem at ${ecosystemAddress}`);
  const ecosystem = getEcosystem(ecosystemAddress);
  ecosystem
    .getUserAccount(username)
    .then((data) => {
      if (!data.raw) throw boom.badImplementation(`Failed to get address for user with username ${username}`);
      log.trace(`SUCCESS: Retrieved user address ${data.raw[0]} by username ${username} and ecosystem ${ecosystemAddress}`);
      return resolve({
        address: data.raw[0],
      });
    })
    .catch((err) => {
      if (err.isBoom) return reject(err);
      return reject(boomify(err, `Failed to get address for user with username ${username}`));
    });
});

const getUserByUsername = username => getUserByUsernameAndEcosystem(username, appManager.ecosystemAddress);

const addUserToEcosystem = (username, address) => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Add user ${username} with address ${address} to ecosystem at ${appManager.ecosystemAddress}`);
  const ecosystem = getEcosystem(appManager.ecosystemAddress);
  ecosystem
    .addUserAccount(username, address)
    .then(() => {
      log.info(`SUCCESS: Successfully added user ${username} with address ${address} to ecosystem at ${appManager.ecosystemAddress}`);
      resolve();
    })
    .catch(err => reject(boomify(err, `Failed to add user with username ${username} and address ${address} to ecosystem`)));
});

const addUserToOrganization = (userAddress, organizationAddress, actingUserAddress) => new Promise((resolve, reject) => {
  log.debug('REQUEST: Add user %s to organization %s', userAddress, organizationAddress);
  const organization = getOrganization(organizationAddress);
  const payload = organization.addUser.encode(userAddress);
  callOnBehalfOf(actingUserAddress, organizationAddress, payload, true)
    .then((returnData) => {
      const data = organization.addUser.decode(returnData);
      if (data.raw[0].valueOf() === true) {
        log.info('SUCCESS: User %s successfully added to organization %s', userAddress, organizationAddress);
        return resolve();
      }
      return reject(boom.badImplementation(`Failed to add user ${userAddress} to organization ${organizationAddress}!: ${returnData}`));
    })
    .catch(error => reject(boom.badImplementation(`Error forwarding addUser request via acting user ${actingUserAddress} to organization ${organizationAddress}! Error: ${error}`)));
});

const removeUserFromOrganization = (userAddress, organizationAddress, actingUserAddress) => new Promise((resolve, reject) => {
  log.debug('REQUEST: Remove user %s from organization %s', userAddress, organizationAddress);
  const organization = getOrganization(organizationAddress);
  const payload = organization.removeUser.encode(userAddress);
  callOnBehalfOf(actingUserAddress, organizationAddress, payload, true)
    .then((returnData) => {
      const data = organization.removeUser.decode(returnData);
      if (data.raw[0].valueOf() === true) {
        log.info('SUCCESS: User %s successfully removed from organization %s', userAddress, organizationAddress);
        return resolve();
      }
      return reject(boom.badImplementation(`Failed to remove user ${userAddress} from organization ${organizationAddress}!: ${returnData}`));
    })
    .catch(error => reject(boom.badImplementation(`Error forwarding removeUser request via acting user ${actingUserAddress} to organization ${organizationAddress}! Error: ${error}`)));
});

const addApproverToOrganization = (approverAddress, organizationAddress, actingUserAddress) => new Promise((resolve, reject) => {
  log.debug('REQUEST: Add approver %s to organization %s', approverAddress, organizationAddress);
  const organization = getOrganization(organizationAddress);
  const payload = organization.addApprover.encode(approverAddress);
  callOnBehalfOf(actingUserAddress, organizationAddress, payload, true)
    .then(() => {
      log.info('SUCCESS: Approver %s successfully added to organization %s', approverAddress, organizationAddress);
      return resolve();
    })
    .catch((error) => {
      if (error.isBoom) return reject(error);
      return reject(boom.badImplementation(`Error forwarding addApprover request via acting approver ${actingUserAddress} to organization ${organizationAddress}! Error: ${error.stack}`));
    });
});

const removeApproverFromOrganization = (approverAddress, organizationAddress, actingUserAddress) => new Promise((resolve, reject) => {
  log.debug('REQUEST: Remove approver %s from organization %s', approverAddress, organizationAddress);
  const organization = getOrganization(organizationAddress);
  const payload = organization.removeApprover.encode(approverAddress);
  callOnBehalfOf(actingUserAddress, organizationAddress, payload, true)
    .then(() => {
      log.info('SUCCESS: Approver %s successfully removed from organization %s', approverAddress, organizationAddress);
      return resolve();
    })
    .catch((error) => {
      if (error.isBoom) return reject(error);
      return reject(boom.badImplementation(`Error forwarding removeApprover request via acting approver ${actingUserAddress} to organization ${organizationAddress}! Error: ${error.stack}`));
    });
});

const createDepartment = (organizationAddress, id, actingUserAddress) => new Promise((resolve, reject) => {
  log.debug('REQUEST: Create department ID %s with name %s in organization %s', id, organizationAddress);
  const organization = getOrganization(organizationAddress);
  const payload = organization.addDepartment.encode(id);
  callOnBehalfOf(actingUserAddress, organizationAddress, payload, true)
    .then((returnData) => {
      const data = organization.addDepartment.decode(returnData);
      if (data.raw[0].valueOf() === true) {
        log.info('SUCCESS: Department ID %s successfully created in organization %s', id, organizationAddress);
        return resolve();
      }
      return reject(boom.badImplementation(`Failed to create department ID ${id} in organization ${organizationAddress}!: ${returnData}`));
    })
    .catch(error => reject(boom.badImplementation(`Error forwarding createDepartment request via acting user ${actingUserAddress} to organization ${organizationAddress}! Error: ${error}`)));
});

const removeDepartment = (organizationAddress, id, actingUserAddress) => new Promise((resolve, reject) => {
  log.debug('REQUEST: Remove department %s from organization %s', id, organizationAddress);
  const organization = getOrganization(organizationAddress);
  const payload = organization.removeDepartment.encode(id);
  callOnBehalfOf(actingUserAddress, organizationAddress, payload, true)
    .then((returnData) => {
      const data = organization.removeDepartment.decode(returnData);
      if (data.raw[0].valueOf() === true) {
        log.info('SUCCESS: Department ID %s successfully removed from organization %s', id, organizationAddress);
        return resolve();
      }
      return reject(boom.badImplementation(`Failed to remove department ID ${id} in organization ${organizationAddress}!: ${returnData}`));
    })
    .catch(error => reject(boom.badImplementation(`Error forwarding removeDepartment request via acting user ${actingUserAddress} to organization ${organizationAddress}! Error: ${error}`)));
});

const addDepartmentUser = (organizationAddress, depId, userAddress, actingUserAddress) => new Promise((resolve, reject) => {
  log.debug('REQUEST: Add user %s to department ID in organization %s', userAddress, depId, organizationAddress);
  const organization = getOrganization(organizationAddress);
  const payload = organization.addUserToDepartment.encode(userAddress, depId);
  callOnBehalfOf(actingUserAddress, organizationAddress, payload, true)
    .then((returnData) => {
      const data = organization.addUserToDepartment.decode(returnData);
      if (data.raw[0].valueOf() === true) {
        log.info('SUCCESS: User %s successfully added to department ID %s in organization %s', userAddress, depId, organizationAddress);
        return resolve();
      }
      return reject(boom.badImplementation(`Failed to add user ${userAddress} to department ID ${depId} in organization ${organizationAddress}!: ${returnData}`));
    })
    .catch(error => reject(boom.badImplementation(`Error forwarding addDepartmentUser request via acting user ${actingUserAddress} to organization ${organizationAddress}! Error: ${error}`)));
});

const removeDepartmentUser = (organizationAddress, depId, userAddress, actingUserAddress) => new Promise((resolve, reject) => {
  log.debug('REQUEST: Remove user %s from department ID %s in organization %s', userAddress, depId, organizationAddress);
  const organization = getOrganization(organizationAddress);
  const payload = organization.removeUserFromDepartment.encode(userAddress, depId);
  callOnBehalfOf(actingUserAddress, organizationAddress, payload, true)
    .then((returnData) => {
      const data = organization.removeUserFromDepartment.decode(returnData);
      if (data.raw[0].valueOf() === true) {
        log.info('SUCCESS: User %s successfully removed from department ID %s in organization %s', userAddress, depId, organizationAddress);
        return resolve();
      }
      return reject(boom.badImplementation(`Failed to remove user ${userAddress} from department ID ${depId} in organization ${organizationAddress}!: ${returnData}`));
    })
    .catch(error => reject(boom.badImplementation(`Error forwarding removeDepartmentUser request via acting user ${actingUserAddress} to organization ${organizationAddress}! Error: ${error}`)));
});

const createProcessModel = (modelId, modelVersion, author, isPrivate, modelFileReference) => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Create process model with following data: ${JSON.stringify({
    modelId,
    modelVersion,
    author,
    isPrivate,
    modelFileReference,
  })}`);
  const modelIdHex = global.stringToHex(modelId);
  appManager
    .contracts['ProcessModelRepository']
    .factory.createProcessModel(modelIdHex, modelVersion, author, isPrivate, modelFileReference)
    .then((data) => {
      log.info(`SUCCESS: Model with Id ${modelId} created at ${data.raw[1]}`);
      return resolve(data.raw[1]);
    })
    .catch((err) => {
      reject(boomify(err, `Failed to create process model with id ${modelId}: ${JSON.stringify(err)}`));
    });
});

const addDataDefinitionToModel = (pmAddress, dataStoreField) => new Promise((resolve, reject) => {
  const processModel = getContract(global.__abi, global.__bundles.BPM_MODEL.contracts.PROCESS_MODEL, pmAddress);
  log.debug('REQUEST: Add data definition %s to process model %s', JSON.stringify(dataStoreField), pmAddress);
  const dataIdHex = global.stringToHex(dataStoreField.dataStorageId);
  const dataPathHex = global.stringToHex(dataStoreField.dataPath);
  processModel.addDataDefinition(dataIdHex, dataPathHex, dataStoreField.parameterType, (err) => {
    if (err) {
      return reject(boom
        .badImplementation(`Failed to add data definition for dataId: ${dataStoreField.dataStorageId}, dataPath: ${dataStoreField.dataPath}, parameterType: ${dataStoreField.parameterType}: ${err}`));
    }
    log.info('SUCCESS: Data definition %s added to Process Model at %s', JSON.stringify(dataStoreField), pmAddress);
    return resolve(dataStoreField);
  });
});

const addProcessInterface = (pmAddress, interfaceId) => new Promise((resolve, reject) => {
  const processModel = getContract(global.__abi, global.__bundles.BPM_MODEL.contracts.PROCESS_MODEL, pmAddress);
  log.debug(`REQUEST: Add process interface ${interfaceId} to process model at ${pmAddress}`);
  const interfaceIdHex = global.stringToHex(interfaceId);
  processModel.addProcessInterface(interfaceIdHex, (err, data) => {
    if (err || !data.raw) {
      return reject(boom
        .badImplementation(`Failed to add process interface ${interfaceId}to model at ${pmAddress}: ${err}`));
    }
    if (parseInt(data.raw[0], 10) === 1002) {
      // interfaceId already registered to model
      return resolve();
    }
    if (parseInt(data.raw[0], 10) !== 1) {
      return reject(boom
        .badImplementation(`Error code while adding process interface ${interfaceId} to model at ${pmAddress}: ${data.raw[0]}`));
    }
    log.info(`SUCCESS: Interface ${interfaceId} added to Process Model at ${pmAddress}`);
    return resolve();
  });
});

const addParticipant = (pmAddress, participantId, accountAddress, dataPath, dataStorageId, dataStorageAddress) => new Promise((resolve, reject) => {
  const processModel = getContract(global.__abi, global.__bundles.BPM_MODEL.contracts.PROCESS_MODEL, pmAddress);
  log.debug(`REQUEST: Add participant ${participantId} to process model at ${pmAddress} with data: ${JSON.stringify({
    accountAddress,
    dataPath,
    dataStorageId,
    dataStorageAddress,
  })}`);
  const participantIdHex = global.stringToHex(participantId);
  const dataPathHex = global.stringToHex(dataPath);
  const dataStorageIdHex = global.stringToHex(dataStorageId);
  log.debug(`Adding a participant with ID: ${participantId}`);
  processModel.addParticipant(participantIdHex, accountAddress, dataPathHex,
    dataStorageIdHex, dataStorageAddress, (err, data) => {
      if (err || !data.raw) {
        return reject(boom
          .badImplementation(`Failed to add participant ${participantId} to model ${pmAddress}: ${err}`));
      }
      if (parseInt(data.raw[0], 10) !== 1) {
        return reject(boom
          .badImplementation(`Error code while adding participant ${participantId} to model ${pmAddress}: ${data.raw[0]}`));
      }
      log.info(`SUCCESS: Participant ${participantId} added to model ${pmAddress}`);
      return resolve();
    });
});

const createProcessDefinition = (modelAddress, processDefnId) => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Create process definition with Id ${processDefnId} for process model ${modelAddress}`);
  const processDefnIdHex = global.stringToHex(processDefnId);
  appManager
    .contracts['ProcessModelRepository']
    .factory.createProcessDefinition(modelAddress, processDefnIdHex, (error, data) => {
      if (error || !data.raw) {
        return reject(boom
          .badImplementation(`Failed to create process definition ${processDefnId} in model at ${modelAddress}: ${error}`));
      }
      log.info(`SUCCESS: Process definition ${processDefnId} in model at ${modelAddress} created at ${data.raw[0]}`);
      return resolve(data.raw[0]);
    });
});

const addProcessInterfaceImplementation = (pmAddress, pdAddress, interfaceId) => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Add process interface implementation ${interfaceId} to process definition ${pdAddress} for process model ${pmAddress}`);
  const processDefinition = getContract(global.__abi, global.__bundles.BPM_MODEL.contracts.PROCESS_DEFINITION, pdAddress);
  const interfaceIdHex = global.stringToHex(interfaceId);
  processDefinition.addProcessInterfaceImplementation(pmAddress, interfaceIdHex, (err, data) => {
    if (err || !data.raw) {
      return reject(boom
        .badImplementation(`Failed to add interface implementation ${interfaceId} to process at ${pdAddress}: ${err}`));
    }
    if (parseInt(data.raw[0], 10) === 1001) {
      return reject(boom
        .badData(`InterfaceId ${interfaceId} for process at ${pdAddress} is not registered to the model at ${pmAddress}`));
    }
    if (parseInt(data.raw[0], 10) !== 1) {
      return reject(boom
        .badImplementation(`Error code while adding process interface implementation ${interfaceId} to process at ${pdAddress}: ${data.raw[0]}`));
    }
    log.info(`SUCCESS: Interface implementation ${interfaceId} added to Process Definition at ${pdAddress}`);
    return resolve();
  });
});

const createActivityDefinition = (processAddress, activityId, activityType, taskType, behavior, assignee, multiInstance, application, subProcessModelId, subProcessDefinitionId) => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Create activity definition with data: ${JSON.stringify({
    processAddress,
    activityId,
    activityType,
    taskType,
    behavior,
    assignee,
    multiInstance,
    application,
    subProcessModelId,
    subProcessDefinitionId,
  })}`);
  const processDefinition = getContract(global.__abi, global.__bundles.BPM_MODEL.contracts.PROCESS_DEFINITION, processAddress);
  processDefinition.createActivityDefinition(global.stringToHex(activityId), activityType, taskType, behavior,
    global.stringToHex(assignee), multiInstance, global.stringToHex(application), global.stringToHex(subProcessModelId),
    global.stringToHex(subProcessDefinitionId), (error, data) => {
      if (error || !data.raw) {
        return reject(boom
          .badImplementation(`Failed to create activity definition ${activityId} in process at ${processAddress}: ${error}`));
      }
      if (parseInt(data.raw[0], 10) !== 1) {
        return reject(boom
          .badImplementation(`Error code creating activity definition ${activityId} in process at ${processAddress}: ${data.raw[0]}`));
      }
      log.info(`SUCCESS: Activity definition ${activityId} created in process at ${processAddress}`);
      return resolve();
    });
});

const createDataMapping = (processAddress, id, direction, accessPath, dataPath, dataStorageId, dataStorage) => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Create data mapping with data: ${JSON.stringify({
    processAddress,
    id,
    direction,
    accessPath,
    dataPath,
    dataStorageId,
    dataStorage,
  })}`);
  const processDefinition = getContract(global.__abi, global.__bundles.BPM_MODEL.contracts.PROCESS_DEFINITION, processAddress);
  processDefinition
    .createDataMapping(global.stringToHex(id), direction, global.stringToHex(accessPath),
      global.stringToHex(dataPath), global.stringToHex(dataStorageId), dataStorage, (error) => {
        if (error) {
          return reject(boom
            .badImplementation(`Failed to create data mapping for activity ${id} in process at ${processAddress}: ${error}`));
        }
        log.info(`SUCCESS: Data mapping created for activityId ${id} in process at ${processAddress}`);
        return resolve();
      });
});

const createGateway = (processAddress, gatewayId, gatewayType) => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Create gateway with data: ${JSON.stringify({ processAddress, gatewayId, gatewayType })}`);
  const processDefinition = getContract(global.__abi, global.__bundles.BPM_MODEL.contracts.PROCESS_DEFINITION, processAddress);
  processDefinition.createGateway(global.stringToHex(gatewayId), gatewayType, (error) => {
    if (error) {
      return reject(boom
        .badImplementation(`Failed to create gateway with id ${gatewayId} and type ${gatewayType} in process at ${processAddress}: ${error}`));
    }
    log.info(`SUCCESS: Gateway created with id ${gatewayId} and type ${gatewayType} in process at ${processAddress}`);
    return resolve();
  });
});

const createTransition = (processAddress, sourceGraphElement, targetGraphElement) => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Create transition with data: ${JSON.stringify({
    processAddress,
    sourceGraphElement,
    targetGraphElement,
  })}`);
  const processDefinition = getContract(global.__abi, global.__bundles.BPM_MODEL.contracts.PROCESS_DEFINITION, processAddress);
  processDefinition.createTransition(global.stringToHex(sourceGraphElement), global.stringToHex(targetGraphElement), (error, data) => {
    if (error || !data.raw) {
      return reject(boom
        .badImplementation(`Failed to create transition from ${sourceGraphElement} to ${targetGraphElement} in process at ${processAddress}: ${error}`));
    }
    if (parseInt(data.raw[0], 10) !== 1) {
      return reject(boom
        .badImplementation(`Error code creating transition from ${sourceGraphElement} to ${targetGraphElement} in process at ${processAddress}: ${data.raw[0]}`));
    }
    log.info(`SUCCESS: Transition created from ${sourceGraphElement} to ${targetGraphElement} in process at ${processAddress}`);
    return resolve();
  });
});

const setDefaultTransition = (processAddress, gatewayId, activityId) => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Set default transition with data: ${JSON.stringify({ processAddress, gatewayId, activityId })}`);
  const processDefinition = getContract(global.__abi, global.__bundles.BPM_MODEL.contracts.PROCESS_DEFINITION, processAddress);
  processDefinition.setDefaultTransition(global.stringToHex(gatewayId), global.stringToHex(activityId), (error) => {
    if (error) {
      return reject(boom
        .badImplementation(`Failed to set default transition between gateway ${gatewayId} and activity ${activityId} in process at ${processAddress}: ${error}`));
    }
    log.info(`SUCCESS: Default transition set between gateway ${gatewayId} and model element ${activityId} in process at ${processAddress}`);
    return resolve();
  });
});

const getTransitionConditionFunctionByDataType = (processAddress, dataType) => {
  const processDefinition = getContract(global.__abi, global.__bundles.BPM_MODEL.contracts.PROCESS_DEFINITION, processAddress);
  const functions = {};
  functions[`${DATA_TYPES.BOOLEAN}`] = processDefinition.createTransitionConditionForBool;
  functions[`${DATA_TYPES.STRING}`] = processDefinition.createTransitionConditionForString;
  functions[`${DATA_TYPES.BYTES32}`] = processDefinition.createTransitionConditionForBytes32;
  functions[`${DATA_TYPES.UINT}`] = processDefinition.createTransitionConditionForUint;
  functions[`${DATA_TYPES.INT}`] = processDefinition.createTransitionConditionForInt;
  functions[`${DATA_TYPES.ADDRESS}`] = processDefinition.createTransitionConditionForAddress;
  return functions[dataType];
};

const createTransitionCondition = (processAddress, dataType, gatewayId, activityId, dataPath, dataStorageId, dataStorage, operator, value) => new Promise((resolve, reject) => {
  log.debug('REQUEST: Create transition condition with data: %s', JSON.stringify({
    processAddress,
    dataType,
    gatewayId,
    activityId,
    dataPath,
    dataStorageId,
    dataStorage,
    operator,
    value,
  }));
  const createFunction = getTransitionConditionFunctionByDataType(processAddress, dataType);
  let formattedValue;
  if (dataType === DATA_TYPES.UINT || dataType === DATA_TYPES.INT) {
    formattedValue = parseInt(value, 10);
    log.debug('Converted value to integer: %d', formattedValue);
  } else if (dataType === DATA_TYPES.BOOLEAN) {
    formattedValue = (typeof value === 'string') ? (value.toLowerCase() === 'true') : Boolean(value);
    log.debug('Converted value to boolean: %s', formattedValue);
  } else if (dataType === DATA_TYPES.BYTES32) {
    formattedValue = global.stringToHex(value);
    log.debug('Converted value to bytes32: %s', formattedValue);
  } else {
    formattedValue = value;
  }
  createFunction(global.stringToHex(gatewayId), global.stringToHex(activityId), global.stringToHex(dataPath), global.stringToHex(dataStorageId), dataStorage, operator, formattedValue, (error) => {
    if (error) {
      return reject(boom.badImplementation('Failed to add transition condition for gateway id ' +
        `${gatewayId} and activity id ${activityId} in process at address ${processAddress}: ${error}`));
    }
    log.info(`SUCCESS: Transition condition created for gateway id ${gatewayId} and activity id ${activityId} in process at address ${processAddress}`);
    return resolve();
  });
});

const signAgreement = (actingUserAddress, agreementAddress) => new Promise(async (resolve, reject) => {
  log.debug('REQUEST: Sign agreement %s by user %s', agreementAddress, actingUserAddress);
  try {
    const agreement = getContract(global.__abi, global.__bundles.AGREEMENTS.contracts.ACTIVE_AGREEMENT, agreementAddress);
    const payload = agreement.sign.encode();
    await callOnBehalfOf(actingUserAddress, agreementAddress, payload, false);
    log.info('SUCCESS: Agreement %s signed by user %s', agreementAddress, actingUserAddress);
    return resolve();
  } catch (error) {
    return reject(boom.badImplementation(`Error forwarding sign request via acting user ${actingUserAddress} to agreement ${agreementAddress}! Error: ${error.stack}`));
  }
});

const cancelAgreement = (actingUserAddress, agreementAddress) => new Promise(async (resolve, reject) => {
  log.debug('REQUEST: Cancel agreement %s by user %s', agreementAddress, actingUserAddress);
  try {
    const agreement = getContract(global.__abi, global.__bundles.AGREEMENTS.contracts.ACTIVE_AGREEMENT, agreementAddress);
    const payload = agreement.cancel.encode();
    await callOnBehalfOf(actingUserAddress, agreementAddress, payload, true);
    log.info('SUCCESS: Agreement %s canceled by user %s', agreementAddress, actingUserAddress);
    return resolve();
  } catch (error) {
    return reject(boom.badImplementation(`Error forwarding cancel request via acting user ${actingUserAddress} to agreement ${agreementAddress}! Error: ${error}`));
  }
});

const completeActivity = (actingUserAddress, activityInstanceId, dataMappingId = null, dataType = null, value = null) => new Promise(async (resolve, reject) => {
  log.debug('REQUEST: Complete task %s by user %s', activityInstanceId, actingUserAddress);
  try {
    const bpmService = appManager.contracts['BpmService'];
    const piAddress = await bpmService.factory.getProcessInstanceForActivity(activityInstanceId)
      .then(data => data.raw[0]);
    log.info('Found process instance %s for activity instance ID %s', piAddress, activityInstanceId);
    const processInstance = getContract(global.__abi, global.__bundles.BPM_RUNTIME.contracts.PROCESS_INSTANCE, piAddress);
    let payload;
    if (dataMappingId) {
      log.info('Completing activity with OUT data mapping ID:Value (%s:%s) for activityInstance %s in process instance %s', dataMappingId, value, activityInstanceId, piAddress);
      const hexDataMappingId = global.stringToHex(dataMappingId);
      switch (dataType) {
        case DATA_TYPES.BOOLEAN:
          payload = processInstance.completeActivityWithBoolData.encode(activityInstanceId, bpmService.address, hexDataMappingId, value);
          break;
        case DATA_TYPES.STRING:
          payload = processInstance.completeActivityWithStringData.encode(activityInstanceId, bpmService.address, hexDataMappingId, value);
          break;
        case DATA_TYPES.BYTES32:
          payload = processInstance.completeActivityWithBytes32Data.encode(activityInstanceId, bpmService.address, hexDataMappingId, value);
          break;
        case DATA_TYPES.UINT:
          payload = processInstance.completeActivityWithUintData.encode(activityInstanceId, bpmService.address, hexDataMappingId, value);
          break;
        case DATA_TYPES.INT:
          payload = processInstance.completeActivityWithIntData.encode(activityInstanceId, bpmService.address, hexDataMappingId, value);
          break;
        case DATA_TYPES.ADDRESS:
          payload = processInstance.completeActivityWithAddressData.encode(activityInstanceId, bpmService.address, hexDataMappingId, value);
          break;
        default:
          return reject(boom.badImplementation(`Unsupported dataType parameter ${dataType}`));
      }
    } else {
      payload = processInstance.completeActivity.encode(activityInstanceId, bpmService.address);
    }

    const returnData = await callOnBehalfOf(actingUserAddress, piAddress, payload, true);

    const data = processInstance.completeActivity.decode(returnData);
    const errorCode = data.raw[0].valueOf();
    if (errorCode !== 1) {
      log.warn('Completing activity instance ID %s by user %s returned error code: %d', activityInstanceId, actingUserAddress, errorCode);
    }
    if (errorCode === 1001) return reject(boom.notFound(`No activity instance found with ID ${activityInstanceId}`));
    if (errorCode === 4103) return reject(boom.forbidden(`User ${actingUserAddress} not authorized to complete activity ID ${activityInstanceId}`));
    if (errorCode !== 1) return reject(boom.badImplementation(`Error code returned from completing activity ${activityInstanceId} by user ${actingUserAddress}: ${errorCode}`));
    log.info('SUCCESS: Completed task %s by user %s', activityInstanceId, actingUserAddress);
  } catch (error) {
    return reject(boom.badImplementation(`Error completing activity instance ID ${activityInstanceId} by user ${actingUserAddress}! Error: ${error}`));
  }
  return resolve();
});

const getModelAddressFromId = (modelId) => {
  log.debug(`REQUEST: Get model address for model id ${modelId}`);
  return new Promise((resolve, reject) => {
    appManager.contracts['ProcessModelRepository'].factory.getModel(
      global.stringToHex(modelId),
      (error, data) => {
        if (error || !data.raw) return reject(boom.badImplementation(`Failed to get address of model with id ${modelId}: ${error}`));
        log.info(`SUCCESS: Retrieved model address ${data.raw[0]} for model id ${modelId}`);
        return resolve(data.raw[0]);
      },
    );
  });
};

const getProcessDefinitionAddress = (modelId, processId) => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Get process definition address for model Id ${modelId} and process Id ${processId}`);
  const modelIdHex = global.stringToHex(modelId);
  const processIdHex = global.stringToHex(processId);
  appManager.contracts['ProcessModelRepository']
    .factory.getProcessDefinition(modelIdHex, processIdHex, (error, data) => {
      if (error || !data.raw) {
        return reject(boom
          .badImplementation(`Failed to get address of process definition with id ${processId} in model ${modelId}: ${error}`));
      }
      log.info(`SUCCESS: Retrieved process definition address ${data.raw[0]} for model id ${modelId} and process id ${processId}`);
      return resolve(data.raw[0]);
    });
});

const isValidProcess = processAddress => new Promise((resolve, reject) => {
  const processDefinition = getContract(global.__abi, global.__bundles.BPM_MODEL.contracts.PROCESS_DEFINITION, processAddress);
  log.debug(`REQUEST: Validate process definition at address: ${processAddress}`);
  processDefinition.validate((error, data) => {
    if (error || !data.raw) {
      return reject(boom
        .badImplementation(`Failed to validate process at ${processAddress}: ${error}`));
    }
    if (!data.raw[0]) {
      return reject(boom
        .badImplementation(`Invalid process definition at ${processAddress}: ${global.hexToString(data.raw[1].valueOf())}`));
    }
    log.info(`SUCCESS: Process Definition at ${processAddress} validated`);
    return resolve(data.raw[0]);
  });
});

const startProcessFromAgreement = agreementAddress => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Start formation process from agreement at address: ${agreementAddress}`);
  appManager.contracts['ActiveAgreementRegistry'].factory.startProcessLifecycle(agreementAddress)
    .then(data => ventHelper.waitForVent(data))
    .then((data) => {
      if (!data.raw) throw boom.badImplementation(NO_TRANSACTION_RESPONSE_ERR);
      if (parseInt(data.raw[0], 10) !== 1) {
        throw boom.badImplementation(`Error code creating/starting process instance for agreement at ${agreementAddress}: ${data.raw[0]}`);
      }
      log.info(`SUCCESS: Formation process for agreement at ${agreementAddress} created and started at address: ${data.raw[1]}`);
      return resolve(data.raw[1]);
    })
    .catch((err) => {
      if (err.isBoom) return reject(err);
      return reject(boom.badImplementation(`Failed to start formation process from agreement at ${agreementAddress}: ${err.stack}`));
    });
});

const getStartActivity = processAddress => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Get start activity id for process at address: ${processAddress}`);
  const processDefinition = getContract(global.__abi, global.__bundles.BPM_MODEL.contracts.PROCESS_DEFINITION, processAddress);
  processDefinition.getStartActivity()
    .then(data => ventHelper.waitForVent(data))
    .then((data) => {
      if (!data.raw) throw boom.badImplementation(NO_TRANSACTION_RESPONSE_ERR);
      const activityId = global.hexToString(data.raw[0]);
      log.info(`SUCCESS: Retrieved start activity id ${activityId} for process at ${processAddress}`);
      return resolve(activityId);
    })
    .catch((err) => {
      if (err.isBoom) return reject(err);
      return reject(boom.badImplementation(boom.badImplementation(`Failed to get start activity for process: ${err.stack}`)));
    });
});

const getProcessInstanceCount = () => new Promise((resolve, reject) => {
  log.debug('REQUEST: Get process instance count');
  appManager.contracts['BpmService']
    .factory.getNumberOfProcessInstances((error, data) => {
      if (error || !data.raw) return reject(boom.badImplementation(`Failed to get process instance count: ${error}`));
      log.info(`SUCCESS: Retrievef process instance count: ${data.raw[0]}`);
      return resolve(data.raw[0]);
    });
});

const getProcessInstanceForActivity = activityInstanceId => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Get process instance for activity ${activityInstanceId}`);
  appManager
    .contracts['BpmService']
    .factory.getProcessInstanceForActivity(activityInstanceId, (error, data) => {
      if (error || !data.raw) {
        return reject(boom
          .badImplementation(`Failed to get process instance for activity with id ${activityInstanceId}: ${error}`));
      }
      log.info(`SUCCESS: Retrieved process instance for activity ${activityInstanceId}: ${data.raw[0].valueOf()}`);
      return resolve(data.raw[0].valueOf());
    });
});

const getDataMappingKeys = (processDefinition, activityId, direction) => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Get data mapping keys for process definition at ${processDefinition}, activity ${activityId} and direction ${direction}`);
  const countPromise = direction === global.__constants.DIRECTION.IN ?
    processDefinition.getInDataMappingKeys : processDefinition.getOutDataMappingKeys;
  countPromise(global.stringToHex(activityId), (err, data) => {
    if (err || !data.raw) {
      return reject(boom
        .badImplementation(`Failed to get ${direction ? 'out-' : 'in-'}data mapping ids for activity ${activityId}: ${err}`));
    }
    if (data.raw[0] && Array.isArray(data.raw[0])) {
      const keys = data.raw[0].map(elem => global.hexToString(elem));
      log.info(`SUCCESS: Retrieved data mapping keys for process definition at ${processDefinition}, activity ${activityId} and direction ${direction}: ${JSON.stringify(keys)}`);
      return resolve(keys);
    }
    log.info(`SUCCESS: No data mapping keys found for process definition at ${processDefinition}, activity ${activityId} and direction ${direction}`);
    return resolve([]);
  });
});

const getDataMappingDetails = (processDefinition, activityId, dataMappingIds, direction) => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Get data mapping details for process definition at ${processDefinition}, activity ${activityId}, data mapping ids ${JSON.stringify(dataMappingIds)} and direction ${direction}`);
  const dataPromises = [];
  dataMappingIds.forEach((dataMappingId) => {
    const getter = direction === global.__constants.DIRECTION.IN ?
      processDefinition.getInDataMappingDetails : processDefinition.getOutDataMappingDetails;
    dataPromises.push(getter(global.stringToHex(activityId), global.stringToHex(dataMappingId)));
  });
  Promise.all(dataPromises)
    .then((data) => {
      const details = data.map(d => d.values);
      log.infp(`SUCCESS: Retreieved data mapping details for process definition at ${processDefinition}, activity ${activityId}, data mapping ids ${JSON.stringify(dataMappingIds)} and direction ${direction}: ${JSON.stringify(details)}`);
      resolve(details);
    })
    .catch(err => reject(boom
      .badImplementation(`Failed to get ${direction ? 'out-' : 'in-'}data mapping details for activityId ${activityId}: ${err}`)));
});

const getDataMappingDetailsForActivity = async (pdAddress, activityId, dataMappingIds = [], direction) => {
  log.debug(`REQUEST: Get ${direction ? 'out-' : 'in-'}data mapping details for activity ${activityId} in process definition at ${pdAddress}`);
  const processDefinition = getContract(global.__abi, global.__bundles.BPM_MODEL.contracts.PROCESS_DEFINITION, pdAddress);
  try {
    const keys = dataMappingIds || (await getDataMappingKeys(processDefinition, activityId, direction)); // NOTE: activityId are hex converted inside getDataMappingKeys and not here
    const details = await getDataMappingDetails(processDefinition, activityId, keys, direction); // NOTE: activityId and dataMappingIds are hex converted inside getDataMappingDetails and not here
    log.info(`SUCCESS: Retrieved ${direction ? 'out-' : 'in-'}data mapping details for activity ${activityId} in process definition at ${pdAddress}`);
    return details;
  } catch (err) {
    if (boom.isBoom(err)) {
      throw err;
    } else {
      throw boom.badImplementation(`Failed to get data mapping details for process definition at ${pdAddress} and activityId ${activityId}`);
    }
  }
};

const getArchetypeProcesses = archAddress => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Get formation and execution processes for archetype at address ${archAddress}`);
  let formation;
  let execution;
  appManager.contracts['ArchetypeRegistry']
    .factory.getArchetypeData(archAddress, (err, data) => {
      if (err || !data.raw) return reject(boom.badImplementation(`Failed to get archetype processes: ${err}`));
      formation = data.raw[5] ? data.raw[5].valueOf() : '';
      execution = data.raw[6] ? data.raw[6].valueOf() : '';
      log.info(`SUCCESS: Retreived processes for archetype at ${archAddress}: ${JSON.stringify({ formation, execution })}`);
      return resolve({
        formation,
        execution,
      });
    });
});

const getActivityInstanceData = (piAddress, activityInstanceId) => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Get activity instance data for activity id ${activityInstanceId} in process instance at address ${piAddress}`);
  appManager
    .contracts['BpmService']
    .factory.getActivityInstanceData(piAddress, activityInstanceId, (err, data) => {
      if (err || !data.raw) {
        return reject(boom
          .badImplementation(`Failed to get data for activity instance with id ${activityInstanceId} in process instance at ${piAddress}: ${err}`));
      }
      const aiData = {
        activityId: data.raw[0] ? data.raw[0].valueOf() : '',
        created: data.raw[1] ? data.raw[1].valueOf() : '',
        completed: data.raw[2] ? data.raw[2].valueOf() : '',
        performer: data.raw[3] ? data.raw[3].valueOf() : '',
        completedBy: data.raw[4] ? data.raw[4].valueOf() : '',
        state: data.raw[5] ? data.raw[5].valueOf() : '',
      };
      log.info(`SUCCESS: Retrieved actvity instance data for activity id ${activityInstanceId} in process instance at address ${piAddress}: 
        ${JSON.stringify(aiData)}`);
      return resolve(aiData);
    });
});

const getActiveAgreementData = agreementAddress => new Promise((resolve, reject) => {
  log.debug(`REQUEST: Get data for agreement at address ${agreementAddress}`);
  appManager
    .contracts['ActiveAgreementRegistry']
    .factory.getActiveAgreementData(agreementAddress, (err, data) => {
      if (err || !data.raw) {
        return reject(boom
          .badImplementation(`Failed to get data of agreement at ${agreementAddress}: ${err}`));
      }
      const agData = {
        archetype: data.raw[0] ? data.raw[0].valueOf() : '',
        name: data.raw[1] ? global.hexToString(data.raw[1].valueOf()) : '',
        creator: data.raw[2] ? data.raw[2].valueOf() : '',
        maxNumberOfAttachments: data.raw[7] ? data.raw[7].valueOf() : '',
        isPrivate: data.raw[8] ? data.raw[8].valueOf() : '',
        legalState: data.raw[9] ? data.raw[9].valueOf() : '',
        formationProcessInstance: data.raw[10] ? data.raw[10].valueOf() : '',
        executionProcessInstance: data.raw[11] ? data.raw[11].valueOf() : '',
      };
      log.info(`SUCCESS: Retreieved data for agreement at ${agreementAddress}: ${JSON.stringify(agData)}`);
      return resolve(agData);
    });
});

module.exports = {
  load,
  events,
  listen: chainEvents,
  db,
  boomify,
  registerEcosystem,
  setToNameRegistry,
  getFromNameRegistry,
  getContract,
  getBpmService,
  getProcessInstance,
  createOrganization,
  createArchetype,
  isActiveArchetype,
  getArchetypeAuthor,
  activateArchetype,
  deactivateArchetype,
  setArchetypeSuccessor,
  getArchetypeSuccessor,
  addArchetypeParameters,
  addArchetypeDocuments,
  setArchetypePrice,
  addJurisdictions,
  createArchetypePackage,
  activateArchetypePackage,
  deactivateArchetypePackage,
  addArchetypeToPackage,
  createAgreement,
  initializeObjectAdministrator,
  setMaxNumberOfAttachments,
  setAddressScopeForAgreementParameters,
  updateAgreementFileReference,
  cancelAgreement,
  createAgreementCollection,
  addAgreementToCollection,
  createUserInEcosystem,
  createUser,
  getUserByUsernameAndEcosystem,
  getUserByUsername,
  addUserToEcosystem,
  addUserToOrganization,
  removeUserFromOrganization,
  addApproverToOrganization,
  removeApproverFromOrganization,
  createDepartment,
  removeDepartment,
  addDepartmentUser,
  removeDepartmentUser,
  createProcessModel,
  addDataDefinitionToModel,
  addProcessInterface,
  addParticipant,
  createProcessDefinition,
  addProcessInterfaceImplementation,
  createActivityDefinition,
  createDataMapping,
  createGateway,
  createTransition,
  setDefaultTransition,
  createTransitionCondition,
  completeActivity,
  signAgreement,
  getModelAddressFromId,
  getProcessDefinitionAddress,
  isValidProcess,
  startProcessFromAgreement,
  getStartActivity,
  getProcessInstanceCount,
  getProcessInstanceForActivity,
  getDataMappingKeys,
  getDataMappingDetails,
  getDataMappingDetailsForActivity,
  getArchetypeProcesses,
  getActivityInstanceData,
  getActiveAgreementData,
  callOnBehalfOf,
};
