const chai = require('chai');
const chaiHttp = require('chai-http');
const chaiAsPromised = require('chai-as-promised');
const request = require('supertest');
const rid = require('random-id');
const path = require('path');
const fs = require('fs');
const _ = require('lodash');
const crypto = require('crypto');

const app = require('../../app')();
const server = require(__common + '/aa-web-api')();
const logger = require(__common + '/monax-logger');
const log = logger.getLogger('agreements.tests');
const { appPool, chainPool } = require(__common + '/postgres-db');
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

/**
 * ######## HOARD ###############################################################################################################
 */
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
        await api.activateUser(hoardUser);
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


/**
 * ######## Incorporation use case ###############################################################################################################
 */
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
        await api.activateUser(signer);
        let loginResult = await api.loginUser(signer);
        expect(loginResult.token).to.exist;
        signer.token = loginResult.token;
        await api.activateUser(receiver);
        loginResult = await api.loginUser(receiver);
        expect(loginResult.token).to.exist;
        receiver.token = loginResult.token;
        await api.activateUser(confirmer);
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
    let formCacheReponse = await appPool.query({
      text: 'SELECT process_name FROM PROCESS_DETAILS WHERE model_id = $1 AND process_id = $2',
      values: [formation.id, formation.process.processDefinitionId]
    });
    expect(formCacheReponse.rows[0].process_name).to.equal(formation.process.processName);
    let execCacheReponse = await appPool.query({
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


/**
 * ######## Sale of Goods use case ###############################################################################################################
 */
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
      await api.activateUser(user1);
      let loginResult = await api.loginUser(user1);
      expect(loginResult.token).to.exist;
      user1.token = loginResult.token;
      await api.activateUser(user2);
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


/**
 * ######## Data Mapping Test ###############################################################################################################
 */
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
        await api.activateUser(manager);
        let loginResult = await api.loginUser(manager);
        expect(loginResult.token).to.exist;
        manager.token = loginResult.token;
        await api.activateUser(admin);
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
          [{ id: 'writeApproved', value: true }],
          manager.token
        ));
        let data = await assert.isFulfilled(api.getActivityDataValues(managerTasks[0].activityInstanceId, manager.token));
        expect(data.length).to.equal(1);
        let approved = data.filter(d => d.accessPointId === 'readApproved')[0].value;
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
      expect(aiData.data.in.length).to.equal(1);
      expect(aiData.data.out.length).to.equal(1);
      let readApproved = aiData.data.in.filter(d => d.dataMappingId === 'readApproved')[0];
      let writeApproved = aiData.data.out.filter(d => d.dataMappingId === 'writeApproved')[0];
      expect(readApproved.value).to.equal(true);
      expect(writeApproved.dataPath).to.equal('approved');
    } catch (err) {
      throw err;
    }
  }).timeout(10000);

  it('Should be able to set single data and complete suspended task in one transaction', done => {
    setTimeout(async () => {
      let data = [
        { id: 'writeApproved', value: true } //IMPORTANT: test completing an activity with only one data in order to trigger the completeActivityWithData single transaction path in the API!
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
        let readApproved = aiData.data.in.filter(d => d.dataMappingId === 'readApproved')[0];
        expect(readApproved.value).to.equal(true);
        done();
      } catch (err) {
        done(err);
      }
    }, 5000);
  }).timeout(10000);

});

/**
 * ######## Gateway Test ###############################################################################################################
 * Deploys a model with a conditional task based on a uint condition and XOR gateway.
 * Verifies that the gateway is working properly by running two processes, one for each path.
 */
describe(':: GATEWAY TEST ::', () => {
  let tenant = {
    username: `tenant${rid(5, 'aA0')}`,
    password: 'tenant',
    email: `tenant${rid(3, 'aA0')}@test.com`,
  };

  let formation = {
    filePath: 'test/data/Formation-Tenant-XOR-Gateway.bpmn',
    process: {},
    id: rid(16, 'aA0'),
    name: 'Formation-Tenant-XOR-Gateway'
  }
  let execution = {
    filePath: 'test/data/Execution-NoAction.bpmn',
    process: {},
    id: rid(16, 'aA0'),
    name: 'Execution-NoAction'
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
    name: 'Rental Archetype',
    description: 'Rental Archetype',
    price: 10,
    isPrivate: 0,
    active: true,
    parameters: [
      { type: 8, name: 'Tenant' },
      { type: 2, name: 'Building Completed' },
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
    name: 'Rental Agreement 1',
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

  let tenantTask;

  it('Should register users', async () => {
    // REGISTER USERS
    let registerResult = await api.registerUser(tenant);
    tenant.address = registerResult.address;
    expect(tenant.address).to.exist
  }).timeout(3000);

  it('Should login users', (done) => {
    // LOGIN USERS
    setTimeout(async () => {
      try {
        await api.activateUser(tenant);
        let loginResult = await api.loginUser(tenant);
        expect(loginResult.token).to.exist;
        tenant.token = loginResult.token;
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

  it('Should deploy formation and execution models', async () => {
    // DEPLOY FORMATION MODEL
    let formXml = api.generateModelXml(formation.id, formation.filePath);
    let formationDeploy = await api.createAndDeployModel(formXml, tenant.token);
    expect(formationDeploy).to.exist;
    Object.assign(formation, formationDeploy.model);
    Object.assign(formation.process, formationDeploy.processes[0]);
    archetype.formationProcessDefinition = formation.process.address;
    expect(String(archetype.formationProcessDefinition).match(/[0-9A-Fa-f]{40}/)).to.exist;
    // DEPLOY EXECUTION MODEL
    let execXml = api.generateModelXml(execution.id, execution.filePath);
    let executionDeploy = await api.createAndDeployModel(execXml, tenant.token);
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
        Object.assign(archetype, await api.createArchetype(archetype, tenant.token));
        expect(String(archetype.address)).match(/[0-9A-Fa-f]{40}/).to.exist;
        agreement.archetype = archetype.address;
        done();
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(10000);

  it('Should create an agreement and start formation process leading to user task', done => {
    // CREATE AGREEMENT
    setTimeout(async () => {
      try {
        let tenantTasks = await api.getTasksForUser(tenant.token);
        const numberOfTasksBefore = tenantTasks.length;
        agreement.parameters.length = 0; // reset parameters
        agreement.parameters.push({ name: 'Tenant', type: 8, value: tenant.address });
        agreement.parameters.push({ name: 'Building Completed', type: 2, value: 1950 });
        agreement.hoardAddress = hoardRef.address;
        agreement.hoardSecret = hoardRef.secretKey;
        Object.assign(agreement, await api.createAgreement(agreement, tenant.token));
        expect(String(agreement.address)).match(/[0-9A-Fa-f]{40}/).to.exist;
        setTimeout(async () => {
          tenantTasks = await api.getTasksForUser(tenant.token);
          expect(tenantTasks.length).to.equal(numberOfTasksBefore + 1);
          done();  
        }, 5000);
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(20000);

  it('Should create an agreement and start formation process with staight-through processing (no user task)', done => {
    // CREATE AGREEMENT
    setTimeout(async () => {
      try {
        let tenantTasks = await api.getTasksForUser(tenant.token);
        const numberOfTasksBefore = tenantTasks.length;
        agreement.parameters.length = 0; // reset parameters
        agreement.parameters.push({ name: 'Tenant', type: 8, value: tenant.address });
        agreement.parameters.push({ name: 'Building Completed', type: 2, value: 2007 });
        agreement.hoardAddress = hoardRef.address;
        agreement.hoardSecret = hoardRef.secretKey;
        Object.assign(agreement, await api.createAgreement(agreement, tenant.token));
        expect(String(agreement.address)).match(/[0-9A-Fa-f]{40}/).to.exist;
        setTimeout(async () => {
          tenantTasks = await api.getTasksForUser(tenant.token);
          expect(tenantTasks.length).to.equal(numberOfTasksBefore);
          done();  
        }, 5000);
      } catch (err) {
        done(err);
      }
    }, 3000);
  }).timeout(20000);

});
