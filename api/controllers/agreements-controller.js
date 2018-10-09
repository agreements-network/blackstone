const path = require('path');
const boom = require('boom');
const Joi = require('joi');
const Analytics = require('analytics-node');
const _ = require('lodash');
const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const {
  encrypt,
  decrypt,
  format,
  splitMeta,
  addMeta,
  asyncMiddleware,
  getBooleanFromString,
} = require(`${global.__common}/controller-dependencies`);
const pool = require(`${global.__common}/postgres-db`);
const pgCache = require('./postgres-cache-helper');
const contracts = require('./contracts-controller');
const dataStorage = require(path.join(global.__controllers, 'data-storage-controller'));
const archetypeSchema = require(`${global.__schemas}/archetype`);
const agreementSchema = require(`${global.__schemas}/agreement`);
const { hoard } = require(`${global.__controllers}/hoard-controller`);
const logger = require(`${global.__common}/monax-logger`);
const log = logger.getLogger('agreements');
const sqlCache = require('./sqlsol-query-helper');
const { PARAMETER_TYPE: PARAM_TYPE, AGREEMENT_PARTIES } = global.__monax_constants;

const analytics = new Analytics(global.__settings.monax.analyticsID);

const getArchetypes = asyncMiddleware(async (req, res) => {
  const retData = [];
  const archData = await sqlCache.getArchetypeData(req.query, req.user.address);
  const jurisData = await sqlCache.getArchetypeJurisdictionsAll();
  archData.forEach((_archetype) => {
    const archetype = Object.assign(_archetype, { countries: [] });
    jurisData.forEach((juris) => {
      if (juris.address === archetype.address) archetype.countries.push(global.hexToString(juris.country));
    });
    retData.push(format('Archetype', archetype));
  });
  res.json(retData);
});

const getDocumentsFromHoard = (docMetadata, password) => {
  // Don't just decrypt. Also fetch each one and resolve name. replace name in the colomn
  if (docMetadata.length > 0) {
    const promises = docMetadata.map((_doc) => {
      const doc = Object.assign(_doc, {
        secretKey: decrypt(Buffer.from(_doc.secretKey, 'hex'), password).toString('hex').toUpperCase(),
      });
      const ref = {
        address: Buffer.from(doc.hoardAddress, 'hex'),
        secretKey: Buffer.from(doc.secretKey, 'hex'),
      };
      return hoard.get(ref).then((_data) => {
        const data = splitMeta(_data);
        doc.name = data.meta.name;
        return format('Document', doc);
      });
    });
    return Promise.all(promises)
      .then(documents => Promise.resolve(documents))
      .catch((err) => {
        log.error(`Failed to get documents: ${err}`);
        return Promise.reject(boom.unauthorized('Archetype could not be unlocked'));
      });
  }
  return {};
};

const getArchetype = asyncMiddleware(async (req, res) => {
  const password = req.query.password || null;
  let data;
  if (!req.params.address) throw boom.badRequest('Archetype address is required');
  data = await sqlCache.getArchetypeDataWithProcessDefinitions(req.params.address, req.user.address);
  if (!data) throw boom.notFound(`Archetype at ${req.params.address} not found or user has insufficient privileges`);
  data = format('Archetype', data);
  const formationProcess = await pgCache.populateProcessNames([
    {
      modelId: data.formationModelId,
      modelAddress: data.formationModelAddress,
      processDefinitionId: data.formationProcessId,
    }]);
  const executionProcess = await pgCache.populateProcessNames([
    {
      modelId: data.executionModelId,
      modelAddress: data.executionModelAddress,
      processDefinitionId: data.executionProcessId,
    }]);
  data.formationProcessName = formationProcess[0].processName;
  data.executionProcessName = executionProcess[0].processName;
  delete data.formationModelId;
  delete data.formationProcessId;
  delete data.executionModelId;
  delete data.executionProcessId;
  data.parameters = await sqlCache.getArchetypeParameters(req.params.address);
  // Early return if you only are fetching meta data
  if (getBooleanFromString(req.query.meta)) {
    data.documents = [];
    return res.json(data);
  }
  data.jurisdictions = await sqlCache.getArchetypeJurisdictions(req.params.address);
  const documentMetadata = await sqlCache.getArchetypeDocuments(req.params.address);
  data.documents = await getDocumentsFromHoard(documentMetadata, password);
  data.packages = await sqlCache.getPackagesOfArchetype(req.params.address);
  const governingArchetypes = await sqlCache.getGoverningArchetypes(req.params.address);
  data.governingArchetypes = governingArchetypes.map(arch => format('Archetype', arch));
  return res.status(200).json(data);
});

const createArchetype = asyncMiddleware(async (req, res) => {
  const password = req.body.password || null;
  if (!req.body || Object.keys(req.body).length === 0) throw boom.badRequest('Archetype data required');
  let type = req.body;
  type.parameters = type.parameters || [];
  // TODO: Revisit setting of archetype author
  // The author is overwritten with the logged-in-user's address for now
  // since we do not yet have a review/approval process
  // for changes made to an organization-authored archetype
  // by a user who is part of that organization
  type.author = req.user.address;
  log.debug(`Request to create new archetype: ${type.name}`);
  const { value, error } = Joi.validate(type, archetypeSchema, { abortEarly: false });
  if (error) throw boom.badRequest(`Required fields missing or malformed: ${error}`);
  type = value;
  type.governingArchetypes = type.governingArchetypes || [];
  type.description = _.escape(type.description);
  type.price = parseFloat(type.price, 10);
  type.active = type.active || false;
  if (type.packageId) {
    const packageData = await sqlCache.getArchetypePackages({ package_key: type.packageId }, req.user.address);
    if (!packageData) throw boom.badRequest(`Given packageId ${type.packageId} does not exist, or may not be accessible to user`);
    if (packageData.author !== req.user.address) throw boom.forbidden(`Package with id ${type.packageId} is not modifiable by user at address ${req.user.address}`);
    if (type.isPrivate && !packageData.isPrivate) throw boom.badRequest(`Private archetype ${type.name} cannot be added to public package with id ${type.packageId}`);
  }
  const archetypeAddress = await contracts.createArchetype(type);
  if (type.parameters.length > 0) {
    await contracts.addArchetypeParameters(archetypeAddress, type.parameters);
  }
  if (type.documents) {
    const docs = [];
    type.documents.forEach((_obj) => {
      // Set document name to hoard address
      const obj = Object.assign({}, _obj);
      obj.name = obj.hoardAddress;
      if (password != null) {
        obj.secretKey = encrypt(
          Buffer.from(obj.secretKey, 'hex'),
          password,
        ).toString('hex');
      }
      docs.push(obj);
    });
    await contracts.addArchetypeDocuments(archetypeAddress, docs);
  }
  if (type.jurisdictions) {
    await contracts.addJurisdictions(archetypeAddress, type.jurisdictions);
  }

  analytics.track({
    event: 'Archetype created',
    userId: req.user.id,
    properties: {
      userContract: req.user.address,
      archetypeContract: archetypeAddress,
    },
  });

  return res
    .status(200)
    .set('content-type', 'application/json')
    .json({ address: archetypeAddress });
});

const activateArchetype = asyncMiddleware(async (req, res) => {
  const archetype = req.params.address;
  const user = req.user.address;
  const author = await contracts.getArchetypeAuthor(archetype);
  if (user !== author) throw boom.unauthorized(`User at ${user} is not authorized to activate archetype at ${archetype}`);
  await contracts.activateArchetype(archetype, user);
  return res.sendStatus(200);
});

const deactivateArchetype = asyncMiddleware(async (req, res) => {
  const archetype = req.params.address;
  const user = req.user.address;
  const author = await contracts.getArchetypeAuthor(archetype);
  if (user !== author) throw boom.unauthorized(`User at ${user} is not authorized to deactivate archetype at ${archetype}`);
  await contracts.deactivateArchetype(archetype, user);
  return res.sendStatus(200);
});

const setArchetypeSuccessor = asyncMiddleware(async (req, res) => {
  const { address: archetype, successor } = req.params;
  if (!archetype) throw boom.badRequest('Archetype address must be supplied');
  await contracts.setArchetypeSuccessor(archetype, successor || 0x0, req.user.address);
  return res.sendStatus(200);
});

const getArchetypeSuccessor = asyncMiddleware(async (req, res) => {
  const { archetype } = req.params;
  if (!archetype) throw boom.badRequest('Archetype address must be supplied');
  const successor = await contracts.getArchetypeSuccessor(archetype, req.user.address);
  return res.sendStatus({ address: successor });
});

const updateArchetypeConfiguration = asyncMiddleware(async (req, res) => {
  if (!req.params.address) throw boom.badRequest('Archetype address required');
  if (!req.body || Object.keys(req.body).length === 0) {
    throw boom.badRequest('Archetype configuration data required');
  }
  await contracts.configureArchetype(req.params.address, req.body);
  return res.sendStatus(200);
});

const addParametersToArchetype = asyncMiddleware(async (req, res) => {
  if (!req.params.address) throw boom.badRequest('Archetype address required');
  if (!req.body || Object.keys(req.body).length === 0) {
    throw boom.badRequest('Archetype parameter data required');
  }
  await contracts.addArchetypeParameters(req.params.address, req.body);
  return res.sendStatus(200);
});

const setArchetypePrice = asyncMiddleware(async (req, res) => {
  if (!req.params.address) throw boom.badRequest('Archetype address must be supplied');
  if (!req.body.price) throw boom.badRequest('Archetype price must be supplied');
  await contracts.setArchetypePrice(req.params.address, req.body.price);
  return res.sendStatus(200);
});

const createArchetypePackage = asyncMiddleware(async (req, res) => {
  const { name, description } = req.body;
  let { author, isPrivate, active } = req.body;
  if (!name) throw boom.badRequest('Archetype package name is required');
  if (!description) throw boom.badRequest('Archetype package description is required');
  author = author || req.user.address;
  isPrivate = isPrivate || false;
  active = active || false;
  const id = await contracts.createArchetypePackage(name, description, author, isPrivate, active);
  res.status(200).json({ id });
});

const activateArchetypePackage = asyncMiddleware(async (req, res) => {
  const packageId = req.params.id;
  const user = req.user.address;
  await contracts.activateArchetypePackage(packageId, user);
  return res.sendStatus(200);
});

const deactivateArchetypePackage = asyncMiddleware(async (req, res) => {
  const packageId = req.params.id;
  const user = req.user.address;
  await contracts.deactivateArchetypePackage(packageId, user);
  return res.sendStatus(200);
});

const getArchetypePackages = asyncMiddleware(async (req, res) => {
  let packages = await sqlCache.getArchetypePackages(req.query, req.user.address);
  packages = packages.map(pkg => format('Archetype Package', pkg));
  res.status(200).json(packages);
});

const getArchetypePackage = asyncMiddleware(async (req, res) => {
  const { package_key } = req.params;
  const archPackage = await sqlCache.getArchetypePackages({ package_key }, req.user.address);
  if (!archPackage) throw boom.notFound(`Archetype Package with id ${package_key} not found or user has insufficient privileges`);
  const archetypes = await sqlCache.getArchetypesInPackage(package_key);
  archPackage.archetypes = archetypes.map(elem => ({
    name: elem.name,
    address: elem.address,
    active: Boolean(elem.active),
  }));
  res.status(200).json(format('Archetype Package', archPackage));
});

const addArchetypeToPackage = asyncMiddleware(async (req, res) => {
  const { packageId, archetypeAddress } = req.params;
  if (!packageId || !archetypeAddress) throw boom.badRequest('Package id and archetype address are required');
  const packageData = await sqlCache.getArchetypePackages({ package_key: packageId }, req.user.address);
  const archetypeData = (await sqlCache.getArchetypeData({ address: archetypeAddress }, req.user.address))[0];
  if (!packageData) throw boom.forbidden(`Package with id ${packageId} is not accessible by user ${req.user.address}`);
  if (!archetypeData) {
    throw boom.forbidden(`User at ${req.user.address} is not the author of the private archetype at ${archetypeAddress} ` +
      `and thus not allowed to add it to the package with id ${packageId}`);
  }
  if (req.user.address !== packageData.author) throw boom.forbidden(`Package with id ${packageId} is not modifiable by user at address ${req.user.address}`);
  if (archetypeData.isPrivate && !packageData.isPrivate) throw boom.badRequest(`Archetype at ${archetypeAddress} is private and cannot be added to public package with id ${packageId}`);
  await contracts.addArchetypeToPackage(packageId, archetypeAddress);
  res.sendStatus(200);
});

const createOrFindAccountsWithEmails = async (params) => {
  const newParams = {
    notAccountOrEmail: [],
    withEmail: [],
    forExistingUser: [],
    forNewUser: [],
  };
  params.forEach((param) => {
    if (param.type !== PARAM_TYPE.USER_ORGANIZATION && param.type !== PARAM_TYPE.SIGNING_PARTY) {
      // Ignore non-account parameters
      newParams.notAccountOrEmail.push({ ...param });
    } else if (/^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i.test(param.value)) {
      // Select parameters with email values
      newParams.withEmail.push({ ...param });
    } else {
      // Ignore parameters with non-email values
      newParams.notAccountOrEmail.push({ ...param });
    }
  });
  const client = await pool.connect();
  try {
    if (newParams.withEmail.length) {
      const { rows } = await client.query({
        text: `SELECT LOWER(email) AS email, address FROM users WHERE LOWER(email) IN (${newParams.withEmail.map((param, i) => `LOWER($${i + 1})`)});`,
        values: newParams.withEmail.map(({ value }) => value),
      });
      newParams.forNewUser = {};
      newParams.withEmail.forEach((param) => {
        const emailAddr = param.value.toLowerCase();
        const existingUser = rows.find(({ email }) => emailAddr === email);
        if (existingUser) {
          // Use existing accounts info if email already registered
          newParams.forExistingUser.push({ ...param, value: existingUser.address });
        } else if (newParams.forNewUser[emailAddr]) {
          // Consolidate users that need to be registered into obj in case the same email was entered for multiple parameters
          // Also save the parameters that each email was used for
          newParams.forNewUser[emailAddr].push(param);
        } else {
          newParams.forNewUser[emailAddr] = [param];
        }
      });
      const createNewUserPromises = (Object.keys(newParams.forNewUser)).map(async (email) => {
        // Create user on chain
        const address = await contracts.createUser({ id: email });
        const password = crypto.randomBytes(32).toString('hex');
        const salt = await bcrypt.genSalt(10);
        const hash = await bcrypt.hash(password, salt);
        // Create user in db
        const queryString = `INSERT INTO users(
          address, username, email, password_digest, is_producer, external_user
          ) VALUES(
            $1, $2, $3, $4, $5, $6
            );`;
        await client.query({ text: queryString, values: [address, email, email, hash, false, true] });
        return { email, address };
      });
      const newUsers = await Promise.all(createNewUserPromises);
      newParams.forNewUser = Object.keys(newParams.forNewUser).reduce((acc, emailAddr) => {
        const { address } = newUsers.find(({ email }) => email === emailAddr);
        const newUserParams = newParams.forNewUser[emailAddr].map(param => ({ ...param, value: address }));
        return acc.concat(newUserParams);
      }, []);
    }
    // Release client
    client.release();
    // Return all parameters
    return newParams.notAccountOrEmail.concat(newParams.forExistingUser).concat(newParams.forNewUser);
  } catch (err) {
    client.release();
    if (boom.isBoom(err)) throw err;
    throw boom.badImplementation(err);
  }
};

const _generateParamSetterPromises = (agreementAddr, archetypeParamDetails, agreementParams) => {
  const promises = [];
  const invalidParams = [];
  agreementParams.forEach((param) => {
    const matchingParam = archetypeParamDetails.filter(item => param.name === item.name)[0];
    if (matchingParam) {
      const setterFunction = dataStorage.agreementDataSetters[`${matchingParam.parameterType}`];
      if (setterFunction) {
        log.debug(`Setting value: ${param.value} for parameter: ${matchingParam.name} in agremeement at agreement address ${agreementAddr}`);
        const formattedParam = format('Parameter Value', { parameterType: matchingParam.parameterType, value: param.value });
        promises.push(setterFunction(agreementAddr, matchingParam.name, formattedParam.value));
      } else {
        throw boom.badImplementation(`No setter function found for parameter name ${matchingParam.name} with parameter type ${matchingParam.parameterType}`);
      }
    } else {
      invalidParams.push(param.name);
    }
  });
  return { promises, invalidParams };
};

const setAgreementParameters = async (agreeAddr, archAddr, parameters) => {
  const getterFunc = archAddr
    ? dataStorage.getArchetypeValidParameters
    : dataStorage.getAgreementValidParameters;
  const archetypeParamDetails = await getterFunc(archAddr || agreeAddr);
  return new Promise((resolve, reject) => {
    const params = Array.isArray(parameters) ? parameters : [];
    const { promises, invalidParams } = _generateParamSetterPromises(agreeAddr, archetypeParamDetails, params);
    if (invalidParams.length > 0) {
      return reject(boom.badRequest(`Given parameter name(s) do not exist in archetype: ${invalidParams}`));
    }
    return Promise.all(promises)
      .then(() => resolve())
      .catch(err => reject(boom.badImplementation(`Failed to set agreement parameters: ${err}`)));
  });
};

const createAgreement = asyncMiddleware(async (req, res) => {
  const password = req.body.password || null;
  let parameters = req.body.parameters || [];
  parameters = await createOrFindAccountsWithEmails(parameters);
  const parties = req.body.parties || [];
  const hoardRef = {};
  hoardRef.address = req.body.eventLogHoardAddress || '';
  hoardRef.secretKey = req.body.eventLogHoardSecret || '';
  parameters.forEach((param) => {
    if (parseInt(param.type, 10) === PARAM_TYPE.SIGNING_PARTY) parties.push(param.value);
  });
  let agreement = {
    name: req.body.name,
    archetype: req.body.archetype,
    creator: req.user.address,
    isPrivate: req.body.isPrivate,
    parties,
    hoardAddress: '',
    hoardSecret: '',
    collectionId: req.body.collectionId,
    governingAgreements: req.body.governingAgreements || [],
  };
  const { value, error } = Joi.validate(agreement, agreementSchema, { abortEarly: false });
  if (error) { throw boom.badRequest(error); }
  agreement = value;

  // validate if archetype is active - only active archetypes can be instantiated into an agreement
  if (!contracts.isActiveArchetype(agreement.archetype)) {
    throw boom.badRequest(`Cannot instantiate inactive archetype at ${agreement.archetype} for agreement ${agreement.name}`);
  }
  // TODO: Hoard stuff- implement later for saving private field values. Currently saving all values to chain.
  // plaintextIn = {
  //   data: new Buffer(JSON.stringify(req.body.values)),
  // };
  // hoard
  //   .put(plaintextIn)
  //   .then((ref) => {
  //     ref.address = ref.address.toString('hex');
  //     ref.secretKey = encrypt(ref.secretKey, password).toString('hex');

  //     agreement.hoardAddress = ref.address;
  //     agreement.hoardSecret = ref.secretKey;

  //     log.debug('Request to create new agreement: ' + agreement.name);

  const agreementAddress = await contracts.createAgreement(agreement);
  await contracts.setMaxNumberOfEvents(agreementAddress, parseInt(req.body.maxNumberOfEvents, 10));
  await contracts.updateAgreementEventLog(agreementAddress, hoardRef);
  await setAgreementParameters(agreementAddress, req.body.archetype, parameters);
  await contracts.setAddressScopeForAgreementParameters(agreementAddress, parameters.filter(({ scope }) => scope));
  await contracts.setAddressScopeForAgreementParameters(agreementAddress, parameters
    .filter(({ scope, value: paramVal }) => scope && parties.includes(paramVal))
    .map(param => ({ ...param, name: AGREEMENT_PARTIES })));
  const { formation } = await contracts.getArchetypeProcesses(req.body.archetype);
  if (!formation) {
    throw boom.badImplementation(`No formation process found for archetype ${req.body.archetype}`);
  }
  const piAddress = await contracts.startProcessFromAgreement(agreementAddress);
  log.debug(`Process Instance Address: ${piAddress}`);
  analytics.track({
    event: 'Agreement created',
    userId: req.user.id,
    properties: {
      userContract: agreement.creator,
      archetypeContract: agreement.archetype,
      agreementContract: agreementAddress,
      agreementName: agreement.name,
      agreementParties: JSON.stringify(agreement.parties),
    },
  });
  res
    .status(200)
    .set('content-type', 'application/json')
    .json({ address: agreementAddress });
});

const _generateParamGetterPromises = (agreementAddr, agreementParams, reqParams) => {
  const promises = [];
  const invalidParams = [];
  reqParams.forEach(({ name }) => {
    const matchingParam = agreementParams.filter(item => name === item.name)[0];
    if (matchingParam) {
      const getterFunction = dataStorage.agreementDataGetters[`${matchingParam.parameterType}`];
      if (getterFunction) {
        log.debug(`Getting value of parameter: ${matchingParam.name} in agremeement at address ${agreementAddr}`);
        promises.push(getterFunction(agreementAddr, matchingParam.parameter_key));
      } else {
        log.error(`No getter function found for parameter name ${matchingParam.name} with parameter type ${matchingParam.parameterType}`);
      }
    } else {
      invalidParams.push(name);
    }
  });
  return { promises, invalidParams };
};

const getAgreementParameters = async (agreementAddr, reqParams) => {
  const agreementParams = await dataStorage.getAgreementValidParameters(agreementAddr);
  return new Promise((resolve, reject) => {
    const params = reqParams || [];
    if (params.length === 0) {
      agreementParams.forEach((param) => {
        params.push(param);
      });
    }
    const { promises, invalidParams } = _generateParamGetterPromises(agreementAddr, agreementParams, params);
    if (invalidParams.length > 0) {
      return reject(boom.badRequest(`Given parameter name(s) do not exist in archetype: ${invalidParams}`));
    }
    return Promise.all(promises)
      .then(results => resolve(results.map(({ name, value }, i) => ({ name, value, type: params[i].parameterType }))))
      .catch(err => reject(boom.badImplementation(`Failed to get agreement parameters: ${err}`)));
  });
};

const getAgreements = asyncMiddleware(async (req, res) => {
  const retData = [];
  const forCurrentUser = req.query.forCurrentUser === 'true';
  delete req.query.forCurrentUser;
  let { tags: queryTags } = req.query;
  delete req.query.tags;
  const queryParams = Object.keys(req.query).length ? req.query : null;
  const data = await sqlCache.getAgreements(queryParams, forCurrentUser, req.user.address);
  // get addresses of organizations the user is an approver of
  const orgs = await sqlCache.getManagedOrganizationsOfUser(req.user.address);
  const ownerAddresses = orgs.map(({ organization }) => organization).concat([req.user.address]);
  // find all agreements that have tags with the given text applied that belong to the authenticated user or their organizations
  let text = `SELECT agreement_address AS agreement, tags.id AS id, text, owner_address AS owner FROM taggings 
  JOIN tags ON taggings.tag_id = tags.id 
  WHERE owner_address IN (${ownerAddresses.map((owner, i) => `$${i + 1}`)})`;
  let values = ownerAddresses;
  if (queryTags) {
    if (typeof queryTags === 'string') queryTags = [queryTags]; // `queryTags` is a string if only a single tag is received
    // add filter for text specified in queryTags
    text = text.concat(` AND LOWER(text) IN (${queryTags.map((tag, i) => `LOWER($${i + 1 + ownerAddresses.length})`)});`);
    values = values.concat(queryTags);
  }
  const { rows: tags } = await pool.query({ text, values });
  // group tag details by agreement
  const tagsByAgreement = {};
  tags.forEach(({
    agreement, id, text: tagText, owner,
  }) => {
    tagsByAgreement[agreement] = tagsByAgreement[agreement] || [];
    tagsByAgreement[agreement].push({ id, text: tagText, owner });
  });
  data.forEach((elem) => {
    // filter sqlsol agreement by tag results
    if (queryTags && !tagsByAgreement[elem.address]) return;
    // format agreement obj and add tag details
    const formatted = format('Agreement', elem);
    formatted.tags = tagsByAgreement[formatted.address] || [];
    retData.push(formatted);
  });
  return res.json(retData);
});

const getAgreement = asyncMiddleware(async (req, res) => {
  const retData = {};
  if (!req.params.address) throw boom.badRequest('Agreement address is required');
  const addr = req.params.address;
  const data = await sqlCache.getAgreementData(addr, req.user.address);
  if (!data) throw boom.notFound(`Agreement at ${addr} not found or user has insufficient privileges`);
  const parameters = await getAgreementParameters(addr, null);
  const parties = await sqlCache.getAgreementParties(addr);
  Object.assign(retData, format('Agreement', data));
  const password = req.query.password || null;
  const documentMetadata = await sqlCache.getArchetypeDocuments(retData.archetype);
  retData.documents = await getDocumentsFromHoard(documentMetadata, password);
  retData.parameters = parameters.map(param => format('Parameter Value', param));
  retData.parties = parties.map(party => format('Parameter Value', party));
  const governingAgreements = await sqlCache.getGoverningAgreements(req.params.address);
  retData.governingAgreements = governingAgreements.map(agreement => format('Agreement', agreement));
  delete retData.hoardAddress;
  delete retData.hoardSecret;
  // find tags for the agreement that belong to the user or their organizations
  const orgs = await sqlCache.getManagedOrganizationsOfUser(req.user.address);
  const ownerAddresses = orgs.map(({ organization }) => organization).concat([req.user.address]);
  const { rows: tags } = await pool.query({
    text: `SELECT tags.id AS id, text, owner_address AS owner FROM taggings 
    JOIN tags ON taggings.tag_id = tags.id 
    WHERE agreement_address = $1 
    AND owner_address IN (${ownerAddresses.map((owner, i) => `$${i + 2}`)});`,
    values: [req.params.address].concat(ownerAddresses),
  });
  retData.tags = tags;
  return res.status(200).json(retData);
});

const updateAgreementEventLog = asyncMiddleware(async ({ params: { address }, body: { eventName, content }, user }, res) => {
  if (!address) throw boom.badRequest('Agreement address is required');
  if (!eventName) throw boom.badRequest('eventName is required');
  const data = await sqlCache.getAgreementEventLogDetails(address);
  const newEvent = {
    name: eventName,
    submitter: user.address,
    timestamp: Date.now(),
    content: content || '',
  };
  let eventLog;
  if (data.eventLogHoardAddress === '0000000000000000000000000000000000000000000000000000000000000000') {
    eventLog = { data: [] };
  } else {
    const hoardRef = {
      address: Buffer.from(data.eventLogHoardAddress, 'hex'),
      secretKey: Buffer.from(data.eventLogHoardSecret, 'hex'),
    };
    eventLog = await hoard.get(hoardRef);
    eventLog = splitMeta(eventLog);
    eventLog.data = JSON.parse(eventLog.data);
  }
  if (eventLog.data.length < data.maxNumberOfEvents) {
    eventLog.data.push(newEvent);
    const plaintext = {
      data: addMeta({ agreement: address }, JSON.stringify(eventLog.data)),
    };
    let newHoardRef = await hoard.put(plaintext);
    newHoardRef = {
      address: newHoardRef.address.toString('hex'),
      secretKey: newHoardRef.secretKey.toString('hex'),
      salt: newHoardRef.salt.toString('hex'),
    };
    await contracts.updateAgreementEventLog(address, newHoardRef);
    return res.status(200).json(newHoardRef);
  }
  throw boom.badRequest(`Cannot log event. Max number of events (${data.maxNumberOfEvents}) has been reached.`);
});

const signAgreement = asyncMiddleware(async (req, res) => {
  if (!req.user.address) throw boom.badRequest('No logged in user found');
  if (!req.params.address) throw boom.badRequest('Agreement address required');
  const userAddr = req.user.address;
  const agreementAddr = req.params.address;
  await contracts.signAgreementByUser(userAddr, agreementAddr);
  log.debug(`Signed agreement ${agreementAddr} by user ${userAddr}`);
  res.status(200).send();
});

const cancelAgreement = asyncMiddleware(async (req, res) => {
  if (!req.user.address) throw boom.badRequest('No logged in user found');
  if (!req.params.address) throw boom.badRequest('Agreement address required');
  const agrAddr = req.params.address;
  const userAddr = req.user.address;
  await contracts.cancelAgreement(userAddr, agrAddr);
  return res.status(200).send();
});

const createAgreementCollection = asyncMiddleware(async (req, res) => {
  const { name, collectionType, packageId } = req.body;
  let { author } = req.body;
  if (!name) throw boom.badRequest('Agreement collection name required');
  if (collectionType === undefined) throw boom.badRequest('Agreement collection type required');
  if (!packageId) throw boom.badRequest('Archetype packageId required');
  author = author || req.user.address;
  const id = await contracts.createAgreementCollection(name, author, collectionType, packageId);
  res.status(200).json({ id });
});

const getAgreementCollections = asyncMiddleware(async (req, res) => {
  const collections = await sqlCache.getAgreementCollections(req.user.address);
  res.status(200).json(collections);
});

const getAgreementCollection = asyncMiddleware(async (req, res) => {
  if (!req.params.id) throw boom.badRequest('Agreement collectionId required');
  const queryRes = await sqlCache.getAgreementCollectionData(req.params.id);
  const profileData = await sqlCache.getProfile(req.user.address);
  if (queryRes[0].author !== req.user.address && !profileData.find(({ organization }) => organization === queryRes[0].author)) {
    throw boom.forbidden(`User is not authorized to read collection ${req.params.id}`);
  }
  let collection;
  queryRes.forEach(({
    id, name, author, collectionType, packageId, agreementAddress, agreementName, archetype,
  }, i) => {
    if (i === 0) {
      collection = {
        id, name, author, collectionType, packageId, agreements: [],
      };
    }
    if (agreementAddress) {
      const agrName = agreementName;
      collection.agreements.push({
        address: agreementAddress, name: agrName, archetype,
      });
    }
  });
  res.status(200).json(collection);
});

const addAgreementToCollection = asyncMiddleware(async (req, res) => {
  if (!req.body.collectionId || !req.body.agreement) throw boom.badRequest('Collection id and agreement address are required');
  await contracts.addAgreementToCollection(req.body.collectionId, req.body.agreement);
  res.sendStatus(200);
});

const createTags = asyncMiddleware(async (req, res) => {
  const { tags, owner } = req.body;
  // Check format of request body
  if (!tags || !tags.length) {
    throw boom.badRequest('Tags are required');
  } else if (!Array.isArray(tags)) {
    throw boom.badRequest('Tags must be array');
  } else {
    const badTags = tags.filter(tag => typeof tag !== 'string' || !tag.length || tag.length > 40).length;
    if (badTags.length) {
      throw boom.badRequest(`Tags must be strings with length 1 to 40. The following tags require changes: ${badTags.join(', ')}`);
    }
  }
  let ownerAddress = req.user.address;
  if (owner) {
    // Check if user is authorized to create tags under given owner
    const orgs = await sqlCache.getManagedOrganizationsOfUser(req.user.address);
    const authorized = orgs.find(({ organization }) => organization === owner);
    if (!authorized) throw boom.forbidden(`Authenticated user is not authorized to create tags for organization ${owner}`);
    ownerAddress = owner;
  }
  try {
    // Create tags and get tag details for inserted tags
    await pool.query({
      text: `INSERT INTO tags(owner_address, text) VALUES ${tags.map((tag, i) => `(UPPER($1), $${i + 2})`)}
      ON CONFLICT (UPPER(owner_address), LOWER(text)) DO NOTHING;`,
      values: [ownerAddress].concat(tags),
    });
    // Get tag details to return
    const { rows } = await pool.query({
      text: `SELECT id, text, owner_address AS owner FROM tags
      WHERE owner_address = $1 AND LOWER(text) IN (${tags.map((tag, i) => `LOWER($${i + 2})`)})`,
      values: [ownerAddress].concat(tags),
    });
    res.status(200).send(rows);
  } catch (err) {
    throw boom.badImplementation(err);
  }
});

const addTagsToAgreement = asyncMiddleware(async (req, res) => {
  const { tagIds } = req.body;
  // Check format of request body
  if (!tagIds || !tagIds.length) {
    throw boom.badRequest('TagIds required');
  } else if (tagIds && !Array.isArray(tagIds)) {
    throw boom.badRequest('TagIds must be an array');
  }
  let badArr = tagIds.filter(tagId => typeof tagId !== 'number');
  if (badArr.length) {
    throw boom.badRequest(`TagIds must be numbers. The following tagIds are invalid: ${JSON.stringify(badArr)}`);
  }
  // Check that user is authorized to manage tags for given agreement
  let authorized = await sqlCache.userIsAuthorOrPartyOfAgreement(req.user.address, req.params.address);
  if (!authorized) throw boom.forbidden(`User is not authorized to apply tags to agreement ${req.params.address}`);

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    // Get tag details
    const { rows } = await client.query({
      text: `SELECT UPPER(owner_address) AS owner, id, text FROM tags WHERE id IN (${tagIds.map((tag, i) => `$${i + 1}`)})`,
      values: tagIds,
    });
    // Check that the given tags exist
    badArr = tagIds.filter(givenId => !rows.find(({ id }) => id === givenId));
    if (badArr.length) {
      throw boom.badData(`Tag ids ${JSON.stringify(badArr)} not found`);
    }
    // Check that the user is authorized to manage the given tags
    badArr = rows.filter(({ owner }) => owner !== req.user.address.toUpperCase());
    if (badArr.length) {
      const orgs = await sqlCache.getManagedOrganizationsOfUser(req.user.address);
      authorized = badArr.every(({ owner }) => orgs.find(({ organization }) => organization === owner));
      if (!authorized) throw boom.forbidden('User is not authorized to apply one or more of the specified tagIds');
    }
    // Finally apply tags
    await client.query({
      text: `INSERT INTO taggings(agreement_address, tag_id) VALUES ${rows.map((row, i) => `(UPPER($1), $${i + 2})`)}
      ON CONFLICT (UPPER(agreement_address), tag_id) DO NOTHING;`,
      values: [req.params.address].concat(rows.map(({ id }) => id)),
    });
    await client.query('COMMIT');
    client.release();
    res.status(200).send();
  } catch (err) {
    await client.query('ROLLBACK');
    client.release();
    if (boom.isBoom(err)) throw err;
    throw boom.badImplementation(err);
  }
});

const removeTagFromAgreement = asyncMiddleware(async (req, res) => {
  const { address, id } = req.params;
  // Check that user is authorized to manage tags for given agreement
  let authorized = await sqlCache.userIsAuthorOrPartyOfAgreement(req.user.address, address);
  if (!authorized) throw boom.forbidden(`User is not authorized to remove tags from agreement ${address}`);
  const client = await pool.connect();
  try {
    // Get tag details
    const { rows } = await client.query({
      text: 'SELECT UPPER(owner_address) AS owner, id, text FROM tags WHERE id = $1;',
      values: [id],
    });
    const tag = rows[0];
    if (!tag) {
      throw boom.notFound(`Tag ${id} not found`);
    }
    // Check that the user is authorized to manage the given tag
    if (tag.owner !== req.user.address) {
      const orgs = await sqlCache.getManagedOrganizationsOfUser(req.user.address);
      authorized = orgs.find(({ organization }) => organization === tag.owner);
      if (!authorized) throw boom.forbidden(`User is not authorized to manage tag ${id}`);
    }
    // Delete tagging
    await client.query({
      text: 'DELETE FROM taggings WHERE agreement_address = $1 AND tag_id = $2;',
      values: [address, id],
    });
    await client.query('COMMIT');
    client.release();
    return res.status(200).send();
  } catch (err) {
    await client.query('ROLLBACK');
    client.release();
    if (boom.isBoom(err)) throw err;
    throw boom.badImplementation(err);
  }
});

module.exports = {
  getArchetypes,
  getArchetype,
  createArchetype,
  activateArchetype,
  deactivateArchetype,
  setArchetypeSuccessor,
  getArchetypeSuccessor,
  updateArchetypeConfiguration,
  addParametersToArchetype,
  setArchetypePrice,
  createArchetypePackage,
  activateArchetypePackage,
  deactivateArchetypePackage,
  getArchetypePackage,
  getArchetypePackages,
  addArchetypeToPackage,
  createAgreementCollection,
  getAgreementCollections,
  getAgreementCollection,
  addAgreementToCollection,
  createAgreement,
  setAgreementParameters,
  getAgreementParameters,
  getAgreements,
  getAgreement,
  updateAgreementEventLog,
  signAgreement,
  cancelAgreement,
  createTags,
  addTagsToAgreement,
  removeTagFromAgreement,
};
