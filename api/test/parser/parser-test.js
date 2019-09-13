const path = require("path");
const fs = require("fs");
const chai = require("chai");
const should = chai.should();
const expect = chai.expect;
const assert = chai.assert;

global.__config = path.resolve('config');
global.__common = path.resolve('common');
global.__constants = require(path.join(__common, 'constants'));

const bpmnParser = require(path.resolve("lib", "bpmn-parser"));

const xmlString = fs.readFileSync(path.resolve("data", "sample", "T2-example.bpmn"), "utf8");
const gatewayXml = fs.readFileSync(path.resolve("test", "data", "Gateways-Parser-Test.bpmn"), "utf8");
const timerXml = fs.readFileSync(path.resolve("test", "data", "parser-timer.bpmn"), "utf8");

const expectedModel = {
  id: "model_1",
  name: "Model_1",
  version: [1, 0, 0],
  private: true,
  dataStoreFields: [{
      dataStorageId: 'PROCESS_INSTANCE',
      dataPath: 'agreement',
      parameterType: 7,
    },
    {
      dataStorageId: 'agreement',
      dataPath: 'Assignee',
      parameterType: 8,
    },
  ],
};

const expectedProcess1 = {
  "id": "formationProcess1",
  "name": "Formation Process 1",
  "interface": "FormationProcess",
  "participants": [{
    "id": "lane1",
    "name": "Signatories",
    "tasks": ["reviewTask1", "Task_03gfu05", "signTask1", "Task_00is0tl"],
    "conditionalPerformer": true,
    "dataPath": "AGREEMENT_PARTIES",
    "dataStorageId": "agreement"
  }, {
    "id": "lane2",
    "name": "Acme Corp",
    "tasks": ["approveTask1", "Task_0667wyu"],
    "account": "0x1040e6521541daB4E7ee57F21226dD17Ce9F0Fb7"
  }],
  "tasks": [{
    "id": "Task_03gfu05",
    "name": "Dummy Task",
    "assignee": "",
    "activityType": 0,
    "taskType": 0,
    "behavior": 0,
    "multiInstance": false,
    "application": "",
    "subProcessModelId": "",
    "subProcessDefinitionId": ""
  }],
  "userTasks": [{
    "id": "reviewTask1",
    "name": "Review Agreement",
    "assignee": "lane1",
    "activityType": 0,
    "taskType": 1,
    "behavior": 1,
    "multiInstance": false,
    "dataMappings": [{
      "id": "agreement",
      "direction": 0,
      "dataPath": "agreement",
      "dataStorageId": ""
    }],
    "application": "AgreementSignatureCheck",
    "completionFunction": "",
    "subProcessModelId": "",
    "subProcessDefinitionId": ""
  }, {
    "id": "signTask1",
    "name": "Sign Agreement",
    "assignee": "lane1",
    "activityType": 0,
    "taskType": 1,
    "behavior": 1,
    "multiInstance": false,
    "application": "",
    "subProcessModelId": "",
    "subProcessDefinitionId": ""
  }, {
    "id": "Task_0667wyu",
    "name": "Validate Signature",
    "assignee": "lane2",
    "activityType": 0,
    "taskType": 1,
    "behavior": 1,
    "multiInstance": false,
    "dataMappings": [{
      "id": "Signed",
      "direction": 1,
      "dataPath": "Signed",
      "dataStorageId": "agreement"
    }, {
      "id": "Notified",
      "direction": 0,
      "dataPath": "Notified",
      "dataStorageId": "agreement"
    }, {
      "id": "Sealed",
      "direction": 1,
      "dataPath": "Sealed",
      "dataStorageId": "agreement"
    }],
    "application": "",
    "subProcessModelId": "",
    "subProcessDefinitionId": ""
  }],
  "sendTasks": [{
    "id": "Task_00is0tl",
    "name": "Send Notification",
    "activityType": 0,
    "taskType": 3,
    "application": "",
    "behavior": 1,
    "subProcessModelId": "",
    "subProcessDefinitionId": "",
    "assignee": "",
    "multiInstance": false
  }],
  "serviceTasks": [{
    "id": "Task_13ndog8",
    "name": "Emit Sign Event",
    "assignee": "",
    "activityType": 0,
    "taskType": 2,
    "behavior": 0,
    "multiInstance": false,
    "application": "ActivityEventEmitter",
    "subProcessModelId": "",
    "subProcessDefinitionId": "",
    "dataMappings": [{
      "id": "Notified",
      "direction": 1,
      "dataPath": "Notified",
      "dataStorageId": "agreement"
    }]
  }],
  "subProcesses": [{
    "id": "approveTask1",
    "name": "Approve Formation",
    "assignee": "",
    "activityType": 1,
    "taskType": 0,
    "behavior": 0,
    "multiInstance": false,
    "application": "",
    "subProcessModelId": "model_1",
    "subProcessDefinitionId": "executionProcess1"
  }],
  "transitions": [{
    "id": "SequenceFlow_0f0mciq",
    "source": "Task_00is0tl",
    "target": "Task_13ndog8"
  }, {
    "id": "SequenceFlow_11wkg2g",
    "source": "reviewTask1",
    "target": "Task_03gfu05"
  }, {
    "id": "SequenceFlow_0g7y82m",
    "source": "Task_03gfu05",
    "target": "signTask1"
  }, {
    "id": "SequenceFlow_1inl1i9",
    "source": "signTask1",
    "target": "Task_00is0tl"
  }, {
    "id": "SequenceFlow_032hols",
    "source": "Task_13ndog8",
    "target": "Task_0667wyu"
  }, {
    "id": "SequenceFlow_0j7lsvv",
    "source": "Task_0667wyu",
    "target": "approveTask1"
  }],
  "activityMap": {
    "reviewTask1": "Review Agreement",
    "Task_03gfu05": "Dummy Task",
    "signTask1": "Sign Agreement",
    "Task_00is0tl": "Send Notification",
    "Task_13ndog8": "Emit Sign Event",
    "Task_0667wyu": "Validate Signature"
  },
  "boundaryEvents": [],
  "intermediateCatchEvents": [],
  "andGateways": [],
  "xorGateways": []
};

const expectedProcess2 = {
  "id": "executionProcess1",
  "name": "Execution Process 1",
  "interface": "ExecutionProcess",
  "participants": [{
    "id": "lane3",
    "name": "WalCorp",
    "tasks": ["disburse1", "reviewTask2", "Task_1b37sj9"],
    "account": "0x1040e6521541daB4E7ee57F21226dD17Ce9F0Ef7"
  }],
  "tasks": [],
  "userTasks": [{
    "id": "disburse1",
    "name": "Disburse Payments",
    "assignee": "lane3",
    "activityType": 0,
    "taskType": 1,
    "behavior": 1,
    "multiInstance": false,
    "application": "",
    "subProcessModelId": "",
    "subProcessDefinitionId": ""
  }, {
    "id": "reviewTask2",
    "name": "Review Completion",
    "assignee": "lane3",
    "activityType": 0,
    "taskType": 1,
    "behavior": 1,
    "multiInstance": false,
    "application": "",
    "subProcessModelId": "",
    "subProcessDefinitionId": ""
  }],
  "sendTasks": [],
  "serviceTasks": [],
  "subProcesses": [],
  "transitions": [{
    "id": "SequenceFlow_14t5289",
    "source": "reviewTask2",
    "target": "Task_1b37sj9"
  }, {
    "id": "SequenceFlow_1nxuq77",
    "source": "Task_1b37sj9",
    "target": "disburse1"
  }],
  "activityMap": {
    "disburse1": "Disburse Payments",
    "reviewTask2": "Review Completion",
  },
  "boundaryEvents": [],
  "intermediateCatchEvents": [],
  "andGateways": [],
  "xorGateways": []
};

const gatewayModel1 = {
  "dataStoreFields": [{
    "dataStorageId": "PROCESS_INSTANCE",
    "dataPath": "agreement",
    "parameterType": 7
  }, {
    "dataStorageId": "agreement",
    "dataPath": "Age",
    "parameterType": 2
  }, {
    "dataStorageId": "agreement",
    "dataPath": "ContentId",
    "parameterType": 1
  }],
  "name": "Collaboration_1bqszqk",
  "id": "vg_age_ver123",
  "version": [1, 0, 0],
  "private": false
};

const gatewayProcess1 = {
  "id": "Process_AgeVer",
  "name": "Video Game Age Verification",
  "interface": "Agreement Formation",
  "participants": [{
    "id": "Lane_14s4k1q",
    "name": "Gamer",
    "tasks": ["Task_0ykqbq7"],
    "conditionalPerformer": true,
    "dataStorageId": "agreement",
    "dataPath": "Gamer"
  }],
  "tasks": [],
  "userTasks": [{
    "id": "Task_0ykqbq7",
    "name": "Enter Age",
    "assignee": "Lane_14s4k1q",
    "activityType": 0,
    "taskType": 1,
    "behavior": 1,
    "multiInstance": false,
    "dataMappings": [{
      "id": "Age",
      "direction": 1,
      "dataPath": "Age",
      "dataStorageId": "agreement"
    }],
    "application": "WebAppApprovalForm",
    "subProcessModelId": "",
    "subProcessDefinitionId": ""
  }],
  "sendTasks": [],
  "transitions": [{
    "id": "SequenceFlow_0i0kus1",
    "source": "Task_0ykqbq7",
    "target": "ExclusiveGateway_0gx4teu"
  }, {
    "id": "SequenceFlow_1f964ot",
    "source": "ExclusiveGateway_0gx4teu",
    "target": "Task_0y0e72x",
    "condition": {
      "lhDataStorageId": "agreement",
      "lhDataPath": "Age",
      "operator": 4,
      "rhValue": "18",
      "dataType": 18
    }
  }, {
    "id": "SequenceFlow_1jj19x9",
    "source": "ExclusiveGateway_0gx4teu",
    "target": "Task_0676pdy"
  }, {
    "id": "SequenceFlow_0rfe1i3",
    "source": "Task_0y0e72x",
    "target": "ExclusiveGateway_0901bl7"
  }, {
    "id": "SequenceFlow_1agn7w1",
    "source": "Task_0676pdy",
    "target": "ExclusiveGateway_0901bl7"
  }, {
    "id": "SequenceFlow_09zher9",
    "source": "ExclusiveGateway_0901bl7",
    "target": "Task_1x5ar30"
  }, {
    "id": "SequenceFlow_0q8umgj",
    "source": "Task_1x5ar30",
    "target": "ExclusiveGateway_0mqmev4"
  }, {
    "id": "SequenceFlow_0sqk84k",
    "source": "ExclusiveGateway_0mqmev4",
    "target": "Task_1wmfg58"
  }, {
    "id": "SequenceFlow_0ijntc6",
    "source": "ExclusiveGateway_0mqmev4",
    "target": "Task_09kuq9m"
  }, {
    "id": "SequenceFlow_0lvec4s",
    "source": "Task_1wmfg58",
    "target": "ExclusiveGateway_11bw6vr"
  }, {
    "id": "SequenceFlow_04yguww",
    "source": "Task_09kuq9m",
    "target": "ExclusiveGateway_11bw6vr"
  }, {
    "id": "SequenceFlow_021mzyg",
    "source": "ExclusiveGateway_11bw6vr",
    "target": "Task_0dy81yu"
  }],
  "subProcesses": [],
  "serviceTasks": [{
    "id": "Task_0y0e72x",
    "name": "Show Trailer",
    "assignee": "",
    "activityType": 0,
    "taskType": 2,
    "behavior": 0,
    "multiInstance": false,
    "subProcessModelId": "",
    "subProcessDefinitionId": "",
    "dataMappings": [{
      "id": "ContentId",
      "direction": 1,
      "dataPath": "ContentId",
      "dataStorageId": ""
    }],
    "application": "ShowContentApp"
  }, {
    "id": "Task_0676pdy",
    "name": "Display Message",
    "assignee": "",
    "activityType": 0,
    "taskType": 2,
    "behavior": 0,
    "multiInstance": false,
    "subProcessModelId": "",
    "subProcessDefinitionId": "",
    "dataMappings": [{
      "id": "MessageId",
      "direction": 1,
      "dataPath": "MessageId",
      "dataStorageId": ""
    }],
    "application": "ShowMessageApp"
  }, {
    "id": "Task_1x5ar30",
    "name": "Navigate To Home",
    "assignee": "",
    "activityType": 0,
    "taskType": 2,
    "behavior": 0,
    "multiInstance": false,
    "subProcessModelId": "",
    "subProcessDefinitionId": "",
    "application": "RouterApp"
  }, {
    "id": "Task_1wmfg58",
    "name": "Show Feedback Form",
    "assignee": "",
    "activityType": 0,
    "taskType": 2,
    "behavior": 0,
    "multiInstance": false,
    "subProcessModelId": "",
    "subProcessDefinitionId": "",
    "application": "FeedbackFormApp"
  }, {
    "id": "Task_09kuq9m",
    "name": "Update View Stats",
    "assignee": "",
    "activityType": 0,
    "taskType": 2,
    "behavior": 0,
    "multiInstance": false,
    "subProcessModelId": "",
    "subProcessDefinitionId": "",
    "application": "UpdateStatsApp"
  }, {
    "id": "Task_0dy81yu",
    "name": "Save Feedback",
    "assignee": "",
    "activityType": 0,
    "taskType": 2,
    "behavior": 0,
    "multiInstance": false,
    "subProcessModelId": "",
    "subProcessDefinitionId": "",
    "application": "FeedbackApp"
  }],
  "xorGateways": [{
    "id": "ExclusiveGateway_0gx4teu",
    "type": 0,
    "incoming": ["SequenceFlow_0i0kus1"],
    "outgoing": ["SequenceFlow_1f964ot", "SequenceFlow_1jj19x9"]
  }, {
    "id": "ExclusiveGateway_0901bl7",
    "type": 0,
    "incoming": ["SequenceFlow_0rfe1i3", "SequenceFlow_1agn7w1"],
    "outgoing": ["SequenceFlow_09zher9"]
  }],
  "andGateways": [{
    "id": "ExclusiveGateway_0mqmev4",
    "type": 2,
    "incoming": ["SequenceFlow_0q8umgj"],
    "outgoing": ["SequenceFlow_0sqk84k", "SequenceFlow_0ijntc6"]
  }, {
    "id": "ExclusiveGateway_11bw6vr",
    "type": 2,
    "incoming": ["SequenceFlow_0lvec4s", "SequenceFlow_04yguww"],
    "outgoing": ["SequenceFlow_021mzyg"]
  }],
  "activityMap": {
    "Task_0ykqbq7": "Enter Age",
    "Task_0y0e72x": "Show Trailer",
    "Task_0676pdy": "Display Message",
    "Task_1x5ar30": "Navigate To Home",
    "Task_1wmfg58": "Show Feedback Form",
    "Task_09kuq9m": "Update View Stats",
    "Task_0dy81yu": "Save Feedback"
  },
  "boundaryEvents": [],
  "intermediateCatchEvents": [],
  "defaultTransitions": [{
    "gateway": "ExclusiveGateway_0gx4teu",
    "transition": "SequenceFlow_1jj19x9",
    "activity": "Task_0676pdy"
  }]
};


/**
 * MODEL WITH TIMER EVENTS
 */
const timerModel = {
  id: 'timer_model',
  name: 'timer_model',
  version: [1, 0, 0],
  private: true,
  dataStoreFields: [
    {
      dataStorageId: 'PROCESS_INSTANCE',
      dataPath: 'agreement',
      parameterType: 7,
    },
    {
      dataStorageId: 'agreement',
      dataPath: 'Assignee',
      parameterType: 8,
    },
    {
      dataStorageId: 'agreement',
      dataPath: 'Datetime Param',
      parameterType: 4,
    },
    {
      dataStorageId: 'agreement',
      dataPath: 'Duration Param',
      parameterType: 1,
    },
  ],
};

const timerProcess = {
  id: 'Process_104nkeu',
  name: 'Process Name',
  interface: 'Agreement Formation',
  participants: [
    {
      id: 'Lane_18i4kvj',
      name: 'All Parties (Signatories)',
      tasks: [
        'Task_1j8291w',
        'Task_0ky8n9d',
        'Task_0kqou8a',
        'BoundaryEvent_0dscihb',
        'BoundaryEvent_12uyb1r',
        'Task_1h9s4bv',
      ],
      conditionalPerformer: true,
      dataPath: 'AGREEMENT_PARTIES',
      dataStorageId: 'agreement',
    },
    {
      id: 'Lane_1qvrgtf',
      name: 'Assignee',
      tasks: [
        'Task_1jrtitw',
        'IntermediateThrowEvent_1q6ogli',
        'Task_1bq4143',
        'BoundaryEvent_1dcsxxu',
        'BoundaryEvent_0kfiepp',
        'IntermediateThrowEvent_1iqn4ys',
        'IntermediateThrowEvent_04u998w',
      ],
      conditionalPerformer: true,
      dataPath: 'Assignee',
      dataStorageId: 'agreement',
    },
  ],
  tasks: [
    {
      id: 'Task_1bq4143',
      name: 'Noop task 1',
      assignee: '',
      activityType: 0,
      taskType: 0,
      behavior: 0,
      multiInstance: false,
      application: '',
      subProcessModelId: '',
      subProcessDefinitionId: '',
    },
    {
      id: 'Task_1j8291w',
      name: 'Noop Task 2',
      assignee: '',
      activityType: 0,
      taskType: 0,
      behavior: 0,
      multiInstance: false,
      application: '',
      subProcessModelId: '',
      subProcessDefinitionId: '',
    },
    {
      id: 'Task_0kqou8a',
      name: 'The End',
      assignee: '',
      activityType: 0,
      taskType: 0,
      behavior: 0,
      multiInstance: false,
      application: '',
      subProcessModelId: '',
      subProcessDefinitionId: '',
    },
    {
      id: 'Task_1h9s4bv',
      name: 'The End From Bound',
      assignee: '',
      activityType: 0,
      taskType: 0,
      behavior: 0,
      multiInstance: false,
      application: '',
      subProcessModelId: '',
      subProcessDefinitionId: '',
    },
  ],
  userTasks: [
    {
      activityType: 0,
      application: '',
      assignee: 'Lane_1qvrgtf',
      behavior: 1,
      id: 'Task_1jrtitw',
      multiInstance: false,
      name: 'User Task',
      subProcessDefinitionId: '',
      subProcessModelId: '',
      taskType: 1,
    },
    {
      activityType: 0,
      application: 'AgreementSignatureCheck',
      assignee: 'Lane_18i4kvj',
      behavior: 1,
      dataMappings: [
        {
          dataPath: 'agreement',
          dataStorageId: '',
          direction: 0,
          id: 'agreement',
        },
      ],
      id: 'Task_0ky8n9d',
      multiInstance: true,
      name: 'Signing Task',
      subProcessDefinitionId: '',
      subProcessModelId: '',
      taskType: 1,
    },
  ],
  sendTasks: [],
  serviceTasks: [],
  subProcesses: [],
  boundaryEvents: [
    {
      attachedTo: 'Task_1jrtitw',
      conditionalValue: {
        dataPath: 'Duration Param',
        dataStorageId: 'agreement',
        direction: 0,
        id: 'Duration Param',
      },
      escalationAction: {
        targetFunction: 'cancel()',
        dataPath: 'agreement',
        dataStorageId: '',
        dataStorage: '',
        fixedTarget: '',
      },
      eventBehavior: 0,
      eventType: 0,
      fixedValue: undefined,
      id: 'BoundaryEvent_1dcsxxu',
      name: 'Bound w conditional duration',
    },
    {
      attachedTo: 'Task_1bq4143',
      conditionalValue: undefined,
      escalationAction: {
        targetFunction: 'cancel()',
        dataPath: 'agreement',
        dataStorageId: '',
        dataStorage: '',
        fixedTarget: '',
        
      },
      eventBehavior: 0,
      eventType: 1,
      fixedValue: 110809805,
      id: 'BoundaryEvent_0kfiepp',
      name: 'bound w fixed duration',
    },
    {
      attachedTo: 'Task_0ky8n9d',
      conditionalValue: {
        dataPath: 'Datetime Param',
        dataStorageId: 'agreement',
        direction: 0,
        id: 'Datetime Param',
      },
      escalationAction: {
        targetFunction: 'cancel()',
        dataPath: 'agreement',
        dataStorageId: '',
        dataStorage: '',
        fixedTarget: '',
        
      },
      eventBehavior: 0,
      eventType: 0,
      fixedValue: undefined,
      id: 'BoundaryEvent_0dscihb',
      name: 'Bound w timedate',
    },
    {
      attachedTo: 'Task_1j8291w',
      conditionalValue: {
        dataPath: 'Datetime Param',
        dataStorageId: 'agreement',
        direction: 0,
        id: 'Datetime Param',
      },
      escalationAction: undefined,
      eventBehavior: 0,
      eventType: 0,
      fixedValue: undefined,
      id: 'BoundaryEvent_12uyb1r',
      name: 'Bound w timedate to process',
    },
  ],
  intermediateCatchEvents: [
    {
      conditionalValue: {
        dataPath: 'Duration Param',
        dataStorageId: 'agreement',
        direction: 0,
        id: 'Duration Param',
      },
      eventBehavior: 0,
      eventType: 0,
      fixedValue: undefined,
      id: 'IntermediateThrowEvent_1q6ogli',
      name: 'Catch w conditional duration',
    },
    {
      conditionalValue: undefined,
      eventBehavior: 0,
      eventType: 1,
      fixedValue: 110809805,
      id: 'IntermediateThrowEvent_1iqn4ys',
      name: 'Catch w fixed duration',
    },
    {
      conditionalValue: {
        dataPath: 'Datetime Param',
        dataStorageId: 'agreement',
        direction: 0,
        id: 'Datetime Param',
      },
      eventBehavior: 0,
      eventType: 0,
      fixedValue: undefined,
      id: 'IntermediateThrowEvent_04u998w',
      name: 'Catch w timedate',
    },
  ],
  transitions: [
    {
      id: 'SequenceFlow_0twrlls',
      source: 'Task_0ky8n9d',
      target: 'IntermediateThrowEvent_04u998w',
    },
    {
      id: 'SequenceFlow_1chkl5e',
      source: 'IntermediateThrowEvent_04u998w',
      target: 'Task_1jrtitw',
    },
    {
      id: 'SequenceFlow_1wv98fy',
      source: 'Task_1jrtitw',
      target: 'IntermediateThrowEvent_1q6ogli',
    },
    {
      id: 'SequenceFlow_00hsej8',
      source: 'IntermediateThrowEvent_1q6ogli',
      target: 'Task_1bq4143',
    },
    {
      id: 'SequenceFlow_1v3my1m',
      source: 'Task_1bq4143',
      target: 'IntermediateThrowEvent_1iqn4ys',
    },
    {
      id: 'SequenceFlow_126qubd',
      source: 'IntermediateThrowEvent_1iqn4ys',
      target: 'Task_1j8291w',
    },
    {
      id: 'SequenceFlow_0bwi3b7',
      source: 'Task_1j8291w',
      target: 'Task_0kqou8a',
    },
    {
      id: 'SequenceFlow_0snxz1y',
      source: 'BoundaryEvent_12uyb1r',
      target: 'Task_1h9s4bv',
    },
  ],
  activityMap: {
    Task_0kqou8a: 'The End',
    Task_0ky8n9d: 'Signing Task',
    Task_1bq4143: 'Noop task 1',
    Task_1h9s4bv: 'The End From Bound',
    Task_1j8291w: 'Noop Task 2',
    Task_1jrtitw: 'User Task',
  },
  andGateways: [],
  xorGateways: [],
};

describe("BPMN XML Parser", () => {
  let parser;

  it("should parse stringified booleans", () => {
    expect(bpmnParser.getBooleanFromString("true")).to.be.true;
    expect(bpmnParser.getBooleanFromString("True")).to.be.false;
    expect(bpmnParser.getBooleanFromString("false")).to.be.false;
    expect(bpmnParser.getBooleanFromString("False")).to.be.false;
    expect(bpmnParser.getBooleanFromString(true)).to.be.true;
    expect(bpmnParser.getBooleanFromString(false)).to.be.false;
    expect(bpmnParser.getBooleanFromString(1)).to.be.false;
    expect(bpmnParser.getBooleanFromString(-100)).to.be.false;
    expect(bpmnParser.getBooleanFromString(0)).to.be.false;
    expect(bpmnParser.getBooleanFromString("abc")).to.be.false;
    expect(bpmnParser.getBooleanFromString({
      a: 1
    })).to.be.false;
    expect(bpmnParser.getBooleanFromString()).to.be.false;
  });

  it("should get model details", async () => {
    parser = bpmnParser.getNewParser();
    expect(parser).to.exist;
    await parser.parse(xmlString);
    let model = parser.getModel();
    expect(model).to.deep.equal(expectedModel);
  });

  it("should get processes", async () => {
    let processes = parser.getProcesses();
    let p1 = processes.filter((p) => {
      return p.id === expectedProcess1.id;
    })[0];
    let p2 = processes.filter((p) => {
      return p.id === expectedProcess2.id;
    })[0];
    expect(p1).to.deep.equal(expectedProcess1);
    expect(p2).to.deep.equal(expectedProcess2);
  });

  it('Should get gateway details', async () => {
    try {
      parser = bpmnParser.getNewParser();
      await parser.parse(gatewayXml);
      let model = parser.getModel();
      let processes = parser.getProcesses();
      let p1 = processes.filter((p) => {
        return p.id === gatewayProcess1.id;
      })[0];
      expect(model).to.deep.equal(gatewayModel1);
      expect(p1).to.deep.equal(gatewayProcess1);
    } catch (err) {
      throw err;
    }
  });

  it('should get timer event details', async () => {
    parser = bpmnParser.getNewParser();
    await parser.parse(timerXml);
    const model = parser.getModel();
    expect(model).to.deep.equal(timerModel);
    const parsedTimerProcess = parser.getProcesses()[0];
    expect(parsedTimerProcess).to.deep.equal(timerProcess);
  });

});
