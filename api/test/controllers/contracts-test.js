const events = require('events')
const toml = require('toml')
const fs = require('fs')
const util = require('util')
const path = require('path')
const rid = require('random-id')
const async = require('async')
const chai = require('chai')
const chaiAsPromised = require('chai-as-promised')
chai.use(chaiAsPromised)
const should = chai.should()
const expect = chai.expect
const assert = chai.assert
const monax = require('@monax/burrow')

global.__appDir = path.resolve()
global.__common = path.resolve(__appDir, 'common')
global.__config = path.resolve(__appDir, 'config')
global.__contracts = path.resolve(__appDir, 'contracts')
global.__abi = path.resolve(__appDir, 'public-abi')
global.__sqlsol = path.resolve(__appDir, 'sqlsol')
global.__routes = path.resolve(__appDir, 'routes')
global.__controllers = path.resolve(__appDir, 'controllers')
global.__data = path.resolve(__appDir, 'data')
global.__lib = path.resolve(__appDir, 'lib')

const logger = require(__common + '/monax-logger')
const eventEmitter = new events.EventEmitter()
const eventsConsts = { STARTED: 'started' }
const log = logger.getLogger('Test.Harness')

const configFilePath = process.env.MONAX_CONFIG || __config + '/settings.toml'
global.__settings = (() => {
  let settings = toml.parse(fs.readFileSync(configFilePath))
  if (process.env.MONAX_DOUG) _.set(settings, 'monax.DOUG', process.env.MONAX_DOUG)
  if (process.env.MONAX_HOARD) _.set(settings, 'monax.hoard', process.env.MONAX_HOARD)
  if (process.env.MONAX_ANALYTICS_ID) _.set(settings, 'monax.analyticsID', process.env.MONAX_ANALYTICS_ID)
  if (process.env.MONAX_CHAIN_HOST) _.set(settings, 'monax.chain.host', process.env.MONAX_CHAIN_HOST)
  if (process.env.MONAX_CHAIN_PORT) _.set(settings, 'monax.chain.port', process.env.MONAX_CHAIN_PORT)
  if (process.env.MONAX_ACCOUNTS_SERVER_KEY) _.set(settings, 'monax.accounts.server', process.env.MONAX_ACCOUNTS_SERVER_KEY)
  if (process.env.MONAX_CONTRACTS_LOAD) _.set(settings, 'monax.contracts.load', process.env.MONAX_CONTRACTS_LOAD)
  if (process.env.MONAX_BUNDLES_PATH) _.set(settings, 'monax.bundles.bundles_path', process.env.MONAX_BUNDLES_PATH)
  return settings
})()

global.global.hexToString = (hex) => { return monax.utils.hexToAscii(hex || '') }
global.global.stringToHex = (str) => { return monax.utils.asciiToHex(str || '') }

global.__monax_bundles = require(path.join(__common, 'monax-constants')).MONAX_BUNDLES
global.__monax_constants = require(path.join(__common, 'monax-constants'));
const sqlCache = require(path.join(__controllers, 'sqlsol-query-helper'))
const contracts = require(path.join(__controllers, 'contracts-controller'))

before(function (done) {
  this.timeout(99999999)
  contracts.load().then(() => {
    log.info('Contracts loaded.')
    return contracts.initCache()
  }).then(() => {
    log.info('SQL Cache initiated.')
    log.info('Application started. Running Contracts Test Suite ...')
    done()
  }).catch(error => {
    log.error('Unexpected error initializing the test harness: ' + error.message)
    done(error)
  })
})

// beforeEach((done) => { sleep.msleep(3000); done(); });

describe('CONTRACTS', () => {
  let pmAddress, pdFormAddress, pdExecAddress, packageId, archAddress, agrAddress, piAddress, aiId
  let formationInterface = 'Agreement Formation'
  let executionInterface = 'Agreement Execution'
  const model = { id: rid(16, 'aA0'), name: 'Model With User Task', version: [1, 0, 0]}
  const formationProcess = { id: 'testProcessDefn1', name: 'Formation Process' }
  const executionProcess = { id: 'testProcessDefn2', name: 'Execution Process' }
  const pAccount = {
    id: 'participantAcct',
    address: ''
  }
  const pConditional = {
    id: 'participantCond',
    dataPath: 'AGREEMENT_PARTIES',
    dataStorageId: 'agreement'
  }
  const userTask1 = {
    id: 'userActivity1',
    activityType: 0,
    taskType: 1,
    behavior: 1,
    assignee: 'participantAcct',
    multiInstance: false,
    application: 'AgreementSignatureCheck',
    completionFunction: '',
    subProcessModelId: '',
    subProcessDefinitionId: ''
  }
  const userTask2 = {
    id: 'userActivity2',
    activityType: 0,
    taskType: 1,
    behavior: 1,
    assignee: 'participantCond',
    multiInstance: false,
    application: '',
    subProcessModelId: '',
    subProcessDefinitionId: ''
  }
  const dummyTask1 = {
    id: 'dummyTask1',
    activityType: 0,
    taskType: 0,
    behavior: 0,
    assignee: '',
    multiInstance: false,
    application: '',
    subProcessModelId: '',
    subProcessDefinitionId: ''
  }
  const dummyTask2 = {
    id: 'dummyTask2',
    activityType: 0,
    taskType: 0,
    behavior: 0,
    assignee: '',
    multiInstance: false,
    application: '',
    subProcessModelId: '',
    subProcessDefinitionId: ''
  }
  const dataMapping = {
    activityId: 'userActivity1',
    direction: 0,
    accessPath: 'agreement',
    dataPath: 'agreement',
    dataStorageId: '',
    dataStorage: 0x0
  }
  const arch = {
    name: 'TestType1',
    description: 'Test1',
    price: 10,
    isPrivate: false,
    active: true,
    governingArchetypes: []
  }

  const agreement = {
    name: 'Agreement 1',
    isPrivate: false,
    values: [],
    hoardAddress: 'hoardAddress',
    hoardSecret: 'hoardSecret',
    eventLogHoardAddress: 0x0,
    eventLogHoardSecret: 0x0,
    maxNumberOfEvents: 5,
    governingAgreements: []
  }

  it('Should create a user', async () => {
    let user = { id: rid(16, 'aA0') }
    let res = await contracts.createUser(user)
    res.should.match(/[0-9A-Fa-f]{40}/) // match for 20 byte hex
    pAccount.address = res
    arch.author = pAccount.address
    agreement.creator = pAccount.address
    agreement.parties = [pAccount.address]
  }).timeout(10000)

  it('Should create a process model', async () => {
    let res = await contracts.createProcessModel(model.id, model.name, model.version, arch.author, false, 'hoardAddress', 'hoardSecret')
    res.should.match(/[0-9A-Fa-f]{40}/) // match for 20 byte hex
    pmAddress = res
  }).timeout(10000)

  // it('Should add process interface implementations', async () => {
  //   await contracts.addProcessInterface(pmAddress, formationInterface);
  //   await contracts.addProcessInterface(pmAddress, executionInterface);
  // }).timeout(10000);

  it('Should create a formation process definition', async () => {
    let res = await contracts.createProcessDefinition(pmAddress, formationProcess.id, formationProcess.name)
    res.should.match(/[0-9A-Fa-f]{40}/) // match for 20 byte hex
    pdFormAddress = res
    arch.formationProcessDefinition = pdFormAddress
  }).timeout(10000)

  it('Should create a execution process definition', async () => {
    let res = await contracts.createProcessDefinition(pmAddress, executionProcess.id, executionProcess.name)
    res.should.match(/[0-9A-Fa-f]{40}/) // match for 20 byte hex
    pdExecAddress = res
    arch.executionProcessDefinition = pdExecAddress
  }).timeout(10000)

  // it('Should add formation process interface implmentation', () => {
  //   return assert.isFulfilled(contracts.addProcessInterfaceImplementation(pmAddress, pdFormAddress, formationInterface));
  // }).timeout(10000);

  // it('Should add execution process interface implmentation', () => {
  //   return assert.isFulfilled(contracts.addProcessInterfaceImplementation(pmAddress, pdExecAddress, executionInterface));
  // }).timeout(10000);

  it('Should add a participant with account address', async () => {
    await assert.isFulfilled(contracts.addParticipant(pmAddress, pAccount.id, pAccount.address))
  }).timeout(10000)

  // it('Should add a conditional performer', () => {
  //   return assert.isFulfilled(contracts.addParticipant(
  //         pmAddress,
  //         pConditional.id,
  //         "",
  //         pConditional.dataPath,
  //         pConditional.dataStorageId,
  //         ""
  //   ));
  // }).timeout(10000);

  // it('Should create first activity definition', () => {
  //   return assert.isFulfilled(contracts.createActivityDefinition(
  //         pdAddress,
  //         userTask1.id,
  //         userTask1.activityType,
  //         userTask1.taskType,
  //         userTask1.behavior,
  //         userTask1.assignee,
  //         userTask1.multiInstance,
  //         userTask1.application,
  //         userTask1.subProcessModelId,
  //         userTask1.subProcessDefinitionId
  //   ));
  // }).timeout(10000);

  // it('Should create second activity definition', () => {
  //   return assert.isFulfilled(contracts.createActivityDefinition(
  //         pdAddress,
  //         userTask2.id,
  //         userTask2.activityType,
  //         userTask2.taskType,
  //         userTask2.behavior,
  //         userTask2.assignee,
  //         userTask2.multiInstance,
  //         userTask2.application,
  //         userTask2.subProcessModelId,
  //         userTask2.subProcessDefinitionId
  //   ));
  // }).timeout(10000);

  it('Should create first activity definition', async () => {
    await assert.isFulfilled(contracts.createActivityDefinition(
      pdFormAddress,
      dummyTask1.id,
      dummyTask1.activityType,
      dummyTask1.taskType,
      dummyTask1.behavior,
      dummyTask1.assignee,
      dummyTask1.multiInstance,
      dummyTask1.application,
      dummyTask1.subProcessModelId,
      dummyTask1.subProcessDefinitionId
    ))
  }).timeout(10000)

  it('Should create second activity definition', async () => {
    await assert.isFulfilled(contracts.createActivityDefinition(
      pdExecAddress,
      dummyTask2.id,
      dummyTask2.activityType,
      dummyTask2.taskType,
      dummyTask2.behavior,
      dummyTask2.assignee,
      dummyTask2.multiInstance,
      dummyTask2.application,
      dummyTask2.subProcessModelId,
      dummyTask2.subProcessDefinitionId
    ))
  }).timeout(10000)

  // it('Should create data mapping', () => {
  //   return assert.isFulfilled(
  //     contracts.createDataMapping(pdAddress, dataMapping.activityId,
  //       dataMapping.direction, dataMapping.accessPath, dataMapping.dataPath,
  //       dataMapping.dataStorageId, dataMapping.dataStorage));
  // }).timeout(10000);

  // it('Should create a transition', () => {
  //   return assert.isFulfilled(
  //     contracts.createTransition(pdAddress, userTask1.id, userTask2.id));
  // }).timeout(10000);

  it('Should validate formation process', async () => {
    await expect(contracts.isValidProcess(pdFormAddress)).to.eventually.equal(true)
  }).timeout(10000)

  it('Should validate execution process', async () => {
    await expect(contracts.isValidProcess(pdExecAddress)).to.eventually.equal(true)
  }).timeout(10000)

  it('Should get formation start activity', async () => {
    await expect(contracts.getStartActivity(pdFormAddress)).to.eventually.equal('dummyTask1')
  }).timeout(10000)

  it('Should get execution start activity', async () => {
    await expect(contracts.getStartActivity(pdExecAddress)).to.eventually.equal('dummyTask2')
  }).timeout(10000)

  it('Should fail to create archetype with fake package id', async () => {
    arch.packageId = 'abc123'
    await assert.isRejected(contracts.createArchetype(arch))
  }).timeout(10000)

  it('Should create a package', async () => {
    arch.packageId = await contracts.createArchetypePackage(
      'sale of goods package', 'a package with archetypes for sale of goods', arch.author, false)
    expect(arch.packageId).to.exist
  }).timeout(10000)

  it('Should create an archetype', async () => {
    let res = await contracts.createArchetype(arch)
    res.should.match(/[0-9A-Fa-f]{40}/)
    archAddress = res
    agreement.archetype = archAddress
  }).timeout(10000)

  it('Should validate archetype belongs to package', done => {
    setTimeout(async () => {
      try {
        let res = await sqlCache.getArchetypesInPackage(arch.packageId)
        expect(res.length).to.equal(1)
        expect(global.hexToString(res[0].name)).to.equal(arch.name)
        expect(res[0].address).to.equal(archAddress)
        done()
      } catch (err) {
        done(err)
      }
    }, 3000)
  }).timeout(10000)

  it('Should get the process model from cache', done => {
    contracts.cache.db.all('select * from process_models', (err, data) => {
      expect(data.length).to.be.greaterThan(0)
      let model = data.filter(item => {
        return item.modelAddress === pmAddress
      })[0]
      expect(model).to.exist
      done()
    })
  }).timeout(10000)

  // it('Should get the process definition from cache', done => {
  //   setTimeout(() => {
  //     contracts.cache.db.all('select * from process_definitions', (err, data) => {
  //       expect(data.length).to.be.greaterThan(0);
  //       let formProc = data.filter(item => {
  //         return item.modelAddress === pmAddress &&
  //           item.processDefinitionAddress === pdFormAddress;
  //       })[0];
  //       let execProc = data.filter(item => {
  //         return item.modelAddress === pmAddress &&
  //           item.processDefinitionAddress === pdExecAddress;
  //       })[0];
  //       expect(formProc).to.exist;
  //       expect(execProc).to.exist;
  //       expect(global.hexToString(formProc.interfaceId)).to.equal(formationInterface);
  //       expect(global.hexToString(execProc.interfaceId)).to.equal(executionInterface);
  //       done();
  //     });
  //   }, 3000);
  // }).timeout(10000);

  it('Should create an agreement', async () => {
    let res = await contracts.createAgreement(agreement)
    res.should.match(/[0-9A-Fa-f]{40}/)
    agrAddress = res
  }).timeout(10000)

  // it('Should get agreement name', async () => {
  //   let name = await contracts.getDataFromAgreement(agrAddress);
  //   expect(name).to.equal(agreement.name);
  // }).timeout(10000);

  it('Should create a process instance from agreement', async () => {
    let res = await contracts.startProcessFromAgreement(agrAddress)
    res.should.match(/[0-9A-Fa-f]{40}/)
    piAddress = res
  }).timeout(10000)

  it('Should update the event log hoard reference of an agreement', async () => {
    await assert.isFulfilled(contracts.updateAgreementEventLog(agrAddress, { address: 'dummyaddress', secretKey: 'dummykey' }))
  }).timeout(10000)

  // it('Should get activity definitions from cache', done => {
  //   contracts.cache.db.all(`select * from activity_definitions where processDefinitionAddress = '${pdAddress}'`, (err, data) => {
  //     expect(data.length).to.equal(2);
  //     let activity1 = data.filter(item => {
  //       return global.hexToString(item.activityDefinitionId) === userTask1.id &&
  //         global.hexToString(item.application) === userTask1.application;
  //     })[0];
  //     let activity2 = data.filter(item => {
  //       return global.hexToString(item.activityDefinitionId) === userTask2.id;
  //     })[0];
  //     expect(activity1).to.exist;
  //     expect(activity2).to.exist;
  //     done();
  //   });
  // }).timeout(10000);

  // it('Should get the process instance from cache', done => {
  //   sleep.msleep(10000);
  //   contracts.cache.db.all(`select * from process_instances where processDefinition = '${pdAddress}'`, (err, data) => {
  //     expect(data.length).to.equal(1);
  //     expect(data[0].processAddress).to.equal(piAddress);
  //     done();
  //   })
  // }).timeout(10000);

  // it('Should get activity instances from cache', done => {
  //   contracts.cache.db.all(`select * from activity_instances where processAddress = '${piAddress}'`, (err, data) => {
  //     expect(data.length).to.equal(1);
  //     expect(global.hexToString(data[0].activityId)).to.equal(userTask1.id);
  //     expect(data[0].performer).to.equal(pAccount.address);
  //     expect(data[0].state).to.equal(4);
  //     aiId = data[0].activityInstanceId;
  //     done();
  //   });
  // }).timeout(10000);

  // TODO - Fails, needs some digging
  // it('Should complete activity by user', async () => {
  //   return assert.isFulfilled(contracts.completeActivityByUser(pAccount.address, aiId));
  // }).timeout(10000);

  it('Should cancel an agreement', async () => {
    await assert.isFulfilled(contracts.cancelAgreement(pAccount.address, agrAddress))
  }).timeout(10000)
})
