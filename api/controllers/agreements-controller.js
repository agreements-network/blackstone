const path = require('path');
const boom = require('@hapi/boom');
const Joi = require('@hapi/joi');
const _ = require('lodash');
const { parse, toSeconds } = require('iso8601-duration');
const {
  format,
  splitMeta,
  asyncMiddleware,
  getBooleanFromString,
} = require(`${global.__common}/controller-dependencies`);
const contracts = require('./contracts-controller');
const dataStorage = require(path.join(global.__controllers, 'data-storage-controller'));
const archetypeSchema = require(`${global.__schemas}/archetype`);
const agreementSchema = require(`${global.__schemas}/agreement`);
const { hoardGet, hoardPut } = require(`${global.__controllers}/hoard-controller`);
const { parseBpmnModel } = require(`${global.__controllers}/bpm-controller`);
const { createOrFindAccountsWithEmails, getParticipantNames } = require(`${global.__controllers}/participants-controller`);
const logger = require(`${global.__common}/logger`);
const log = logger.getLogger('controllers.agreements');
const sqlCache = require('./postgres-query-helper');
const { PARAMETER_TYPES: PARAM_TYPE, AGREEMENT_PARTIES, AGREEMENT_ATTACHMENT_CONTENT_TYPES } = global.__constants;

const AGREEMENT_DATA_ID = 'agreement';

const _createPrivatePublicArrays = (parameters, paramsRequired) => {
  const privateParams = [];
  const publicParams = [];
  parameters.forEach((param) => {
    if (paramsRequired[param.name] !== undefined) {
      publicParams.push(param);
    } else {
      privateParams.push(param);
    }
  });
  return { privateParams, publicParams };
};

const _checkObjectsForParamUse = (
  objArray,
  parametersLength,
  paramsRequired,
  paramsRequiredCount,
  dataStorageIdFieldName = 'dataStorageId',
  dataPathFieldName = 'dataPath',
) => {
  if (!objArray || !objArray.length || parametersLength === paramsRequiredCount) return paramsRequiredCount;
  const { [dataStorageIdFieldName]: dataStorageId, [dataPathFieldName]: dataPath } = objArray.pop();
  let newCount = paramsRequiredCount;
  if (dataStorageId === AGREEMENT_DATA_ID && dataPath !== AGREEMENT_PARTIES && paramsRequired[dataPath] === undefined) {
    newCount += 1;
    paramsRequired[dataPath] = true; // eslint-disable-line no-param-reassign
  }
  return _checkObjectsForParamUse(objArray, parametersLength, paramsRequired, newCount, dataStorageIdFieldName, dataPathFieldName);
};

const _checkTasksForParamUse = (tasks, parametersLength, paramsRequired, paramsRequiredCount) => {
  if (!tasks.length || parametersLength === paramsRequiredCount) return paramsRequiredCount;
  let newCount = paramsRequiredCount;
  const { dataMappings } = tasks.pop();
  newCount = _checkObjectsForParamUse(dataMappings, parametersLength, paramsRequired, newCount);
  return _checkTasksForParamUse(tasks, parametersLength, paramsRequired, newCount);
};

const _checkProcessForParamUse = async (process, paramsRequired, parametersLength, paramsRequiredCount = 0) => {
  let newCount = paramsRequiredCount;
  newCount = _checkObjectsForParamUse(process.participants, parametersLength, paramsRequired, newCount);
  ['tasks', 'userTasks', 'sendTasks', 'serviceTasks'].forEach((taskType) => {
    newCount = _checkTasksForParamUse(process[taskType], parametersLength, paramsRequired, newCount);
  });
  newCount = _checkObjectsForParamUse(
    process.transitions
      .filter(({ condition }) => condition)
      .map(({ condition }) => condition),
    parametersLength,
    paramsRequired,
    newCount,
    'lhDataStorageId',
    'lhDataPath',
  );
  return newCount;
};

const _getParsedModel = async (modelFileRef) => {
  let xml = await hoardGet(modelFileRef);
  xml = splitMeta(xml);
  const { model: { dataStoreFields }, processes } = await parseBpmnModel(xml.data.toString());
  return { dataStoreFields, processes };
};

const _setRequiredParamType = (dataStoreFields, paramsRequired) => {
  dataStoreFields.forEach(({ dataStorageId, dataPath, parameterType }) => {
    if (dataStorageId === AGREEMENT_DATA_ID && paramsRequired[dataPath]) {
      paramsRequired[dataPath] = parameterType; // eslint-disable-line no-param-reassign
    }
  });
};

const _checkModelsForRequiredParameters = async (archetypeAddress, formationProcessDefinition, executionProcessDefinition, userAddress) => {
  let formationModelFileReference;
  let executionModelFileReference;
  let formationProcessId;
  let executionProcessId;
  try {
    if (archetypeAddress) {
      ({
        formationModelFileReference, executionModelFileReference, formationProcessId, executionProcessId,
      } = (await sqlCache.getArchetypeModelFileReferences(archetypeAddress))[0]);
    } else if (formationProcessDefinition && executionProcessDefinition && userAddress) {
      ({
        modelFileReference: formationModelFileReference, processDefinitionId: formationProcessId,
      } = await sqlCache.getProcessDefinitionData(formationProcessDefinition, userAddress));
      ({
        modelFileReference: executionModelFileReference, processDefinitionId: executionProcessId,
      } = await sqlCache.getProcessDefinitionData(executionProcessDefinition, userAddress));
    } else {
      throw boom.badImplementation(`Some or all arguments needed to check for required parameters in models not received: 
      archetype: ${archetypeAddress},
      formation: ${formationProcessDefinition},
      execution: ${executionProcessDefinition},
      user: ${userAddress}`);
    }
    const paramsRequired = {};
    let dataStoreFields;
    let processes;
    let parametersLength;
    let paramsRequiredCount;
    if (formationModelFileReference) {
      ({ dataStoreFields, processes } = await _getParsedModel(formationModelFileReference));
      parametersLength = dataStoreFields.filter(({ dataStorageId }) => dataStorageId === AGREEMENT_DATA_ID).length;
      // Each of the _check functions will update the `paramsRequired` obj and increment a `paramsRequiredCount`
      // They will return early once `paramsRequiredCount` meets `parametersLength`, ie all parameters are required
      paramsRequiredCount = await _checkProcessForParamUse(
        processes.find(({ id }) => id === formationProcessId), paramsRequired, parametersLength,
      );
      _setRequiredParamType(dataStoreFields, paramsRequired);
    }
    if (!executionModelFileReference) return paramsRequired;
    if (formationModelFileReference !== executionModelFileReference) {
      // Only get model data and reset count if execution uses a different model
      ({ dataStoreFields, processes } = await _getParsedModel(executionModelFileReference));
      parametersLength = dataStoreFields.filter(({ dataStorageId }) => dataStorageId === AGREEMENT_DATA_ID).length;
      paramsRequiredCount = 0;
    } else if (paramsRequiredCount === parametersLength) {
      // Models are the same and we've already found that all data store fields are required
      return paramsRequired;
    }
    await _checkProcessForParamUse(
      processes.find(({ id }) => id === executionProcessId), paramsRequired, parametersLength, paramsRequiredCount,
    );
    _setRequiredParamType(dataStoreFields, paramsRequired);
    return paramsRequired;
  } catch (err) {
    if (err.isBoom) throw err;
    throw boom.badImplementation(`Failed to get parameters required by models for archetype ${archetypeAddress}: ${JSON.stringify(err)}`);
  }
};

const getArchetypes = asyncMiddleware(async (req, res, next) => {
  const retData = [];
  const archData = await sqlCache.getArchetypes(req.query, req.user.address);
  archData.forEach((_archetype) => {
    retData.push(format('Archetype', _archetype));
  });
  res.locals.data = retData;
  res.status(200);
  return next();
});

const getArchetype = asyncMiddleware(async (req, res, next) => {
  let data;
  data = await sqlCache.getArchetypeDataWithProcessDefinitions(req.params.address, req.user.address);
  if (!data) throw boom.notFound(`Archetype at ${req.params.address} not found or user has insufficient privileges`);
  data = format('Archetype', data);
  data.parameters = await sqlCache.getArchetypeParameters(req.params.address);
  // Early return if you only are fetching meta data
  if (getBooleanFromString(req.query.meta)) {
    res.locals.data = data;
    res.status(200);
    return next();
  }
  data.jurisdictions = await sqlCache.getArchetypeJurisdictions(req.params.address);
  data.documents = await sqlCache.getArchetypeDocuments(req.params.address);
  data.packages = await sqlCache.getPackagesOfArchetype(req.params.address);
  const governingArchetypes = await sqlCache.getGoverningArchetypes(req.params.address);
  data.governingArchetypes = governingArchetypes.map(arch => format('Archetype', arch));
  res.locals.data = data;
  res.status(200);
  return next();
});

const createArchetype = asyncMiddleware(async (req, res, next) => {
  if (!req.body || Object.keys(req.body).length === 0) throw boom.badRequest('Archetype data required');
  let arch = { ...req.body };
  arch.parameters = arch.parameters || [];
  arch.author = req.user.address;
  if (!arch.owner) arch.owner = arch.author;
  log.debug(`Request to create new archetype: ${arch.name}`);

  const { value, error } = Joi.validate(arch, archetypeSchema, { abortEarly: false });
  if (error) throw boom.badRequest(`Required fields missing or malformed: ${error}`);
  arch = value;

  if (arch.packageId) {
    let packageData;
    try {
      packageData = await sqlCache.getArchetypePackage(arch.packageId, req.user.address);
    } catch (err) {
      if (err.isBoom && err.output.statusCode === 404) {
        throw boom.badRequest(`Given packageId ${arch.packageId} does not exist, or may not be accessible to user`);
      }
      throw boom.badImplementation(err);
    }
    if (packageData.author !== req.user.address) throw boom.forbidden(`Package with id ${arch.packageId} is not modifiable by user at address ${req.user.address}`);
    if (arch.isPrivate && !packageData.isPrivate) throw boom.badRequest(`Private archetype ${arch.name} cannot be added to public package with id ${arch.packageId}`);
  }

  let validOwner = arch.owner === req.user.address;
  if (!validOwner) {
    const userOrgStatus = await sqlCache.userStatusInOrganization(arch.owner, req.user.address);
    validOwner = (userOrgStatus.isMember || userOrgStatus.isApprover);
  }
  if (!validOwner) throw boom.badRequest(`Owner ${arch.owner} is not a valid organization address, or the user is not a member or approver of the organization.`);

  const requiredParams = await _checkModelsForRequiredParameters(null, arch.formationProcessDefinition, arch.executionProcessDefinition, req.user.address);
  const missingParams = Object.keys(requiredParams).filter(param => !arch.parameters.find(({ name, type }) => name === param && type === requiredParams[param]));
  if (missingParams.length) {
    throw boom.badRequest(`Parameters used in model not all found in archetype parameters: ${missingParams}`);
  }

  const archetypeAddress = await contracts.createArchetype(arch);
  if (arch.parameters.length > 0) {
    await contracts.addArchetypeParameters(archetypeAddress, arch.parameters);
  }
  if (arch.documents) {
    await contracts.addArchetypeDocuments(archetypeAddress, arch.documents);
  }
  if (arch.jurisdictions) {
    await contracts.addJurisdictions(archetypeAddress, arch.jurisdictions);
  }
  await sqlCache.insertArchetypeDetails({ address: archetypeAddress, name: arch.name, description: _.escape(arch.description) });
  res.locals.data = { address: archetypeAddress };
  res.status(200);
  return next();
});

const activateArchetype = asyncMiddleware(async (req, res, next) => {
  const { address } = req.params;
  const user = req.user.address;
  const archetype = sqlCache.getArchetypeData(address, user);
  if (!archetype) throw boom.unauthorized(`User at ${user} is not authorized to activate archetype at ${address}`);
  await contracts.activateArchetype(address, user);
  res.status(200);
  return next();
});

const deactivateArchetype = asyncMiddleware(async (req, res, next) => {
  const { address } = req.params;
  const user = req.user.address;
  const archetype = sqlCache.getArchetypeData(address, user);
  if (!archetype) throw boom.unauthorized(`User at ${user} is not authorized to deactivate archetype at ${address}`);
  await contracts.deactivateArchetype(address, user);
  res.status(200);
  return next();
});

const setArchetypeSuccessor = asyncMiddleware(async (req, res, next) => {
  const { address, successor } = req.params;
  const user = req.user.address;
  const archetype = sqlCache.getArchetypeData(address, user);
  if (!archetype) throw boom.unauthorized(`User at ${user} is not authorized to deactivate archetype at ${address}`);
  await contracts.setArchetypeSuccessor(address, successor || 0x0, user);
  res.status(200);
  return next();
});

const updateArchetypeConfiguration = asyncMiddleware(async (req, res, next) => {
  if (!req.params.address) throw boom.badRequest('Archetype address required');
  if (!req.body || Object.keys(req.body).length === 0) {
    throw boom.badRequest('Archetype configuration data required');
  }
  await contracts.configureArchetype(req.params.address, req.body);
  res.status(200);
  return next();
});

const addParametersToArchetype = asyncMiddleware(async (req, res, next) => {
  if (!req.params.address) throw boom.badRequest('Archetype address required');
  if (!req.body || Object.keys(req.body).length === 0) {
    throw boom.badRequest('Archetype parameter data required');
  }
  await contracts.addArchetypeParameters(req.params.address, req.body);
  res.status(200);
  return next();
});

const setArchetypePrice = asyncMiddleware(async (req, res, next) => {
  if (!req.params.address) throw boom.badRequest('Archetype address must be supplied');
  if (!req.body.price) throw boom.badRequest('Archetype price must be supplied');
  await contracts.setArchetypePrice(req.params.address, req.body.price);
  res.status(200);
  return next();
});

const createArchetypePackage = asyncMiddleware(async (req, res, next) => {
  const { name, description } = req.body;
  let { author, isPrivate, active } = req.body;
  if (!name) throw boom.badRequest('Archetype package name is required');
  if (!name.length > 255) throw boom.badRequest('Archetype package name cannot exceed 255 characters');
  if (!description) throw boom.badRequest('Archetype package description is required');
  author = author || req.user.address;
  isPrivate = isPrivate || false;
  active = active || false;
  const id = await contracts.createArchetypePackage(author, isPrivate, active);
  await sqlCache.insertPackageDetails({ id, name, description });
  res.locals.data = { id };
  res.status(200);
  return next();
});

const activateArchetypePackage = asyncMiddleware(async (req, res, next) => {
  const packageId = req.params.id;
  const user = req.user.address;
  await contracts.activateArchetypePackage(packageId, user);
  res.status(200);
  return next();
});

const deactivateArchetypePackage = asyncMiddleware(async (req, res, next) => {
  const packageId = req.params.id;
  const user = req.user.address;
  await contracts.deactivateArchetypePackage(packageId, user);
  res.status(200);
  return next();
});

const getArchetypePackages = asyncMiddleware(async (req, res, next) => {
  const packages = await sqlCache.getArchetypePackages(req.query, req.user.address);
  res.locals.data = packages.map(pkg => format('Archetype Package', pkg));
  res.status(200);
  return next();
});

const getArchetypePackage = asyncMiddleware(async (req, res, next) => {
  const { id } = req.params;
  const archPackage = await sqlCache.getArchetypePackage(id, req.user.address);
  if (!archPackage) throw boom.notFound(`Archetype Package with id ${id} not found or user has insufficient privileges`);
  const archetypes = await sqlCache.getArchetypesInPackage(id);
  archPackage.archetypes = archetypes.map(elem => ({
    name: elem.name,
    address: elem.address,
    active: Boolean(elem.active),
  }));
  res.locals.data = format('Archetype Package', archPackage);
  res.status(200);
  return next();
});

const addArchetypeToPackage = asyncMiddleware(async (req, res, next) => {
  const { packageId, archetypeAddress } = req.params;
  if (!packageId || !archetypeAddress) throw boom.badRequest('Package id and archetype address are required');
  const packageData = (await sqlCache.getArchetypePackage(packageId, req.user.address));
  const archetypeData = await sqlCache.getArchetypeData(archetypeAddress, req.user.address);
  if (!archetypeData) {
    throw boom.forbidden(`Archetype at ${archetypeAddress} not found or user at ${req.user.address} does not have rights to access archetype at ${archetypeAddress} ` +
      `and thus not allowed to add it to the package with id ${packageId}`);
  }
  if (req.user.address !== packageData.author) throw boom.forbidden(`Package with id ${packageId} is not modifiable by user at address ${req.user.address}`);
  if (archetypeData.isPrivate && !packageData.isPrivate) throw boom.badRequest(`Archetype at ${archetypeAddress} is private and cannot be added to public package with id ${packageId}`);
  await contracts.addArchetypeToPackage(packageId, archetypeAddress);
  res.status(200);
  return next();
});

const validateAgreementParameterValue = (param) => {
  /* eslint-disable no-param-reassign */
  const err = new Error();
  err.status = 400;
  if (param.type === PARAM_TYPE.BOOLEAN && typeof param.value !== 'boolean') {
    err.message = 'Invalid boolean value';
    throw err;
  } else if (param.type === PARAM_TYPE.STRING && typeof param.value !== 'string') {
    err.message = 'Invalid string value';
    throw err;
  } else if (param.type === PARAM_TYPE.NUMBER || param.type === PARAM_TYPE.DATE || param.type === PARAM_TYPE.DATETIME) {
    if (typeof param.value !== 'number') {
      err.message = 'Number, Date, and Datetime values must be integers';
      throw err;
    }
    param.value = Math.round(param.value);
  } else if (param.type === PARAM_TYPE.MONETARY_AMOUNT) {
    if (typeof param.value !== 'number') {
      err.message = 'Monetary value must be a number';
    }
    param.value = Math.round(param.value * 100);
  } else if (param.type === PARAM_TYPE.USER_ORGANIZATION ||
    param.type === PARAM_TYPE.CONTRACT_ADDRESS ||
    param.type === PARAM_TYPE.SIGNING_PARTY) {
    if (typeof param.value !== 'string' || !param.value.match(/^[0-9A-Fa-f]{40}$/)) {
      err.message = 'Accounts must be 40-digit hexadecimals';
      throw err;
    }
  } else if (param.type === PARAM_TYPE.POSITIVE_NUMBER) {
    if (typeof param.value !== 'number' || param.value < 0) {
      err.message = 'Positive number value must be positive number';
      throw err;
    }
    param.value = Math.round(param.value);
  } else if (param.type === PARAM_TYPE.DURATION) {
    if (typeof param.value !== 'string') {
      err.message = 'Duration must be a string';
      throw err;
    } else {
      const asSeconds = toSeconds(parse(param.value));
      if (!asSeconds) {
        err.message = 'Duration must be greater than 0s. Check if format meets ISO-8601 standard.';
        throw err;
      }
    }
  }
  return param;
  /* eslint-enable no-param-reassign */
};

const _generateParamSetterPromises = (agreementAddr, archetypeParamDetails, agreementParams) => {
  const promises = [];
  const invalidParams = [];
  agreementParams.forEach((param) => {
    log.trace('Processing parameter data for agreement %s: %s', agreementAddr, JSON.stringify(param));
    const matchingParam = archetypeParamDetails.filter(item => param.name === item.name)[0];
    if (matchingParam) {
      const setterFunction = dataStorage.agreementDataSetters[`${matchingParam.parameterType}`];
      if (setterFunction) {
        log.debug('Setting value: %s for parameter %s with type %d in agremeement %s', param.value, matchingParam.name, matchingParam.parameterType, agreementAddr);
        promises.push(setterFunction(agreementAddr, matchingParam.name, param.value));
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
    ? sqlCache.getArchetypeValidParameters
    : sqlCache.getAgreementValidParameters;
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

const createAgreement = async (agr, userAddr) => {
  const _parameters = agr.parameters || [];
  const { parameters, newUsers } = await createOrFindAccountsWithEmails(_parameters, 'type');
  const parties = agr.parties || [];
  parameters.forEach((param) => {
    validateAgreementParameterValue(param);
    if (parseInt(param.type, 10) === PARAM_TYPE.SIGNING_PARTY) parties.push(param.value);
  });
  let agreement = {
    name: agr.name,
    archetype: agr.archetype,
    creator: userAddr,
    owner: agr.owner || userAddr,
    isPrivate: agr.isPrivate,
    parties,
    collectionId: agr.collectionId,
    governingAgreements: agr.governingAgreements || [],
  };
  const { value, error } = Joi.validate(agreement, agreementSchema, { abortEarly: false });
  if (error) { throw boom.badRequest(error); }
  agreement = value;
  // validate if archetype is active - only active archetypes can be instantiated into an agreement
  if (!contracts.isActiveArchetype(agreement.archetype)) {
    throw boom.badRequest(`Cannot instantiate inactive archetype at ${agreement.archetype} for agreement ${agreement.name}`);
  }
  const paramsRequired = await _checkModelsForRequiredParameters(agreement.archetype);
  const { privateParams, publicParams } = _createPrivatePublicArrays(parameters, paramsRequired);
  agreement.privateParametersFileReference = await hoardPut({ name: 'privateParameters.json' }, JSON.stringify(privateParams));
  const agreementAddress = await contracts.createAgreement(agreement);
  await contracts.initializeObjectAdministrator(agreementAddress);
  await contracts.setMaxNumberOfAttachments(agreementAddress, parseInt(agreement.maxNumberOfAttachments, 10));
  await setAgreementParameters(agreementAddress, agreement.archetype, publicParams);
  await contracts.setAddressScopeForAgreementParameters(agreementAddress, parameters.filter(({ scope }) => scope));
  await contracts.setAddressScopeForAgreementParameters(agreementAddress, parameters
    .filter(({ scope, value: paramVal }) => scope && parties.includes(paramVal))
    .map(param => ({ ...param, name: AGREEMENT_PARTIES })));
  const { formation } = await contracts.getArchetypeProcesses(agreement.archetype);
  if (!formation) {
    throw boom.badImplementation(`No formation process found for archetype ${agreement.archetype}`);
  }
  await sqlCache.insertAgreementDetails({ address: agreementAddress, name: agreement.name });
  const piAddress = await contracts.startProcessFromAgreement(agreementAddress);
  log.debug(`Process Instance Address: ${piAddress}`);
  return {
    address: agreementAddress, newUsers, parameters, processInstance: piAddress,
  };
};

const createAgreementHandler = asyncMiddleware(async (req, res, next) => {
  res.locals.data = await createAgreement(req.body, req.user.address);
  res.status(200);
  return next();
});

const _generateParamGetterPromises = (agreementAddr, agreementParams) => {
  const promises = [];
  const invalidParams = [];
  agreementParams.forEach((param) => {
    const getterFunction = dataStorage.agreementDataGetters[`${param.parameterType}`];
    if (getterFunction) {
      log.debug(`Getting value of parameter: ${param.name} in agremeement at address ${agreementAddr}`);
      promises.push(getterFunction(agreementAddr, param.name));
    } else {
      log.error(`No getter function found for parameter name ${param.name} with parameter type ${param.parameterType}`);
    }
  });
  return { promises, invalidParams };
};

const _getPrivateAgreementParameters = async (fileRef) => {
  const parameters = await hoardGet(fileRef);
  return JSON.parse(splitMeta(parameters).data.toString());
};

const getAgreementParameters = async (agreementAddr, parametersFileRef) => {
  try {
    const agreementParams = await sqlCache.getAgreementValidParameters(agreementAddr);
    const { promises, invalidParams } = _generateParamGetterPromises(agreementAddr, agreementParams);
    if (invalidParams.length > 0) {
      throw boom.badRequest(`Given parameter name(s) do not exist in archetype: ${invalidParams}`);
    }
    const paramsFromChain = await Promise.all(promises);
    const paramsObj = {};
    paramsFromChain.forEach(({ name, value }, i) => {
      paramsObj[name] = { name, value, type: agreementParams[i].parameterType };
    });
    const privateParams = await _getPrivateAgreementParameters(parametersFileRef);
    // paramsFromChain includes all paramsObj from archetype, so "private" ones will also be included with empty values
    // these empty values must be filled in with the private values retrieved from hoard
    privateParams.forEach(({ name, value, type }) => {
      paramsObj[name] = { name, value, type };
    });
    const parameters = Object.values(paramsObj).map(param => format('Parameter Value', param));
    const withNames = await getParticipantNames(parameters, 'value');
    const withNamesObj = {};
    withNames.forEach(({ value, displayName }) => {
      if (displayName) withNamesObj[value] = { displayValue: displayName };
    });
    return parameters.map(param => Object.assign(param, withNamesObj[param.value] || {}));
  } catch (err) {
    if (err.isBoom) throw err;
    throw boom.badImplementation(`Failed to get agreement parameters: ${err.stack}`);
  }
};

const getAgreements = asyncMiddleware(async (req, res, next) => {
  const retData = [];
  const forCurrentUser = req.query.forCurrentUser === 'true';
  delete req.query.forCurrentUser;
  const data = await sqlCache.getAgreements(req.query, forCurrentUser, req.user.address);
  data.forEach((elem) => { retData.push(format('Agreement', elem)); });
  res.locals.data = retData;
  res.status(200);
  return next();
});

const getAgreement = async (agrAddress, userAddress) => {
  let data = await sqlCache.getAgreementData(agrAddress, userAddress);
  if (!data) throw boom.notFound(`Agreement at ${agrAddress} not found or user has insufficient privileges`);
  data.parties = await sqlCache.getAgreementParties(agrAddress);
  data.documents = await sqlCache.getArchetypeDocuments(data.archetype);
  data.parameters = await getAgreementParameters(agrAddress, data.privateParametersFileReference);
  data.governingAgreements = await sqlCache.getGoverningAgreements(agrAddress);
  data = format('Agreement', data);
  return data;
};

const getAgreementHandler = asyncMiddleware(async (req, res, next) => {
  res.locals.data = await getAgreement(req.params.address, req.user.address);
  res.status(200);
  return next();
});

const updateAgreementAttachments = asyncMiddleware(async (req, res, next) => {
  const { address } = req.params;
  const data = await sqlCache.getAgreementData(address, req.user.address, false);
  if (!data) throw boom.notFound(`Agreement at ${address} not found or user has insufficient privileges`);
  let name;
  let content;
  let contentType;
  if (req.headers['content-type'].startsWith('multipart/form-data')) {
    // Receiving file - upload to hoard and get grant
    if (!req.files) throw boom.badRequest('No file received for attachment');
    const file = req.files[0];
    name = file.originalname;
    const meta = {
      name,
      mime: file.mimetype,
    };
    content = await hoardPut(meta, file.buffer);
    contentType = AGREEMENT_ATTACHMENT_CONTENT_TYPES.fileReference;
  } else {
    ({ name, content } = req.body);
    if (!name || !content) throw boom.badRequest('Name and content are required fields');
    contentType = AGREEMENT_ATTACHMENT_CONTENT_TYPES.plaintext;
  }
  let attachments;
  if (!data.attachmentsFileReference) {
    // No reference stored- start new attachments
    attachments = [];
  } else {
    // Get existing data with reference
    attachments = await hoardGet(data.attachmentsFileReference);
    attachments = splitMeta(attachments);
    attachments = JSON.parse(attachments.data);
  }
  // TODO: Put back attachments length check when some kind of metering is established
  // if (attachments.length < data.maxNumberOfAttachments) {
  attachments.push({
    name,
    submitter: req.user.address,
    timestamp: Date.now(),
    content,
    contentType,
  });
  // Store new data in hoard
  const hoardGrant = await hoardPut({ agreement: address, name: 'agreement_attachments.json' }, JSON.stringify(attachments));
  await contracts.updateAgreementFileReference('EventLog', address, hoardGrant);
  res.locals.data = { attachmentsFileReference: hoardGrant, attachments };
  res.status(200);
  return next();
  // }
  // throw boom.badRequest(`Cannot add attachment. Max number of attachments (${data.maxNumberOfAttachments}) has been reached.`);
});

const signAgreement = asyncMiddleware(async (req, res, next) => {
  if (!req.user.address) throw boom.badRequest('No logged in user found');
  if (!req.params.address) throw boom.badRequest('Agreement address required');
  const userAddr = req.user.address;
  const agreementAddr = req.params.address;
  await contracts.signAgreement(userAddr, agreementAddr);
  log.debug(`Signed agreement ${agreementAddr} by user ${userAddr}`);
  res.status(200);
  return next();
});

const cancelAgreement = asyncMiddleware(async (req, res, next) => {
  if (!req.user.address) throw boom.badRequest('No logged in user found');
  if (!req.params.address) throw boom.badRequest('Agreement address required');
  const agrAddr = req.params.address;
  const userAddr = req.user.address;
  await contracts.cancelAgreement(userAddr, agrAddr);
  res.status(200);
  return next();
});

const createAgreementCollection = asyncMiddleware(async (req, res, next) => {
  const { name, collectionType, packageId } = req.body;
  let { author } = req.body;
  if (!name) throw boom.badRequest('Agreement collection name required');
  if (name.length > 255) throw boom.badRequest('Agreement collection name cannot exceed 255 characters');
  if (collectionType === undefined) throw boom.badRequest('Agreement collection type required');
  if (!packageId) throw boom.badRequest('Archetype packageId required');
  author = author || req.user.address;
  const id = await contracts.createAgreementCollection(author, collectionType, packageId);
  await sqlCache.insertCollectionDetails({ id, name });
  res.locals.data = { id };
  res.status(200);
  return next();
});

const getAgreementCollections = asyncMiddleware(async (req, res, next) => {
  res.locals.data = await sqlCache.getAgreementCollections(req.user.address);
  res.status(200);
  return next();
});

const getAgreementCollection = asyncMiddleware(async (req, res, next) => {
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
  res.locals.data = collection;
  res.status(200);
  return next();
});

const addAgreementToCollection = asyncMiddleware(async (req, res, next) => {
  if (!req.body.collectionId || !req.body.agreement) throw boom.badRequest('Collection id and agreement address are required');
  await contracts.addAgreementToCollection(req.body.collectionId, req.body.agreement);
  res.status(200);
  return next();
});

module.exports = {
  _checkModelsForRequiredParameters,
  getArchetypes,
  getArchetype,
  createArchetype,
  activateArchetype,
  deactivateArchetype,
  setArchetypeSuccessor,
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
  validateAgreementParameterValue,
  createAgreement,
  createAgreementHandler,
  setAgreementParameters,
  getAgreementParameters,
  getAgreements,
  getAgreement,
  getAgreementHandler,
  updateAgreementAttachments,
  signAgreement,
  cancelAgreement,
};
