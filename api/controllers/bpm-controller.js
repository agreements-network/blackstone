const path = require('path');
const boom = require('boom');
const contracts = require(`${global.__controllers}/contracts-controller`);
const {
  format,
  addMeta,
  splitMeta,
  asyncMiddleware,
  byteLength,
  setUserIds,
  getNamesOfOrganizations,
} = require(`${global.__common}/controller-dependencies`);
const logger = require(`${global.__common}/monax-logger`);
const log = logger.getLogger('agreements.bpm');
const parser = require(path.resolve(global.__lib, 'bpmn-parser.js'));
const {
  hoard,
  getModelFromHoard,
} = require(`${global.__controllers}/hoard-controller`);
const sqlCache = require('./postgres-query-helper');
const pgCache = require('./postgres-cache-helper');
const dataStorage = require(path.join(`${global.__controllers}/data-storage-controller`));

const getActivityInstances = asyncMiddleware(async (req, res) => {
  const data = await sqlCache.getActivityInstances(req.query);
  const activities = await pgCache.populateTaskNames(data);
  return res.status(200).json(activities.map(activity => format('Task', activity)));
});

const _getDataMappingDetails = async (userAddress, activityInstanceId, dataMappingIds = [], direction) => {
  if (!activityInstanceId) throw boom.badRequest('Activity instance id required');
  try {
    let dataMappingDetails;
    // validations
    const aiData = (await sqlCache.getActivityInstanceData(activityInstanceId, userAddress))[0];
    const {
      performer,
      processDefinitionAddress,
      activityId,
      application,
      state,
    } = aiData;
    if (!application) {
      throw boom.badData(`Cannot resolve data type since no application has been configured for activity ${activityInstanceId}`);
    }
    const profileData = await (sqlCache.getProfile(userAddress))[0];
    if (performer !== userAddress && !profileData.find(({ organization }) => organization === performer)) {
      throw boom.forbidden('User is not authorized to access this activity');
    }
    if (state !== 4) throw boom.forbidden('Data mappings can only be accessed while activity is in SUSPENDED state');
    // get data mapping details from smart contracts
    dataMappingDetails = await contracts.getDataMappingDetailsForActivity(processDefinitionAddress, activityId,
      (dataMappingIds.length > 0 ? dataMappingIds : null), direction);
    dataMappingDetails = dataMappingDetails.map((_mapping) => {
      const mapping = _mapping;
      delete mapping.accessPath;
      delete mapping.dataStorage;
      return format('Data Mapping', mapping);
    });
    // get access point details from vent
    const accessPointDetails = await sqlCache.getAccessPointDetails(dataMappingDetails, application);
    if (dataMappingDetails.length === 0 || accessPointDetails.length === 0) {
      throw boom.notFound(`No ${direction ? 'out-' : 'in-'}data mapping details found for activity ${activityInstanceId}`);
    }
    // merge the data mapping and access point objects
    dataMappingDetails = dataMappingDetails.map((_mapping) => {
      const matchingAp = accessPointDetails.filter(ap => ap.accessPointId === _mapping.dataMappingId)[0];
      const mapping = Object.assign(_mapping, matchingAp);
      return mapping;
    });
    return dataMappingDetails;
  } catch (err) {
    if (boom.isBoom(err)) throw err;
    else throw boom.badImplementation(`Failed to get access point details for activity ${activityInstanceId}`);
  }
};

const _validateDataMapping = (dataMapping) => {
  const errMessage = `Value ${dataMapping.value} not valid input for data type ${dataMapping.dataType}`;
  switch (dataMapping.dataType) {
    case 1:
      // bool
      if (dataMapping.value !== true && dataMapping.value !== false) {
        throw boom.badRequest(errMessage);
      }
      break;
    case 2:
      // string
      if (typeof dataMapping.value !== 'string') {
        throw boom.badRequest(errMessage);
      }
      break;
    case 59:
      // bytes32
      if (typeof dataMapping.value === 'string' && byteLength(dataMapping.value) > 32) {
        throw boom.badRequest(errMessage);
      }
      break;
    case 8:
      // uint
      if (typeof dataMapping.value !== 'number' || dataMapping.value < 0) {
        throw boom.badRequest(errMessage);
      }
      break;
    case 18:
      // int
      if (typeof dataMapping.value !== 'number') {
        throw boom.badRequest(errMessage);
      }
      break;
    case 40:
      // address
      if (!dataMapping.value.match(/^[0-9A-Fa-f]{40}$/)) {
        throw boom.badRequest(errMessage);
      }
      break;
    default:
      break;
  }
};

const _prepareDataMappings = async (userAddress, activityInstanceId, dataMappings, direction) => {
  dataMappings.forEach((mapping) => {
    if (!mapping.id) throw boom.badRequest('Data mapping id required');
  });
  try {
    const details = await _getDataMappingDetails(userAddress, activityInstanceId, dataMappings.map(({ id }) => id), direction);
    if (dataMappings.length > 0) {
      dataMappings.forEach((mapping) => {
        Object.assign(mapping, details.filter(d => d.accessPointId === mapping.id)[0]);
        if (mapping.direction !== direction) throw boom.forbidden(`Data mapping does not allow ${direction === 0 ? 'read' : 'write'} access`);
        if (direction === global.__monax_constants.DIRECTION.OUT) _validateDataMapping(mapping);
      });
      return dataMappings;
    }
    return details;
  } catch (err) {
    if (boom.isBoom(err)) throw err;
    else throw boom.badImplementation(`Failed to prepare data mappings for activity ${activityInstanceId}: ${err}`);
  }
};

const _getInDataForActivity = async (userAddress, activityInstanceId, dataMappingId) => {
  const preparedDataMappings = await _prepareDataMappings(
    userAddress,
    activityInstanceId,
    dataMappingId ? [{ id: dataMappingId }] : [],
    global.__monax_constants.DIRECTION.IN,
  );
  const getValuePromises = preparedDataMappings.map(data => dataStorage.activityInDataGetters[`${data.dataType}`](userAddress, activityInstanceId, data.accessPointId));
  return new Promise((resolve, reject) => {
    Promise.all(getValuePromises)
      .then((dataValues) => {
        const data = preparedDataMappings.map((_mapping, i) => {
          const mapping = _mapping;
          mapping.value = dataValues[i];
          delete mapping.id;
          return format('Data', mapping);
        });
        return resolve(dataMappingId ? data[0] : data);
      })
      .catch(err => reject(boom.badImplementation(err)));
  });
};

const _getOutDataForActivity = async (userAddress, activityInstanceId, dataMappingId) => {
  const preparedDataMappings = await _prepareDataMappings(
    userAddress,
    activityInstanceId,
    dataMappingId ? [{ id: dataMappingId }] : [],
    global.__monax_constants.DIRECTION.OUT,
  );
  return preparedDataMappings;
};

const getActivityInstance = asyncMiddleware(async (req, res) => {
  let activityInstanceResult = (await sqlCache.getActivityInstanceData(req.params.id, req.user.address))[0];
  if (!activityInstanceResult) throw boom.notFound(`Activity instance ${req.params.id} not found or user not authorized`);
  activityInstanceResult = (await pgCache.populateTaskNames([activityInstanceResult]))[0];
  activityInstanceResult.performerName = (await setUserIds([{ address: activityInstanceResult.performer }]))[0];
  if (!activityInstanceResult.performerName) {
    activityInstanceResult.performerName = (await getNamesOfOrganizations([{ address: activityInstanceResult.performer }]))[0];
  }
  activityInstanceResult.performerName = activityInstanceResult.performerName.id || activityInstanceResult.performerName.name;
  activityInstanceResult.data = {};
  try {
    activityInstanceResult.data.in = await _getInDataForActivity(req.user.address, activityInstanceResult.activityInstanceId, null);
    activityInstanceResult.data.out = await _getOutDataForActivity(req.user.address, activityInstanceResult.activityInstanceId, null);
    return res.status(200).json(activityInstanceResult);
  } catch (err) {
    log.error(`Failed to get data mappings for activity ${req.params.id} and user ${req.user.address}: ${err}`);
    return res.status(200).json(format('Task', activityInstanceResult));
  }
});

const getDataMappings = asyncMiddleware(async ({ user, params: { activityInstanceId, dataMappingId } }, res) => {
  const data = await _getInDataForActivity(user.address, activityInstanceId, dataMappingId);
  return res.status(200).json(data);
});

const setDataMappings = asyncMiddleware(async ({ user, params: { activityInstanceId, dataMappingId }, body }, res) => {
  let dataMappings;
  if (dataMappingId) {
    dataMappings = [Object.assign(body, { id: dataMappingId })];
  } else {
    dataMappings = body;
    if (!Array.isArray(dataMappings)) throw boom.badRequest('Expected array of data mapping objects');
  }
  const preparedDataMappings = await _prepareDataMappings(user.address,
    activityInstanceId, dataMappings, global.__monax_constants.DIRECTION.OUT);
  const setValuePromises = preparedDataMappings.map(data => dataStorage.activityOutDataSetters[`${data.dataType}`](user.address, activityInstanceId, data.id, data.value));
  await Promise.all(setValuePromises)
    .then(() => res.sendStatus(200))
    .catch((err) => {
      throw boom.badImplementation(`Failed to set data mapping values for activity ${activityInstanceId}: ${err.stack}`);
    });
});

const getTasksForUser = asyncMiddleware(async ({ user: { address } }, res) => {
  if (!address) throw boom.badRequest('No logged in user found');
  const data = await sqlCache.getTasksByUserAddress(address);
  const tasks = await pgCache.populateTaskNames(data);
  return res.status(200).json(tasks.map(task => format('Task', task)));
});

const getModels = asyncMiddleware(async (req, res) => {
  if (!req.user.address) throw boom.badRequest('No logged in user found');
  const retData = [];
  const models = await sqlCache.getModels(req.user.address);
  models.forEach((model) => {
    retData.push(format('Model', model));
  });
  return res.status(200).json(retData);
});

const getApplications = asyncMiddleware(async (req, res) => {
  const applications = await sqlCache.getApplications();
  const appObj = {};
  applications.forEach((_app) => {
    const app = format('Application', _app);
    if (!appObj[app.id]) {
      app.accessPoints = [];
      appObj[app.id] = app;
    }
    if (app.accessPointId) {
      const accessPoint = format('Access Point', {
        accessPointId: app.accessPointId,
        direction: app.direction,
        dataType: app.dataType,
      });
      appObj[app.id].accessPoints.push(accessPoint);
    }
    delete appObj[app.id].accessPointId;
    delete appObj[app.id].direction;
    delete appObj[app.id].dataType;
  });
  return res.status(200).json(Object.values(appObj));
});

const validateProcess = asyncMiddleware(async (req, res) => {
  if (!req.body.address) throw boom.badRequest('Process definition address required');
  const isValid = await contracts.isValidProcess(req.body.address);
  return res.status(200).json({ processIsValid: isValid });
});

const writeDataForActivity = (userAddr, activityInstanceId, dataMappings) => {
  const promises = dataMappings.map((mapping) => {
    const setter = dataStorage.activityOutDataSetters[mapping.dataType];
    return setter(userAddr, activityInstanceId, mapping.id, mapping.value);
  });
  return Promise.all(promises)
    .then(() => Promise.resolve())
    .catch(err => Promise.reject(err));
};

const completeActivity = asyncMiddleware(async (req, res) => {
  const { activityInstanceId } = req.params;
  const userAddr = req.user.address;
  const { data } = req.body;
  if (!activityInstanceId) throw boom.badRequest('Activity instance Id required');
  if (data) {
    const preparedData = await _prepareDataMappings(userAddr, activityInstanceId, data, global.__monax_constants.DIRECTION.OUT);
    if (preparedData.length === 1) {
      // if only one data mapping then writing data and completing activity
      // are carried out as part of a single transaction in solidity
      // via the appropriately mapped function in
      // contracts-controller.js::getCompletionFunctionByParamType
      await contracts.completeActivity(userAddr, activityInstanceId,
        preparedData[0].id, preparedData[0].dataType, preparedData[0].value);
    } else {
      // in case of multiple data mappings, they are written as a series of promises
      // and then the activity is completed as a separate transaction
      await writeDataForActivity(userAddr, activityInstanceId, preparedData);
      await contracts.completeActivity(userAddr, activityInstanceId);
    }
  } else {
    await contracts.completeActivity(userAddr, activityInstanceId);
  }
  return res.sendStatus(200);
});

const signAndCompleteActivity = asyncMiddleware(async (req, res) => {
  if (!req.user.address) throw boom.badRequest('No logged in user found');
  if (!req.params.activityInstanceId) throw boom.badRequest('Activity instance Id required');
  if (!req.params.agreementAddress) throw boom.badRequest('agreemenrAddress is required');
  const id = req.params.activityInstanceId;
  const agreementAddr = req.params.agreementAddress;
  const userAddr = req.user.address;
  await contracts.signAgreement(userAddr, agreementAddr);
  await contracts.completeActivity(userAddr, id);
  return res.sendStatus(200);
});

const getProcessInstanceCount = asyncMiddleware(async (req, res) => {
  let count = await contracts.getProcessInstanceCount();
  count = parseInt(count, 10);
  return res.status(200).json({ count });
});

const getDefinitions = asyncMiddleware(async (req, res) => {
  if (!req.user.address) throw boom.badRequest('No logged in user found');
  const data = await sqlCache.getProcessDefinitions(req.user.address, req.query.interfaceId);
  const processes = await pgCache.populateProcessNames(data);
  return res.status(200).json(processes);
});

const getDefinition = asyncMiddleware(async (req, res) => {
  const processDefn = (await sqlCache.getProcessDefinitionData(req.params.address))[0];
  const profileData = (await sqlCache.getProfile(req.user.address))[0];
  if (!processDefn) throw boom.notFound(`Data for process definition ${req.params.address} not found`);
  if (processDefn.isPrivate &&
    processDefn.author !== req.user.address &&
    !profileData.find(({ organization }) => organization === processDefn.author)) {
    throw boom.forbidden('You are not authorized to view process details from this private model');
  }
  // retData = format('Definition', processDefn);
  const data = await pgCache.populateProcessNames([processDefn]);
  return res.status(200).json(data[0]);
});

const parseBpmnModel = async (rawXml) => {
  const anParser = parser.getNewParser();
  try {
    await anParser.parse(rawXml);
    const model = anParser.getModel();
    const processes = anParser.getProcesses();
    return { model, processes };
  } catch (err) {
    if (boom.isBoom(err)) throw err;
    else throw boom.badImplementation(`Failed to parse xml: ${err}`);
  }
};

const getModelDiagram = asyncMiddleware(async (req, res) => {
  const model = (await sqlCache.getProcessModelData(req.params.address))[0];
  if (!model) throw boom.notFound(`Data for process model ${req.params.address} not found`);
  const profileData = (await sqlCache.getProfile(req.user.address))[0];
  if (model.isPrivate &&
    model.author !== req.user.address &&
    !profileData.find(({ organization }) => organization === model.author)) {
    throw boom.forbidden('You are not authorized to view this private model');
  }
  const diagram = await getModelFromHoard(model.diagramAddress, model.diagramSecret);
  const data = splitMeta(diagram);
  if (req.headers.accept.includes('application/xml')) {
    res.attachment(data.meta.name);
    return res.status(200).send(data.data);
  }
  if (req.headers.accept.includes('application/json')) {
    const parsedModel = await parseBpmnModel(data.data.toString());
    return res.status(200).json(parsedModel);
  }
  throw boom.badRequest(`${req.headers.accept} format not supported`);
});

/* ************************************************************************
 * Controller functions specific to model & process generation from BPMN
 ************************************************************************ */

const pushModelXmlToHoard = async (rawXml) => {
  let hoardRef;
  try {
    const plaintext = {
      data: addMeta({
        mime: 'application/xml',
        name: 'bpmn_xml',
      }, rawXml),
    };
    hoardRef = await hoard.put(plaintext);
    return {
      address: hoardRef.address.toString('hex'),
      secretKey: hoardRef.secretKey.toString('hex'),
      salt: hoardRef.salt.toString('hex'),
    };
  } catch (err) {
    throw boom.badImplementation(`Failed to upload data to hoard: ${err}`);
  }
};

const setDefaultTransitions = (pdAddress, defaultTransitions = []) => {
  const promises = defaultTransitions.map(t => contracts.setDefaultTransition(pdAddress, t.gateway, t.activity));
  return Promise.all(promises)
    .then(() => Promise.resolve())
    .catch(err => Promise.reject(boom.badImplementation(err)));
};

const addTransitionsFromBpmn = (pdAddress, transitions) => {
  const transitionPromises = [];
  transitions.forEach((transition) => {
    if (!transition.source || !transition.target) {
      throw boom
        .badRequest(`Transition source and target IDs are required for transition id ${transition.id} in process definition at ${pdAddress}`);
    }
    transitionPromises.push(contracts.createTransition(pdAddress, transition.source, transition.target));
  });
  // TODO - Implemented chaining of individual promises in the loop above. - this seems to have solved the out of sequence creation of transitions and transition conditions
  // Need to keep an eye out for the time being to ensure we don't get such failure with the above strategy
  return Promise.all(transitionPromises)
    .then(() => Promise.resolve())
    .catch(err => Promise.reject(boom.badImplementation(`Failed to create transition(s): ${err.stack}`)));
};

const addTransitionConditionsFromBpmn = (pdAddress, transitions) => {
  const conditionPromises = [];
  transitions.forEach((transition) => {
    if (transition.condition) {
      conditionPromises.push(
        contracts.createTransitionCondition(
          pdAddress,
          transition.condition.dataType,
          transition.source,
          transition.target,
          transition.condition.lhDataPath,
          transition.condition.lhDataStorageId,
          0x0,
          transition.condition.operator,
          transition.condition.rhValue,
        ),
      );
    }
  });
  // TODO - Implemented chaining of individual promises in the loop above. - this seems to have solved the out of sequence creation of transitions and transition conditions
  // Need to keep an eye out for the time being to ensure we don't get such failure with the above strategy
  return Promise.all(conditionPromises)
    .then(() => Promise.resolve())
    .catch(err => Promise.reject(boom.badImplementation(`Failed to create condition(s): ${err.stack}`)));
};

const addBpmnGateways = (pdAddress, gateways) => {
  const promises = gateways.map((gateway) => {
    if (!gateway.id) {
      throw boom.badRequest(`Gateway in process definition at ${pdAddress} does not have an id`);
    }
    if (!(gateway.type === 0 || gateway.type === 2)) {
      throw boom.badRequest(`Gateway with id ${gateway.id} in process definition at ${pdAddress} has unsupported gateway type of ${gateway.type}`);
    }
    return contracts.createGateway(pdAddress, gateway.id, gateway.type);
  });
  return Promise.all(promises)
    .then(() => Promise.resolve())
    .catch(err => Promise.reject(boom
      .badImplementation(`Failed to create BPMN gateways for process at ${pdAddress}: ${err.stack}`)));
};

const addBpmnFlowElements = (pdAddress, tasks) => {
  const taskPromises = [];
  let dataMappings = [];
  tasks.forEach((task) => {
    taskPromises.push(contracts.createActivityDefinition(
      pdAddress,
      task.id,
      task.activityType,
      task.taskType,
      task.behavior,
      task.assignee,
      task.multiInstance,
      task.application,
      task.subProcessModelId,
      task.subProcessDefinitionId,
    ));
    if (task.dataMappings) {
      dataMappings = dataMappings.concat(task.dataMappings.map(m => Object.assign(m, { taskId: task.id })));
    }
  });
  return Promise.all(taskPromises)
    .then(() => Promise.all(dataMappings.map(m => contracts.createDataMapping(
      pdAddress, m.taskId, m.direction, m.id, m.dataPath, m.dataStorageId, 0x0,
    ))))
    .then(() => Promise.resolve())
    .catch(err => Promise.reject(boom
      .badImplementation(`Failed to create BPMN activities and/or data-mappings in process at ${pdAddress}: ${err.stack}`)));
};

const addParticipantsFromBpmn = (pmAddress, participants) => new Promise((resolve, reject) => {
  const promises = participants.map((participant) => {
    if (Object.prototype.hasOwnProperty.call(participant, 'account') &&
      Object.prototype.hasOwnProperty.call(participant, 'conditionalPerformer')) {
      return reject(boom.badRequest(`Participant ${participant.id} has both account and conditional performer`));
    }
    if (Object.prototype.hasOwnProperty.call(participant, 'account')) {
      return contracts.addParticipant(pmAddress, participant.id, participant.account, '', '', '');
    }
    if (Object.prototype.hasOwnProperty.call(participant, 'conditionalPerformer')) {
      if (!Object.prototype.hasOwnProperty.call(participant, 'dataPath') ||
        !Object.prototype.hasOwnProperty.call(participant, 'dataStorageId')) {
        return reject(boom
          .badRequest(`Participant ${participant.id} is designated as a conditional performer but does not have dataPath or dataStorageId`));
      }
      return contracts.addParticipant(pmAddress, participant.id, '', participant.dataPath, participant.dataStorageId, '');
    }
    return reject(boom
      .badRequest(`Participant ${participant.id} has neither an account address or been designated as a conditional performer - one or the other is required`));
  });
  Promise.all(promises)
    .then(() => resolve())
    .catch(err => reject(boom.badImplementation(err)));
});

const addProcessToModel = (pmAddress, pd) => new Promise(async (resolve, reject) => {
  const proc = {
    processDefinitionId: pd.id,
    interfaceId: pd.interface,
    processName: pd.name,
    modelAddress: pmAddress,
  };
  try {
    proc.address = await contracts.createProcessDefinition(pmAddress, pd.id);
    await contracts.addProcessInterface(pmAddress, pd.interface);
    await contracts.addProcessInterfaceImplementation(pmAddress, proc.address, pd.interface);
    await addParticipantsFromBpmn(pmAddress, pd.participants);
    await addBpmnFlowElements(proc.address, pd.tasks);
    await addBpmnFlowElements(proc.address, pd.userTasks);
    await addBpmnFlowElements(proc.address, pd.subProcesses);
    await addBpmnFlowElements(proc.address, pd.sendTasks);
    await addBpmnFlowElements(proc.address, pd.serviceTasks);
    await addBpmnGateways(proc.address, pd.xorGateways);
    await addBpmnGateways(proc.address, pd.andGateways);
    await addTransitionsFromBpmn(proc.address, pd.transitions);
    await addTransitionConditionsFromBpmn(proc.address, pd.transitions);
    await setDefaultTransitions(proc.address, pd.defaultTransitions);
    await contracts.isValidProcess(proc.address);
    await contracts.getStartActivity(proc.address);
    return resolve(proc);
  } catch (err) {
    return reject(boom.badImplementation(`Error while adding process [ ${pd.name} ] with id: [ ${pd.id} ]: ${err}`));
  }
});

const addProcessesToModel = (modelAddress, processes) => new Promise((resolve, reject) => {
  const processPromises = processes.map(p => addProcessToModel(modelAddress, p));
  Promise.all(processPromises)
    .then(processResponses => resolve(processResponses))
    .catch(error => reject(boom.badImplementation(`Failed to add processes to model at [ ${modelAddress} ]: ${error}`)));
});

const createModelFromBpmn = asyncMiddleware(async (req, res) => {
  if (!req.user.address) throw boom.badRequest('No logged in user found');
  if (req.query.format && req.query.format !== 'bpmn') {
    throw boom.notAcceptable(`${req.query.format} format not supported`);
  }
  const rawXml = req.body;
  if (!rawXml) throw boom.badRequest('rawXml required');
  const response = {
    model: {},
    processes: [],
  };
  const parsedResponse = await parseBpmnModel(rawXml);
  const { model, processes } = parsedResponse;
  model.author = req.user.address;
  response.model.id = model.id;
  const hoardRef = await pushModelXmlToHoard(rawXml);
  response.model.address = await contracts.createProcessModel(model.id, model.name, model.version, model.author, model.private, hoardRef.address, hoardRef.secretKey);
  response.processes = await addProcessesToModel(response.model.address, processes);
  response.processes = response.processes.map(_proc => Object.assign(_proc, { isPrivate: model.isPrivate, author: model.author }));
  response.parsedDiagram = parsedResponse;
  return res.status(200).json(response);
});

/* *****************************************************************************
 * END -- Controller functions specific to model & process generation from BPMN
 ***************************************************************************** */

module.exports = {
  createModelFromBpmn,
  validateProcess,
  completeActivity,
  signAndCompleteActivity,
  getProcessInstanceCount,
  getActivityInstances,
  getActivityInstance,
  getDataMappings,
  setDataMappings,
  getTasksForUser,
  getModels,
  getApplications,
  getDefinitions,
  getDefinition,
  getModelDiagram,
  parseBpmnModel,
  pushModelXmlToHoard,
  addProcessesToModel,
};
