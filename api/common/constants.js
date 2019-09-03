const BUNDLES = {
  AGREEMENTS: {
    contracts: {
      ACTIVE_AGREEMENT: 'ActiveAgreement',
      ARCHETYPE: 'Archetype',
    },
  },
  BPM_MODEL: {
    contracts: {
      PROCESS_DEFINITION: 'ProcessDefinition',
      PROCESS_MODEL: 'ProcessModel',
    },
  },
  BPM_RUNTIME: {
    contracts: {
      PROCESS_INSTANCE: 'ProcessInstance',
    },
  },
  COMMONS_AUTH: {
    contracts: {
      ECOSYSTEM: 'Ecosystem',
      USER_ACCOUNT: 'UserAccount',
    },
  },
  PARTICIPANTS_MANAGER: {
    contracts: {
      ORGANIZATION: 'Organization',
    },
  },
};

const PARAMETER_TYPES = {
  BOOLEAN: 0,
  STRING: 1,
  NUMBER: 2,
  DATE: 3,
  DATETIME: 4,
  MONETARY_AMOUNT: 5,
  USER_ORGANIZATION: 6,
  CONTRACT_ADDRESS: 7,
  SIGNING_PARTY: 8,
  BYTES32: 9,
  DOCUMENT: 10,
  LARGE_TEXT: 11,
  POSITIVE_NUMBER: 12,
  DURATION: 13,
};

const DATA_TYPES = {
  BOOLEAN: 1,
  STRING: 2,
  BYTES32: 59,
  UINT: 8,
  INT: 18,
  ADDRESS: 40,
};

const PARAM_TYPE_TO_DATA_TYPE_MAP = {
  0: { label: 'Boolean', dataType: DATA_TYPES.BOOLEAN, parameterType: PARAMETER_TYPES.BOOLEAN },
  1: { label: 'Text', dataType: DATA_TYPES.STRING, parameterType: PARAMETER_TYPES.STRING },
  2: { label: 'Number', dataType: DATA_TYPES.INT, parameterType: PARAMETER_TYPES.NUMBER },
  3: { label: 'Date', dataType: DATA_TYPES.UINT, parameterType: PARAMETER_TYPES.DATE },
  4: { label: 'Datetime', dataType: DATA_TYPES.UINT, parameterType: PARAMETER_TYPES.DATETIME },
  5: { label: 'Monetary Amount', dataType: DATA_TYPES.INT, parameterType: PARAMETER_TYPES.MONETARY_AMOUNT },
  6: { label: 'User/Organization', dataType: DATA_TYPES.ADDRESS, parameterType: PARAMETER_TYPES.USER_ORGANIZATION },
  7: { label: 'Contract Address', dataType: DATA_TYPES.ADDRESS, parameterType: PARAMETER_TYPES.CONTRACT_ADDRESS },
  8: { label: 'Signatory', dataType: DATA_TYPES.ADDRESS, parameterType: PARAMETER_TYPES.SIGNING_PARTY },
  9: { label: '32-byte Value', dataType: DATA_TYPES.BYTES32, parameterType: PARAMETER_TYPES.BYTES32 },
  10: { label: 'Document', dataType: DATA_TYPES.STRING, parameterType: PARAMETER_TYPES.DOCUMENT },
  11: { label: 'Large Text', dataType: DATA_TYPES.STRING, parameterType: PARAMETER_TYPES.LARGE_TEXT },
  12: { label: 'Positive Number', dataType: DATA_TYPES.UINT, parameterType: PARAMETER_TYPES.POSITIVE_NUMBER },
  13: { label: 'Duration', dataType: DATA_TYPES.STRING, parameterType: PARAMETER_TYPES.DURATION },
};

const DIRECTION = {
  IN: 0,
  OUT: 1,
};

const COMPARISON_OPERATOR = {
  EQ: 0,
  LT: 1,
  GT: 2,
  LTE: 3,
  GTE: 4,
  NEQ: 5,
};

const ERROR_CODES = {
  UNAUTHORIZED: 'ERR403',
  RESOURCE_NOT_FOUND: 'ERR404',
  RESOURCE_ALREADY_EXISTS: 'ERR409',
  INVALID_INPUT: 'ERR422',
  RUNTIME_ERROR: 'ERR500',
  INVALID_STATE: 'ERR600',
  INVALID_PARAMETER_STATE: 'ERR601',
  OVERWRITE_NOT_ALLOWED: 'ERR610',
  NULL_PARAMETER_NOT_ALLOWED: 'ERR611',
  DEPENDENCY_NOT_FOUND: 'ERR704',
};

const AGREEMENT_PARTIES = 'AGREEMENT_PARTIES';
const DEFAULT_DEPARTMENT_ID = 'DEFAULT_DEPARTMENT';

const NOTIFICATION = {
  ACTIVITY_INSTANCE_STATE_CHANGED: 'activityinstancestatechanged',
};

const AGREEMENT_ATTACHMENT_CONTENT_TYPES = {
  fileReference: 'fileReference',
  plaintext: 'plaintext',
};

const BPM_TIMER_EVENT_TYPES = {
  timeDate: 0,
  timeDuration: 1,
};

module.exports = {
  BUNDLES,
  PARAMETER_TYPES,
  DATA_TYPES,
  DIRECTION,
  PARAM_TYPE_TO_DATA_TYPE_MAP,
  COMPARISON_OPERATOR,
  ERROR_CODES,
  AGREEMENT_PARTIES,
  DEFAULT_DEPARTMENT_ID,
  NOTIFICATION,
  AGREEMENT_ATTACHMENT_CONTENT_TYPES,
  BPM_TIMER_EVENT_TYPES,
};
