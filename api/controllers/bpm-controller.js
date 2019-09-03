const path = require('path');
const boom = require('@hapi/boom');
const joi = require('@hapi/joi');
const contracts = require(`${global.__controllers}/contracts-controller`);
const {
  format,
  splitMeta,
  asyncMiddleware,
  byteLength,
} = require(`${global.__common}/controller-dependencies`);
const parser = require(path.resolve(global.__lib, 'bpmn-parser.js'));
const {
  hoardPut,
  hoardGet,
} = require(`${global.__controllers}/hoard-controller`);
const sqlCache = require('./postgres-query-helper');
const dataStorage = require(path.join(`${global.__controllers}/data-storage-controller`));
const { createOrFindAccountsWithEmails } = require(`${global.__controllers}/participants-controller`);
const { PARAM_TYPE_TO_DATA_TYPE_MAP, DATA_TYPES } = require(`${global.__common}/constants`);
const signatureSchema = require(`${global.__schemas}/signature`);

const getActivityInstances = asyncMiddleware(async (req, res, next) => {
  const data = await sqlCache.getActivityInstances(req.user.address, req.query);
  res.locals.data = data;
  res.status(200);
  return next();
});

const _validateDataMappings = (dataMappings) => {
  dataMappings.forEach((dataMapping) => {
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
  });
};

const getValuesForDataMappings = (userAddress, activityInstanceId, dataMappings) => {
  const getValuePromises = dataMappings
    .map(async (data) => {
      if (data.direction === 0) {
        let value = await dataStorage.activityInDataGetters[data.dataType](userAddress, activityInstanceId, data.dataMappingId);
        if (data.dataType === DATA_TYPES.ADDRESS && Number(value) === 0) value = null;
        if (data.parameterType === 5) value /= 100;
        return {
          ...data,
          value,
        };
      }
      return data;
    });
  return Promise.all(getValuePromises);
};

const addDataTypes = dataMappings => dataMappings.map(dm => ({
  ...dm,
  dataType: PARAM_TYPE_TO_DATA_TYPE_MAP[dm.parameterType].dataType,
}));

const getActivityInstance = asyncMiddleware(async (req, res, next) => {
  const activityInstanceResult = (await sqlCache.getActivityInstanceData(req.params.id, req.user.address))[0];
  if (!activityInstanceResult) throw boom.notFound(`Activity instance ${req.params.id} not found`);
  if (activityInstanceResult.state !== 4) return res.status(200).json({ activityInstanceId: req.params.id, state: activityInstanceResult.state });
  if (!activityInstanceResult.assignedToUser) throw boom.forbidden(`User is not an authorized performer for activity instance ${req.params.id}`);
  activityInstanceResult.data = await sqlCache.getDataMappingsForActivity(req.params.id);
  activityInstanceResult.data = addDataTypes(activityInstanceResult.data);
  try {
    activityInstanceResult.data = await getValuesForDataMappings(req.user.address, req.params.id, activityInstanceResult.data);
  } catch (err) {
    throw boom.badImplementation(`Failed to get values for IN data mappings for activity instance id ${req.params.id}: ${err}`);
  }
  res.locals.data = activityInstanceResult;
  res.status(200);
  return next();
});

const getDataMappings = asyncMiddleware(async ({ user, params: { activityInstanceId, dataMappingId } }, res, next) => {
  let dataMappings = await sqlCache.getDataMappingsForActivity(activityInstanceId, dataMappingId);
  if (dataMappingId && !dataMappings[0]) throw boom.notFound(`Data mapping with id ${dataMappingId} for activity instance ${activityInstanceId} does not exist`);
  dataMappings = addDataTypes(dataMappings);
  try {
    dataMappings = await getValuesForDataMappings(user.address, activityInstanceId, dataMappings);
  } catch (err) {
    let msg = `Failed to get values for IN data mappings for activity instance id ${activityInstanceId}: ${err.stack}`;
    if (dataMappingId) msg = `Failed to get IN values for activity instance id ${activityInstanceId} and data mapping id ${dataMappingId}: ${err.stack}`;
    throw boom.badImplementation(msg);
  }
  res.locals.data = dataMappingId ? dataMappings[0] : dataMappings;
  res.status(200);
  return next();
});

const setDataMappings = asyncMiddleware(async ({ user, params: { activityInstanceId, dataMappingId }, body }, res, next) => {
  let dataMappings;
  if (dataMappingId) {
    dataMappings = [Object.assign(body, { id: dataMappingId })];
  } else {
    dataMappings = body;
    if (!Array.isArray(dataMappings)) throw boom.badRequest('Expected array of data mapping objects');
  }
  ({ parameters: dataMappings } = await createOrFindAccountsWithEmails(dataMappings, 'parameterType'));
  _validateDataMappings(dataMappings);
  const setValuePromises = dataMappings.map(data => dataStorage.activityOutDataSetters[`${data.dataType}`](user.address, activityInstanceId, data.id, data.value));
  await Promise.all(setValuePromises)
    .then(() => {
      res.status(200);
      return next();
    })
    .catch((err) => {
      throw boom.badImplementation(`Failed to set data mapping values for activity ${activityInstanceId}: ${err.stack}`);
    });
});

const getTasksForUser = asyncMiddleware(async ({ user: { address } }, res, next) => {
  if (!address) throw boom.badRequest('No logged in user found');
  const data = await sqlCache.getTasksByUserAddress(address);
  res.locals.data = data;
  res.status(200);
  return next();
});

const getModels = asyncMiddleware(async (req, res, next) => {
  if (!req.user.address) throw boom.badRequest('No logged in user found');
  const retData = [];
  const models = await sqlCache.getModels(req.user.address);
  models.forEach((model) => {
    retData.push(format('Model', model));
  });
  res.locals.data = retData;
  res.status(200);
  return next();
});

const getApplications = asyncMiddleware(async (req, res, next) => {
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
  res.locals.data = Object.values(appObj);
  res.status(200);
  return next();
});

const validateProcess = asyncMiddleware(async (req, res, next) => {
  if (!req.body.address) throw boom.badRequest('Process definition address required');
  const isValid = await contracts.isValidProcess(req.body.address);
  res.locals.data = { processIsValid: isValid };
  res.status(200);
  return next();
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

const completeActivity = asyncMiddleware(async (req, res, next) => {
  const { activityInstanceId } = req.params;
  const userAddr = req.user.address;
  let { data } = req.body;
  if (!activityInstanceId) throw boom.badRequest('Activity instance Id required');
  if (data) {
    ({ parameters: data } = await createOrFindAccountsWithEmails(data, 'parameterType'));
    _validateDataMappings(data);
    if (data.length === 1) {
      // if only one data mapping then writing data and completing activity
      // are carried out as part of a single transaction in solidity
      // via the appropriately mapped function in
      // contracts-controller.js::getCompletionFunctionByParamType
      await contracts.completeActivity(userAddr, activityInstanceId,
        data[0].id, data[0].dataType, data[0].value);
    } else {
      // in case of multiple data mappings, they are written as a series of promises
      // and then the activity is completed as a separate transaction
      await writeDataForActivity(userAddr, activityInstanceId, data);
      await contracts.completeActivity(userAddr, activityInstanceId);
    }
  } else {
    await contracts.completeActivity(userAddr, activityInstanceId);
  }
  res.status(200);
  return next();
});

const saveSignature = async (req, agreementAddress) => {
  const ip = (req.headers['x-original-forwarded-for'] || '').split(',').pop() ||
         (req.headers['x-forwarded-for'] || '').split(',').pop() ||
         req.connection.remoteAddress ||
         req.socket.remoteAddress ||
         req.connection.socket.remoteAddress;
  let signature = { ...req.body, userAddress: req.user.address, ip };
  let error = null;
  ({ value: signature, error } = joi.validate(signature, signatureSchema, { abortEarly: false }));
  if (error) throw boom.badRequest(`Missing or misformatted data for signature: ${error.stack}`);
  const agreement = await sqlCache.getAgreementData(agreementAddress, req.user.address, false);
  if (!agreement) throw boom.notFound(`Agreement at ${agreementAddress} not found or user has insufficient privileges`);
  let signatures;
  if (!agreement.signaturesFileReference) {
    // No reference stored- start new signatures
    signatures = [];
  } else {
    // Get existing data with reference
    signatures = await hoardGet(agreement.signaturesFileReference);
    signatures = splitMeta(signatures);
    signatures = JSON.parse(signatures.data);
  }
  signatures.push(signature);
  // Store new data in hoard
  const hoardGrant = await hoardPut({ agreement: agreementAddress, name: 'agreement_signatures.json', mime: 'application/json' }, JSON.stringify(signatures));
  await contracts.updateAgreementFileReference('SignatureLog', agreementAddress, hoardGrant);
};

const signAndCompleteActivity = asyncMiddleware(async (req, res, next) => {
  const { activityInstanceId, agreementAddress } = req.params;
  const userAddr = req.user.address;
  await saveSignature(req, agreementAddress);
  await contracts.signAgreement(userAddr, agreementAddress);
  await contracts.completeActivity(userAddr, activityInstanceId);
  res.status(200);
  return next();
});

const getProcessInstanceCount = asyncMiddleware(async (req, res, next) => {
  let count = await contracts.getProcessInstanceCount();
  count = parseInt(count, 10);
  res.locals.data = { count };
  res.status(200);
  return next();
});

const getDefinitions = asyncMiddleware(async (req, res, next) => {
  if (!req.user.address) throw boom.badRequest('No logged in user found');
  const data = await sqlCache.getProcessDefinitions(req.user.address, req.query);
  res.locals.data = data;
  res.status(200);
  return next();
});

const getDefinition = asyncMiddleware(async (req, res, next) => {
  const data = await sqlCache.getProcessDefinitionData(req.params.address, req.user.address);
  res.locals.data = data;
  res.status(200);
  return next();
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

const getModelDiagram = asyncMiddleware(async (req, res, next) => {
  const modelFileReference = await sqlCache.getProcessModelFileReference(req.params.address, req.user.address);
  const diagram = await hoardGet(modelFileReference);
  const data = splitMeta(diagram);
  if (req.headers.accept.includes('application/xml')) {
    res.attachment(data.meta.name);
    res.locals.data = data.data;
  } else if (req.headers.accept.includes('application/json')) {
    const parsedModel = await parseBpmnModel(data.data.toString());
    res.locals.data = parsedModel;
  } else {
    throw boom.badRequest(`${req.headers.accept} format not supported`);
  }
  res.status(200);
  return next();
});

/* ************************************************************************
 * Controller functions specific to model & process generation from BPMN
 ************************************************************************ */

const pushModelXmlToHoard = async (rawXml) => {
  let hoardGrant;
  try {
    const meta = {
      name: 'bpmn_xml',
      mime: 'application/xml',
    };
    hoardGrant = await hoardPut(meta, Buffer.from(rawXml));
    return hoardGrant;
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

const addBpmnFlowElements = ({
  modelId,
  processDefinitionId,
  address: pdAddress,
  processName,
}, tasks) => {
  const taskPromises = [];
  const saveTaskDetailPromises = [];
  let dataMappings = [];
  tasks.forEach((task) => {
    saveTaskDetailPromises.push(sqlCache.saveActivityDetails(modelId, processDefinitionId, processName, task.id, task.name));
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

const addTimerBoundaryEvents = (pdAddress, boundaryEvents) => {
  const promises = boundaryEvents.map(boundaryEvent => contracts.addBoundaryEvent(pdAddress, boundaryEvent));
  return Promise.all(promises);
};

const addTimerBoundaryEventEscalationActions = (pdAddress, boundaryEvents) => {
  const promises = boundaryEvents
    .filter(({ escalationAction }) => escalationAction)
    .map(boundaryEvent => contracts.addBoundaryEventAction(pdAddress, boundaryEvent));
  return Promise.all(promises);
};

const addTimerIntermediateCatchEvents = (pdAddress, intermediateCatchEvents) => {
  const promises = intermediateCatchEvents.map(intCatchEvent => contracts.createIntermediateEvent(pdAddress, intCatchEvent));
  return Promise.all(promises);
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

const addProcessToModel = (modelId, modelAddress, pd) => new Promise(async (resolve, reject) => {
  const proc = {
    modelId,
    processDefinitionId: pd.id,
    interfaceId: pd.interface,
    processName: pd.name,
    modelAddress,
  };
  try {
    proc.address = await contracts.createProcessDefinition(modelAddress, pd.id);
    await contracts.addProcessInterface(modelAddress, pd.interface);
    await contracts.addProcessInterfaceImplementation(modelAddress, proc.address, pd.interface);
    await addParticipantsFromBpmn(modelAddress, pd.participants);
    await addBpmnFlowElements(proc, pd.tasks);
    await addBpmnFlowElements(proc, pd.userTasks);
    await addBpmnFlowElements(proc, pd.subProcesses);
    await addBpmnFlowElements(proc, pd.sendTasks);
    await addBpmnFlowElements(proc, pd.serviceTasks);
    await addTimerBoundaryEvents(proc.address, pd.boundaryEvents);
    await addTimerBoundaryEventEscalationActions(proc.address, pd.boundaryEvents);
    await addTimerIntermediateCatchEvents(proc.address, pd.intermediateCatchEvents);
    await addBpmnGateways(proc.address, pd.xorGateways);
    await addBpmnGateways(proc.address, pd.andGateways);
    await addTransitionsFromBpmn(proc.address, pd.transitions);
    await addTransitionConditionsFromBpmn(proc.address, pd.transitions);
    await setDefaultTransitions(proc.address, pd.defaultTransitions);
    await contracts.isValidProcess(proc.address);
    await contracts.getStartActivity(proc.address);
    await sqlCache.saveProcessDetails(modelId, pd.id, pd.name);
    return resolve(proc);
  } catch (err) {
    return reject(boom.badImplementation(`Error while adding process [ ${pd.name} ] with id: [ ${pd.id} ]: ${err}`));
  }
});

const addProcessesToModel = (modelId, modelAddress, processes) => new Promise((resolve, reject) => {
  const processPromises = processes.map(p => addProcessToModel(modelId, modelAddress, p));
  Promise.all(processPromises)
    .then(processResponses => resolve(processResponses))
    .catch(error => reject(boom.badImplementation(`Failed to add processes to model at [ ${modelAddress} ]: ${error}`)));
});

/**
 * Adds the provided dataStoreFields to the model contract specified by the given address.
 */
const addDataDefinitionsToModel = (modelAddress, dataStoreFields) => new Promise((resolve, reject) => {
  const dataDefinitionPromises = dataStoreFields.map(field => contracts.addDataDefinitionToModel(modelAddress, field));
  Promise.all(dataDefinitionPromises)
    .then(dataDefinitionResponses => resolve(dataDefinitionResponses))
    .catch(error => reject(boom.badImplementation(`Failed to add data definitions to model at [ ${modelAddress} ]: ${error}`)));
});

const createModelFromBpmn = asyncMiddleware(async (req, res, next) => {
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
  const hoardGrant = await pushModelXmlToHoard(rawXml);
  response.model.address = await contracts.createProcessModel(model.id, model.version, model.author, model.private, hoardGrant);
  response.model.dataStoreFields = await addDataDefinitionsToModel(response.model.address, model.dataStoreFields);
  response.processes = await addProcessesToModel(model.id, response.model.address, processes);
  response.processes = response.processes.map(_proc => Object.assign(_proc, { isPrivate: model.isPrivate, author: model.author }));
  response.parsedDiagram = parsedResponse;
  res.locals.data = response;
  res.status(200);
  return next();
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
  addDataTypes,
  getValuesForDataMappings,
  getTasksForUser,
  getModels,
  getApplications,
  getDefinitions,
  getDefinition,
  getModelDiagram,
  parseBpmnModel,
  pushModelXmlToHoard,
  addProcessesToModel,
  addDataDefinitionsToModel,
};
