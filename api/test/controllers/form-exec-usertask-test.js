require('../constants');
const toml = require('toml')
const fs = require('fs')
const path = require('path')
const rid = require('random-id')
const chai = require('chai')
const chaiAsPromised = require('chai-as-promised')
chai.use(chaiAsPromised)
const should = chai.should()
const expect = chai.expect
const assert = chai.assert
const _ = require('lodash')
const burrow = require('@hyperledger/burrow')
const crypto = require('crypto');

global.__appDir = path.resolve()
global.__common = path.resolve(__appDir, 'common')
global.__config = path.resolve(__appDir, 'config')
global.__contracts = path.resolve(__appDir, 'contracts')
global.__abi = path.resolve(__appDir, 'public-abi')
global.__routes = path.resolve(__appDir, 'routes')
global.__controllers = path.resolve(__appDir, 'controllers')
global.__data = path.resolve(__appDir, 'data')
global.__lib = path.resolve(__appDir, 'lib')
global.__schemas = path.resolve(__appDir, 'schemas')

const logger = require(__common + '/logger')
const log = logger.getLogger('tests.Harness')

global.__settings = (() => {
  let settings = toml.parse(fs.readFileSync(`${global.__config}/settings.toml`))
  if (process.env.HOARD) _.set(settings, 'hoard', process.env.HOARD)
  if (process.env.ANALYTICS_ID) _.set(settings, 'analyticsID', process.env.ANALYTICS_ID)
  if (process.env.CHAIN_URL_GRPC) _.set(settings, 'chain.url', process.env.CHAIN_URL_GRPC);
  if (process.env.ACCOUNTS_SERVER) _.set(settings, 'accounts.server', process.env.ACCOUNTS_SERVER)
  return settings
})()

global.__constants = require(path.join(__common, 'constants'));
global.__bundles = require(path.join(__common, 'constants')).BUNDLES
const { hexToString, stringToHex } = require(`${global.__common}/controller-dependencies`);
global.hexToString = hexToString;
global.stringToHex = stringToHex;

const contracts = require(path.join(__controllers, 'contracts-controller'))
const agreementsController = require(path.join(__controllers, 'agreements-controller'))
const bpm = require(path.join(__controllers, 'bpm-controller'))
const createModel = require('./model-creation-helper').createModel
const sqlCache = require(path.join(__controllers, 'postgres-query-helper'))

before(function (done) {
  this.timeout(99999999)
  contracts.load().then(() => {
    log.info('Contracts loaded.')
    log.info('Application started. Running Contracts Test Suite ...')
    done()
  }).catch(error => {
    log.error('Unexpected error initializing the test harness: ' + error.message)
    done(error)
  })
})

describe('FORMATION - EXECUTION with 1 User Task each', () => {
  let piAddress, aiId;
  let model = { id: rid(5, 'aA0'), name: 'Model With User Task', version: [1, 0, 0] }
  const INTERFACE_FORMATION = 'Agreement Formation'
  const INTERFACE_EXECUTION = 'Agreement Execution'
  let buyer = {
    username: `buyer${rid(5, 'aA0')}`,
    address: ''
  }
  let seller = {
    username: `seller${rid(5, 'aA0')}`,
    address: ''
  }
  let buyProcess = {
    model: '',
    id: 'buy',
    name: 'Buy'
  }
  let sellProcess = {
    model: '',
    id: 'sell',
    name: 'Sell'
  }

  /**
      { type: 0, name: 'bool' },
      { type: 1, name: 'string' },
      { type: 2, name: 'num' },
      { type: 3, name: 'date' },
      { type: 4, name: 'date' },
      { type: 5, name: 'money' },
      { type: 6, name: 'user' },
      { type: 7, name: 'addr' },
      { type: 8, name: 'signatory' },
   */
  let archetype = {
    name: 'SOG archetype',
    description: 'SOG archetype',
    isPrivate: 1,
    active: true,
    parameters: [
      { type: 8, name: 'Buyer' },
      { type: 6, name: 'Seller' }
    ],
    executionProcessDefinition: '',
    formationProcessDefinition: ''
  }

  let buyTask = {
    activityId: 'buy',
    activityType: 0,
    taskType: 1,
    behavior: 1,
    assignee: buyer.username,
    multiInstance: false
  }

  let sellTask = {
    activityId: 'sell',
    activityType: 0,
    taskType: 1,
    behavior: 1,
    assignee: seller.username,
    multiInstance: false
  }
  let agreement = {
    name: 'user tasks agreement',
    archetype: '',
    isPrivate: false,
    parameters: [{
      name: 'Buyer',
      type: 8,
      value: ''
    }, {
      name: 'Seller',
      type: 6,
      value: ''
    }
    ],
    maxNumberOfAttachments: 0
  }

  it('Should create a buyer and a seller', async () => {
    let resBuyer = await contracts.createUser({ username: crypto.createHash('sha256').update(buyer.username).digest('hex') });
    let resSeller = await contracts.createUser({ username: crypto.createHash('sha256').update(seller.username).digest('hex') });
    resBuyer.should.match(/[0-9A-Fa-f]{40}/) // match for 20 byte hex
    resSeller.should.match(/[0-9A-Fa-f]{40}/) // match for 20 byte hex
    buyer.address = resBuyer
    seller.address = resSeller
    archetype.author = buyer.address
    agreement.creator = buyer.address
    agreement.parameters[0].value = buyer.address
    agreement.parameters[1].value = seller.address
  }).timeout(10000)

  /******************************
   *  DEPLOY MODEL AND PROCESSES
   ******************************/

  it('Should create a process model', async () => {
    model.address = await contracts.createProcessModel(model.id, model.version, buyer.address, false, '', '')
    expect(model.address).to.match(/[0-9A-Fa-f]{40}/)
  }).timeout(10000)

  it('Should add process model interfaces', async () => {
    await assert.isFulfilled(contracts.addProcessInterface(model.address, INTERFACE_FORMATION))
    await assert.isFulfilled(contracts.addProcessInterface(model.address, INTERFACE_EXECUTION))
  }).timeout(10000)

  it('Should add participants', async () => {
    await assert.isFulfilled(contracts.addParticipant(model.address, buyer.username, '', 'Buyer', 'agreement'))
    await assert.isFulfilled(contracts.addParticipant(model.address, seller.username, '', 'Seller', 'agreement'))
  }).timeout(10000)

  it('Should add formation process', async () => {
    buyProcess.address = await contracts.createProcessDefinition(model.address, buyProcess.id, buyProcess.name)
    expect(buyProcess.address).to.match(/[0-9A-Fa-f]{40}/)
  }).timeout(10000)

  it('Should add execution process', async () => {
    sellProcess.address = await contracts.createProcessDefinition(model.address, sellProcess.id, sellProcess.name)
    expect(sellProcess.address).to.match(/[0-9A-Fa-f]{40}/)
  }).timeout(10000)

  it('Should add process interface implementations', async () => {
    await assert.isFulfilled(contracts.addProcessInterfaceImplementation(model.address, buyProcess.address, INTERFACE_FORMATION))
    await assert.isFulfilled(contracts.addProcessInterfaceImplementation(model.address, sellProcess.address, INTERFACE_EXECUTION))
  }).timeout(10000)

  it('Should add buy task to Agreement Formation', async () => {
    await assert.isFulfilled(contracts.createActivityDefinition(
      buyProcess.address, buyTask.activityId, buyTask.activityType,
      buyTask.taskType, buyTask.behavior, buyTask.assignee, buyTask.multiInstance, '', '', ''))
  }).timeout(10000)

  it('Should add sell task to Agreement Execution', async () => {
    await assert.isFulfilled(contracts.createActivityDefinition(
      sellProcess.address, sellTask.activityId, sellTask.activityType,
      sellTask.taskType, sellTask.behavior, sellTask.assignee, sellTask.multiInstance, '', '', ''))
  }).timeout(10000)

  it('Should validate formation process', async () => {
    let processIsValid = await contracts.isValidProcess(buyProcess.address)
    expect(processIsValid).to.be.true
  }).timeout(10000)

  it('Should validate execution process', async () => {
    let processIsValid = await contracts.isValidProcess(sellProcess.address)
    expect(processIsValid).to.be.true
  }).timeout(10000)

  /**********************************
   *  CREATE ARCHETYPE AND AGREEMENT
   **********************************/

  it('Should create an archetype', async () => {
    archetype.address = await contracts.createArchetype({
      name: archetype.name,
      description: archetype.description,
      price: 10,
      author: buyer.address,
      isPrivate: true,
      active: archetype.active,
      formationProcessDefinition: buyProcess.address,
      executionProcessDefinition: sellProcess.address,
      governingArchetypes: []
    })
    expect(archetype.address).to.match(/[0-9A-Fa-f]{40}/)
    agreement.archetype = archetype.address
    await contracts.addArchetypeParameters(archetype.address, archetype.parameters)
  }).timeout(10000)

  it('Should create an agreement', async () => {
    agreement.address = await contracts.createAgreement({
      archetype: agreement.archetype,
      name: agreement.name,
      creator: agreement.creator,
      maxNumberOfAttachments: 0,
      isPrivate: agreement.isPrivate,
      parties: [buyer.address],
      governingAgreements: []
    })
    expect(agreement.address).to.match(/[0-9A-Fa-f]{40}/)
  }).timeout(10000)

  it('Should set agreement parameters', done => {
    setTimeout(async () => {
      await agreementsController.setAgreementParameters(
        agreement.address, agreement.archetype, agreement.parameters)
      done()
    }, 1000)
  }).timeout(10000)

  it('Should validate agreement parameters', async () => {
    const params = await agreementsController.getAgreementParameters(agreement.address);
    let buyerExists = false, sellerExists = false;
    params.forEach(param => {
      if (param.name === 'Buyer' && param.value.match(/[0-9A-Fa-f]{40}/)) buyerExists = true;
      if (param.name === 'Seller' && param.value.match(/[0-9A-Fa-f]{40}/)) sellerExists = true;
    });
    expect(buyerExists).to.be.true;
    expect(sellerExists).to.be.true;
  }).timeout(10000)

  /************************************
   *  START PROCESS AND COMPLETE TASKS
   ************************************/

  it('Should start process from agreement', done => {
    setTimeout(async () => {
      piAddress = await contracts.startProcessFromAgreement(agreement.address)
      expect(piAddress).to.match(/[0-9A-Fa-f]{40}/)
      done()
    }, 1000)
  }).timeout(10000)

  it('Should confirm pending user task for buyer', done => {
    setTimeout(async () => {
      try {
        let tasks = await sqlCache.getTasksByUserAddress(buyer.address)
        expect(tasks.length).to.equal(1)
        expect(tasks[0].processAddress).to.equal(piAddress)
        expect(tasks[0].activityId).to.equal(buyTask.activityId)
        expect(tasks[0].agreementAddress).to.equal(agreement.address)
        expect(tasks[0].state).to.equal(4)
        aiId = tasks[0].activityInstanceId
        done()
      } catch (err) {
        done(err)
      }
    }, 1000)
  }).timeout(10000)

  it('Should sign agreement by buyer', async () => {
    await assert.isFulfilled(contracts.signAgreement(buyer.address, agreement.address))
  }).timeout(10000)

  it('Should complete task by buyer', async () => {
    await assert.isFulfilled(contracts.completeActivity(buyer.address, aiId))
  }).timeout(10000)

  it('Should confirm NO pending user task for buyer', done => {
    setTimeout(async () => {
      let tasks = await sqlCache.getTasksByUserAddress(buyer.address)
      expect(tasks.length).to.equal(0)
      done()
    }, 1000)
  }).timeout(10000)

  it('Should confirm active agreement state EXECUTED', async () => {
    let agreementData = await contracts.getActiveAgreementData(agreement.address)
    expect(parseInt(agreementData.legalState, 10)).to.equal(2) // EXECUTED
  }).timeout(10000)

  it('Should confirm pending user task for seller', async () => {
    let tasks = await sqlCache.getTasksByUserAddress(seller.address)
    expect(tasks.length).to.equal(1)
    expect(tasks[0].activityId).to.equal(sellTask.activityId)
    expect(tasks[0].agreementAddress).to.equal(agreement.address)
    expect(tasks[0].state).to.equal(4)
    aiId = tasks[0].activityInstanceId
  }).timeout(10000)

  it('Should complete task by seller', async () => {
    await assert.isFulfilled(contracts.completeActivity(seller.address, aiId))
  }).timeout(10000)

  it('Should confirm NO pending user task for seller', done => {
    setTimeout(async () => {
      let tasks = await sqlCache.getTasksByUserAddress(seller.address)
      expect(tasks.length).to.equal(0)
      done()
    }, 1000)
  }).timeout(10000)

  it('Should confirm active agreement state FULFILLED', async () => {
    let agreementData = await contracts.getActiveAgreementData(agreement.address)
    expect(parseInt(agreementData.legalState, 10)).to.equal(3) // FULFILLED
  }).timeout(10000)
})
