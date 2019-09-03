const logger = require(`${global.__common}/logger`);
const contracts = require('../controllers/contracts-controller');
const CONTRACT_ACTIVE_AGREEMENT = global.__bundles.AGREEMENTS.contracts.ACTIVE_AGREEMENT;
const { PARAMETER_TYPES: PARAM_TYPE, DATA_TYPES } = global.__constants;
const log = logger.getLogger('controllers.data-storage');

/* **********************************************************
 *       PARAMETER TYPES TO SOLIDITY DATA TYPES MAPPING
 *       dataTypes match DataTypes.sol uint8 data types
 *       parameterTypes match DataTypes.ParameterType enums
 ********************************************************** */

const agreementDataSetters = {};
const agreementDataGetters = {};
const activityOutDataSetters = {};
const activityInDataGetters = {};

/* **********************************
 *      AGREEMENT DATA SETTERS
 ********************************** */

const setDataValueAsBool = (agreementAddr, fieldName, fieldValue) => new Promise((resolve, reject) => {
  const agreement = contracts.getContract(global.__abi, CONTRACT_ACTIVE_AGREEMENT, agreementAddr);
  log.trace('Setting data ID %s in DataStorage %s to value: %s', fieldName, agreementAddr, fieldValue);
  agreement.setDataValueAsBool(global.stringToHex(fieldName), fieldValue, (err) => {
    if (err) return reject(err);
    return resolve();
  });
});

const setDataValueAsString = (agreementAddr, fieldName, fieldValue) => new Promise((resolve, reject) => {
  const agreement = contracts.getContract(global.__abi, CONTRACT_ACTIVE_AGREEMENT, agreementAddr);
  log.trace('Setting data ID %s in DataStorage %s to value: %s', fieldName, agreementAddr, fieldValue);
  agreement.setDataValueAsString(global.stringToHex(fieldName), fieldValue, (err) => {
    if (err) return reject(err);
    return resolve();
  });
});

const setDataValueAsUint = (agreementAddr, fieldName, fieldValue) => new Promise((resolve, reject) => {
  const agreement = contracts.getContract(global.__abi, CONTRACT_ACTIVE_AGREEMENT, agreementAddr);
  log.trace('Setting data ID %s in DataStorage %s to value: %d', fieldName, agreementAddr, fieldValue);
  agreement.setDataValueAsUint(global.stringToHex(fieldName), fieldValue, (err) => {
    if (err) return reject(err);
    return resolve();
  });
});

const setDataValueAsInt = (agreementAddr, fieldName, fieldValue) => new Promise((resolve, reject) => {
  const agreement = contracts.getContract(global.__abi, CONTRACT_ACTIVE_AGREEMENT, agreementAddr);
  log.trace('Setting data ID %s in DataStorage %s to value: %d', fieldName, agreementAddr, fieldValue);
  agreement.setDataValueAsInt(global.stringToHex(fieldName), fieldValue, (err) => {
    if (err) return reject(err);
    return resolve();
  });
});

const setDataValueAsAddress = (agreementAddr, fieldName, fieldValue) => new Promise((resolve, reject) => {
  const agreement = contracts.getContract(global.__abi, CONTRACT_ACTIVE_AGREEMENT, agreementAddr);
  log.trace('Setting data ID %s in DataStorage %s to value: %s', fieldName, agreementAddr, fieldValue);
  agreement.setDataValueAsAddress(global.stringToHex(fieldName), fieldValue, (err) => {
    if (err) return reject(err);
    return resolve();
  });
});

const setDataValueAsBytes32 = (agreementAddr, fieldName, fieldValue) => new Promise((resolve, reject) => {
  const agreement = contracts.getContract(global.__abi, CONTRACT_ACTIVE_AGREEMENT, agreementAddr);
  log.trace('Setting data ID %s in DataStorage %s to value: %s', fieldName, agreementAddr, fieldValue);
  agreement.setDataValueAsBytes32(global.stringToHex(fieldName), global.stringToHex(fieldValue), (err) => {
    if (err) return reject(err);
    return resolve();
  });
});

/* **********************************
 *       AGREEMENT DATA GETTERS
 ********************************** */

const getDataValueAsBool = (agreementAddr, fieldName) => new Promise((resolve, reject) => {
  const agreement = contracts.getContract(global.__abi, CONTRACT_ACTIVE_AGREEMENT, agreementAddr);
  agreement.getDataValueAsBool(global.stringToHex(fieldName), (err, data) => {
    if (err) return reject(err);
    const result = { name: fieldName, value: data.raw[0].valueOf() };
    log.trace('Resolved data ID %s in DataStorage %s to value: %s', fieldName, agreementAddr, result.value);
    return resolve(result);
  });
});

const getDataValueAsString = (agreementAddr, fieldName) => new Promise((resolve, reject) => {
  const agreement = contracts.getContract(global.__abi, CONTRACT_ACTIVE_AGREEMENT, agreementAddr);
  agreement.getDataValueAsString(global.stringToHex(fieldName), (err, data) => {
    if (err) return reject(err);
    const result = { name: fieldName, value: data.raw[0].valueOf() };
    log.trace('Resolved data ID %s in DataStorage %s to value: %s', fieldName, agreementAddr, result.value);
    return resolve(result);
  });
});

const getDataValueAsUint = (agreementAddr, fieldName) => new Promise((resolve, reject) => {
  const agreement = contracts.getContract(global.__abi, CONTRACT_ACTIVE_AGREEMENT, agreementAddr);
  agreement.getDataValueAsUint(global.stringToHex(fieldName), (err, data) => {
    if (err) return reject(err);
    const result = { name: fieldName, value: parseInt(data.raw[0].valueOf(), 10) };
    log.trace('Resolved data ID %s in DataStorage %s to value: %d', fieldName, agreementAddr, result.value);
    return resolve(result);
  });
});

const getDataValueAsInt = (agreementAddr, fieldName) => new Promise((resolve, reject) => {
  const agreement = contracts.getContract(global.__abi, CONTRACT_ACTIVE_AGREEMENT, agreementAddr);
  agreement.getDataValueAsInt(global.stringToHex(fieldName), (err, data) => {
    if (err) return reject(err);
    const result = { name: fieldName, value: parseInt(data.raw[0].valueOf(), 10) };
    log.trace('Resolved data ID %s in DataStorage %s to value: %d', fieldName, agreementAddr, result.value);
    return resolve(result);
  });
});

const getDataValueAsAddress = (agreementAddr, fieldName) => new Promise((resolve, reject) => {
  const agreement = contracts.getContract(global.__abi, CONTRACT_ACTIVE_AGREEMENT, agreementAddr);
  agreement.getDataValueAsAddress(global.stringToHex(fieldName), (err, data) => {
    if (err) return reject(err);
    const result = { name: fieldName, value: data.raw[0].valueOf() };
    log.trace('Resolved data ID %s in DataStorage %s to value: %s', fieldName, agreementAddr, result.value);
    return resolve(result);
  });
});

const getDataValueAsBytes32 = (agreementAddr, fieldName) => new Promise((resolve, reject) => {
  const agreement = contracts.getContract(global.__abi, CONTRACT_ACTIVE_AGREEMENT, agreementAddr);
  agreement.getDataValueAsBytes32(global.stringToHex(fieldName), (err, data) => {
    if (err) return reject(err);
    const result = { name: fieldName, value: global.hexToString(data.raw[0].valueOf()) };
    log.trace('Resolved data ID %s in DataStorage %s to value: %s', fieldName, agreementAddr, result.value);
    return resolve(result);
  });
});

/* **********************************
 *     ACTIVITY IN-DATA GETTERS
 ********************************** */

const getActivityInDataAsBool = (userAddr, activityInstanceId, dataMappingId) => new Promise(async (resolve, reject) => {
  try {
    log.trace('User %s reading IN data %s as bool value on activity instance ID %s', userAddr, dataMappingId, activityInstanceId);
    const piAddress = await contracts.getBpmService().factory.getProcessInstanceForActivity(activityInstanceId).then(result => result.raw[0]);
    const processInstance = contracts.getProcessInstance(piAddress);
    const payload = processInstance.getActivityInDataAsBool.encode(activityInstanceId, global.stringToHex(dataMappingId));
    const returnData = await contracts.callOnBehalfOf(userAddr, piAddress, payload);
    log.trace('Activity data bool return: %s', JSON.stringify(processInstance.getActivityInDataAsBool.decode(returnData)));
    return resolve(processInstance.getActivityInDataAsBool.decode(returnData).raw[0]);
  } catch (error) {
    return reject(error);
  }
});

const getActivityInDataAsString = (userAddr, activityInstanceId, dataMappingId) => new Promise(async (resolve, reject) => {
  try {
    log.trace('User %s reading IN data %s as string value on activity instance ID %s', userAddr, dataMappingId, activityInstanceId);
    const piAddress = await contracts.getBpmService().factory.getProcessInstanceForActivity(activityInstanceId).then(result => result.raw[0]);
    const processInstance = contracts.getProcessInstance(piAddress);
    const payload = processInstance.getActivityInDataAsString.encode(activityInstanceId, global.stringToHex(dataMappingId));
    const returnData = await contracts.callOnBehalfOf(userAddr, piAddress, payload);
    log.trace('Activity data string return: %s', JSON.stringify(processInstance.getActivityInDataAsString.decode(returnData)));
    return resolve(processInstance.getActivityInDataAsString.decode(returnData).raw[0].valueOf());
  } catch (error) {
    return reject(error);
  }
});

const getActivityInDataAsBytes32 = (userAddr, activityInstanceId, dataMappingId) => new Promise(async (resolve, reject) => {
  try {
    log.trace('User %s reading IN data %s as bytes32 value on activity instance ID %s', userAddr, dataMappingId, activityInstanceId);
    const piAddress = await contracts.getBpmService().factory.getProcessInstanceForActivity(activityInstanceId).then(result => result.raw[0]);
    const processInstance = contracts.getProcessInstance(piAddress);
    const payload = processInstance.getActivityInDataAsBytes32.encode(activityInstanceId, global.stringToHex(dataMappingId));
    const returnData = await contracts.callOnBehalfOf(userAddr, piAddress, payload);
    log.trace('Activity data bytes32 return: %s', JSON.stringify(processInstance.getActivityInDataAsBytes32.decode(returnData)));
    return resolve(global.hexToString(processInstance.getActivityInDataAsBytes32.decode(returnData).raw[0].valueOf()));
  } catch (error) {
    return reject(error);
  }
});

const getActivityInDataAsUint = (userAddr, activityInstanceId, dataMappingId) => new Promise(async (resolve, reject) => {
  try {
    log.trace('User %s reading IN data %s as uint value on activity instance ID %s', userAddr, dataMappingId, activityInstanceId);
    const piAddress = await contracts.getBpmService().factory.getProcessInstanceForActivity(activityInstanceId).then(result => result.raw[0]);
    const processInstance = contracts.getProcessInstance(piAddress);
    const payload = processInstance.getActivityInDataAsUint.encode(activityInstanceId, global.stringToHex(dataMappingId));
    const returnData = await contracts.callOnBehalfOf(userAddr, piAddress, payload);
    log.trace('Activity data uint return: %s', JSON.stringify(processInstance.getActivityInDataAsUint.decode(returnData)));
    return resolve(processInstance.getActivityInDataAsUint.decode(returnData).raw[0].valueOf());
  } catch (error) {
    return reject(error);
  }
});

const getActivityInDataAsInt = (userAddr, activityInstanceId, dataMappingId) => new Promise(async (resolve, reject) => {
  try {
    log.trace('User %s reading IN data %s as int value on activity instance ID %s', userAddr, dataMappingId, activityInstanceId);
    const piAddress = await contracts.getBpmService().factory.getProcessInstanceForActivity(activityInstanceId).then(result => result.raw[0]);
    const processInstance = contracts.getProcessInstance(piAddress);
    const payload = processInstance.getActivityInDataAsInt.encode(activityInstanceId, global.stringToHex(dataMappingId));
    const returnData = await contracts.callOnBehalfOf(userAddr, piAddress, payload);
    log.trace('Activity data int return: %s', JSON.stringify(processInstance.getActivityInDataAsInt.decode(returnData)));
    return resolve(processInstance.getActivityInDataAsInt.decode(returnData).raw[0].valueOf());
  } catch (error) {
    return reject(error);
  }
});

const getActivityInDataAsAddress = (userAddr, activityInstanceId, dataMappingId) => new Promise(async (resolve, reject) => {
  try {
    log.trace('User %s reading IN data %s as string value on activity instance ID %s', userAddr, dataMappingId, activityInstanceId);
    const piAddress = await contracts.getBpmService().factory.getProcessInstanceForActivity(activityInstanceId).then(result => result.raw[0]);
    const processInstance = contracts.getProcessInstance(piAddress);
    const payload = processInstance.getActivityInDataAsAddress.encode(activityInstanceId, global.stringToHex(dataMappingId));
    const returnData = await contracts.callOnBehalfOf(userAddr, piAddress, payload);
    log.trace('Activity data address return: %s', JSON.stringify(processInstance.getActivityInDataAsAddress.decode(returnData)));
    return resolve(processInstance.getActivityInDataAsAddress.decode(returnData).raw[0].valueOf());
  } catch (error) {
    return reject(error);
  }
});

/* **********************************
 *     ACTIVITY OUT-DATA SETTERS
 ********************************** */

const setActivityOutDataAsBool = (userAddr, activityInstanceId, dataMappingId, value) => new Promise(async (resolve, reject) => {
  try {
    log.trace('User %s setting OUT data %s as bool value %s on activity instance ID %s', userAddr, dataMappingId, value, activityInstanceId);
    const piAddress = await contracts.getBpmService().factory.getProcessInstanceForActivity(activityInstanceId).then(result => result.raw[0]);
    const processInstance = contracts.getProcessInstance(piAddress);
    const payload = processInstance.setActivityOutDataAsBool.encode(activityInstanceId, global.stringToHex(dataMappingId), value);
    await contracts.callOnBehalfOf(userAddr, piAddress, payload);
    return resolve();
  } catch (error) {
    return reject(error);
  }
});

const setActivityOutDataAsString = (userAddr, activityInstanceId, dataMappingId, value) => new Promise(async (resolve, reject) => {
  try {
    log.trace('User %s setting OUT data %s as string value %s on activity instance ID %s', userAddr, dataMappingId, value, activityInstanceId);
    const piAddress = await contracts.getBpmService().factory.getProcessInstanceForActivity(activityInstanceId).then(result => result.raw[0]);
    const processInstance = contracts.getProcessInstance(piAddress);
    const payload = processInstance.setActivityOutDataAsString.encode(activityInstanceId, global.stringToHex(dataMappingId), value);
    await contracts.callOnBehalfOf(userAddr, piAddress, payload);
    return resolve();
  } catch (error) {
    return reject(error);
  }
});

const setActivityOutDataAsBytes32 = (userAddr, activityInstanceId, dataMappingId, value) => new Promise(async (resolve, reject) => {
  try {
    log.trace('User %s setting OUT data %s as bytes32 value %s on activity instance ID %s', userAddr, dataMappingId, value, activityInstanceId);
    const piAddress = await contracts.getBpmService().factory.getProcessInstanceForActivity(activityInstanceId).then(result => result.raw[0]);
    const processInstance = contracts.getProcessInstance(piAddress);
    const payload = processInstance.setActivityOutDataAsBytes32.encode(activityInstanceId, global.stringToHex(dataMappingId), global.stringToHex(value));
    await contracts.callOnBehalfOf(userAddr, piAddress, payload);
    return resolve();
  } catch (error) {
    return reject(error);
  }
});

const setActivityOutDataAsUint = (userAddr, activityInstanceId, dataMappingId, value) => new Promise(async (resolve, reject) => {
  try {
    log.trace('User %s setting OUT data %s as uint value %s on activity instance ID %s', userAddr, dataMappingId, value, activityInstanceId);
    const piAddress = await contracts.getBpmService().factory.getProcessInstanceForActivity(activityInstanceId).then(result => result.raw[0]);
    const processInstance = contracts.getProcessInstance(piAddress);
    const payload = processInstance.setActivityOutDataAsUint.encode(activityInstanceId, global.stringToHex(dataMappingId), value);
    await contracts.callOnBehalfOf(userAddr, piAddress, payload);
    return resolve();
  } catch (error) {
    return reject(error);
  }
});

const setActivityOutDataAsInt = (userAddr, activityInstanceId, dataMappingId, value) => new Promise(async (resolve, reject) => {
  try {
    log.trace('User %s setting OUT data %s as int value %s on activity instance ID %s', userAddr, dataMappingId, value, activityInstanceId);
    const piAddress = await contracts.getBpmService().factory.getProcessInstanceForActivity(activityInstanceId).then(result => result.raw[0]);
    const processInstance = contracts.getProcessInstance(piAddress);
    const payload = processInstance.setActivityOutDataAsInt.encode(activityInstanceId, global.stringToHex(dataMappingId), value);
    await contracts.callOnBehalfOf(userAddr, piAddress, payload);
    return resolve();
  } catch (error) {
    return reject(error);
  }
});

const setActivityOutDataAsAddress = (userAddr, activityInstanceId, dataMappingId, value) => new Promise(async (resolve, reject) => {
  try {
    log.trace('User %s setting OUT data %s as address value %s on activity instance ID %s', userAddr, dataMappingId, value, activityInstanceId);
    const piAddress = await contracts.getBpmService().factory.getProcessInstanceForActivity(activityInstanceId).then(result => result.raw[0]);
    const processInstance = contracts.getProcessInstance(piAddress);
    const payload = processInstance.setActivityOutDataAsAddress.encode(activityInstanceId, global.stringToHex(dataMappingId), value);
    await contracts.callOnBehalfOf(userAddr, piAddress, payload);
    return resolve();
  } catch (error) {
    return reject(error);
  }
});

agreementDataSetters[`${PARAM_TYPE.BOOLEAN}`] = setDataValueAsBool;
agreementDataSetters[`${PARAM_TYPE.STRING}`] = setDataValueAsString;
agreementDataSetters[`${PARAM_TYPE.NUMBER}`] = setDataValueAsInt;
agreementDataSetters[`${PARAM_TYPE.DATE}`] = setDataValueAsUint;
agreementDataSetters[`${PARAM_TYPE.DATETIME}`] = setDataValueAsUint;
agreementDataSetters[`${PARAM_TYPE.MONETARY_AMOUNT}`] = setDataValueAsInt;
agreementDataSetters[`${PARAM_TYPE.USER_ORGANIZATION}`] = setDataValueAsAddress;
agreementDataSetters[`${PARAM_TYPE.CONTRACT_ADDRESS}`] = setDataValueAsAddress;
agreementDataSetters[`${PARAM_TYPE.SIGNING_PARTY}`] = setDataValueAsAddress;
agreementDataSetters[`${PARAM_TYPE.BYTES32}`] = setDataValueAsBytes32;
agreementDataSetters[`${PARAM_TYPE.DOCUMENT}`] = setDataValueAsString;
agreementDataSetters[`${PARAM_TYPE.LARGE_TEXT}`] = setDataValueAsString;
agreementDataSetters[`${PARAM_TYPE.POSITIVE_NUMBER}`] = setDataValueAsUint;
agreementDataSetters[`${PARAM_TYPE.DURATION}`] = setDataValueAsString;

agreementDataGetters[`${PARAM_TYPE.BOOLEAN}`] = getDataValueAsBool;
agreementDataGetters[`${PARAM_TYPE.STRING}`] = getDataValueAsString;
agreementDataGetters[`${PARAM_TYPE.NUMBER}`] = getDataValueAsInt;
agreementDataGetters[`${PARAM_TYPE.DATE}`] = getDataValueAsUint;
agreementDataGetters[`${PARAM_TYPE.DATETIME}`] = getDataValueAsUint;
agreementDataGetters[`${PARAM_TYPE.MONETARY_AMOUNT}`] = getDataValueAsInt;
agreementDataGetters[`${PARAM_TYPE.USER_ORGANIZATION}`] = getDataValueAsAddress;
agreementDataGetters[`${PARAM_TYPE.CONTRACT_ADDRESS}`] = getDataValueAsAddress;
agreementDataGetters[`${PARAM_TYPE.SIGNING_PARTY}`] = getDataValueAsAddress;
agreementDataGetters[`${PARAM_TYPE.BYTES32}`] = getDataValueAsBytes32;
agreementDataGetters[`${PARAM_TYPE.DOCUMENT}`] = getDataValueAsString;
agreementDataGetters[`${PARAM_TYPE.LARGE_TEXT}`] = getDataValueAsString;
agreementDataGetters[`${PARAM_TYPE.POSITIVE_NUMBER}`] = getDataValueAsUint;
agreementDataGetters[`${PARAM_TYPE.DURATION}`] = getDataValueAsString;

activityInDataGetters[`${DATA_TYPES.BOOLEAN}`] = getActivityInDataAsBool;
activityInDataGetters[`${DATA_TYPES.STRING}`] = getActivityInDataAsString;
activityInDataGetters[`${DATA_TYPES.BYTES32}`] = getActivityInDataAsBytes32;
activityInDataGetters[`${DATA_TYPES.UINT}`] = getActivityInDataAsUint;
activityInDataGetters[`${DATA_TYPES.INT}`] = getActivityInDataAsInt;
activityInDataGetters[`${DATA_TYPES.ADDRESS}`] = getActivityInDataAsAddress;

activityOutDataSetters[`${DATA_TYPES.BOOLEAN}`] = setActivityOutDataAsBool;
activityOutDataSetters[`${DATA_TYPES.STRING}`] = setActivityOutDataAsString;
activityOutDataSetters[`${DATA_TYPES.BYTES32}`] = setActivityOutDataAsBytes32;
activityOutDataSetters[`${DATA_TYPES.UINT}`] = setActivityOutDataAsUint;
activityOutDataSetters[`${DATA_TYPES.INT}`] = setActivityOutDataAsInt;
activityOutDataSetters[`${DATA_TYPES.ADDRESS}`] = setActivityOutDataAsAddress;


module.exports = {
  agreementDataSetters,
  agreementDataGetters,
  activityOutDataSetters,
  activityInDataGetters,
};
