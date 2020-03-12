const boom = require('@hapi/boom');
const { status } = require('grpc');
const logger = require('./common/logger');
const log = logger.getLogger('contracts');
const utils = require('./common/utils');
const burrowDB = require('./common/burrow-db');
const burrowApp = require('./common/burrow-app');
const VentHelper = require('./common/VentHelper');
const {
  DATA_TYPES,
  ERROR_CODES: ERR,
  CONTRACTS,
  BUNDLES,
  DIRECTION,
} = require('./common/constants');
const { hexToString, hexFromString } = require('./lib/hex');

const NO_TRANSACTION_RESPONSE_ERR = 'No transaction response raw data received from burrow';

// TODO: [Silas] refactor this into a mapping from blackstone codes to HTTP status codes then just use a single:
// boom.boomify(`${message}: ${parsedError.message}. ${burrowError.stack}`, {statusCode: statusFromErrorCode(parsedError.code)})
// Probably easiest to do when introducing typescript where enum gives you reverse lookups for free
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
    case ERR.INVALID_STATE:
      error = boom.expectationFailed(`${message}: ${parsedError.message}. ${burrowError.stack}`);
      break;
    case ERR.RUNTIME_ERROR:
    case ERR.DEPENDENCY_NOT_FOUND:
      error = boom.badImplementation(`${message}: ${parsedError.message}. ${burrowError.stack}`);
      break;
    default:
      error = boom.badImplementation(`${message}: ${burrowError ? parsedError.message : 'Unknown Error'}. ${burrowError.stack}`);
      break;
  }
  return error;
};

function checkEnvSet(key) {
  const value = process.env[key];
  if (!value) {
    throw boom.badImplementation(`Contracts: environment variable '${key}' must be set`);
  }
  return value;
}

// Global static singletons for Contracts
let appManager;
let ventHelper;
let db;
let ABI_DIR;
let ACCOUNTS_SERVER_KEY;

/**
 * Contracts provides a client interface to the agreements network contracts. The underlying Burrow and Postgres
 * connections are shared but each instance can be configured with different synchronisation behaviour.
 */
class Contracts {
  /**
   * Create a new Contracts object that provides client-side mappings for the blackstone contracts.
   * @param interceptor a function that will be called after each Burrow call and awaited before the results are processed
   *  the default is for each call to wait for synchronisation with Vent. For more fine-grained control @see Contracts.do
   */
  constructor(interceptor) {
    this.ventWaiter = ventHelper.newVentWaiter();
    this.interceptor = async (data) => {
      this.ventWaiter(data);
      // NOTE: in general interceptor may be async
      return typeof interceptor === 'function' ? interceptor(data) : data;
    };
  }

  /**
   * Initialises the long-lived process singletons that are shared between all Contracts clients. This function should
   * be called before any {@link Contracts} instance is initialised. It only needs to be called once but it is idempotent
   * so there is no need to worry about calling it redundantly if it makes structuring your code easier.
   * {@link Contracts.do} will call this for you.
   *
   * Reading its parameters from the environment this function:
   *
   * - Connects to Burrow
   * - Listens to vent notifications
   * - Loads contracts into burrow-js AppManager
   * - Registers the default ecosystem
   *
   * @returns {Promise<void>}
   */
  static async init() {
    // Make sure this is idempotent
    if (appManager !== undefined) return;

    // Fail early
    ABI_DIR = checkEnvSet('API_ABI_DIRECTORY');
    ACCOUNTS_SERVER_KEY = checkEnvSet('ACCOUNTS_SERVER_KEY');
    const chainURL = checkEnvSet('CHAIN_URL_GRPC');
    const dbUser = checkEnvSet('POSTGRES_DB_USER');
    const dbPass = checkEnvSet('POSTGRES_DB_PASSWORD');
    const dbHost = checkEnvSet('POSTGRES_DB_HOST');
    const dbPort = checkEnvSet('POSTGRES_DB_PORT');
    const dbDatabase = checkEnvSet('POSTGRES_DB_DATABASE');
    const identityProvider = checkEnvSet('IDENTITY_PROVIDER');
    const maxVentWait = checkEnvSet('MAX_WAIT_FOR_VENT_MS');

    db = new burrowDB.Connection(chainURL, ACCOUNTS_SERVER_KEY);

    const connectionString = `postgres://${dbUser}:${dbPass}@${dbHost}:${dbPort}/${dbDatabase}`;

    ventHelper = new VentHelper(connectionString, maxVentWait);
    await ventHelper.listen();

    const doug = await db.burrow.namereg.get('DOUG');
    log.info(`Creating AppManager with DOUG at address: ${doug}`);
    appManager = new burrowApp.Manager(db, doug.Data);

    const modules = utils.getArrayFromString(CONTRACTS);
    log.info(`Detected ${modules.length} contract modules to be loaded from DOUG: ${modules}`);

    // When performing a restore executing these concurrently (i.e. in arbitrary order) would cause a ERR600 on first
    // run and work on second run. This is a workaroudn that can be scrapped once that behaviour is understood.
    // await Promise.all(modules.map(m => appManager.loadContract(m)));
    for (const m of modules) {
      try {
        await appManager.loadContract(m);
        console.log(`${m} loaded`);
      } catch (err) {
        throw new Error(`error loading module ${m}: ${err}`);
      }
    }

    // Lastly, ensure Ecosystem setup
    // Resolve the Ecosystem address for this ContractsManager
    if (!identityProvider) {
      throw boom.badImplementation('No Ecosystem name set. Unable to start API ...');
    }

    const ecosystemName = identityProvider;
    const contracts = new Contracts();
    log.info(`Validating if Ecosystem ${ecosystemName} is in NameReg`);
    appManager.ecosystemAddress = await contracts.getFromNameRegistry(ecosystemName);
    if (!appManager.ecosystemAddress) {
      appManager.ecosystemAddress = await contracts.registerEcosystem(ecosystemName);
      // This should not happen, but just in case, double-check the AppManager.ecosystemAddress
      if (!appManager.ecosystemAddress) {
        throw boom.badImplementation('Failed to configure the AppManager with an ecosystem address');
      }
    }
    await contracts.sync();
    log.info(`AppManager configured for Ecosystem ${ecosystemName} at address ${appManager.ecosystemAddress}`);
  }

  /**
   * Create a contracts client that synchronises with Vent after every call
   * @returns {Contracts}
   */
  static newSync() {
    const waitForVent = ventHelper.waitForVent.bind(ventHelper);
    return new Contracts(waitForVent);
  }

  /**
   * Static version of @see do that acts on a new Contract object. Will also calls {@link Contracts.init} idempotently.
   * @param func
   * @returns {Promise<*|"ok"|"not-equal"|"timed-out">}
   */
  static async do(func) {
    await Contracts.init();
    const contracts = new Contracts();
    return contracts.do(func);
  }

  /**
   * Groups together sets of actions on a Contracts object that should be synchronised with Vent as a whole. That is
   * the passed `func(contracts)` will be executed and passed a special Contracts object that will be synchronised
   * only after awaiting the return of (the possibly async) func. This allows multiple contract calls to be made without
   * synchronising with vent after each one (as would be the default behaviour from {@link Contracts.newSync}.
   * The {@link sync} function
   * can be called if intermediate synchronisation is required.
   * @param func
   * @returns {Promise<*|"ok"|"not-equal"|"timed-out">}
   */
  async do(func) {
    const result = await func(this);
    await this.sync();
    return result;
  }

  async sync() {
    return this.ventWaiter.wait();
  }

  /**
   * Returns the JS representation of the deplopyed contract
   * @param {*} contractName name of the contract with or without the .abi extension
   * @param {*} contractAddress address of the deployed contract
   */
  static getContract(contractName, contractAddress) {
    const abi = burrowApp.getAbi(ABI_DIR, contractName);
    return db.burrow.contracts.new(abi, null, contractAddress);
  }

  // shortcut functions to retrieve often needed objects and services
  // Note: contracts need to be loaded before invoking these functions. see load() function
  static getBpmService() {
    return appManager.contracts['BpmService'];
  }

  static getUserAccount(userAddress) {
    return Contracts.getContract(BUNDLES.COMMONS_AUTH.contracts.USER_ACCOUNT, userAddress);
  }

  static getOrganization(orgAddress) {
    return Contracts.getContract(BUNDLES.PARTICIPANTS_MANAGER.contracts.ORGANIZATION, orgAddress);
  }

  static getProcessInstance(piAddress) {
    return Contracts.getContract(BUNDLES.BPM_RUNTIME.contracts.PROCESS_INSTANCE, piAddress);
  }

  static getEcosystem(ecosystemAddress) {
    return Contracts.getContract(BUNDLES.COMMONS_AUTH.contracts.ECOSYSTEM, ecosystemAddress);
  }

  /**
 * Returns a promise to call the forwardCall function of the given userAddress to invoke the function encoded in the given payload on the provided target address and return the result bytes representation
 * The 'payload' parameter must be the output of calling the 'encode(...)' function on a contract's function. E.g. <contract>.<function>.encode(param1, param2)
 * 'shouldWaitForVent' is a boolean parameter which indicates whether this.callOnBehalfOf should to wait for vent db to catch up to the block height in the forwardCall response, before resolving the promise.
 */
  async callOnBehalfOf(userAddress, targetAddress, payload) {
    try {
      const actingUser = Contracts.getUserAccount(userAddress);
      log.debug('REQUEST: Call target %s on behalf of user %s with payload: %s', targetAddress, userAddress, payload);
      const data = await actingUser.forwardCall(targetAddress, payload);
      if (!data.raw) throw new Error('burrow returned no raw data!');
      await this.interceptor(data);
      log.info('SUCCESS: ReturnData from target %s forwardCall on behalf of user %s: %s', targetAddress, userAddress, data.raw[0]);
      return data.raw[0];
    } catch (err) {
      throw boomify(err, `Unexpected error in forwardCall function on user ${userAddress} attempting to call target ${targetAddress}`);
    }
  }

  createEcosystem(name) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Create new Ecosystem with name ${name}`);
      appManager.contracts['EcosystemRegistry'].factory.createEcosystem(name)
        .then(this.interceptor)
        .then((data) => {
          if (!data.raw) return reject(new Error(`Failed to create Ecosystem ${name}: no result returned}`));
          log.info(`SUCCESS: Created Ecosystem ${name} at ${data.raw[0]}`);
          return resolve(data.raw[0]);
        })
        .catch(err => reject(boomify(err, `Failed to create Ecosystem ${name}: ${err.stack}`)));
    });
  }

  addExternalAddressToEcosystem(externalAddress, ecosystemAddress) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Add external address ${externalAddress} to Ecosystem at ${ecosystemAddress}`);
      const ecosystem = Contracts.getContract(BUNDLES.COMMONS_AUTH.contracts.ECOSYSTEM, ecosystemAddress);
      ecosystem.addExternalAddress(externalAddress)
        .then(this.interceptor)
        .then(() => {
          log.info(`SUCCESS: Added external address ${externalAddress} to ecosystem at ${ecosystemAddress}`);
          return resolve();
        })
        .catch(err => reject(boom.badImplementation(`Failed to add external address ${externalAddress} to ecosystem at ${ecosystemAddress}: ${err.stack}`)));
    });
  }

  setToNameRegistry(name, value, lease) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Set to name registry: ${JSON.stringify({ name, value, lease })}`);
      db.burrow.namereg.set(name, value, lease)
        .then(this.interceptor)
        .then(() => {
          log.info(`SUCCESS: Set name-value pair ${name}:${value} to namereg`);
          return resolve();
        })
        .catch(err => reject(boom.badImplementation(`Error setting ${JSON.stringify({ name, value, lease })} to namereg: ${err.stack}`)));
    });
  }

  // Currently there is no height field passed by burrow-js to sync on here - it is available in TxExecution
  // eslint-disable-next-line class-methods-use-this
  getFromNameRegistry(name) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Get from name registry: ${name}`);
      db.burrow.namereg.get(name)
        .then((result) => {
          log.info(`SUCCESS: Retrieved name-value pair ${name}:${result ? result.Data : null} from namereg`);
          return resolve((result && result.Data) ? result.Data : undefined);
        })
        .catch((err) => {
          if (err.code === status.NOT_FOUND) {
            return resolve(undefined);
          }
          return reject(boom.badImplementation(`Error getting entry for <${name}> from namereg: ${err.stack}`));
        });
    });
  }

  registerEcosystem(ecosystemName) {
    return new Promise(async (resolve, reject) => {
      try {
        const address = await this.createEcosystem(ecosystemName);
        log.debug(`REQUEST: Add external address ${db.burrow.account} to ecosystem ${ecosystemName} at address ${address}`);
        await this.addExternalAddressToEcosystem(db.burrow.account, address);
        await this.setToNameRegistry(ecosystemName, address, 0);
        log.info(`SUCCESS: Added external address ${db.burrow.account} to ecosystem ${ecosystemName} at address ${address}`);
        return resolve(address);
      } catch (err) {
        return reject(new Error(`Failed to register ecosystem [ ${ecosystemName}]: ${err.stack}`));
      }
    });
  }

  /**
 * Creates a promise to create a new organization and add to Accounts Manager.
 * @param organization
 */
  createOrganization(org) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Create organization with: ${JSON.stringify(org)}`);
      appManager.contracts['ParticipantsManager']
        .factory.createOrganization(org.approvers ? org.approvers : [], org.defaultDepartmentId)
        .then(this.interceptor)
        .then((data) => {
          if (!data.raw) throw boom.badImplementation(NO_TRANSACTION_RESPONSE_ERR);
          if (parseInt(data.raw[0], 10) === 1002) throw boom.badRequest('Organization id must be unique');
          if (parseInt(data.raw[0], 10) !== 1) throw boom.badImplementation(`Error code creating new organization: ${data.raw[0]}`);
          log.info(`SUCCESS: Created new organization at address ${data.raw[1]}, with approvers ${org.approvers}`);
          return resolve(data.raw[1]);
        })
        .catch((err) => {
          if (err.isBoom) return reject(err);
          return reject(boom.badImplementation(`Failed to create organization: ${err.stack}`));
        });
    });
  }

  createArchetype(type) {
    const archetype = type;
    archetype.isPrivate = archetype.isPrivate || false;
    archetype.price = Math.floor(archetype.price * 100); // monetary unit conversion to cents which is the recorded unit on chain
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Create archetype with: ${JSON.stringify(archetype)}`);
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
        .then(this.interceptor)
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
  }

  isActiveArchetype(archetypeAddress) {
    log.debug(`REQUEST: Determine if archetype at ${archetypeAddress} is active`);
    const archetype = Contracts.getContract(BUNDLES.AGREEMENTS.contracts.ARCHETYPE, archetypeAddress);
    return new Promise((resolve, reject) => {
      archetype.isActive()
        .then(this.interceptor)
        .then((data) => {
          if (!data.raw) {
            return reject(boom.badImplementation(`Failed to determine if archetype at ${archetypeAddress} is active: no result returned`));
          }
          log.info(`SUCCESS: Archetype at ${archetypeAddress} has been found to be ${data.raw[0] ? 'active' : 'inactive'}`);
          return resolve(data.raw[0]);
        })
        .catch(err => reject(boom.badImplementation(`Failed to determine if archetype at ${archetypeAddress} is active: ${err}`)));
    });
  }

  getArchetypeAuthor(archetypeAddress) {
    log.debug(`REQUEST: Get archetype author for archetype at ${archetypeAddress}`);
    const archetype = Contracts.getContract(BUNDLES.AGREEMENTS.contracts.ARCHETYPE, archetypeAddress);
    return new Promise((resolve, reject) => {
      archetype.getAuthor()
        .then(this.interceptor)
        .then((data) => {
          if (!data.raw) {
            return reject(boom.badImplementation(`Failed to get author of archetype at ${archetypeAddress}: no result returned`));
          }
          log.info(`SUCCESS: Retrieved archetype author for archetype at ${archetypeAddress}: ${data.raw[0]}`);
          return resolve(data.raw[0]);
        })
        .catch(err => reject(boom.badImplementation(`Failed to get author of archetype at ${archetypeAddress}: ${err}`)));
    });
  }


  activateArchetype(archetypeAddress, userAccount) {
    log.debug(`REQUEST: Activate archetype at ${archetypeAddress} by user at ${userAccount}`);
    const archetype = Contracts.getContract(BUNDLES.AGREEMENTS.contracts.ARCHETYPE, archetypeAddress);
    return new Promise((resolve, reject) => {
      const payload = archetype.activate.encode();
      this.callOnBehalfOf(userAccount, archetypeAddress, payload)
        .then(() => {
          log.info(`SUCCESS: Archetype at ${archetypeAddress} activated by user at ${userAccount}`);
          resolve();
        })
        .catch(error => reject(boom.badImplementation(`Error forwarding activate request via acting user ${userAccount} to archetype ${archetypeAddress}! Error: ${error}`)));
    });
  }

  deactivateArchetype(archetypeAddress, userAccount) {
    log.debug(`REQUEST: Deactivate archetype at ${archetypeAddress} by user at ${userAccount}`);
    const archetype = Contracts.getContract(BUNDLES.AGREEMENTS.contracts.ARCHETYPE, archetypeAddress);
    return new Promise((resolve, reject) => {
      const payload = archetype.deactivate.encode();
      this.callOnBehalfOf(userAccount, archetypeAddress, payload)
        .then(() => {
          log.info(`SUCCESS: Archetype at ${archetypeAddress} deactivated by user at ${userAccount}`);
          resolve();
        })
        .catch(error => reject(boom.badImplementation(`Error forwarding deactivate request via acting user ${userAccount} to archetype ${archetypeAddress}! Error: ${error}`)));
    });
  }

  setArchetypeSuccessor(archetypeAddress, successorAddress, userAccount) {
    log.debug(`REQUEST: Set successor to ${successorAddress} for archetype at ${archetypeAddress} by user at ${userAccount}`);
    const archetype = Contracts.getContract(BUNDLES.AGREEMENTS.contracts.ARCHETYPE, archetypeAddress);
    return new Promise((resolve, reject) => {
      const payload = archetype.setSuccessor.encode(successorAddress);
      this.callOnBehalfOf(userAccount, archetypeAddress, payload)
        .then(() => {
          log.info(`SUCCESS: Successor ${successorAddress} set for archetype at ${archetypeAddress} by user at ${userAccount}`);
          resolve();
        })
        .catch(error => reject(boom.badImplementation(`Error forwarding setArchetypeSuccessor request via acting user ${userAccount} to archetype ${archetypeAddress} with successor ${successorAddress}! Error: ${error}`)));
    });
  }

  getArchetypeSuccessor(archetypeAddress) {
    log.debug(`REQUEST: Get successor for archetype at ${archetypeAddress}`);
    return new Promise((resolve, reject) => {
      appManager.contracts['ArchetypeRegistry'].factory.getArchetypeSuccessor(archetypeAddress)
        .then(this.interceptor)
        .then((data) => {
          log.info(`SUCCESS: Retrieved successor for archetype at ${archetypeAddress}`);
          return resolve(data.raw[0]);
        })
        .catch(err => reject(boomify(err, `Failed to get successor for archetype at ${archetypeAddress}`)));
    });
  }

  // TODO configuration currently not supported until new specification is clear, i.e. which fields will be included in the configuration
  // configureArchetype(address, config) { return {
  //   return new Promise(function (resolve, reject) {
  //     log.debug(`Configuring archetype at address ${address} with: ${JSON.stringify(config)}`);
  //     appManager.contracts['ArchetypeRegistry'].factory.configure(
  //       address,
  //       config.numberOfParticipants,
  //       config.termination,
  //       config.fulfillment,
  //       config.amount,
  //       config.currency,
  //       ).then((data) => {
  // })
  // .catch(error => {
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

  addArchetypeParameters(address, parameters) {
    return new Promise((resolve, reject) => {
      const paramTypes = [];
      const paramNames = [];
      for (let i = 0; i < parameters.length; i += 1) {
        paramTypes[i] = parseInt(parameters[i].type, 10);
        paramNames[i] = hexFromString(parameters[i].name);
      }
      log.debug(`REQUEST: Add archetype parameters to archetype at address ${address}. ` +
    `Parameter Types: ${JSON.stringify(paramTypes)}, Parameter Names: ${JSON.stringify(paramNames)}`);
      appManager
        .contracts['ArchetypeRegistry']
        .factory.addParameters(address, paramTypes, paramNames)
        .then(this.interceptor)
        .then((data) => {
          if (!data.raw) {
            return reject(boom.badImplementation(`Failed to add parameters to archetype at ${address}: no result returned`));
          }
          if (parseInt(data.raw[0], 10) !== 1) {
            return reject(boom.badImplementation(`Error code adding parameter to archetype at ${address}: ${data.raw[0]}`));
          }
          log.info(`SUCCESS: Added parameters ${parameters.map(({ name }) => name)} to archetype at ${address}`);
          return resolve();
        })
        .catch(err => reject(boom.badImplementation(`Failed to add parameters to archetype at ${address}: ${err}`)));
    });
  }

  addArchetypeDocument(address, fileReference) {
    return new Promise((resolve, reject) => {
      log.debug('REQUEST: Add document to archetype at %s', address);
      appManager
        .contracts['ArchetypeRegistry']
        .factory.addDocument(address, fileReference)
        .then(this.interceptor)
        .then(() => {
          log.info('SUCCESS: Added document to archetype at %s', address);
          return resolve();
        })
        .catch(err => reject(boomify(err, `Failed to add document to archetype ${address}`)));
    });
  }

  async addArchetypeDocuments(archetypeAddress, documents) {
    const names = documents.map(doc => doc.name).join(', ');
    log.debug(`REQUEST: Add archetype documents to archetype at ${archetypeAddress}: ${names}`);
    const resolvedDocs = await Promise.all(documents.map(async ({ grant }) => {
      const result = await this.addArchetypeDocument(archetypeAddress, grant);
      return result;
    }));
    log.info(`SUCCESS: Added documents to archetype at ${archetypeAddress}: ${names}`);
    return resolvedDocs;
  }

  setArchetypePrice(address, price) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Set price to ${price} for archetype at ${address}`);
      const priceInCents = Math.floor(price * 100); // monetary unit conversion to cents which is the recorded unit on chain
      appManager.contracts['ArchetypeRegistry'].factory.setArchetypePrice(address, priceInCents)
        .then(this.interceptor)
        .then(() => {
          log.info(`SUCCESS: Set price to ${price} for archetype at ${address}`);
          return resolve();
        })
        .catch(err => reject(boom.badImplementation(`Failed to set price to ${price} for archetype at ${address}`)));
    });
  }

  createArchetypePackage(author, isPrivate, active) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Create a ${(isPrivate ? 'private' : 'public')}, ${(active ? 'active' : 'inactive')} archetype package ` +
    `by user at ${author}`);
      appManager
        .contracts['ArchetypeRegistry']
        .factory.createArchetypePackage(author, isPrivate, active)
        .then(this.interceptor)
        .then((data) => {
          if (!data.raw) throw boom.badImplementation(NO_TRANSACTION_RESPONSE_ERR);
          if (parseInt(data.raw[0], 10) !== 1) throw boom.badImplementation(`Error code adding archetype package by user ${author}: ${data.raw[0]}`);
          log.info(`SUCCESS: Created new archetype package by author ${author} with id ${data.raw[1]}`);
          return resolve(data.raw[1]);
        })
        .catch(err => reject(boom.badImplementation(`Failed to add archetype package by user ${author}: ${err.stack}`)));
    });
  }

  activateArchetypePackage(packageId, userAccount) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Activate archetype package with id ${packageId} by user at ${userAccount}`);
      appManager.contracts['ArchetypeRegistry'].factory.activatePackage(packageId, userAccount)
        .then(this.interceptor)
        .then(() => {
          log.info(`SUCCESS: Archetype package with id ${packageId} activated by user at ${userAccount}`);
          return resolve();
        })
        .catch(err => reject(boomify(err, `Failed to activate archetype package with id ${packageId} by user ${userAccount}`)));
    });
  }

  deactivateArchetypePackage(packageId, userAccount) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Deactivate archetype package with id ${packageId} by user at ${userAccount}`);
      appManager
        .contracts['ArchetypeRegistry'].factory.deactivatePackage(packageId, userAccount)
        .then(this.interceptor)
        .then(() => {
          log.info(`SUCCESS: Archetype package with id ${packageId} deactivated by user at ${userAccount}`);
          return resolve();
        })
        .catch(err => reject(boomify(err, `Failed to deactivate archetype package with id ${packageId} by user ${userAccount}`)));
    });
  }

  addArchetypeToPackage(packageId, archetype) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Add archetype at ${archetype} to package ${packageId}`);
      appManager
        .contracts['ArchetypeRegistry']
        .factory.addArchetypeToPackage(packageId, archetype)
        .then(this.interceptor)
        .then(() => {
          log.info(`SUCCESS: Added archetype at ${archetype} to package with id ${packageId}`);
          return resolve();
        })
        .catch(err => reject(boomify(err, `Failed to add archetype at ${archetype} to package ${packageId}`)));
    });
  }

  addJurisdictions(address, jurisdictions) {
    return new Promise((resolve, reject) => {
      const countries = [];
      const regions = [];
      jurisdictions.forEach((item) => {
        if (item.regions.length > 0) {
          item.regions.forEach((region) => {
            countries.push(hexFromString(item.country));
            regions.push(region);
          });
        } else {
          countries.push(hexFromString(item.country));
          regions.push('');
        }
      });
      log.debug(`REQUEST: Add jurisdictions to archetype at ${address}. ` +
    `Countries: ${JSON.stringify(countries)}, Regions: ${JSON.stringify(regions)}`);
      appManager.contracts['ArchetypeRegistry'].factory.addJurisdictions(address, countries, regions)
        .then(this.interceptor)
        .then((data) => {
          if (!data.raw) {
            return reject(boom.badImplementation(`Failed to add juridictions to archetype at ${address} since no result}`));
          }
          if (parseInt(data.raw[0], 10) !== 1) {
            return reject(boom.badImplementation(`Error code adding jurisdictions to archetype at ${address}: ${data.raw[0]}`));
          }
          log.info(`SUCCESS: Added jurisdictions to archetype at ${address}`);
          return resolve();
        })
        .catch(error => reject(boom.badImplementation(`Failed to add juridictions to archetype at ${address}: ${error}`)));
    });
  }

  createAgreement(agreement) {
    return new Promise((resolve, reject) => {
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
          parties, collectionId, governingAgreements)
        .then(this.interceptor)
        .then((data) => {
          if (!data.raw) {
            return reject(boom.badImplementation(`Failed to create agreement by ${creator} from archetype at ${agreement.archetype}: no result returned`));
          }
          log.info(`SUCCESS: Created agreement by ${creator} at address ${data.raw[0]}`);
          return resolve(data.raw[0]);
        })
        .catch(err => reject(boomify(err, `Failed to create agreement by ${creator} from archetype at ${agreement.archetype}`)));
    });
  }

  async setLegalState(agreementAddress, legalState) {
    try {
      log.debug(`REQUEST: Set legal state of agreement ${agreementAddress} to ${legalState}`);
      const agreement = Contracts.getContract(BUNDLES.AGREEMENTS.contracts.ACTIVE_AGREEMENT, agreementAddress);
      const permissionId = (await agreement.ROLE_ID_LEGAL_STATE_CONTROLLER()).raw[0];
      const hasPermission = (await agreement.hasPermission(permissionId, ACCOUNTS_SERVER_KEY)).raw[0];
      if (!hasPermission) await agreement.grantPermission(permissionId, ACCOUNTS_SERVER_KEY);
      const data = await agreement.setLegalState(legalState);
      await agreement.revokePermission(permissionId, ACCOUNTS_SERVER_KEY);
      await this.interceptor(data);
      log.info(`SUCCESS: Set legal state of agreement ${agreementAddress} to ${legalState}`);
    } catch (err) {
      throw boomify(err, `Failed to set legal state of agreement ${agreementAddress} to ${legalState}`);
    }
  }

  initializeObjectAdministrator(agreementAddress) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Initializing agreement admin role for agreement: ${agreementAddress}`);
      const agreement = Contracts.getContract(BUNDLES.AGREEMENTS.contracts.ACTIVE_AGREEMENT, agreementAddress);
      agreement.initializeObjectAdministrator(ACCOUNTS_SERVER_KEY)
        .then(this.interceptor)
        .then(() => {
          log.info(`SUCCESS: Initialized agreement admin role for agreement ${agreementAddress}`);
          return resolve();
        })
        .catch(err => reject(boomify(err, `Failed to initialize object admin for agreement ${agreementAddress}`)));
    });
  }

  setMaxNumberOfAttachments(agreementAddress, maxNumberOfAttachments) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Set max number of events to ${maxNumberOfAttachments} for agreement at ${agreementAddress}`);
      appManager
        .contracts['ActiveAgreementRegistry']
        .factory.setMaxNumberOfEvents(agreementAddress, maxNumberOfAttachments)
        .then(this.interceptor)
        .then(() => {
          log.info(`SUCCESS: Set max number of events to ${maxNumberOfAttachments} for agreement at ${agreementAddress}`);
          return resolve();
        })
        .catch(err => reject(boom.badImplementation(`Failed to set max number of events to ${maxNumberOfAttachments} for agreement at ${agreementAddress}: ${err}`)));
    });
  }

  // eslint-disable-next-line class-methods-use-this
  async setAddressScopeForAgreementParameters(agreementAddr, parameters) {
    log.debug(`REQUEST: Add scopes to agreement ${agreementAddr} parameters: ${JSON.stringify(parameters)}`);
    const agreement = Contracts.getContract(BUNDLES.AGREEMENTS.contracts.ACTIVE_AGREEMENT, agreementAddr);
    const promises = parameters.map(({ name, value, scope }) => new Promise((resolve, reject) => {
      agreement.setAddressScope(value, hexFromString(name), scope, '', '', '0x0')
        .then(this.interceptor)
        .then(() => resolve())
        .catch(error => reject(boomify(error, `Failed to add scope ${scope} to address ${value} in context ${name}`)));
    }));
    try {
      await Promise.all(promises);
      log.info(`SUCCESS: Added scopes to agreement ${agreementAddr} parameters`);
    } catch (err) {
      if (boom.isBoom(err)) throw err;
      throw boom.badImplementation(err);
    }
  }

  async updateAgreementFileReference(fileKey, agreementAddress, hoardGrant) {
    log.debug(`REQUEST: Update reference for  ${fileKey} for agreement at ${agreementAddress} with new reference ${hoardGrant}`);
    let data;
    try {
      const agreement = Contracts.getContract(BUNDLES.AGREEMENTS.contracts.ACTIVE_AGREEMENT, agreementAddress);
      switch (fileKey) {
        case 'EventLog':
          data = await agreement.setEventLogReference(hoardGrant);
          break;
        case 'SignatureLog':
          data = await agreement.setSignatureLogReference(hoardGrant);
          break;
        case 'PrivateParameters':
          data = await agreement.setPrivateParametersReference(hoardGrant);
          break;
        default:
          throw boom.badImplementation(`Did not recognize agreement file key: ${fileKey}`);
      }
      await this.interceptor(data);
    } catch (err) {
      throw boom.badImplementation(`Failed to set new reference ${hoardGrant} for ${fileKey} for agreement at ${agreementAddress}: ${err}`);
    }
  }

  createAgreementCollection(author, collectionType, packageId) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Create agreement collection by ${author} with type ${collectionType} ` +
    `and packageId ${packageId} created by user at ${author}`);
      appManager
        .contracts['ActiveAgreementRegistry']
        .factory.createAgreementCollection(author, collectionType, packageId)
        .then(this.interceptor)
        .then((data) => {
          if (!data.raw) {
            return reject(boom.badImplementation(`Failed to add agreement collection by ${author}: no result returned`));
          }
          if (parseInt(data.raw[0], 10) !== 1) {
            return reject(boom.badImplementation(`Error code adding agreement collection by ${author}: ${data.raw[0]}`));
          }
          log.info(`SUCCESS: Created new agreement collection by ${author} with id ${data.raw[1]}`);
          return resolve(data.raw[1]);
        })
        .catch(err => reject(boom.badImplementation(`Failed to add agreement collection by ${author}: ${err}`)));
    });
  }

  addAgreementToCollection(collectionId, agreement) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Add agreement at ${agreement} to collection ${collectionId}`);
      appManager
        .contracts['ActiveAgreementRegistry']
        .factory.addAgreementToCollection(collectionId, agreement)
        .then(this.interceptor)
        .then(() => {
          log.info(`SUCCESS: Added agreement at ${agreement} to collection with id ${collectionId}`);
          return resolve();
        })
        .catch(err => reject(boomify(err, `Failed to add agreement at ${agreement} to collection ${collectionId}`)));
    });
  }

  createUserInEcosystem(user, ecosystemAddress) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Create a new user with ID: ${user.username} in ecosystem at ${ecosystemAddress}`);
      appManager
        .contracts['ParticipantsManager']
        .factory.createUserAccount(user.username, '0x0', ecosystemAddress)
        .then(this.interceptor)
        .then((data) => {
          if (!data || !data.raw) throw new Error(NO_TRANSACTION_RESPONSE_ERR);
          log.info(`SUCCESS: Created new user ${user.username} at address ${data.raw[0]}`);
          return resolve(data.raw[0]);
        })
        .catch(error => reject(boom.badImplementation(`Failed to create user ${user.username}: ${error}`)));
    });
  }

  createUser(user) {
    return this.createUserInEcosystem(user, appManager.ecosystemAddress);
  }

  getUserByIdAndEcosystem(id, ecosystemAddress) {
    return new Promise((resolve, reject) => {
      log.trace(`REQUEST: Get user by id: ${id} in ecosystem at ${ecosystemAddress}`);
      const ecosystem = Contracts.getEcosystem(ecosystemAddress);
      ecosystem.getUserAccount(id)
        .then(this.interceptor)
        .then((data) => {
          if (!data.raw) throw boom.badImplementation(`Failed to get address for user with id ${id}`);
          log.trace(`SUCCESS: Retrieved user address ${data.raw[0]} by id ${id} and ecosystem ${ecosystemAddress}`);
          return resolve({
            address: data.raw[0],
          });
        })
        .catch(err => reject(boomify(err, `Failed to get address for user with id ${id}`)));
    });
  }

  getUserByUsername(username) {
    return this.getUserByIdAndEcosystem(username, appManager.ecosystemAddress);
  }

  getUserByUserId(userid) {
    return this.getUserByIdAndEcosystem(userid, appManager.ecosystemAddress);
  }

  addUserToEcosystem(username, address) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Add user ${username} with address ${address} to ecosystem at ${appManager.ecosystemAddress}`);
      const ecosystem = Contracts.getEcosystem(appManager.ecosystemAddress);
      ecosystem.addUserAccount(username, address)
        .then(this.interceptor)
        .then(() => {
          log.info(`SUCCESS: Successfully added user ${username} with address ${address} to ecosystem at ${appManager.ecosystemAddress}`);
          resolve();
        })
        .catch(err => reject(boomify(err, `Failed to add user with username ${username} and address ${address} to ecosystem`)));
    });
  }

  migrateUserAccountInEcosystem(userAddress, migrateFromId, migrateToId) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Migrate user account ${userAddress} from id ${migrateFromId} to id ${migrateToId}`);
      const ecosystem = Contracts.getEcosystem(appManager.ecosystemAddress);
      ecosystem
        .migrateUserAccount(userAddress, migrateFromId, migrateToId)
        .then(this.interceptor)
        .then(() => {
          log.info(`SUCCESS: Successfully migrated user account ${userAddress} from id ${migrateFromId} to id ${migrateToId}`);
          resolve();
        })
        .catch(err => reject(boomify(err, `Failed to migrate user account ${userAddress} from id ${migrateFromId} to id ${migrateToId}`)));
    });
  }

  addUserToOrganization(userAddress, organizationAddress, actingUserAddress) {
    return new Promise((resolve, reject) => {
      log.debug('REQUEST: Add user %s to organization %s', userAddress, organizationAddress);
      const organization = Contracts.getOrganization(organizationAddress);
      const payload = organization.addUser.encode(userAddress);
      this.callOnBehalfOf(actingUserAddress, organizationAddress, payload)
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
  }

  removeUserFromOrganization(userAddress, organizationAddress, actingUserAddress) {
    return new Promise((resolve, reject) => {
      log.debug('REQUEST: Remove user %s from organization %s', userAddress, organizationAddress);
      const organization = Contracts.getOrganization(organizationAddress);
      const payload = organization.removeUser.encode(userAddress);
      this.callOnBehalfOf(actingUserAddress, organizationAddress, payload)
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
  }

  addApproverToOrganization(approverAddress, organizationAddress, actingUserAddress) {
    return new Promise((resolve, reject) => {
      log.debug('REQUEST: Add approver %s to organization %s', approverAddress, organizationAddress);
      const organization = Contracts.getOrganization(organizationAddress);
      const payload = organization.addApprover.encode(approverAddress);
      this.callOnBehalfOf(actingUserAddress, organizationAddress, payload)
        .then(() => {
          log.info('SUCCESS: Approver %s successfully added to organization %s', approverAddress, organizationAddress);
          return resolve();
        })
        .catch((error) => {
          if (error.isBoom) return reject(error);
          return reject(boom.badImplementation(`Error forwarding addApprover request via acting approver ${actingUserAddress} to organization ${organizationAddress}! Error: ${error.stack}`));
        });
    });
  }

  removeApproverFromOrganization(approverAddress, organizationAddress, actingUserAddress) {
    return new Promise((resolve, reject) => {
      log.debug('REQUEST: Remove approver %s from organization %s', approverAddress, organizationAddress);
      const organization = Contracts.getOrganization(organizationAddress);
      const payload = organization.removeApprover.encode(approverAddress);
      this.callOnBehalfOf(actingUserAddress, organizationAddress, payload)
        .then(() => {
          log.info('SUCCESS: Approver %s successfully removed from organization %s', approverAddress, organizationAddress);
          return resolve();
        })
        .catch((error) => {
          if (error.isBoom) return reject(error);
          return reject(boom.badImplementation(`Error forwarding removeApprover request via acting approver ${actingUserAddress} to organization ${organizationAddress}! Error: ${error.stack}`));
        });
    });
  }

  createDepartment(organizationAddress, id, actingUserAddress) {
    return new Promise((resolve, reject) => {
      log.debug('REQUEST: Create department ID %s with name %s in organization %s', id, organizationAddress);
      const organization = Contracts.getOrganization(organizationAddress);
      const payload = organization.addDepartment.encode(id);
      this.callOnBehalfOf(actingUserAddress, organizationAddress, payload)
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
  }

  removeDepartment(organizationAddress, id, actingUserAddress) {
    return new Promise((resolve, reject) => {
      log.debug('REQUEST: Remove department %s from organization %s', id, organizationAddress);
      const organization = Contracts.getOrganization(organizationAddress);
      const payload = organization.removeDepartment.encode(id);
      this.callOnBehalfOf(actingUserAddress, organizationAddress, payload)
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
  }

  addDepartmentUser(organizationAddress, depId, userAddress, actingUserAddress) {
    return new Promise((resolve, reject) => {
      log.debug('REQUEST: Add user %s to department ID in organization %s', userAddress, depId, organizationAddress);
      const organization = Contracts.getOrganization(organizationAddress);
      const payload = organization.addUserToDepartment.encode(userAddress, depId);
      this.callOnBehalfOf(actingUserAddress, organizationAddress, payload)
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
  }

  removeDepartmentUser(organizationAddress, depId, userAddress, actingUserAddress) {
    return new Promise((resolve, reject) => {
      log.debug('REQUEST: Remove user %s from department ID %s in organization %s', userAddress, depId, organizationAddress);
      const organization = Contracts.getOrganization(organizationAddress);
      const payload = organization.removeUserFromDepartment.encode(userAddress, depId);
      this.callOnBehalfOf(actingUserAddress, organizationAddress, payload)
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
  }

  createProcessModel(modelId, modelVersion, author, isPrivate, modelFileReference) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Create process model with following data: ${JSON.stringify({
        modelId,
        modelVersion,
        author,
        isPrivate,
        modelFileReference,
      })}`);
      const modelIdHex = hexFromString(modelId);
      appManager
        .contracts['ProcessModelRepository']
        .factory.createProcessModel(modelIdHex, modelVersion, author, isPrivate, modelFileReference)
        .then(this.interceptor)
        .then((data) => {
          log.info(`SUCCESS: Model with Id ${modelId} created at ${data.raw[1]}`);
          return resolve(data.raw[1]);
        })
        .catch(err => reject(boomify(err, `Failed to create process model with id ${modelId}: ${JSON.stringify(err)}`)));
    });
  }

  addDataDefinitionToModel(pmAddress, dataStoreField) {
    return new Promise((resolve, reject) => {
      const processModel = Contracts.getContract(BUNDLES.BPM_MODEL.contracts.PROCESS_MODEL, pmAddress);
      log.debug('REQUEST: Add data definition %s to process model %s', JSON.stringify(dataStoreField), pmAddress);
      const dataIdHex = hexFromString(dataStoreField.dataStorageId);
      const dataPathHex = hexFromString(dataStoreField.dataPath);
      processModel.addDataDefinition(dataIdHex, dataPathHex, dataStoreField.parameterType)
        .then(this.interceptor)
        .then(() => {
          log.info('SUCCESS: Data definition %s added to Process Model at %s', JSON.stringify(dataStoreField), pmAddress);
          return resolve(dataStoreField);
        })
        .catch(err => reject(boom
          .badImplementation(`Failed to add data definition for dataId: ${dataStoreField.dataStorageId}, dataPath: ${dataStoreField.dataPath}, parameterType: ${dataStoreField.parameterType}: ${err}`)));
    });
  }

  addProcessInterface(pmAddress, interfaceId) {
    return new Promise((resolve, reject) => {
      const processModel = Contracts.getContract(BUNDLES.BPM_MODEL.contracts.PROCESS_MODEL, pmAddress);
      log.debug(`REQUEST: Add process interface ${interfaceId} to process model at ${pmAddress}`);
      const interfaceIdHex = hexFromString(interfaceId);
      processModel.addProcessInterface(interfaceIdHex)
        .then(this.interceptor)
        .then((data) => {
          if (!data.raw) {
            return reject(boom
              .badImplementation(`Failed to add process interface ${interfaceId}to model at ${pmAddress}: no data`));
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
        })
        .catch(err => reject(boom
          .badImplementation(`Failed to add process interface ${interfaceId}to model at ${pmAddress}: ${err}`)));
    });
  }

  addParticipant(pmAddress, participantId, accountAddress, dataPath, dataStorageId, dataStorageAddress) {
    return new Promise((resolve, reject) => {
      const processModel = Contracts.getContract(BUNDLES.BPM_MODEL.contracts.PROCESS_MODEL, pmAddress);
      log.debug(`REQUEST: Add participant ${participantId} to process model at ${pmAddress} with data: ${JSON.stringify({
        accountAddress,
        dataPath,
        dataStorageId,
        dataStorageAddress,
      })}`);
      const participantIdHex = hexFromString(participantId);
      const dataPathHex = hexFromString(dataPath);
      const dataStorageIdHex = hexFromString(dataStorageId);
      log.debug(`Adding a participant with ID: ${participantId}`);
      processModel.addParticipant(participantIdHex, accountAddress, dataPathHex, dataStorageIdHex, dataStorageAddress)
        .then(this.interceptor)
        .then((data) => {
          if (!data.raw) {
            return reject(boom
              .badImplementation(`Failed to add participant ${participantId} to model ${pmAddress}: no result returned`));
          }
          if (parseInt(data.raw[0], 10) !== 1) {
            return reject(boom
              .badImplementation(`Error code while adding participant ${participantId} to model ${pmAddress}: ${data.raw[0]}`));
          }
          log.info(`SUCCESS: Participant ${participantId} added to model ${pmAddress}`);
          return resolve();
        })
        .catch(err => reject(boom
          .badImplementation(`Failed to add participant ${participantId} to model ${pmAddress}: ${err}`)));
    });
  }

  createProcessDefinition(modelAddress, processDefnId) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Create process definition with Id ${processDefnId} for process model ${modelAddress}`);
      const processDefnIdHex = hexFromString(processDefnId);
      appManager
        .contracts['ProcessModelRepository']
        .factory.createProcessDefinition(modelAddress, processDefnIdHex)
        .then(this.interceptor)
        .then((data) => {
          if (!data.raw) {
            return reject(boom
              .badImplementation(`Failed to create process definition ${processDefnId} in model at ${modelAddress}: no result returned`));
          }
          log.info(`SUCCESS: Process definition ${processDefnId} in model at ${modelAddress} created at ${data.raw[0]}`);
          return resolve(data.raw[0]);
        })
        .catch(err => reject(boom
          .badImplementation(`Failed to create process definition ${processDefnId} in model at ${modelAddress}: ${err}`)));
    });
  }

  addProcessInterfaceImplementation(pmAddress, pdAddress, interfaceId) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Add process interface implementation ${interfaceId} to process definition ${pdAddress} for process model ${pmAddress}`);
      const processDefinition = Contracts.getContract(BUNDLES.BPM_MODEL.contracts.PROCESS_DEFINITION, pdAddress);
      const interfaceIdHex = hexFromString(interfaceId);
      processDefinition.addProcessInterfaceImplementation(pmAddress, interfaceIdHex)
        .then(this.interceptor)
        .then((data) => {
          if (!data.raw) {
            return reject(boom.badImplementation(`Failed to add interface implementation ${interfaceId} to process at ${pdAddress}: no result returned`));
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
        })
        .catch(err => reject(boom.badImplementation(`Failed to add interface implementation ${interfaceId} to process at ${pdAddress}: ${err}`)));
    });
  }

  createActivityDefinition(processAddress, activityId, activityType, taskType, behavior, assignee, multiInstance, application, subProcessModelId, subProcessDefinitionId) {
    return new Promise((resolve, reject) => {
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
      const processDefinition = Contracts.getContract(BUNDLES.BPM_MODEL.contracts.PROCESS_DEFINITION, processAddress);
      processDefinition.createActivityDefinition(hexFromString(activityId), activityType, taskType, behavior,
        hexFromString(assignee), multiInstance, hexFromString(application), hexFromString(subProcessModelId),
        hexFromString(subProcessDefinitionId))
        .then(this.interceptor)
        .then((data) => {
          if (!data.raw) {
            return reject(boom
              .badImplementation(`Failed to create activity definition ${activityId} in process at ${processAddress}: no result found`));
          }
          if (parseInt(data.raw[0], 10) !== 1) {
            return reject(boom
              .badImplementation(`Error code creating activity definition ${activityId} in process at ${processAddress}: ${data.raw[0]}`));
          }
          log.info(`SUCCESS: Activity definition ${activityId} created in process at ${processAddress}`);
          return resolve();
        })
        .catch(err => reject(boom
          .badImplementation(`Failed to create activity definition ${activityId} in process at ${processAddress}: ${err}`)));
    });
  }

  createDataMapping(processAddress, id, direction, accessPath, dataPath, dataStorageId, dataStorage) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Create data mapping with data: ${JSON.stringify({
        processAddress,
        id,
        direction,
        accessPath,
        dataPath,
        dataStorageId,
        dataStorage,
      })}`);
      const processDefinition = Contracts.getContract(BUNDLES.BPM_MODEL.contracts.PROCESS_DEFINITION, processAddress);
      processDefinition.createDataMapping(hexFromString(id), direction, hexFromString(accessPath),
        hexFromString(dataPath), hexFromString(dataStorageId), dataStorage)
        .then(this.interceptor)
        .then(() => {
          log.info(`SUCCESS: Data mapping created for activityId ${id} in process at ${processAddress}`);
          return resolve();
        })
        .catch(err => reject(boom
          .badImplementation(`Failed to create data mapping for activity ${id} in process at ${processAddress}: ${err}`)));
    });
  }

  createGateway(processAddress, gatewayId, gatewayType) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Create gateway with data: ${JSON.stringify({ processAddress, gatewayId, gatewayType })}`);
      const processDefinition = Contracts.getContract(BUNDLES.BPM_MODEL.contracts.PROCESS_DEFINITION, processAddress);
      processDefinition.createGateway(hexFromString(gatewayId), gatewayType)
        .then(this.interceptor)
        .then(() => {
          log.info(`SUCCESS: Gateway created with id ${gatewayId} and type ${gatewayType} in process at ${processAddress}`);
          return resolve();
        })
        .catch(err => reject(boom
          .badImplementation(`Failed to create gateway with id ${gatewayId} and type ${gatewayType} in process at ${processAddress}: ${err}`)));
    });
  }

  createTransition(processAddress, sourceGraphElement, targetGraphElement) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Create transition with data: ${JSON.stringify({
        processAddress,
        sourceGraphElement,
        targetGraphElement,
      })}`);
      const processDefinition = Contracts.getContract(BUNDLES.BPM_MODEL.contracts.PROCESS_DEFINITION, processAddress);
      processDefinition.createTransition(hexFromString(sourceGraphElement), hexFromString(targetGraphElement))
        .then(this.interceptor)
        .then((data) => {
          if (!data.raw) {
            return reject(boom
              .badImplementation(`Failed to create transition from ${sourceGraphElement} to ${targetGraphElement} in process at ${processAddress}: no result found`));
          }
          if (parseInt(data.raw[0], 10) !== 1) {
            return reject(boom
              .badImplementation(`Error code creating transition from ${sourceGraphElement} to ${targetGraphElement} in process at ${processAddress}: ${data.raw[0]}`));
          }
          log.info(`SUCCESS: Transition created from ${sourceGraphElement} to ${targetGraphElement} in process at ${processAddress}`);
          return resolve();
        })
        .catch(err => reject(boom
          .badImplementation(`Failed to create transition from ${sourceGraphElement} to ${targetGraphElement} in process at ${processAddress}: ${err}`)));
    });
  }

  setDefaultTransition(processAddress, gatewayId, activityId) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Set default transition with data: ${JSON.stringify({ processAddress, gatewayId, activityId })}`);
      const processDefinition = Contracts.getContract(BUNDLES.BPM_MODEL.contracts.PROCESS_DEFINITION, processAddress);
      processDefinition.setDefaultTransition(hexFromString(gatewayId), hexFromString(activityId))
        .then(this.interceptor)
        .then(() => {
          log.info(`SUCCESS: Default transition set between gateway ${gatewayId} and model element ${activityId} in process at ${processAddress}`);
          return resolve();
        })
        .catch(error => reject(boom
          .badImplementation(`Failed to set default transition between gateway ${gatewayId} and activity ${activityId} in process at ${processAddress}: ${error}`)));
    });
  }

  static getTransitionConditionFunctionByDataType(processAddress, dataType) {
    const processDefinition = Contracts.getContract(BUNDLES.BPM_MODEL.contracts.PROCESS_DEFINITION, processAddress);
    const functions = {};
    functions[`${DATA_TYPES.BOOLEAN}`] = processDefinition.createTransitionConditionForBool;
    functions[`${DATA_TYPES.STRING}`] = processDefinition.createTransitionConditionForString;
    functions[`${DATA_TYPES.BYTES32}`] = processDefinition.createTransitionConditionForBytes32;
    functions[`${DATA_TYPES.UINT}`] = processDefinition.createTransitionConditionForUint;
    functions[`${DATA_TYPES.INT}`] = processDefinition.createTransitionConditionForInt;
    functions[`${DATA_TYPES.ADDRESS}`] = processDefinition.createTransitionConditionForAddress;
    return functions[dataType];
  }

  createTransitionCondition(processAddress, dataType, gatewayId, activityId, dataPath, dataStorageId, dataStorage, operator, value) {
    return new Promise((resolve, reject) => {
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
      const createFunction = Contracts.getTransitionConditionFunctionByDataType(processAddress, dataType);
      let formattedValue;
      if (dataType === DATA_TYPES.UINT || dataType === DATA_TYPES.INT) {
        formattedValue = parseInt(value, 10);
        log.debug('Converted value to integer: %d', formattedValue);
      } else if (dataType === DATA_TYPES.BOOLEAN) {
        formattedValue = (typeof value === 'string') ? (value.toLowerCase() === 'true') : Boolean(value);
        log.debug('Converted value to boolean: %s', formattedValue);
      } else if (dataType === DATA_TYPES.BYTES32) {
        formattedValue = hexFromString(value);
        log.debug('Converted value to bytes32: %s', formattedValue);
      } else {
        formattedValue = value;
      }
      createFunction(hexFromString(gatewayId), hexFromString(activityId), hexFromString(dataPath),
        hexFromString(dataStorageId), dataStorage, operator, formattedValue)
        .then(this.interceptor)
        .then(() => {
          log.info(`SUCCESS: Transition condition created for gateway id ${gatewayId} and activity id ${activityId} in process at address ${processAddress}`);
          return resolve();
        })
        .catch(error => reject(boom.badImplementation('Failed to add transition condition for gateway id ' +
        `${gatewayId} and activity id ${activityId} in process at address ${processAddress}: ${error}`)));
    });
  }

  signAgreement(actingUserAddress, agreementAddress) {
    return new Promise(async (resolve, reject) => {
      log.debug('REQUEST: Sign agreement %s by user %s', agreementAddress, actingUserAddress);
      try {
        const agreement = Contracts.getContract(BUNDLES.AGREEMENTS.contracts.ACTIVE_AGREEMENT, agreementAddress);
        const payload = agreement.sign.encode();
        await this.callOnBehalfOf(actingUserAddress, agreementAddress, payload);
        log.info('SUCCESS: Agreement %s signed by user %s', agreementAddress, actingUserAddress);
        return resolve();
      } catch (error) {
        return reject(boom.badImplementation(`Error forwarding sign request via acting user ${actingUserAddress} to agreement ${agreementAddress}! Error: ${error.stack}`));
      }
    });
  }

  isAgreementSignedBy(agreementAddress, userAddress) {
    return new Promise(async (resolve, reject) => {
      log.debug('REQUEST: Checking if agreement at %s has been signed by user at %s', agreementAddress, userAddress);
      try {
        const agreement = Contracts.getContract(BUNDLES.AGREEMENTS.contracts.ACTIVE_AGREEMENT, agreementAddress);
        const payload = agreement.isSignedBy.encode(userAddress);
        const response = await this.callOnBehalfOf(userAddress, agreementAddress, payload);
        const data = agreement.isSignedBy.decode(response);
        const isSignedBy = data.raw[0].valueOf();
        log.info('SUCCESS: Checked if agreement at %s has been signed by user at %s:', agreementAddress, userAddress);
        return resolve(isSignedBy);
      } catch (err) {
        return reject(boom.badImplementation(`Error determining if agreement at ${agreementAddress} has been signed by user at ${userAddress}: ${err.stack}`));
      }
    });
  }

  async cancelAgreement(actingUserAddress, agreementAddress) {
    log.debug('REQUEST: Cancel agreement %s by user %s', agreementAddress, actingUserAddress);
    const agreement = Contracts.getContract(BUNDLES.AGREEMENTS.contracts.ACTIVE_AGREEMENT, agreementAddress);
    const payload = agreement.cancel.encode();
    return this.callOnBehalfOf(actingUserAddress, agreementAddress, payload);
  }

  async redactAgreement(actingUserAddress, agreementAddress) {
    log.debug('REQUEST: Redact agreement %s by user %s', agreementAddress, actingUserAddress);
    const agreement = Contracts.getContract(BUNDLES.AGREEMENTS.contracts.ACTIVE_AGREEMENT, agreementAddress);
    const payload = agreement.redact.encode();
    return this.callOnBehalfOf(actingUserAddress, agreementAddress, payload);
  }

  completeActivity(actingUserAddress, activityInstanceId, dataMappingId = null, dataType = null, value = null) {
    return new Promise(async (resolve, reject) => {
      log.debug('REQUEST: Complete task %s by user %s', activityInstanceId, actingUserAddress);
      try {
        const bpmService = appManager.contracts['BpmService'];
        const piAddress = await bpmService.factory.getProcessInstanceForActivity(activityInstanceId)
          .then(this.interceptor)
          .then(data => data.raw[0]);
        log.info('Found process instance %s for activity instance ID %s', piAddress, activityInstanceId);
        const processInstance = Contracts.getContract(BUNDLES.BPM_RUNTIME.contracts.PROCESS_INSTANCE, piAddress);
        let payload;
        if (dataMappingId) {
          log.info('Completing activity with OUT data mapping ID:Value (%s:%s) for activityInstance %s in process instance %s', dataMappingId, value, activityInstanceId, piAddress);
          const hexDataMappingId = hexFromString(dataMappingId);
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

        const returnData = await this.callOnBehalfOf(actingUserAddress, piAddress, payload);

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
  }

  getModelAddressFromId(modelId) {
    log.debug(`REQUEST: Get model address for model id ${modelId}`);
    return new Promise((resolve, reject) => {
      appManager.contracts['ProcessModelRepository'].factory.getModel(hexFromString(modelId))
        .then(this.interceptor)
        .then((data) => {
          if (!data.raw) return reject(boom.badImplementation(`Failed to get address of model with id ${modelId}: no result returned`));
          log.info(`SUCCESS: Retrieved model address ${data.raw[0]} for model id ${modelId}`);
          return resolve(data.raw[0]);
        })
        .catch(err => reject(boom.badImplementation(`Failed to get address of model with id ${modelId}: ${err}`)));
    });
  }

  getProcessDefinitionAddress(modelId, processId) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Get process definition address for model Id ${modelId} and process Id ${processId}`);
      const modelIdHex = hexFromString(modelId);
      const processIdHex = hexFromString(processId);
      appManager.contracts['ProcessModelRepository']
        .factory.getProcessDefinition(modelIdHex, processIdHex)
        .then(this.interceptor)
        .then((data) => {
          if (!data.raw) {
            return reject(boom
              .badImplementation(`Failed to get address of process definition with id ${processId} in model ${modelId}: no result returned`));
          }
          log.info(`SUCCESS: Retrieved process definition address ${data.raw[0]} for model id ${modelId} and process id ${processId}`);
          return resolve(data.raw[0]);
        })
        .catch(err => reject(boom
          .badImplementation(`Failed to get address of process definition with id ${processId} in model ${modelId}: ${err}`)));
    });
  }

  isValidProcess(processAddress) {
    return new Promise((resolve, reject) => {
      const processDefinition = Contracts.getContract(BUNDLES.BPM_MODEL.contracts.PROCESS_DEFINITION, processAddress);
      log.debug(`REQUEST: Validate process definition at address: ${processAddress}`);
      processDefinition.validate()
        .then(this.interceptor)
        .then((data) => {
          if (!data.raw) {
            return reject(boom
              .badImplementation(`Failed to validate process at ${processAddress}: no result returned`));
          }
          if (!data.raw[0]) {
            return reject(boom
              .badImplementation(`Invalid process definition at ${processAddress}: ${hexToString(data.raw[1].valueOf())}`));
          }
          log.info(`SUCCESS: Process Definition at ${processAddress} validated`);
          return resolve(data.raw[0]);
        })
        .catch(err => reject(boom.badImplementation(`Failed to validate process at ${processAddress}: ${err}`)));
    });
  }

  startProcessFromAgreement(agreementAddress) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Start formation process from agreement at address: ${agreementAddress}`);
      appManager.contracts['ActiveAgreementRegistry'].factory.startProcessLifecycle(agreementAddress)
        .then(this.interceptor)
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
  }

  getStartActivity(processAddress) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Get start activity id for process at address: ${processAddress}`);
      const processDefinition = Contracts.getContract(BUNDLES.BPM_MODEL.contracts.PROCESS_DEFINITION, processAddress);
      processDefinition.getStartActivity()
        .then(this.interceptor)
        .then((data) => {
          if (!data.raw) throw boom.badImplementation(NO_TRANSACTION_RESPONSE_ERR);
          const activityId = hexToString(data.raw[0]);
          log.info(`SUCCESS: Retrieved start activity id ${activityId} for process at ${processAddress}`);
          return resolve(activityId);
        })
        .catch((err) => {
          if (err.isBoom) return reject(err);
          return reject(boom.badImplementation(boom.badImplementation(`Failed to get start activity for process: ${err.stack}`)));
        });
    });
  }

  getProcessInstanceCount() {
    return new Promise((resolve, reject) => {
      log.debug('REQUEST: Get process instance count');
      appManager.contracts['BpmService']
        .factory.getNumberOfProcessInstances()
        .then(this.interceptor)
        .then((data) => {
          if (!data.raw) return reject(boom.badImplementation('Failed to get process instance count: no result returned'));
          log.info(`SUCCESS: Retrievef process instance count: ${data.raw[0]}`);
          return resolve(data.raw[0]);
        })
        .catch(err => reject(boom.badImplementation(`Failed to get process instance count: ${err}`)));
    });
  }

  getProcessInstanceForActivity(activityInstanceId) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Get process instance for activity ${activityInstanceId}`);
      appManager
        .contracts['BpmService']
        .factory.getProcessInstanceForActivity(activityInstanceId)
        .then(this.interceptor)
        .then((data) => {
          if (!data.raw) {
            return reject(boom
              .badImplementation(`Failed to get process instance for activity with id ${activityInstanceId}: no result returned`));
          }
          log.info(`SUCCESS: Retrieved process instance for activity ${activityInstanceId}: ${data.raw[0].valueOf()}`);
          return resolve(data.raw[0].valueOf());
        })
        .catch(err => reject(boom
          .badImplementation(`Failed to get process instance for activity with id ${activityInstanceId}: ${err}`)));
    });
  }

  getDataMappingKeys(processDefinition, activityId, direction) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Get data mapping keys for process definition at ${processDefinition}, activity ${activityId} and direction ${direction}`);
      const countPromise = direction === DIRECTION.IN ?
        processDefinition.getInDataMappingKeys :
        processDefinition.getOutDataMappingKeys;
      countPromise(hexFromString(activityId))
        .then(this.interceptor)
        .then((data) => {
          if (!data.raw) {
            return reject(boom
              .badImplementation(`Failed to get ${direction ? 'out-' : 'in-'}data mapping ids for activity ${activityId}: no result returned`));
          }
          if (data.raw[0] && Array.isArray(data.raw[0])) {
            const keys = data.raw[0].map(elem => hexToString(elem));
            log.info(`SUCCESS: Retrieved data mapping keys for process definition at ${processDefinition}, activity ${activityId} and direction ${direction}: ${JSON.stringify(keys)}`);
            return resolve(keys);
          }
          log.info(`SUCCESS: No data mapping keys found for process definition at ${processDefinition}, activity ${activityId} and direction ${direction}`);
          return resolve([]);
        })
        .catch(err => reject(boom
          .badImplementation(`Failed to get ${direction ? 'out-' : 'in-'}data mapping ids for activity ${activityId}: ${err}`)));
    });
  }

  getDataMappingDetails(processDefinition, activityId, dataMappingIds, direction) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Get data mapping details for process definition at ${processDefinition}, activity ${activityId}, data mapping ids ${JSON.stringify(dataMappingIds)} and direction ${direction}`);
      const dataPromises = [];
      dataMappingIds.forEach((dataMappingId) => {
        const getter = direction === DIRECTION.IN ?
          processDefinition.getInDataMappingDetails : processDefinition.getOutDataMappingDetails;
        dataPromises.push(getter(hexFromString(activityId), hexFromString(dataMappingId)).then(this.interceptor));
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
  }

  async getDataMappingDetailsForActivity(pdAddress, activityId, dataMappingIds = [], direction) {
    log.debug(`REQUEST: Get ${direction ? 'out-' : 'in-'}data mapping details for activity ${activityId} in process definition at ${pdAddress}`);
    const processDefinition = Contracts.getContract(BUNDLES.BPM_MODEL.contracts.PROCESS_DEFINITION, pdAddress);
    try {
      const keys = dataMappingIds || (await this.getDataMappingKeys(processDefinition, activityId, direction)); // NOTE: activityId are hex converted inside getDataMappingKeys and not here
      const details = await this.getDataMappingDetails(processDefinition, activityId, keys, direction); // NOTE: activityId and dataMappingIds are hex converted inside getDataMappingDetails and not here
      log.info(`SUCCESS: Retrieved ${direction ? 'out-' : 'in-'}data mapping details for activity ${activityId} in process definition at ${pdAddress}`);
      return details;
    } catch (err) {
      if (boom.isBoom(err)) {
        throw err;
      } else {
        throw boom.badImplementation(`Failed to get data mapping details for process definition at ${pdAddress} and activityId ${activityId}`);
      }
    }
  }

  /**
   * Returns the addresses for the formation and execution processes for the archetype identified by the given address
   * @param {string} archAddress - the address of an archetype
   * @return {Object} {formation: string, execution: string}
   */
  getArchetypeProcesses(archAddress) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Get formation and execution processes for archetype at address ${archAddress}`);
      let formation;
      let execution;
      appManager.contracts['ArchetypeRegistry']
        .factory.getArchetypeData(archAddress)
        .then(this.interceptor)
        .then((data) => {
          if (!data.values) return reject(boom.badImplementation('Failed to get archetype processes: no result returned'));
          formation = data.values.formationProcessDefinition ? data.values.formationProcessDefinition.valueOf() : '';
          execution = data.values.executionProcessDefinition ? data.values.executionProcessDefinition.valueOf() : '';
          log.info(`SUCCESS: Retreived processes for archetype ${archAddress}. Formation: ${formation}, Execution: ${execution}}`);
          return resolve({ formation, execution });
        })
        .catch(err => reject(boom.badImplementation(`Failed to get archetype processes: ${err}`)));
    });
  }

  getActivityInstanceData(piAddress, activityInstanceId) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Get activity instance data for activity id ${activityInstanceId} in process instance at address ${piAddress}`);
      appManager
        .contracts['BpmService']
        .factory.getActivityInstanceData(piAddress, activityInstanceId)
        .then(this.interceptor)
        .then((data) => {
          if (!data.raw) {
            return reject(boom
              .badImplementation(`Failed to get data for activity instance with id ${activityInstanceId} in process instance at ${piAddress}: no result returned`));
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
        })
        .catch(err => reject(boom
          .badImplementation(`Failed to get data for activity instance with id ${activityInstanceId} in process instance at ${piAddress}: ${err}`)));
    });
  }

  getActiveAgreementData(agreementAddress) {
    return new Promise((resolve, reject) => {
      log.debug(`REQUEST: Get data for agreement at address ${agreementAddress}`);
      appManager
        .contracts['ActiveAgreementRegistry']
        .factory.getActiveAgreementData(agreementAddress)
        .then(this.interceptor)
        .then((data) => {
          if (!data.raw) {
            return reject(boom
              .badImplementation(`Failed to get data of agreement at ${agreementAddress}: no result returned`));
          }
          const agData = {
            archetype: data.raw[0] ? data.raw[0].valueOf() : '',
            name: data.raw[1] ? hexToString(data.raw[1].valueOf()) : '',
            creator: data.raw[2] ? data.raw[2].valueOf() : '',
            maxNumberOfAttachments: data.raw[7] ? data.raw[7].valueOf() : '',
            isPrivate: data.raw[8] ? data.raw[8].valueOf() : '',
            legalState: data.raw[9] ? data.raw[9].valueOf() : '',
            formationProcessInstance: data.raw[10] ? data.raw[10].valueOf() : '',
            executionProcessInstance: data.raw[11] ? data.raw[11].valueOf() : '',
          };
          log.info(`SUCCESS: Retrieved data for agreement at ${agreementAddress}: ${JSON.stringify(agData)}`);
          return resolve(agData);
        })
        .catch(err => reject(boom
          .badImplementation(`Failed to get data of agreement at ${agreementAddress}: ${err}`)));
    });
  }
}

module.exports = Contracts;
