const _ = require('lodash');
const esmRequire = require('esm')(module);
const BpmnModdle = esmRequire('bpmn-moddle').default;
const moddle = new BpmnModdle();
const boom = esmRequire('@hapi/boom');
const moment = require('moment');
const { COMPARISON_OPERATOR, PARAM_TYPE_TO_DATA_TYPE_MAP, BPM_TIMER_EVENT_TYPES } = require('../common/constants');

const BPMN_ROOT_ELEMENTS = 'rootElements';
const BPMN_DEFINITION = 'bpmn:Definitions';
const BPMN_DATA_STORE = 'bpmn:DataStore';
const BPMN_LOOP_CHARACTERISTCS = 'loopCharacteristics';
const BPMN_TYPE_TASK = 'bpmn:Task';
const BPMN_TYPE_USER_TASK = 'bpmn:UserTask';
const BPMN_TYPE_SEND_TASK = 'bpmn:SendTask';
const BPMN_TYPE_SEQUENCE_FLOW = 'bpmn:SequenceFlow';
const BPMN_TYPE_PROCESS = 'bpmn:Process';
const BPMN_TYPE_SUBPROCESS = 'bpmn:SubProcess';
const BPMN_TYPE_SERVICE_TASK = 'bpmn:ServiceTask';
const BPMN_TYPE_COLLABORATION = 'bpmn:Collaboration';
const BPMN_TYPE_PARALLEL_GATEWAY = 'bpmn:ParallelGateway';
const BPMN_TYPE_EXCLUSIVE_GATEWAY = 'bpmn:ExclusiveGateway';
const BPMN_TYPE_BOUNDARY_EVENT = 'bpmn:BoundaryEvent';
const BPMN_TYPE_INTERMEDIATE_CATCH_EVENT = 'bpmn:IntermediateCatchEvent';
const BPMN_EXTENSION_PROPERTIES = 'camunda:properties';
const BPMN_EXTENTION_ELEMENTS = 'extensionElements';
const BPMN_EVENT_DEFINITIONS = 'eventDefinitions';
const BPMN_EVENT_ATTACHED_TO = 'attachedToRef';
const BPMN_TYPE_TIMER_EVENT_DEFINITION = 'bpmn:TimerEventDefinition';

const BPMN_DATAMAPPINGS_IN = 'IN';
const BPMN_DATAMAPPINGS_OUT = 'OUT';
const BPMN_DATAMAPPINGS_INOUT = 'INOUT';
const BPMN_DATASTORAGEID_PROCESS_INSTANCE = 'PROCESS_INSTANCE';

const BPM_MODEL_TASK_BEHAVIORS = {
  SEND: 0,
  SENDRECEIVE: 1,
  RECEIVE: 2,
};

const BPM_MODEL_ACTIVITY_TYPES = {
  TASK: 0,
  SUBPROCESS: 1,
};

const BPM_MODEL_TASK_TYPES = {
  NONE: 0,
  USER: 1,
  SERVICE: 2,
  EVENT: 3,
};

const BPM_MODEL_APPLICATION_TYPES = {
  EVENT: 0,
  SERVICE: 1,
  WEB: 2,
};

const BPM_MODEL_GATEWAY_TYPE = {
  XOR: 0,
  OR: 1,
  AND: 2,
};

const BPM_MODEL_DATA_STORE_IDS = {
  processInstance: 'PROCESS_INSTANCE',
  agreement: 'agreement',
};

const BPM_TIMER_TYPES = {
  DATE: 'timeDate',
  DURATION: 'timeDuration',
};

const BPM_TIMER_ESCALATION_ACTION = 'ESCALATION_ACTION';

const BPM_BOUNDARY_EVENT_BEHAVIORS = {
  INTERRUPTING: 0,
  NONINTERRUPTING: 1,
};

const BPM_INTERMEDIATE_EVENT_BEHAVIORS = {
  CATCHING: 0,
  THROWING: 1,
};

const getBooleanFromString = (val) => {
  if (val && val.constructor.name === 'Boolean') return val;
  if (val && val.constructor.name === 'String') {
    return val === 'true';
  }
  return false;
};

const formatConditionRhValue = (_value, dataType) => {
  let value;
  switch (dataType) {
    case 1:
      value = getBooleanFromString(_value);
      break;
    case 8:
      value = parseInt(_value, 10);
      break;
    default:
      value = _value;
  }
  return value;
};

const ISO8601DurationToSeconds = (ISO8601Duration) => {
  try {
    const duration = moment.duration(ISO8601Duration);
    if (!duration.isValid()) {
      throw boom.badData(`${ISO8601Duration} is not a valid duration`);
    }
    return Math.floor(duration.asSeconds());
  } catch (err) {
    throw boom.badData(`Failed to parse duration ${ISO8601Duration}: ${err.stack}`);
  }
};

const validateProcess = (process, dataStoreFields) => {
  const validationErrors = [];
  let err;
  process.transitions.forEach((_transition) => {
    const transition = Object.assign({}, _transition);
    if (transition.condition) {
      // test if transition condition data paths match a data store field
      const field = dataStoreFields.filter(f => f.dataPath === transition.condition.lhDataPath)[0];
      transition.condition.rhValue = formatConditionRhValue(transition.condition.rhValue, transition.condition.dataType);
      transition.condition.operator = parseInt(transition.condition.operator, 10);
      if (Object.values(COMPARISON_OPERATOR).indexOf(transition.condition.operator) === -1) {
        validationErrors.push(`Invalid operator ${transition.condition.operator} for transition condition in transition ${transition.id} in process ${process.id}`);
      }
      if (!field) {
        validationErrors.push(`No matching dataStore field found for transition ${transition.id} and it's condition lhDataPath ${transition.condition.lhDataPath}`);
      } else {
        transition.condition.dataType = PARAM_TYPE_TO_DATA_TYPE_MAP[field.parameterType].dataType;
      }
      // test if transition conditions only exist on outgoing transitions of xor gateways
      const sourceXorGateways = process.xorGateways.filter(gw => gw.id === transition.source);
      const sourceAndGateways = process.andGateways.filter(gw => gw.id === transition.source);
      // TODO commented out due to false validation errors on transition with condition between two XOR gateways
      // if (!process.activityMap[transition.target]) {
      //   validationErrors.push(`Transition ${transition.id} in process ${process.id} has a transition condition but is not an incoming transition of an activity`);
      // }
      if (sourceXorGateways.length !== 1 && sourceAndGateways.length !== 0) {
        validationErrors.push(`Transition ${transition.id} in process ${process.id} has a transition condition but is not an outgoing transition of an XOR gateway`);
      }
    }
  });
  if (validationErrors.length > 0) {
    err = boom.badData(`Process ${process.id} has one or more validation errors: ${JSON.stringify(validationErrors)}`);
    err.validationErrors = validationErrors;
    throw err;
  }
  return process;
};

const getDataMappings = (dataMappings) => {
  const retData = [];
  const idKeys = Object.keys(dataMappings).filter(elem => _.startsWith(elem, `${BPMN_DATAMAPPINGS_IN}DATAID`) || _.startsWith(elem, `${BPMN_DATAMAPPINGS_OUT}DATAID`) || _.startsWith(elem, `${BPMN_DATAMAPPINGS_INOUT}DATAID`));
  idKeys.forEach((key) => {
    const id = dataMappings[key];
    let direction = key.split('DATAID_')[0];
    const dataPathKey = `${direction}DATA_${id}_dataPath`;
    const dataPath = dataMappings[dataPathKey];
    const dataStorageIdKey = `${direction}DATA_${id}_dataStorageId`;
    const dataStorageId = dataMappings[dataStorageIdKey] === BPMN_DATASTORAGEID_PROCESS_INSTANCE ? '' : dataMappings[dataStorageIdKey];
    if (direction === BPMN_DATAMAPPINGS_IN) direction = 0;
    if (direction === BPMN_DATAMAPPINGS_OUT) direction = 1;
    if (direction === 0 || direction === 1) {
      retData.push({
        id,
        direction,
        dataPath,
        dataStorageId,
      });
    } else if (direction === BPMN_DATAMAPPINGS_INOUT) {
      retData.push({
        id,
        direction: 0,
        dataPath,
        dataStorageId,
      }, {
        id,
        direction: 1,
        dataPath,
        dataStorageId,
      });
    }
  });
  return retData;
};

const getExtensionElementsFromNode = (node) => {
  try {
    const extensionElements = {};
    const _values = _.get(node, 'extensionElements.values', []);
    _values.forEach((val) => {
      switch (val.$type) {
        case BPMN_EXTENSION_PROPERTIES: {
          extensionElements.properties = {};
          extensionElements.properties.dataMappings = {};
          extensionElements.properties.escalationActions = [];
          const _children = _.get(val, '$children', []);
          _children.forEach((child) => {
            if (_.startsWith(child.name, `${BPMN_DATAMAPPINGS_OUT}DATA`) || _.startsWith(child.name, `${BPMN_DATAMAPPINGS_IN}DATA`) || _.startsWith(child.name, `${BPMN_DATAMAPPINGS_INOUT}DATA`)) {
              extensionElements.properties.dataMappings[`${child.name}`] = child.value;
            } else if (_.startsWith(child.name, BPM_TIMER_ESCALATION_ACTION)) {
              let idx;
              let param;
              try {
                ({ 0: idx, 1: param } = child.name.split(`${BPM_TIMER_ESCALATION_ACTION}_`)[1].split('_'));
              } catch (err) {
                return;
              }
              if (!extensionElements.properties.escalationActions[idx]) extensionElements.properties.escalationActions[idx] = {};
              extensionElements.properties.escalationActions[idx][param] = param === 'dataStorageId' && child.value === BPMN_DATASTORAGEID_PROCESS_INSTANCE ? '' : child.value;
            } else {
              extensionElements.properties[`${child.name}`] = child.value || '';
            }
          });
          if (Object.keys(extensionElements.properties.dataMappings).length === 0) {
            delete extensionElements.properties.dataMappings;
          } else {
            extensionElements.properties.dataMappings =
              getDataMappings(extensionElements.properties.dataMappings);
          }
          extensionElements.properties.escalationActions = extensionElements.properties.escalationActions.filter(action => action);
          if (!extensionElements.properties.escalationActions.length) delete extensionElements.properties.escalationActions;
          break;
        }
        default:
          break;
        // handle other types of extension elements here
      }
    });
    return extensionElements;
  } catch (error) {
    if (boom.isBoom(error)) throw error;
    else throw boom.badImplementation(`Failed to parse extensions: ${error}`);
  }
};

const getTasksFromNode = (node) => {
  const _task = {
    id: node.id,
    name: node.name,
    assignee: '',
    activityType: BPM_MODEL_ACTIVITY_TYPES.TASK,
    taskType: BPM_MODEL_TASK_TYPES.NONE,
    behavior: BPM_MODEL_TASK_BEHAVIORS.SEND,
    multiInstance: false,
    application: '',
    subProcessModelId: '',
    subProcessDefinitionId: '',
  };
  if (Object.prototype.hasOwnProperty.call(node, BPMN_EXTENTION_ELEMENTS)) {
    Object.assign(_task, getExtensionElementsFromNode(node).properties);
  }
  _task.behavior = parseInt(_task.behavior, 10);
  if (!Object.values(BPM_MODEL_TASK_BEHAVIORS).includes(_task.behavior)) {
    throw boom.badData(`Valid BpmnModel TaskBehavior required for send task ${node.name}`);
  }
  return _task;
};

const getServiceTasksFromNode = (node) => {
  const serviceTask = {
    id: node.id,
    name: node.name,
    assignee: '',
    activityType: BPM_MODEL_ACTIVITY_TYPES.TASK,
    taskType: BPM_MODEL_TASK_TYPES.SERVICE,
    behavior: BPM_MODEL_TASK_BEHAVIORS.SEND,
    multiInstance: false,
    subProcessModelId: '',
    subProcessDefinitionId: '',
  };
  const { properties } = getExtensionElementsFromNode(node);
  if (!properties || !properties.application) {
    throw boom.badData('application is a required extension element for a serviceTask activity');
  }
  // some fields below are hardcoded to empty Strings because they are irrelevant for serviceTask
  // but cannot be undefined for createActivityDefinition
  Object.assign(serviceTask, properties);
  return serviceTask;
};

const getSubProcessesFromNode = (node) => {
  const { properties } = getExtensionElementsFromNode(node);
  if (!properties.processId) throw boom.badData('processId is a required extension element for a subProcess activity');
  // some fields below are hardcoded to empty Strings because they are irrelevant for subProcesses
  // but cannot be undefined for createActivityDefinition
  return {
    id: node.id,
    name: node.name,
    assignee: '',
    activityType: BPM_MODEL_ACTIVITY_TYPES.SUBPROCESS,
    taskType: BPM_MODEL_TASK_TYPES.NONE,
    behavior: BPM_MODEL_TASK_BEHAVIORS.SEND,
    multiInstance: false,
    application: '',
    subProcessModelId: properties.modelId || '',
    subProcessDefinitionId: properties.processId,
  };
};

const getTransitionFromNode = (node) => {
  const transition = {
    id: node.id,
    source: node.sourceRef.id,
    target: node.targetRef.id,
  };
  const { properties } = getExtensionElementsFromNode(node);
  if (properties && Object.keys(properties).length > 0) {
    if (!properties.lhDataPath ||
      !properties.lhDataStorageId ||
      properties.operator === undefined ||
      properties.rhValue === undefined
    ) {
      throw boom.badData(`Invalid expression for transition ${node.id}. ` +
        '"lhDataPath", "lhDataStorageId", "operator" and "rhValue" are required fields.'); // TODO instead of rhValue (fixed), an rhDataStorageId and rhDataPath are also valid. The if statement needs work to support this
    }
    // check if dataStorageIds are set and replace reserved DataStorage ID for PROCESS_INSTANCE with an empty string, if detected
    if (properties.lhDataStorageId === BPMN_DATASTORAGEID_PROCESS_INSTANCE) {
      properties.lhDataStorageId = '';
    }
    if (properties.rhDataStorageId === BPMN_DATASTORAGEID_PROCESS_INSTANCE) {
      properties.rhDataStorageId = '';
    }
    transition.condition = properties;
  }
  return transition;
};

const getUserTaskFromNode = (node, participants) => {
  const participant = participants.filter(p => p.tasks.includes(node.id));
  if (participant.length === 0) throw boom.badData(`No assignee found for task with id ${node.id}`);
  // some fields below are hardcoded to empty Strings because they are irrelevant for tasks
  // but cannot be undefined for createActivityDefinition
  const _task = {};
  _task.id = node.id;
  _task.name = node.name;
  _task.assignee = participant[0].id;
  _task.activityType = BPM_MODEL_ACTIVITY_TYPES.TASK;
  _task.taskType = BPM_MODEL_TASK_TYPES.USER;
  _task.behavior = BPM_MODEL_TASK_BEHAVIORS.SENDRECEIVE;
  _task.multiInstance = Object.prototype.hasOwnProperty.call(node, BPMN_LOOP_CHARACTERISTCS);
  if (Object.prototype.hasOwnProperty.call(node, BPMN_EXTENTION_ELEMENTS)) {
    // expecting application and completionFunction
    Object.assign(_task, getExtensionElementsFromNode(node).properties);
  }
  _task.application = _task.application || '';
  _task.subProcessModelId = '';
  _task.subProcessDefinitionId = '';
  return _task;
};

const getSendTaskFromNode = (node) => {
  const _task = {
    id: node.id,
    name: node.name,
    activityType: BPM_MODEL_ACTIVITY_TYPES.TASK,
    taskType: BPM_MODEL_TASK_TYPES.EVENT,
    application: '',
    behavior: BPM_MODEL_TASK_BEHAVIORS.SENDRECEIVE,
  };
  if (Object.prototype.hasOwnProperty.call(node, BPMN_EXTENTION_ELEMENTS)) {
    Object.assign(_task, getExtensionElementsFromNode(node).properties);
  }
  _task.behavior = parseInt(_task.behavior, 10);
  if (!Object.values(BPM_MODEL_TASK_BEHAVIORS).includes(_task.behavior)) {
    throw boom.badData(`Valid BpmnModel TaskBehavior required for send task ${node.name}`);
  }
  _task.subProcessModelId = '';
  _task.subProcessDefinitionId = '';
  _task.assignee = '';
  _task.multiInstance = false;
  return _task;
};

const getGatewayFromNode = (node, type) => {
  const response = {
    gateway: {},
    defaultTransition: {},
  };
  const typeStr = Object.keys(BPM_MODEL_GATEWAY_TYPE)[type];
  if (!Array.isArray(node.incoming) || node.incoming.length === 0) {
    throw boom.badData(`${typeStr} gateway ${node.id} needs at least 1 incoming transition`);
  }
  if (!Array.isArray(node.outgoing) || node.outgoing.length === 0) {
    throw boom.badData(`${typeStr} gateway ${node.id} needs at least 1 outgoing transition`);
  }
  if (node.incoming.length === 1 && node.outgoing.length === 1) {
    throw boom.badData(`${typeStr} gateway ${node.id} must have multiple incoming and/or outgoing transitions`);
  }
  response.gateway.id = node.id;
  response.gateway.type = type;
  if (BPM_MODEL_GATEWAY_TYPE.XOR === type && node.default) {
    response.defaultTransition.gateway = node.id;
    response.defaultTransition.transition = node.default.id;
  } else {
    delete response.defaultTransition;
  }
  response.gateway.incoming = node.incoming.map(seq => seq.id);
  response.gateway.outgoing = node.outgoing.map(seq => seq.id);
  return response;
};

const getTimerEventDefinition = (node) => {
  const eventEl = node[BPMN_EVENT_DEFINITIONS][0];
  if (!eventEl || eventEl['$type'] !== BPMN_TYPE_TIMER_EVENT_DEFINITION) {
    throw boom.badData(`${node.$type} must have a timer event definition`);
  }
  return eventEl;
};

const getTimerEventDefinitionType = (eventEl) => {
  let timerType;
  timerType = eventEl[BPM_TIMER_TYPES.DATE] ? BPM_TIMER_TYPES.DATE : null;
  timerType = timerType || (eventEl[BPM_TIMER_TYPES.DURATION] ? BPM_TIMER_TYPES.DURATION : null);
  if (!timerType) throw boom.badData(`Timer event definition must have ${BPM_TIMER_TYPES.DATE} or ${BPM_TIMER_TYPES.DURATION}`);
  return timerType;
};

const getTimerEventDefinitionConfiguration = (timer, timerType) => {
  if (timerType === BPM_TIMER_TYPES.DURATION && timer.body) {
    // for timeDuration, allow fixed value
    // TODO: validate duration format (ISO-8601)
    return { fixedValue: ISO8601DurationToSeconds(timer.body) };
  }
  if (timer[BPMN_EXTENTION_ELEMENTS]) {
    // get properties stored as child of the timeDate or timeDuration
    // should include data mapping info of conditional data that defines the date or duration
    const { properties } = getExtensionElementsFromNode(timer);
    if (!properties || !properties.dataMappings || !properties.dataMappings.length) throw boom.badData(`Conditional data for ${timerType} must be stored in data mappings`);
    return { conditionalValue: properties.dataMappings[0] };
  }
  throw boom.badData(`${timerType} requires conditional or fixed (duration only) data`);
};

const getTimerBoundaryEventFromNode = (node) => {
  const timerEventDefinition = getTimerEventDefinition(node);
  const timerType = getTimerEventDefinitionType(timerEventDefinition);
  let escalationAction;
  if (timerEventDefinition[BPMN_EXTENTION_ELEMENTS]) {
    const { properties } = getExtensionElementsFromNode(timerEventDefinition);
    if (properties && properties.escalationActions) {
      escalationAction = properties.escalationActions[0];
      if (escalationAction && !escalationAction.dataPath) throw boom.badData(`Escalation action for boundary event ${node.id} is missing a data path`);
      if (escalationAction && !escalationAction.targetFunction) throw boom.badData(`Escalation action for boundary event ${node.id} is missing a target function`);
    }
  }
  const config = getTimerEventDefinitionConfiguration(timerEventDefinition[timerType], timerType);
  const response = {
    name: node.name,
    id: node.id,
    attachedTo: node[BPMN_EVENT_ATTACHED_TO].id,
    eventType: BPM_TIMER_EVENT_TYPES[timerType],
    eventBehavior: BPM_BOUNDARY_EVENT_BEHAVIORS.INTERRUPTING, // smart contracts will set this to interrupting anyway
    fixedValue: config.fixedValue,
    conditionalValue: config.conditionalValue,
    escalationAction,
  };
  return response;
};

const getIntermediateCatchEventFromNode = (node) => {
  const timerEventDefinition = getTimerEventDefinition(node);
  const timerType = getTimerEventDefinitionType(timerEventDefinition);
  const config = getTimerEventDefinitionConfiguration(timerEventDefinition[timerType], timerType);
  const response = {
    name: node.name,
    id: node.id,
    eventType: BPM_TIMER_EVENT_TYPES[timerType],
    eventBehavior: BPM_INTERMEDIATE_EVENT_BEHAVIORS.CATCHING,
    fixedValue: config.fixedValue,
    conditionalValue: config.conditionalValue,
  };
  return response;
};

const getFlowElementDetails = (flowElements, participants) => {
  const response = {
    tasks: [],
    userTasks: [],
    sendTasks: [],
    transitions: [],
    subProcesses: [],
    serviceTasks: [],
    xorGateways: [],
    andGateways: [],
    activityMap: {},
    defaultTransitions: [],
    boundaryEvents: [],
    intermediateCatchEvents: [],
  };
  let task;
  let userTask;
  let sendTask;
  let serviceTask;
  let gateway;
  let defaultTransition;
  flowElements.forEach((elem) => {
    switch (elem.$type) {
      case BPMN_TYPE_SEQUENCE_FLOW:
        response.transitions.push(getTransitionFromNode(elem));
        break;
      case BPMN_TYPE_TASK:
        task = getTasksFromNode(elem);
        response.activityMap[task.id] = task.name;
        response.tasks.push(task);
        break;
      case BPMN_TYPE_USER_TASK:
        userTask = getUserTaskFromNode(elem, participants);
        response.activityMap[userTask.id] = userTask.name;
        response.userTasks.push(userTask);
        break;
      case BPMN_TYPE_SEND_TASK:
        sendTask = getSendTaskFromNode(elem);
        response.activityMap[sendTask.id] = sendTask.name;
        response.sendTasks.push(sendTask);
        break;
      case BPMN_TYPE_SUBPROCESS:
        response.subProcesses.push(getSubProcessesFromNode(elem));
        break;
      case BPMN_TYPE_SERVICE_TASK:
        serviceTask = getServiceTasksFromNode(elem);
        response.activityMap[serviceTask.id] = serviceTask.name;
        response.serviceTasks.push(serviceTask);
        break;
      case BPMN_TYPE_EXCLUSIVE_GATEWAY:
        ({ gateway, defaultTransition } = getGatewayFromNode(elem, BPM_MODEL_GATEWAY_TYPE.XOR));
        response.xorGateways.push(gateway);
        if (defaultTransition) response.defaultTransitions.push(defaultTransition);
        break;
      case BPMN_TYPE_PARALLEL_GATEWAY:
        response.andGateways.push(getGatewayFromNode(elem, BPM_MODEL_GATEWAY_TYPE.AND).gateway);
        break;
      case BPMN_TYPE_BOUNDARY_EVENT:
        response.boundaryEvents.push(getTimerBoundaryEventFromNode(elem));
        break;
      case BPMN_TYPE_INTERMEDIATE_CATCH_EVENT:
        response.intermediateCatchEvents.push(getIntermediateCatchEventFromNode(elem));
        break;
      default:
        break;
    }
  });
  if (response.defaultTransitions.length > 0) {
    response.defaultTransitions.forEach((elem, i) => {
      const activity = response.transitions.filter(t => t.id === elem.transition)[0].target;
      if (!activity) throw boom.badData(`No matching target activity found for transition ${elem.transition}`);
      response.defaultTransitions[i].activity = activity;
    });
  } else {
    delete response.defaultTransitions;
  }
  return response;
};

const getProcessInterface = (_process) => {
  try {
    return getExtensionElementsFromNode(_process).properties.processInterface;
  } catch (error) {
    if (boom.isBoom(error)) throw error;
    else throw boom.badImplementation(`Failed to parse process interface: ${error}`);
  }
};

const getProcessParticipants = (_laneSets) => {
  try {
    const res = [];
    let _lanes = [];
    _laneSets.forEach((_laneSet) => {
      _lanes = _lanes.concat(_.get(_laneSet, 'lanes', []));
    });
    _lanes.forEach((lane) => {
      // Ignore lanes that do not have account/conditionalPerformer set
      if (Object.prototype.hasOwnProperty.call(lane, BPMN_EXTENTION_ELEMENTS)) {
        const _participant = {};
        const tasks = _.get(lane, 'flowNodeRef', []);
        _participant.id = lane.id;
        _participant.name = lane.name;
        _participant.tasks = [];
        tasks.forEach((task) => {
          _participant.tasks.push(task.id);
        });
        Object.assign(_participant, getExtensionElementsFromNode(lane).properties);
        if (_participant.conditionalPerformer) {
          _participant.conditionalPerformer = getBooleanFromString(_participant.conditionalPerformer);
        }
        res.push(_participant);
      }
    });
    return res;
  } catch (error) {
    if (boom.isBoom(error)) throw error;
    else throw boom.badImplementation(`Failed to parse lanes to retrieve participants: ${error}`);
  }
};

const parseProcesses = (bpmnJson) => {
  const _processes = [];
  const parsedProcesses = _.get(bpmnJson, BPMN_ROOT_ELEMENTS, []).filter(item => item.$type === BPMN_TYPE_PROCESS);
  try {
    parsedProcesses.forEach((proc) => {
      const _process = {};
      _process.id = proc.id;
      _process.name = proc.name;
      _process.interface = proc.extensionElements ? getProcessInterface(proc) : '';
      _process.participants = getProcessParticipants(_.get(proc, 'laneSets', []));
      Object.assign(_process, getFlowElementDetails(_.get(proc, 'flowElements', []), _process.participants));
      _processes.push(_process);
    });
    return _processes;
  } catch (error) {
    if (boom.isBoom(error)) throw error;
    else throw boom.badImplementation(`Failed to get process details: ${error.stack}`);
  }
};

const parseModelDetails = (bpmnJson) => {
  let _model = {};
  const dataStoreFields = [];
  Object.values(BPM_MODEL_DATA_STORE_IDS).forEach((id) => {
    const dataStore = _.get(bpmnJson, BPMN_ROOT_ELEMENTS, []).find(item => item.$type === BPMN_DATA_STORE && item.id === id);
    if (!dataStore) {
      throw boom.badData(`Data store with id ${id} required but not found`);
    }
    const parameters = getExtensionElementsFromNode(dataStore).properties;
    if (id === BPM_MODEL_DATA_STORE_IDS.processInstance && parameters.agreement !== '7') {
      throw boom.badData('Process Instance data store requires agreement field of type contract address (7)');
    }
    Object.keys(parameters).forEach((param) => {
      dataStoreFields.push({
        dataStorageId: id,
        dataPath: param,
        parameterType: parseInt(parameters[param], 10),
      });
    });
  });
  _model.dataStoreFields = dataStoreFields;
  const parsedModel = _.get(bpmnJson, BPMN_ROOT_ELEMENTS, []).filter(item => item.$type === BPMN_TYPE_COLLABORATION)[0];
  if (!parsedModel || !parsedModel.extensionElements) throw new Error('No model details found');
  _model.name = parsedModel.id;
  try {
    _model = Object.assign(_model, getExtensionElementsFromNode(parsedModel).properties);
    const [major, minor, patch] = _model.version.split('.');
    if (Number.isNaN(major) || Number.isNaN(minor) || Number.isNaN(patch)) {
      throw boom.badData('Model version should follow Semantic Versioning, e.g. 1.0.0');
    }
    _model.version = [Number(major), Number(minor), Number(patch)];
    _model.private = getBooleanFromString(_model.private);
    return _model;
  } catch (error) {
    if (boom.isBoom(error)) throw error;
    else throw boom.badImplementation(`Failed to get model id and/or version: ${error}`);
  }
};

const getParsedXml = xmlString => new Promise((resolve, reject) => {
  moddle.fromXML(xmlString, BPMN_DEFINITION, (err, parsedXml) => {
    if (err) return reject(boom.badData(`Failed to parse xml: ${err}`));
    return resolve(parsedXml);
  });
});
class BpmnParser {
  constructor() {
    this.rawXml = '';
    this.rawJson = {};
    this.model = {};
    this.processes = [];
  }

  parse(xmlString) {
    this.rawXml = xmlString;
    const self = this;
    return new Promise(async (resolve, reject) => {
      try {
        self.rawJson = await getParsedXml(self.rawXml);
        self.model = parseModelDetails(self.rawJson);
        const processes = parseProcesses(self.rawJson);
        self.processes = processes.map(p => validateProcess(p, self.model.dataStoreFields));
        return resolve();
      } catch (error) {
        if (boom.isBoom(error)) return reject(error);
        return reject(boom.badImplementation(error));
      }
    });
  }

  getRawJson() {
    return this.bpmnJson;
  }

  getModel() {
    return this.model;
  }

  getProcesses() {
    return this.processes;
  }
}

const getNewParser = () => new BpmnParser();

module.exports = {
  getNewParser,
  getBooleanFromString,
};
