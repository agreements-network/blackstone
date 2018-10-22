const chai = require('chai');
const chaiHttp = require('chai-http');
const chaiAsPromised = require('chai-as-promised');
const request = require('supertest');
const rid = require('random-id');
const path = require('path');
const fs = require('fs');
const _ = require('lodash');

const app = require('../../app');
const server = require(__common + '/aa-web-api');
const logger = require(__common + '/monax-logger');
const log = logger.getLogger('agreements.tests');
const pool = require(__common + '/postgres-db');
const contracts = require(`${global.__controllers}/contracts-controller`);

const api = require('./api-helper')(server);

// configure chai
chai.use(chaiHttp);
chai.use(chaiAsPromised);
const should = chai.should();
const expect = chai.expect;
const assert = chai.assert;

// wait for the app to be fully bootstrapped
before(function(done) {
  this.timeout(99999999);
  app.eventEmitter.on(app.events.STARTED, () => {
    log.info('Application started. Running REST API Test Suite ...');
    done();
  });
});

var hoardRef = { address: null, secretKey: null };

describe(':: HOARD ::', () => {
  it('Should upload a real file to hoard', async () => {
    let hoardUser = {
      username: `hoard${rid(5, 'aA0')}`,
      password: 'hoarduser',
      email: `${rid(10, 'aA0')}@test.com`
    };
    await api.registerUser(hoardUser);
    setTimeout(async () => {
      try {
        let loginResult = await api.loginUser(hoardUser);
        token = loginResult.token;
        setTimeout(() => {
          request(server)
            .post('/hoard')
            .set('Cookie', [`access_token=${token}`])
            .attach('myfile.js', __dirname + '/web-api-test.js')
            .expect(200)
            .end((err, res) => {
              expect(err).to.not.exist;
              hoardRef.address = res.body.address.toUpperCase();
              hoardRef.secretKey = res.body.secretKey.toUpperCase();
            });
        }, 3000);
      } catch (err) {
        throw err;
      }
    }, 3000);
  }).timeout(10000);
});
 
describe(':: FORMATION - EXECUTION for Incorporation Signing and Fulfilment ::', () => {
  let signer = {
    username: `signer${rid(5, 'aA0')}`,
    password: 'signer',
    email: `${rid(10, 'aA0')}@test.com`,
  };
  let receiver = {
    username: `receiver${rid(5, 'aA0')}`,
    password: 'eteUser2',
    email: `${rid(10, 'aA0')}@test.com`,
  };
  let confirmer = {
    username: `confirmer${rid(5, 'aA0')}`,
    password: 'eteUser2',
    email: `${rid(10, 'aA0')}@test.com`,
  };

  let formation = {
    filePath: 'test/data/inc-formation.bpmn',
    process: {},
    id: rid(16, 'aA0'),
    name: 'Incorporation-Formation'
  }
  let execution = {
    filePath: 'test/data/inc-execution.bpmn',
    process: {},
    id: rid(16, 'aA0'),
    name: 'Incorporation-Execution'
  }

  /**
      { type: 0, name: 'bool' },
      { type: 1, name: 'string' },
      { type: 2, name: 'num' },
      { type: 3, name: 'date' },
      { type: 4, name: 'datetime' },
      { type: 5, name: 'money' },
      { type: 6, name: 'user' },
      { type: 7, name: 'addr' },
      { type: 8, name: 'signatory' },
   */
  let archetype = {
    name: 'Incorporation Archetype',
    description: 'Incorporation Archetype',
    price: 10,
    isPrivate: 1,
    active: 1,
    parameters: [
      { type: 8, name: 'Incorporator' },
      { type: 6, name: 'Receiver' },
      { type: 6, name: 'Confirmer' },
    ],
    documents: [{
      name: 'doc1.md',
      hoardAddress: '0x0',
      secretKey: '0x0',
    }],
    jurisdictions: [],
    executionProcessDefinition: '',
    formationProcessDefinition: '',
    governingArchetypes: []
  }

  let agreement = {
    name: 'user tasks agreement',
    archetype: '',
    isPrivate: false,
    parameters: [],
    hoardAddress: '',
    hoardSecret: '',
    eventLogHoardAddress: '',
    eventLogHoardSecret: '',
    maxNumberOfEvents: 0,
    governingAgreements: []
  }

  it('Should register users', async () => {
    // REGISTER USERS
    let registerResult = await api.registerUser(signer);
    signer.address = registerResult.address;
    expect(signer.address).to.exist
    registerResult = await api.registerUser(receiver);
    receiver.address = registerResult.address;
    expect(receiver.address).to.exist
    registerResult = await api.registerUser(confirmer);
    confirmer.address = registerResult.address;
    expect(confirmer.address).to.exist
  }).timeout(5000);

  it('Should login users', (done) => {
    // LOGIN USERS
    setTimeout(async () => {
      try {
        let loginResult = await api.loginUser(signer);
        expect(loginResult.token).to.exist;
        signer.token = loginResult.token;
        loginResult = await api.loginUser(receiver);
        expect(loginResult.token).to.exist;
        receiver.token = loginResult.token;
        loginResult = await api.loginUser(confirmer);
        expect(loginResult.token).to.exist;
        confirmer.token = loginResult.token;
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

  it('Should deploy formation and execution models', async () => {
    // DEPLOY FORMATION MODEL
    let formXml = api.generateModelXml(formation.id, formation.filePath);
    let formationDeploy = await api.createAndDeployModel(formXml, signer.token);
    expect(formationDeploy).to.exist;
    Object.assign(formation, formationDeploy.model);
    Object.assign(formation.process, formationDeploy.processes[0]);
    archetype.formationProcessDefinition = formation.process.address;
    expect(String(archetype.formationProcessDefinition).match(/[0-9A-Fa-f]{40}/)).to.exist;
    // DEPLOY EXECUTION MODEL
    let execXml = api.generateModelXml(execution.id, execution.filePath);
    let executionDeploy = await api.createAndDeployModel(execXml, signer.token);
    expect(executionDeploy).to.exist;
    Object.assign(execution, executionDeploy.model);
    Object.assign(execution.process, executionDeploy.processes[0]);
    archetype.executionProcessDefinition = execution.process.address;
    expect(String(archetype.executionProcessDefinition).match(/[0-9A-Fa-f]{40}/)).to.exist;
    expect(String(archetype.executionProcessDefinition).match(/[0-9A-Fa-f]{40}/)).to.exist;
  }).timeout(30000);

  it('Should get a bpm diagram in the requested format', async () => {
    // GET DIAGRAM
    const diagram = await (api.getDiagram(formation.process.modelAddress, 'application/json'));
    expect(diagram).to.be.an('object');
  }).timeout(30000);

  it('Should populate process names in cache', async () => {
    const formationProcess = await api.getProcessDefinition(formation.process.address, signer.token);
    const executionProcess = await api.getProcessDefinition(execution.process.address, signer.token);
    expect(formationProcess.processName).to.equal(formation.process.processName);
    expect(executionProcess.processName).to.equal(execution.process.processName);
    let formCacheReponse = await pool.query({
      text: 'SELECT process_name FROM PROCESS_DETAILS WHERE model_id = $1 AND process_id = $2',
      values: [formation.id, formation.process.processDefinitionId]
    });
    expect(formCacheReponse.rows[0].process_name).to.equal(formation.process.processName);
    let execCacheReponse = await pool.query({
      text: 'SELECT process_name FROM PROCESS_DETAILS WHERE model_id = $1 AND process_id = $2',
      values: [execution.id, execution.process.processDefinitionId]
    });
    expect(execCacheReponse.rows[0].process_name).to.equal(execution.process.processName);
  });

  it('Should create an archetype', done => {
    // CREATE ARCHETYPE
    setTimeout(async () => {
      try {
        archetype.documents[0].hoardAddress = hoardRef.address;
        archetype.documents[0].secretKey = hoardRef.secretKey;
        Object.assign(archetype, await api.createArchetype(archetype, signer.token));
        expect(String(archetype.address)).match(/[0-9A-Fa-f]{40}/).to.exist;
        agreement.archetype = archetype.address;
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

  it('Should create an angreement and start formation process', done => {
    // CREATE AGREEMENT
    setTimeout(async () => {
      try {
        agreement.parameters.push({ name: 'Incorporator', type: 8, value: signer.address });
        agreement.parameters.push({ name: 'Receiver', type: 6, value: receiver.address });
        agreement.parameters.push({ name: 'Confirmer', type: 6, value: confirmer.address });
        agreement.hoardAddress = hoardRef.address;
        agreement.hoardSecret = hoardRef.secretKey;
        Object.assign(agreement, await api.createAgreement(agreement, signer.token));
        expect(String(agreement.address)).match(/[0-9A-Fa-f]{40}/).to.exist;
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

  it('Should sign and complete incorporation task by incorporator', done => {
    setTimeout(async () => {
      try {
        let signerTasks = await api.getTasksForUser(signer.token);
        expect(signerTasks.length).to.be.greaterThan(0);
        expect(signerTasks[0].activityId).to.equal('signTask_abc123');
        expect(signerTasks[0].name).to.equal('Sign For Incorporation');
        await api.completeAndSignTaskForUser(signerTasks[0].activityInstanceId, agreement.address, signer.token);
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

  it('Should sign and complete receive signature task by receiver', done => {
    setTimeout(async () => {
      try {
        let receiverTasks = await api.getTasksForUser(receiver.token);
        expect(receiverTasks.length).to.be.greaterThan(0);
        expect(receiverTasks[0].activityId).to.equal('recTask_123fkjg');
        expect(receiverTasks[0].name).to.equal('Receive Signature');
        await api.completeTaskForUser(receiverTasks[0].activityInstanceId, null, receiver.token);
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

  it('Should verify agreement is EXECUTED', done => {
    setTimeout(async () => {
      try {
        let agreementData = await api.getAgreement(agreement.address, signer.token);
        expect(parseInt(agreementData.legalState, 10)).to.equal(2);
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

  it('Should sign and complete confirmation task by confirmer', done => {
    setTimeout(async () => {
      try {
        let confirmTasks = await api.getTasksForUser(confirmer.token);
        expect(confirmTasks.length).to.be.greaterThan(0);
        expect(confirmTasks[0].activityId).to.equal('confirmTask_kah254');
        expect(confirmTasks[0].name).to.equal('Confirm Incorporation');
        await api.completeTaskForUser(confirmTasks[0].activityInstanceId, null, confirmer.token);
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

  it('Should verify agreement is FULFILLED', done => {
    setTimeout(async () => {
      try {
        let agreementData = await api.getAgreement(agreement.address, signer.token);
        expect(parseInt(agreementData.legalState, 10)).to.equal(3);
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

});

describe(':: FORMATION - EXECUTION for Sale of Goods User Tasks ::', () => {

  const model = { id: rid(16, 'aA0'), filePath: 'test/data/AN-TestTemplate-FE.bpmn' };
  const archetype1 = {
    name: "Archetype 1",
    description: "Archetype 1",
    price: 10,
    isPrivate: true,
    active: true,
    password: "this is a test",
    formationProcessDefinition: "",
    parameters: [
      { name: "buyer", type: 6 },
      { name: "seller", type: 6 }
    ],
    jurisdictions: [{ country: "US", regions: [] }],
    documents: [{
      name: 'doc1.md',
      hoardAddress: '0x0',
      secretKey: '0x0',
    }],
    governingArchetypes: []
  };
  let agreement1 = {
    name: 'Agreement No. ' + new Date().getMilliseconds(),
    archetype: '', // plug in archetype address
    isPrivate: false,
    parties: [],
    parameters: [],
    maxNumberOfEvents: 5,
    governingAgreements: []
  };
  let buyerTask;
  let sellerTask;
  const process1 = {};
  const process2 = {};
  let xml = api.generateModelXml(model.id, model.filePath);
  expect(xml).to.exist;
  const user1 = {
    username: rid(10, 'aA0'),
    password: 'eteUser1',
    email: `${rid(10, 'aA0')}@test.com`,
  };
  const user2 = {
    username: rid(10, 'aA0'),
    password: 'eteUser2',
    email: `${rid(10, 'aA0')}@test.com`,
  };

  it('Should register users', async () => {
    // REGISTER USERS
    let registerResult = await api.registerUser(user1);
    user1.address = registerResult.address;
    expect(user1.address).to.exist
    registerResult = await api.registerUser(user2);
    user2.address = registerResult.address;
    expect(user2.address).to.exist
  }).timeout(5000);

  it('Should login users', (done) => {
    // LOGIN USERS
    setTimeout(async () => {
      let loginResult = await api.loginUser(user1);
      expect(loginResult.token).to.exist;
      user1.token = loginResult.token;
      loginResult = await api.loginUser(user2);
      expect(loginResult.token).to.exist;
      user2.token = loginResult.token;
      done();
    }, 3000);
  }).timeout(10000);

  it('Should deploy model', async () => {
    // DEPLOY MODEL
    let deployResponse = await api.createAndDeployModel(xml, user1.token);
    expect(deployResponse).to.exist;
    Object.assign(model, deployResponse.model);
    Object.assign(process1, deployResponse.processes[0]);
    Object.assign(process2, deployResponse.processes[1]);
    archetype1.formationProcessDefinition = process1.address;
    archetype1.executionProcessDefinition = process2.address;
    expect(String(archetype1.formationProcessDefinition).match(/[0-9A-Fa-f]{40}/)).to.exist;
    expect(String(archetype1.executionProcessDefinition).match(/[0-9A-Fa-f]{40}/)).to.exist;
  }).timeout(30000);

  it('Should create an archetype', async () => {
    // CREATE ARCHETYPE
    archetype1.documents[0].hoardAddress = hoardRef.address;
    archetype1.documents[0].secretKey = hoardRef.secretKey;
    Object.assign(archetype1, await api.createArchetype(archetype1, user1.token));
    expect(String(archetype1.address).match(/[0-9A-Fa-f]{40}/)).to.exist;
  }).timeout(15000);

  it('Should create an agreement', done => {
    // CREATE AGREEMENT AND START PROCESS
    agreement1.archetype = archetype1.address;
    agreement1.parameters.push({ name: 'buyer', type: 6, value: user1.address });
    agreement1.parameters.push({ name: 'seller', type: 6, value: user2.address });
    // adding user1 to parties even though the task assigned to user1 is not a sign task - this is still allowed
    // you need to be in the parties array of an agreement to be able to cancel an agreement
    agreement1.parties.push(user1.address);
    setTimeout(async () => {
      try {
        let agreementRes = await api.createAgreement(agreement1, user1.token);
        agreement1.address = agreementRes.address;
        expect(String(agreement1.address).match(/[0-9A-Fa-f]{40}/)).to.exist;
        done();
      } catch (err) {
        done(err);
      }
    }, 5000);
  }).timeout(20000);

  it('Should verify only ONE pending user task for buyer and complete it', done => {
    // USER TASK VERIFICATION
    setTimeout(async () => {
      try {
        let buyerTasks = await api.getTasksForUser(user1.token);
        expect(buyerTasks.length).to.equal(1);
        expect(buyerTasks[0].activityId).to.equal('SignOffPayment');
        buyerTask = buyerTasks[0];
        let sellerTasks = await api.getTasksForUser(user2.token);
        expect(sellerTasks.length).to.equal(0);
        await api.completeAndSignTaskForUser(buyerTask.activityInstanceId, agreement1.address, user1.token);
        done();
      } catch (err) {
        done(err);
      }
    }, 5000);
  }).timeout(15000);

  it('Should verify NO pending user task for buyer', done => {
    // USER TASK VERIFICATION
    setTimeout(async () => {
      try {
        let tasks = await api.getTasksForUser(user1.token);
        expect(tasks.length).to.equal(0);
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

  it('Should verify only ONE pending user task for seller and complete it', done => {
    // USER TASK VERIFICATION
    setTimeout(async () => {
      try {
        let sellerTasks = await api.getTasksForUser(user2.token);
        expect(sellerTasks.length).to.equal(1);
        expect(sellerTasks[0].activityId).to.equal('ShipGoods');
        sellerTask = sellerTasks[0];
        let buyerTasks = await api.getTasksForUser(user1.token);
        expect(buyerTasks.length).to.equal(0);
        await api.completeTaskForUser(sellerTask.activityInstanceId, null, user2.token);
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

  it('Should verify NO pending user task for seller', done => {
    // USER TASK VERIFICATION
    setTimeout(async () => {
      try {
        let tasks = await api.getTasksForUser(user2.token);
        expect(tasks.length).to.equal(0);
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

  it('Should cancel an agreement by an agreement party member', done => {
    // AGREEMENT CANCELATION VERIFICATION
    setTimeout(async () => {
      try {
        await api.cancelAgreement(agreement1.address, user1.token);
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

});

describe(':: DATA MAPPING TEST ::', () => {
  let manager = {
    username: `manager${rid(5, 'aA0')}`,
    password: 'manager',
    email: `manager${rid(3, 'aA0')}@test.com`,
  };

  let admin = {
    username: `admin${rid(5, 'aA0')}`,
    password: 'administrator',
    email: `admin${rid(3, 'aA0')}@test.com`,
  };

  let formation = {
    filePath: 'test/data/data-mapping-formation.bpmn',
    process: {},
    id: rid(16, 'aA0'),
    name: 'Data-Mapping-Formation'
  }
  let execution = {
    filePath: 'test/data/data-mapping-execution.bpmn',
    process: {},
    id: rid(16, 'aA0'),
    name: 'Data-Mapping-Execution'
  }

  /**
      { type: 0, name: 'bool' },
      { type: 1, name: 'string' },
      { type: 2, name: 'num' },
      { type: 3, name: 'date' },
      { type: 4, name: 'datetime' },
      { type: 5, name: 'money' },
      { type: 6, name: 'user' },
      { type: 7, name: 'addr' },
      { type: 8, name: 'signatory' },
   */
  let archetype = {
    name: 'Data Mapping Archetype',
    description: 'Data Mapping Archetype',
    price: 10,
    isPrivate: 0,
    active: true,
    parameters: [
      { type: 8, name: 'Manager' },
      { type: 6, name: 'Administrator' }
    ],
    documents: [{
      name: 'doc1.md',
      hoardAddress: '0x0',
      secretKey: '0x0',
    }],
    jurisdictions: [],
    executionProcessDefinition: '',
    formationProcessDefinition: '',
    governingArchetypes: []
  }

  let agreement = {
    name: 'data mapping agreement 1',
    archetype: '',
    isPrivate: false,
    parameters: [],
    hoardAddress: '',
    hoardSecret: '',
    eventLogHoardAddress: '',
    eventLogHoardSecret: '',
    maxNumberOfEvents: 0,
    governingAgreements: []
  }

  let managerTask, adminTask;

  it('Should register users', async () => {
    // REGISTER USERS
    let registerResult = await api.registerUser(manager);
    manager.address = registerResult.address;
    expect(manager.address).to.exist
    registerResult = await api.registerUser(admin);
    admin.address = registerResult.address;
    expect(admin.address).to.exist
  }).timeout(3000);

  it('Should login users', (done) => {
    // LOGIN USERS
    setTimeout(async () => {
      try {
        let loginResult = await api.loginUser(manager);
        expect(loginResult.token).to.exist;
        manager.token = loginResult.token;
        loginResult = await api.loginUser(admin);
        expect(loginResult.token).to.exist;
        admin.token = loginResult.token;
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

  it('Should deploy formation and execution models', async () => {
    // DEPLOY FORMATION MODEL
    let formXml = api.generateModelXml(formation.id, formation.filePath);
    let formationDeploy = await api.createAndDeployModel(formXml, manager.token);
    expect(formationDeploy).to.exist;
    Object.assign(formation, formationDeploy.model);
    Object.assign(formation.process, formationDeploy.processes[0]);
    archetype.formationProcessDefinition = formation.process.address;
    expect(String(archetype.formationProcessDefinition).match(/[0-9A-Fa-f]{40}/)).to.exist;
    // DEPLOY EXECUTION MODEL
    let execXml = api.generateModelXml(execution.id, execution.filePath);
    let executionDeploy = await api.createAndDeployModel(execXml, manager.token);
    expect(executionDeploy).to.exist;
    Object.assign(execution, executionDeploy.model);
    Object.assign(execution.process, executionDeploy.processes[0]);
    archetype.executionProcessDefinition = execution.process.address;
    expect(String(archetype.executionProcessDefinition).match(/[0-9A-Fa-f]{40}/)).to.exist;
    expect(String(archetype.executionProcessDefinition).match(/[0-9A-Fa-f]{40}/)).to.exist;
  }).timeout(30000);

  it('Should create an archetype', done => {
    // CREATE ARCHETYPE
    setTimeout(async () => {
      try {
        archetype.documents[0].hoardAddress = hoardRef.address;
        archetype.documents[0].secretKey = hoardRef.secretKey;
        Object.assign(archetype, await api.createArchetype(archetype, manager.token));
        expect(String(archetype.address)).match(/[0-9A-Fa-f]{40}/).to.exist;
        agreement.archetype = archetype.address;
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

  it('Should create an agreement and start formation process', done => {
    // CREATE AGREEMENT
    setTimeout(async () => {
      try {
        agreement.parameters.push({ name: 'Manager', type: 8, value: manager.address });
        agreement.parameters.push({ name: 'Administrator', type: 6, value: admin.address });
        agreement.hoardAddress = hoardRef.address;
        agreement.hoardSecret = hoardRef.secretKey;
        Object.assign(agreement, await api.createAgreement(agreement, manager.token));
        expect(String(agreement.address)).match(/[0-9A-Fa-f]{40}/).to.exist;
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

  it('Should be able to set data as suspended task\'s assigned user', done => {
    setTimeout(async () => {
      try {
        let managerTasks = await api.getTasksForUser(manager.token);
        expect(managerTasks.length).to.be.greaterThan(0);
        expect(managerTasks[0].activityId).to.equal('apprTask_123');
        await assert.isFulfilled(api.setActivityDataValues(
          managerTasks[0].activityInstanceId,
          [
            { id: 'writeName', value: 'John Doe' },
            { id: 'writeApproved', value: true }
          ],
          manager.token
        ));
        let data = await assert.isFulfilled(api.getActivityDataValues(managerTasks[0].activityInstanceId, manager.token));
        expect(data.length).to.equal(2);
        let name = data.filter(d => d.accessPointId === 'readName')[0].value;
        let approved = data.filter(d => d.accessPointId === 'readApproved')[0].value;
        expect(name).to.equal('John Doe');
        expect(approved).to.equal(true);
        managerTask = managerTasks[0];
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

  it('Should be able to get activity instance details including data mappings', async ()  => {
    try {
      let aiData = await api.getActivityInstance(managerTask.activityInstanceId, manager.token);
      expect(aiData.data).to.exist;
      expect(aiData.data.in.length).to.equal(2);
      expect(aiData.data.out.length).to.equal(2);
      let readName = aiData.data.in.filter(d => d.dataMappingId === 'readName')[0];
      let readApproved = aiData.data.in.filter(d => d.dataMappingId === 'readApproved')[0];
      let writeName = aiData.data.out.filter(d => d.dataMappingId === 'writeName')[0];
      let writeApproved = aiData.data.out.filter(d => d.dataMappingId === 'writeApproved')[0];
      expect(readName.value).to.equal('John Doe');
      expect(readApproved.value).to.equal(true);
      expect(writeName.dataPath).to.equal('name');
      expect(writeApproved.dataPath).to.equal('approved');
    } catch (err) {
      throw err;
    }
  }).timeout(10000);

  it('Should be able to set data and complete suspended task', done => {
    setTimeout(async () => {
      let data = [
        { id: 'writeApproved', value: true },
        { id: 'writeName', value: "Jane Doe" },
      ];
      try {
        await assert.isFulfilled(api.completeTaskForUser(managerTask.activityInstanceId, data, manager.token));
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

  it('Should sign the agreement', done => {
    setTimeout(async () => {
      try {
        let signerTasks = await api.getTasksForUser(manager.token);
        expect(signerTasks.length).to.be.greaterThan(0);
        expect(signerTasks[0].activityId).to.equal('signTask_1amiv9a');
        expect(signerTasks[0].name).to.equal('Sign Off');
        await api.completeAndSignTaskForUser(signerTasks[0].activityInstanceId, agreement.address, manager.token);
        done();
      } catch (err) {
        done(err);
      }
    }, 5000);
  }).timeout(10000);

  it('Should be able to read agreement data from data mappings by administrator', done => {
    setTimeout(async () => {
      try {
        let adminTasks = await api.getTasksForUser(admin.token);
        expect(adminTasks.length).to.equal(1);
        let aiData = await api.getActivityInstance(adminTasks[0].activityInstanceId, admin.token);
        expect(aiData.data).to.exist;
        expect(aiData.data.in.length).to.equal(2);
        expect(aiData.data.out).to.not.exist;
        let readName = aiData.data.in.filter(d => d.dataMappingId === 'readName')[0];
        let readApproved = aiData.data.in.filter(d => d.dataMappingId === 'readApproved')[0];
        expect(readName.value).to.equal('Jane Doe');
        expect(readApproved.value).to.equal(true);
        done();
      } catch (err) {
        done(err);
      }
    }, 5000);
  }).timeout(10000);

});

describe(':: Archetype Packages and Agreement Collections ::', () => {
  const model = { id: rid(16, 'aA0'), filePath: 'test/data/AN-TestTemplate-FE.bpmn' };
  const publicArchetype1 = {
    name: "Public Archetype 1",
    description: "Public Archetype 1 " + rid(5, 'aA0'),
    price: 10,
    isPrivate: false,
    active: true,
    password: "this is a test",
    formationProcessDefinition: "",
    parameters: [],
    jurisdictions: [],
    documents: [{
      name: 'doc1.md',
      hoardAddress: '0x0',
      secretKey: '0x0',
    }],
    governingArchetypes: []
  };
  const privateArchetype1 = {
    name: "Private Archetype 1",
    description: "Private Archetype 1",
    price: 10,
    isPrivate: true,
    active: true,
    password: "this is a test",
    formationProcessDefinition: "",
    parameters: [],
    jurisdictions: [],
    documents: [{
      name: 'doc1.md',
      hoardAddress: '0x0',
      secretKey: '0x0',
    }],
    governingArchetypes: []
  };
  let agreement1 = {
    name: 'Agreement No. ' + new Date().getMilliseconds(),
    archetype: '', // plug in archetype address
    isPrivate: false,
    parties: [],
    parameters: [],
    maxNumberOfEvents: 5,
    governingAgreements: []
  };
  let publicPackage1 = {
    name: "publicPackage1",
    description: "arch package 1 " + rid(5, 'aA0'),
    author: "",
    isPrivate: false,
    active: true
  };
  let publicPackage2 = {
    name: "publicPackage2",
    description: "arch package 2 " + rid(5, 'aA0'),
    author: "",
    isPrivate: false,
    active: true
  };
  let privatePackage1 = {
    name: "privatePackage1",
    description: "arch package 3 " + rid(5, 'aA0'),
    author: "",
    isPrivate: true,
    active: true
  };
  let collection1 = {
    name: "collection1",
    author: "",
    collectionType: 4,
    packageId: ""
  };
  let collection2 = {
    name: "collection2",
    author: "",
    collectionType: 3,
    packageId: ""
  };
  let buyerTask;
  const process1 = {};
  const process2 = {};
  let xml = api.generateModelXml(model.id, model.filePath);
  expect(xml).to.exist;
  const user1 = {
    username: rid(8, 'aA0'),
    password: 'archUser1',
    email: `${rid(8, 'aA0')}@test.com`,
  };
  const user2 = {
    username: rid(10, 'aA0'),
    password: 'archeUser2',
    email: `${rid(10, 'aA0')}@test.com`,
  };

  it('Should register users', async () => {
    // REGISTER USERS
    try {
      let registerResult1 = await api.registerUser(user1);
      let registerResult2 = await api.registerUser(user2);
      user1.address = registerResult1.address;
      user2.address = registerResult2.address;
      expect(user1.address).to.exist
      expect(user2.address).to.exist
    } catch (err) {
      throw err;
    }
  }).timeout(5000);

  it('Should login users', (done) => {
    // LOGIN USERS
    setTimeout(async () => { 
      try {
        let loginResult1 = await api.loginUser(user1);
        let loginResult2 = await api.loginUser(user2);
        expect(loginResult1.token).to.exist;
        expect(loginResult2.token).to.exist;
        user1.token = loginResult1.token;
        user2.token = loginResult2.token;
        done();
      } catch (err) {
        done(err);
      }
    }, 5000);
  }).timeout(10000);

  it('Should deploy model', async () => {
    // DEPLOY MODEL
    let deployResponse = await api.createAndDeployModel(xml, user1.token);
    expect(deployResponse).to.exist;
    Object.assign(model, deployResponse.model);
    Object.assign(process1, deployResponse.processes[0]);
    Object.assign(process2, deployResponse.processes[1]);
    expect(String(process1.address).match(/[0-9A-Fa-f]{40}/)).to.exist;
    expect(String(process2.address).match(/[0-9A-Fa-f]{40}/)).to.exist;
    publicArchetype1.formationProcessDefinition = process1.address;
    publicArchetype1.executionProcessDefinition = process2.address;
    privateArchetype1.formationProcessDefinition = process1.address;
    privateArchetype1.executionProcessDefinition = process2.address;
  }).timeout(30000);

  it('Should create a publicPackage1 by user1', async () => {
    // CREATE ARCHETYPE PACKAGE
    let data = await api.createArchetypePackage(publicPackage1, user1.token);
    publicPackage1.id = data.id;
    expect(publicPackage1.id).to.exist;
  }).timeout(10000);

  it('Should create publicPackage2 by user2', async () => {
    // CREATE ARCHETYPE PACKAGE
    let data = await api.createArchetypePackage(publicPackage2, user2.token);
    publicPackage2.id = data.id;
    expect(publicPackage2.id).to.exist;
  }).timeout(10000);

  it('Should fetch both public packages by user2', done => {
    setTimeout(async () => {
      try {
        const packages = await api.getArchetypePackages(user2.token);
        const fPackages = packages.filter(p => p.description === publicPackage1.description ||
          p.description === publicPackage2.description);
        expect(fPackages.length).to.equal(2);
        done()
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

  it('Should fail to deactivate publicPackage1 by user2', async () => {
    await assert.isRejected(api.deactivateArchetypePackage(publicPackage1.id, user2.token));
  }).timeout(10000);

  it('Should deactivate publicPackage1 by user1', async () => {
    await assert.isFulfilled(api.deactivateArchetypePackage(publicPackage1.id, user1.token));
  }).timeout(10000);

  it('Should fetch only active public packages by user2', done => {
    setTimeout(async () => {
      try {
        const packages = await api.getArchetypePackages(user2.token);
        const fPackages = packages.filter(p => p.description === publicPackage1.description ||
          p.description === publicPackage2.description);
        expect(fPackages.length).to.equal(1);
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

  it('Should create privatePackage1 by user1', async () => {
    // CREATE ARCHETYPE PACKAGE
    let data = await api.createArchetypePackage(privatePackage1, user1.token);
    privatePackage1.id = data.id;
    expect(privatePackage1.id).to.exist;
  }).timeout(10000);

  it('Should fail to create publicArchetype1 by user1 in publicPackage2 created by user2', async () => {
    // CREATE ARCHETYPE
    publicArchetype1.documents[0].hoardAddress = hoardRef.address;
    publicArchetype1.documents[0].secretKey = hoardRef.secretKey;
    publicArchetype1.packageId = publicPackage2.id;
    await assert.isRejected(api.createArchetype(publicArchetype1, user1.token));
  }).timeout(15000);

  it('Should create publicArchetype1 by user1 with no package id', async () => {
    // CREATE ARCHETYPE
    delete publicArchetype1.packageId;
    Object.assign(publicArchetype1, await api.createArchetype(publicArchetype1, user1.token));
    expect(String(publicArchetype1.address).match(/[0-9A-Fa-f]{40}/)).to.exist;
  }).timeout(10000);

  it('Should fail to deactivate publicArchetype1 by user2', done => {
    setTimeout(async () => {
      await assert.isRejected(api.deactivateArchetype(publicArchetype1.address, user2.token));
      done();
    }, 3000);
  }).timeout(10000);

  it('Should deactivate publicArchetype1 by user1', done => {
    setTimeout(async () => {
      try {
        await assert.isFulfilled(api.deactivateArchetype(publicArchetype1.address, user1.token));
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

  it('Should not create an agreement from inactive archetype', done => {
    setTimeout(async () => {
      try {
        const agr = {
          name: 'No dice',
          archetype: publicArchetype1.address,
          isPrivate: false,
          parties: [],
          parameters: [],
          maxNumberOfEvents: 5,
        }
        await assert.isRejected(api.createAgreement(agr, user1.token));
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  });

  it('Should not get deactivated archetype by user2', async () => {
    const archetypes = await api.getArchetypes(user2.token);
    const fArchetypes = archetypes.filter(a => a.description === publicArchetype1.desctription);
    expect(fArchetypes.length).to.equal(0);
  }).timeout(10000);

  it('Should activate publicArchetype1 by user1', done => {
    setTimeout(async () => {
      try {
        await assert.isFulfilled(api.activateArchetype(publicArchetype1.address, user1.token));
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

  it('Should get active archetypes by user2', done => {
    setTimeout(async () => {
      try {
        const archetypes = await api.getArchetypes(user2.token);
        const fArchetypes = archetypes.filter(a => a.description === publicArchetype1.description);
        expect(fArchetypes.length).to.equal(1);
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

  it('Should fail to add publicArchetype1 created by user1 to publicPackage2 created by user2', async () => {
    // User1 attempts to add publicArchetype1 to publicPackage2 and fails since he did not author publicPackage2
    await assert.isRejected(api.addArchetypeToPackage(publicPackage2.id, publicArchetype1.address, user1.token));
  }).timeout(10000);

  it('Should create privateArchetype1 by user2 with no package id', async () => {
    // CREATE ARCHETYPE
    privateArchetype1.documents[0].hoardAddress = hoardRef.address;
    privateArchetype1.documents[0].secretKey = hoardRef.secretKey;
    Object.assign(privateArchetype1, await api.createArchetype(privateArchetype1, user2.token));
    expect(String(privateArchetype1.address).match(/[0-9A-Fa-f]{40}/)).to.exist;
  }).timeout(10000);

  it('Should fail to add privateArchetype1 to privatePackage1 by user1 since user1 did not author the archetype', async () => {
    await assert.isRejected(api.addArchetypeToPackage(privatePackage1.id, privateArchetype1.address, user1.token));
  }).timeout(10000);

  it('Should fail to add privateArchetype1 to publicPackage2 since private archetypes cannot be in public packages', async () => {
    await assert.isRejected(api.addArchetypeToPackage(publicPackage2.id, privateArchetype1.address, user2.token));
  }).timeout(10000);

  it('Should add publicArchetype1 to publicPackage2', async () => {
    // User2 attempts to add publicArchetype1 to publicPackage2 and succeeds
    await assert.isFulfilled(api.addArchetypeToPackage(publicPackage2.id, publicArchetype1.address, user2.token));
  }).timeout(10000);

  it('Should create collection1 from publicPackage2', async () => {
    // CREATE COLLECTION
    collection1.packageId = publicPackage2.id;
    let data = await api.createAgreementCollection(collection1, user1.token);
    expect(data.id).to.exist;
    collection1.id = data.id;
  }).timeout(15000);

  it('Should create agreement1 from publicArchetype1', done => {
    // CREATE AGREEMENT AND START PROCESS
    agreement1.archetype = publicArchetype1.address;
    agreement1.collectionId = collection1.id;
    setTimeout(async () => {
      try {
        let agreementRes = await api.createAgreement(agreement1, user1.token);
        agreement1.address = agreementRes.address;
        expect(String(agreement1.address).match(/[0-9A-Fa-f]{40}/)).to.exist;
        done();
      } catch (err) {
        done(err);
      }
    }, 5000);
  }).timeout(20000);

  it('Should validate agreement1 is in collection1', async () => {
    // VALIDATE COLLECTION
    let res = await api.getAgreementCollection(collection1.id, user1.token);
    expect(res.author).to.equal(user1.address);
    expect(res.agreements.length).to.equal(1);
    expect(res.agreements[0].address).to.equal(agreement1.address);
    expect(res.agreements[0].name).to.equal(agreement1.name);
    expect(res.agreements[0].archetype).to.equal(publicArchetype1.address);
  });

  it('Should create collection2 from publicPackage1', async () => {
    // CREATE COLLECTION
    collection2.packageId = publicPackage1.id;
    let data = await api.createAgreementCollection(collection2, user1.token);
    expect(data.id).to.exist;
    collection2.id = data.id;
  }).timeout(15000);

  it('Should fail to create agreement2 from publicArchetype1 in collection2', async () => {
    // An agreement can only be added to a collection if that collection
    // references a package that contains the archetype of the said agreement
    let agreement2 = Object.assign({}, agreement1);
    agreement2.name = 'cannotbeadded';
    agreement2.collectionId = collection2.id;
    await assert.isRejected(api.createAgreement(agreement2, user1.token));
  }).timeout(15000);

});

describe(':: Governing Archetypes and Agreements ::', () => {
  const model = { id: rid(16, 'aA0'), filePath: 'test/data/AN-TestTemplate-FE.bpmn' };
  const user1 = {
    username: rid(8, 'aA0'),
    password: 'archUser1',
    email: `${rid(8, 'aA0')}@test.com`,
  };
  const employmentArchetype = {
    name: "employmentArchetype",
    description: "employmentArchetype",
    price: 10,
    isPrivate: false,
    active: true,
    governingArchetypes: [],
    parameters: [],
    jurisdictions: [],
    documents: []
  }
  const ndaArchetype = {
    name: "ndaArchetype",
    description: "ndaArchetype",
    price: 10,
    isPrivate: false,
    active: true,
    governingArchetypes: [],
    parameters: [],
    jurisdictions: [],
    documents: []
  }
  let employmentAgreement = {
    name: 'Employment Agreement ' + new Date().getMilliseconds(),
    archetype: '',
    isPrivate: false,
    parties: [],
    parameters: [],
    maxNumberOfEvents: 5,
    governingAgreements: []
  };
  let ndaAgreement = {
    name: 'NDA Agreement ' + new Date().getMilliseconds(),
    archetype: '',
    isPrivate: false,
    parties: [],
    parameters: [],
    maxNumberOfEvents: 5,
    governingAgreements: []
  };
  const process1 = {};
  const process2 = {};
  let xml = api.generateModelXml(model.id, model.filePath);
  expect(xml).to.exist;

  it('Should register user1', async () => {
    // REGISTER USER
    let registerResult1 = await api.registerUser(user1);
    user1.address = registerResult1.address;
    expect(user1.address).to.exist;
  }).timeout(5000);

  it('Should login user1', done => {
    // LOGIN USER
    setTimeout(async () => {
      try {
        let loginResult1 = await api.loginUser(user1);
        expect(loginResult1.token).to.exist;
        user1.token = loginResult1.token;
        done();
      } catch (err) {
        done(err);
      }
    }, 5000);
  }).timeout(10000);

  it('Should deploy model', done => {
    // DEPLOY MODEL
    setTimeout(async () => {
      try {
        let deployResponse = await api.createAndDeployModel(xml, user1.token);
        expect(deployResponse).to.exist;
        Object.assign(model, deployResponse.model);
        Object.assign(process1, deployResponse.processes[0]);
        Object.assign(process2, deployResponse.processes[1]);
        expect(String(process1.address).match(/[0-9A-Fa-f]{40}/)).to.exist;
        expect(String(process2.address).match(/[0-9A-Fa-f]{40}/)).to.exist;
        employmentArchetype.formationProcessDefinition = process1.address;
        employmentArchetype.executionProcessDefinition = process2.address;
        ndaArchetype.formationProcessDefinition = process1.address;
        ndaArchetype.executionProcessDefinition = process2.address;
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(30000);

  it('Should create employment and nda archetypes', async () => {
    let data = await api.createArchetype(employmentArchetype, user1.token);
    employmentArchetype.address = data.address;
    expect(String(employmentArchetype.address).match(/[0-9A-Fa-f]{40}/)).to.exist;
    ndaArchetype.governingArchetypes.push(employmentArchetype.address);
    data = await api.createArchetype(ndaArchetype, user1.token);
    ndaArchetype.address = data.address;
    expect(String(ndaArchetype.address).match(/[0-9A-Fa-f]{40}/)).to.exist;
  }).timeout(10000);

  it('Should fail to create an nda agreement without a governing employment agreement', async () => {
    ndaAgreement.archetype = ndaArchetype.address;
    await assert.isRejected(api.createAgreement(ndaAgreement, user1.token));
  }).timeout(10000);

  it('Should create an nda agreement with a governing employment agreement', async () => {
    employmentAgreement.archetype = employmentArchetype.address;
    let data = await api.createAgreement(employmentAgreement, user1.token);
    employmentAgreement.address = data.address;
    ndaAgreement.governingAgreements.push(employmentAgreement.address);
    data = await api.createAgreement(ndaAgreement, user1.token);
    expect(String(data.address).match(/[0-9A-Fa-f]{40}/)).to.exist;
  }).timeout(10000);
});

describe(':: External Users ::', () => {
  let externalUser1 = {
    email: `${rid(10, 'aA0')}@test.com`,
  };
  let externalUser2 = {
    email: `${rid(10, 'aA0')}@test.com`,
  };
  let registeredUser = {
    username: `registeredUser${rid(5, 'aA0')}`,
    password: 'registeredUser',
    email: `${rid(10, 'aA0')}@test.com`,
  };

  let formation = {
    filePath: 'test/data/inc-formation.bpmn',
    process: {},
    id: rid(16, 'aA0'),
    name: 'Incorporation-Formation'
  }
  let execution = {
    filePath: 'test/data/inc-execution.bpmn',
    process: {},
    id: rid(16, 'aA0'),
    name: 'Incorporation-Execution'
  }

  let archetype = {
    name: 'Incorporation Archetype',
    description: 'Incorporation Archetype',
    price: 10,
    isPrivate: 1,
    active: 1,
    parameters: [
      { type: 8, name: 'External1Uppercase' },
      { type: 6, name: 'External2' },
      { type: 6, name: 'External1Lowercase' },
      { type: 8, name: 'RegisteredNormal' },
      { type: 6, name: 'RegisteredByEmail' },
    ],
    documents: [{
      name: 'doc1.md',
      hoardAddress: '0x0',
      secretKey: '0x0',
    }],
    jurisdictions: [],
    executionProcessDefinition: '',
    formationProcessDefinition: '',
    governingArchetypes: []
  }

  let agreement = {
    name: 'external users agreement',
    archetype: '',
    isPrivate: false,
    parameters: [],
    hoardAddress: '',
    hoardSecret: '',
    eventLogHoardAddress: '',
    eventLogHoardSecret: '',
    maxNumberOfEvents: 0,
    governingAgreements: []
  }

  it('Should register user', async () => {
    // REGISTER USER
    const registerResult = await api.registerUser(registeredUser);
    registeredUser.address = registerResult.address;
    expect(registeredUser.address).to.exist
  }).timeout(5000);

  it('Should login user', (done) => {
    // LOGIN USER
    setTimeout(async () => {
      try {
        const loginResult = await api.loginUser(registeredUser);
        expect(loginResult.token).to.exist;
        registeredUser.token = loginResult.token;
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

  it('Should deploy formation and execution models', async () => {
    // DEPLOY FORMATION MODEL
    let formXml = api.generateModelXml(formation.id, formation.filePath);
    let formationDeploy = await api.createAndDeployModel(formXml, registeredUser.token);
    expect(formationDeploy).to.exist;
    Object.assign(formation, formationDeploy.model);
    Object.assign(formation.process, formationDeploy.processes[0]);
    archetype.formationProcessDefinition = formation.process.address;
    expect(String(archetype.formationProcessDefinition).match(/[0-9A-Fa-f]{40}/)).to.exist;
    // DEPLOY EXECUTION MODEL
    let execXml = api.generateModelXml(execution.id, execution.filePath);
    let executionDeploy = await api.createAndDeployModel(execXml, registeredUser.token);
    expect(executionDeploy).to.exist;
    Object.assign(execution, executionDeploy.model);
    Object.assign(execution.process, executionDeploy.processes[0]);
    archetype.executionProcessDefinition = execution.process.address;
    expect(String(archetype.executionProcessDefinition).match(/[0-9A-Fa-f]{40}/)).to.exist;
    expect(String(archetype.executionProcessDefinition).match(/[0-9A-Fa-f]{40}/)).to.exist;
  }).timeout(30000);

  it('Should create an archetype', done => {
    // CREATE ARCHETYPE
    setTimeout(async () => {
      try {
        archetype.documents[0].hoardAddress = hoardRef.address;
        archetype.documents[0].secretKey = hoardRef.secretKey;
        Object.assign(archetype, await api.createArchetype(archetype, registeredUser.token));
        expect(String(archetype.address)).match(/[0-9A-Fa-f]{40}/).to.exist;
        agreement.archetype = archetype.address;
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

  it('Should create an angreement with emails in the user/org/signatory parameters', done => {
    // CREATE AGREEMENT
    setTimeout(async () => {
      try {
        /**
         * Should be able to use an email address for a user/org/sig agreement parameter
         * Should create a new user and use their address when given an unknown email address
         * Should use the address of the user with the given email when given a known email address
         * Should be able to accept the same email address for multiple parameters without errors
         * Should be able to handle email addresses in different cAsEs
        */
        agreement.parameters.push({ name: 'External1Uppercase', type: 8, value: externalUser1.email.toUpperCase() });
        agreement.parameters.push({ name: 'External2', type: 6, value: externalUser2.email });
        agreement.parameters.push({ name: 'External1Lowercase', type: 6, value: externalUser1.email.toLowerCase() });
        agreement.parameters.push({ name: 'RegisteredNormal', type: 6, value: registeredUser.address });
        agreement.parameters.push({ name: 'RegisteredByEmail', type: 6, value: registeredUser.email.toLowerCase() });
        agreement.hoardAddress = hoardRef.address;
        agreement.hoardSecret = hoardRef.secretKey;
        Object.assign(agreement, await api.createAgreement(agreement, registeredUser.token));
        expect(String(agreement.address)).match(/[0-9A-Fa-f]{40}/).to.exist;
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

  it('Should create new users when an unknown email is given', done => {
    // CHECK USER CREATION
    setTimeout(async () => {
      try {
        const user1 = await contracts.getUserById(externalUser1.email.toLowerCase());
        const user2 = await contracts.getUserById(externalUser2.email.toLowerCase());
        expect(user1).to.be.a('object');
        expect(user2).to.be.a('object');
        expect(/[0-9A-Fa-f]{40}/.test(user1.address)).to.be.true;
        expect(/[0-9A-Fa-f]{40}/.test(user2.address)).to.be.true;
        externalUser1.address = user1.address;
        externalUser2.address = user2.address;
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

  it('Should not create multiple users for the same email address (case insensitive)', done => {
    // CHECK USER CREATION
    setTimeout(async () => {
      try {
        await assert.isRejected(contracts.getUserById(externalUser1.email.toUpperCase()));
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

  let parameters;

  it('Should use the address of the already registered user when a known email address is given', done => {
    // CHECK AGREEMENT PARAMETERS
    setTimeout(async () => {
      try {
       ( { parameters } = await api.getAgreement(agreement.address, registeredUser.token));
        expect(parameters.find(({ name }) => name === 'RegisteredByEmail').value).to.equal(registeredUser.address);
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

  it('Should use the addresses of new users for unknown email addresses', done => {
    // CHECK AGREEMENT PARAMETERS
    setTimeout(async () => {
      try {
        expect(parameters.find(({ name }) => name === 'External1Uppercase').value).to.equal(externalUser1.address);
        expect(parameters.find(({ name }) => name === 'External2').value).to.equal(externalUser2.address);
        expect(parameters.find(({ name }) => name === 'External1Lowercase').value).to.equal(externalUser1.address);
        expect(parameters.find(({ name }) => name === 'External1Uppercase').value).to.equal(externalUser1.address);
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

});

describe(':: Agreement Tagging ::', () => {
  let tags1 = ['super', 'nice'];
  let tags2 = ['okay', 'meh'];
  let orgTags = ['bad', 'terribad'];
  const model = { id: rid(16, 'aA0'), filePath: 'test/data/AN-TestTemplate-FE.bpmn' };
  const user1 = {
    username: rid(8, 'aA0'),
    password: 'archUser1',
    email: `${rid(8, 'aA0')}@test.com`,
  };
  const user2 = {
    username: rid(8, 'aA0'),
    password: 'archUser2',
    email: `${rid(8, 'aA0')}@test.com`,
  };
  const org = {
    name: 'org',
  };
  const employmentArchetype = {
    name: "employmentArchetype",
    description: "employmentArchetype",
    price: 10,
    isPrivate: false,
    active: true,
    governingArchetypes: [],
    parameters: [],
    jurisdictions: [],
    documents: []
  }
  const ndaArchetype = {
    name: "ndaArchetype",
    description: "ndaArchetype",
    price: 10,
    isPrivate: false,
    active: true,
    governingArchetypes: [],
    parameters: [],
    jurisdictions: [],
    documents: []
  }
  let employmentAgreement = {
    name: 'Employment Agreement ' + new Date().getMilliseconds(),
    archetype: '',
    isPrivate: false,
    parties: [],
    parameters: [],
    maxNumberOfEvents: 5,
    governingAgreements: []
  };
  let ndaAgreement = {
    name: 'NDA Agreement ' + new Date().getMilliseconds(),
    archetype: '',
    isPrivate: false,
    parties: [],
    parameters: [],
    maxNumberOfEvents: 5,
    governingAgreements: []
  };
  const process1 = {};
  const process2 = {};
  let xml = api.generateModelXml(model.id, model.filePath);
  expect(xml).to.exist;

  it('Should register users', async () => {
    // REGISTER USERS
    let registerResult1 = await api.registerUser(user1);
    user1.address = registerResult1.address;
    expect(user1.address).to.exist;
  
    let registerResult2 = await api.registerUser(user2);
    user2.address = registerResult2.address;
    expect(user2.address).to.exist;
  }).timeout(5000);

  it('Should login users', (done) => {
    // LOGIN USERS
    setTimeout(async () => {
      try {
    let loginResult1 = await api.loginUser(user1);
    expect(loginResult1.token).to.exist;
    user1.token = loginResult1.token;
  
    let loginResult2 = await api.loginUser(user2);
    expect(loginResult2.token).to.exist;
    user2.token = loginResult2.token;
        done();
      } catch (err) {
        done(err);
      }
    }, 2000);
  }).timeout(5000);

  it('Should create an organization with user1 and user2 as approvers', async () => {
    org.approvers = [user1.address, user2.address];
    const { body } = await api.createOrganization(org, user1.token);
    org.address = body.address;
  }).timeout(3000);

  it('Should deploy model', done => {
    // DEPLOY MODEL
    setTimeout(async () => {
      try {
        let deployResponse = await api.createAndDeployModel(xml, user1.token);
        expect(deployResponse).to.exist;
        Object.assign(model, deployResponse.model);
        Object.assign(process1, deployResponse.processes[0]);
        Object.assign(process2, deployResponse.processes[1]);
        expect(String(process1.address).match(/[0-9A-Fa-f]{40}/)).to.exist;
        expect(String(process2.address).match(/[0-9A-Fa-f]{40}/)).to.exist;
        employmentArchetype.formationProcessDefinition = process1.address;
        employmentArchetype.executionProcessDefinition = process2.address;
        ndaArchetype.formationProcessDefinition = process1.address;
        ndaArchetype.executionProcessDefinition = process2.address;
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(30000);

  it('Should create employment and nda archetypes', async () => {
    let data = await api.createArchetype(employmentArchetype, user1.token);
    employmentArchetype.address = data.address;
    expect(String(employmentArchetype.address).match(/[0-9A-Fa-f]{40}/)).to.exist;
    data = await api.createArchetype(ndaArchetype, user1.token);
    ndaArchetype.address = data.address;
    expect(String(ndaArchetype.address).match(/[0-9A-Fa-f]{40}/)).to.exist;
  }).timeout(10000);

  it('Should create nda and employment agreements', async () => {
    employmentAgreement.archetype = employmentArchetype.address;
    let data = await api.createAgreement(employmentAgreement, user1.token);
    expect(String(data.address).match(/[0-9A-Fa-f]{40}/)).to.exist;
    employmentAgreement.address = data.address;
    ndaAgreement.archetype = employmentArchetype.address;
    data = await api.createAgreement(ndaAgreement, user1.token);
    expect(String(data.address).match(/[0-9A-Fa-f]{40}/)).to.exist;
    ndaAgreement.address = data.address;
  }).timeout(60000);

  it('Should create tags1 for user1 and user2', async () => {
    const data1 = await api.createTags(tags1, null, user1.token);
    expect(data1).to.be.a('array');
    expect(data1.length).to.equal(tags1.length);
    expect(data1[0]).to.be.a('object');
    expect(data1[1]).to.be.a('object');
    expect(data1[0].text).to.equal(tags1[0]);
    expect(data1[1].text).to.equal(tags1[1]);
    tags1 = data1;
    const data2 = await api.createTags(tags2, null, user2.token);
    expect(data2).to.be.a('array');
    expect(data2.length).to.equal(tags2.length);
    expect(data2[0]).to.be.a('object');
    expect(data2[1]).to.be.a('object');
    expect(data2[0].text).to.equal(tags2[0]);
    expect(data2[1].text).to.equal(tags2[1]);
    tags2 = data2;
  }).timeout(3000);

  it('Should allow user1 to apply tags1 to the agreement', (done) => {
    try {
      setTimeout(async () => {
        await api.applyTags(tags1.map(({ id }) => id), employmentAgreement.address, user1.token);
        done();
      }, 2000);
    } catch (err) {
      done(err);
    }
  }).timeout(4000);

  it('Should NOT allow user1 to apply tags2 to the agreement', async () => {
    await assert.isRejected(api.applyTags(tags2.map(({ id }) => id), employmentAgreement.address, user1.token));
  }).timeout(3000);

  it('Should NOT allow user2 to apply tags2 to the agreement', async () => {
    await assert.isRejected(api.applyTags(tags2.map(({ id }) => id), employmentAgreement.address, user2.token));
  }).timeout(3000);

  it('Should allow user1 to remove a tag from the agreement', async () => {
    await api.removeTag(tags1[1].id, employmentAgreement.address, user1.token);
  }).timeout(3000);

  it('Should NOT allow user2 to remove a tag from the agreement', async () => {
    await assert.isRejected(api.removeTag(tags1[0].id, employmentAgreement.address, user2.token));
  }).timeout(3000);

  it('Should create orgTags for org', async () => {
    const data = await api.createTags(orgTags, org.address, user1.token);
    expect(data).to.be.a('array');
    expect(data.length).to.equal(orgTags.length);
    expect(data[0]).to.be.a('object');
    expect(data[1]).to.be.a('object');
    expect(data[0].text).to.equal(orgTags[0]);
    expect(data[1].text).to.equal(orgTags[1]);
    expect(data[0].owner).to.equal(org.address);
    expect(data[1].owner).to.equal(org.address);
    orgTags = data;
  }).timeout(5000);

  it('Should allow user1 to apply orgTags to the agreement', (done) => {
    try {
      setTimeout(async() => {
    await api.applyTags(orgTags.map(({ id }) => id), employmentAgreement.address, user1.token);
        done();
      }, 2000);
    } catch (err) {
      done(err);
    }
  }).timeout(5000);

  it('Should NOT allow user2 to apply orgTags to the agreement', async () => {
    await assert.isRejected(api.applyTags(orgTags.map(({ id }) => id), employmentAgreement.address, user2.token));
  }).timeout(3000);

  it('Should allow user1 to remove an orgTag from the agreement', async () => {
    await api.removeTag(orgTags[1].id, employmentAgreement.address, user1.token);
  }).timeout(3000);

  it('Should include tag details in GET /agreements/:address results', (done) => {
    try {
      setTimeout(async() => {
        const data = await api.getAgreement(employmentAgreement.address, user1.token);
        expect(data.tags).to.be.a('array');
        expect(data.tags.length).to.equal(2);
        expect(data.tags[0].id).to.equal(tags1[0].id);
        expect(data.tags[1].id).to.equal(orgTags[0].id);
        done();
      }, 2000);
    } catch (err) {
      done(err);
    }
  }).timeout(10000);

  it('Should include tag details for each agreement in GET /agreements results', async () => {
    const data = await api.getAgreements(user1.token, '?forCurrentUser=true');
    expect(data).to.be.a('array');
    const empAgr = data.find(({ address }) => address === employmentAgreement.address);
    const ndaAgr = data.find(({ address }) => address === ndaAgreement.address);
    expect(empAgr.tags).to.be.a('array');
    expect(ndaAgr.tags).to.be.a('array');
    expect(empAgr.tags.length).to.be.greaterThan(0);
    expect(ndaAgr.tags.length).to.equal(0);
  }).timeout(5000);

  it('Should allow filtering by tag for GET /agreements results', async () => {
    let data = await api.getAgreements(user1.token, '?forCurrentUser=true');
    expect(data).to.be.a('array');
    expect(data.length).to.equal(2);

    data = await api.getAgreements(user1.token, '?forCurrentUser=true&tags=super');
    expect(data).to.be.a('array');
    expect(data.length).to.equal(1);

    data = await api.getAgreements(user1.token, '?forCurrentUser=true&tags=nice');
    expect(data).to.be.a('array');
    expect(data.length).to.equal(0);
  }).timeout(5000);

  it('Should GET tags of a user', async () => {
    const data = await api.getTags(user1.token);
    expect(data.tags).to.be.a('array');
    expect(data.tags.length).to.equal(4);
    tags1.forEach(({ id }) => {
      // Should include the user's tags
      const tag = data.tags.find((tag) => id === tag.id);
      expect(tag).to.be.a('object');
    });
    tags2.forEach(({ id }) => {
      // Should not include the other users' tags
      const tag = data.tags.find((tag) => id === tag.id);
      expect(tag).to.be.an('undefined');
    });
    orgTags.forEach(({ id }) => {
      // Should include the user's organizations' tags
      const tag = data.tags.find((tag) => id === tag.id);
      expect(tag).to.be.a('object');
    });
  }).timeout(3000);

  it('Should filter results of GET /tags if owners query is supplied', async () => {
    const data = await api.getTags(user1.token, `?owners=${org.address}`);
    expect(data.tags).to.be.a('array');
    expect(data.tags.length).to.equal(2);
    tags1.forEach(({ id }) => {
      // Should not include the user's tags
      const tag = data.tags.find((tag) => id === tag.id);
      expect(tag).to.be.an('undefined');
    });
    tags2.forEach(({ id }) => {
      // Should not include the other users' tags
      const tag = data.tags.find((tag) => id === tag.id);
      expect(tag).to.be.an('undefined');
    });
    orgTags.forEach(({ id }) => {
      // Should include the user's organizations' tags
      const tag = data.tags.find((tag) => id === tag.id);
      expect(tag).to.be.a('object');
    });
  }).timeout(3000);

  it('Should DELETE a tag', async () => {
    await api.deleteTag(tags1[1].id, user1.token);
    const data = await api.getTags(user1.token);
    expect(data.tags).to.be.a('array');
    expect(data.tags.length).to.equal(3);
    const tag1 = data.tags.find(({ id }) => id === tags1[0].id);
    const tag2 = data.tags.find(({ id }) => id === tags1[1].id);
    expect(tag1).to.be.a('object');
    expect(tag2).to.be.an('undefined');
  }).timeout(5000);

  it('Should not allow other user to DELETE tag', async () => {
    await assert.isRejected(api.deleteTag(tags1[0].id, user2.token));
  }).timeout(5000);

  it('Should cascade delete for taggings', async () => {
    await api.deleteTag(orgTags[0].id, user1.token);
    const data = await api.getAgreements(user1.token, '?forCurrentUser=true');
    const empAgr = data.find(({ address }) => address === employmentAgreement.address);
    expect(empAgr.tags.length).to.equal(1);
    const deletedTag = empAgr.tags.find(({ id }) => id === orgTags[0].id);
    expect(deletedTag).to.be.an('undefined');
  }).timeout(5000);

  it('Should UPDATE a tag', async () => {
    const newText = 'supersuper';
    await api.updateTag(tags1[0].id, { text: newText }, user1.token);
    const data = await api.getTags(user1.token);
    expect(data.tags).to.be.a('array');
    expect(data.tags.length).to.equal(2);
    const tag = data.tags.find(({ id }) => id === tags1[0].id);
    expect(tag.text).to.equal(newText);
  }).timeout(5000);

  it('Should not allow other user to UPDATE tag', async () => {
    await assert.isRejected(api.updateTag(tags1[0].id, { text: 'should fail' }, user2.token));
  }).timeout(5000);

});
