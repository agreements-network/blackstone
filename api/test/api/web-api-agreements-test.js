require('../constants');
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

var hoardGrant;

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
        let token = loginResult.token;
        setTimeout(() => {
          request(server)
            .post('/hoard')
            .set('Cookie', [`access_token=${token}`])
            .attach('myfile.js', __dirname + '/web-api-test.js')
            .expect(200)
            .end((err, res) => {
              expect(err).to.not.exist;
              hoardGrant = res.body.grant;
            });
        }, global.ventCatchUpMS);
      } catch (err) {
        throw err;
      }
    }, global.ventCatchUpMS);
  }).timeout(10000);
});


/**
 * ######## ARCHETYPES #########################################################################################
 */

describe('Archetypes', () => {
  let token;

  let archUser = {
    username: `arch${rid(5, 'aA0')}`,
    password: 'archuser',
    email: `${rid(10, 'aA0')}@test.com`
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

  let testArchetype = {
    name: 'TestType Complex',
    description: 'Complex',
    parameters: [
      { name: 'parameter1', type: 0 },
      { name: 'parameter2', type: 1 },
      { name: 'parameter3', type: 2 },
      { name: 'parameter4', type: 3 },
      { name: 'parameter5', type: 4 },
      { name: 'parameter6', type: 5 }
    ],
    jurisdictions: [
      { country: 'CA', regions: ['0798FDAD71114ABA2A3CD6B4BD503410F8EF6B9208B889CC0BB33CD57CEEAA9C', '9CD6EEC0C135A0DEC4176812CE66259A61CB5075E1494A123383E2A12A45691C'] },
      {
        country: 'US',
        regions: []
      }
    ],
    formationProcessDefinition: '',
    executionProcessDefinition: ''
  }

  let simpleArchetype, complexArchetype;

  it('Should register a user', async () => {
    await api.registerUser(archUser);
    await global.sleep(1000);
    await api.activateUser(archUser);
    await global.sleep(1000);
    const loginResult = await api.loginUser(archUser);
    await global.sleep(1000);
    expect(loginResult.token).to.exist;
    token = loginResult.token;
  }).timeout(global.testTimeoutMS);

  it('Should create a model and process definitions', async () => {
    // DEPLOY FORMATION MODEL
    let formXml = api.generateModelXml(formation.id, formation.filePath);
    let formationDeploy = await api.createAndDeployModel(formXml, token);
    expect(formationDeploy).to.exist;
    Object.assign(formation, formationDeploy.model);
    Object.assign(formation.process, formationDeploy.processes[0]);
    testArchetype.formationProcessDefinition = formation.process.address;
    expect(String(testArchetype.formationProcessDefinition).match(/[0-9A-Fa-f]{40}/)).to.exist;
    // DEPLOY EXECUTION MODEL
    let execXml = api.generateModelXml(execution.id, execution.filePath);
    let executionDeploy = await api.createAndDeployModel(execXml, token);
    expect(executionDeploy).to.exist;
    Object.assign(execution, executionDeploy.model);
    Object.assign(execution.process, executionDeploy.processes[0]);
    testArchetype.executionProcessDefinition = execution.process.address;
    expect(String(testArchetype.executionProcessDefinition).match(/[0-9A-Fa-f]{40}/)).to.exist;
  }).timeout(global.testTimeoutMS);

  it('GET all archetypes', (done) => {
    chai
      .request(server)
      .get('/archetypes')
      .set('Cookie', [`access_token=${token}`])
      .end((err, res) => {
        res.should.have.status(200)
        res.body.should.be.a('array')
        currentSize = res.body.length
        done()
      })
  }).timeout(2000)

  it('POST a new simple archetype', (done) => {
    try {
      const newObject = {
        name: 'TestType1',
        description: 'Test',
        formationProcessDefinition: formation.process.address,
        executionProcessDefinition: execution.process.address
      }
      chai
        .request(server)
        .post('/archetypes')
        .set('Cookie', [`access_token=${token}`])
        .send(newObject)
        .end((err, res) => {
          res.should.have.status(200)
          res.body.address.should.exist
          res.body.address.should.match(/[0-9A-Fa-f]{40}/) // match for 20 byte hex
          simpleArchetype = res.body.address
          log.debug('Address: ' + simpleArchetype)
          done()
        })
    } catch (err) {
      done(err);
    }
  }).timeout(10000);

  it('POST a new complex archetype', (done) => {
    testArchetype.documents = [{
      name: 'doc1.pdf',
      grant: hoardGrant,
    }]
    chai
      .request(server)
      .post('/archetypes')
      .set('Cookie', [`access_token=${token}`])
      .send(testArchetype)
      .end((err, res) => {
        if (err) done(err);
        try {
          res.should.have.status(200);
          res.body.address.should.exist;
          res.body.address.should.match(/[0-9A-Fa-f]{40}/) // match for 20 byte hex
          complexArchetype = res.body.address
          log.debug('Address: ' + complexArchetype)
          done();
        } catch (error) {
          done(error);
        }
      });
  }).timeout(8000);

  it('should GET complex archetype', done => {
    setTimeout(() => {
      chai
        .request(server)
        .get('/archetypes/' + complexArchetype)
        .set('Cookie', [`access_token=${token}`])
        .end((err, res) => {
          if (err) done(err)
          expect(res.body).to.exist
          expect(res.body.name).to.equal(testArchetype.name)
          expect(res.body.description).to.equal(testArchetype.description)
          expect(res.body.parameters.length).to.equal(6)
          expect(res.body.documents.length).to.equal(1)
          expect(res.body.jurisdictions.length).to.equal(2)
          expect(res.body.jurisdictions[0].regions.length).to.equal(2)
          done()
        })
    },global.ventCatchUpMS )
  }).timeout(10000)

  it('should set archetype successor', async () => {
    await api.setArchetypeSuccessor(simpleArchetype, complexArchetype, token);
  }).timeout(10000);

  it('should validate predecessor archetype is inactive', done => {
    setTimeout(async () => {
      try {
        const data = await api.getArchetype(simpleArchetype, token);
        expect(data.successor).to.equal(complexArchetype);
        expect(data.active).to.be.false;
        done();
      } catch (err) {
        done(err);
      }
    }, global.ventCatchUpMS);
  }).timeout(10000);

  it('should fail to activate archetype that has a successor', async () => {
    await assert.isRejected(api.activateArchetype(simpleArchetype, token));
  }).timeout(10000);

  it('should fail when setting a circular succession dependency', async () => {
    await assert.isRejected(api.setArchetypeSuccessor(complexArchetype, simpleArchetype, token));
  });
});

/**
 * ######## Archetype Packages and Agreement Collections  ###############################################################################################################
 */
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
      grant: hoardGrant
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
      grant: hoardGrant
    }],
    governingArchetypes: []
  };
  let agreement1 = {
    name: 'Agreement No. ' + new Date().getMilliseconds(),
    archetype: '', // plug in archetype address
    isPrivate: false,
    parties: [],
    parameters: [],
    maxNumberOfAttachments: 5,
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
    let registerResult1 = await api.registerUser(user1);
    let registerResult2 = await api.registerUser(user2);

    user1.address = registerResult1.address;
    user2.address = registerResult2.address;
    expect(user1.address).to.exist
    expect(user2.address).to.exist
  }).timeout(5000);

  it('Should login users', (done) => {
    // LOGIN USERS
    setTimeout(async () => {
      try {
        await api.activateUser(user1);
        let loginResult1 = await api.loginUser(user1);
        await api.activateUser(user2);
        let loginResult2 = await api.loginUser(user2);
        expect(loginResult1.token).to.exist;
        expect(loginResult2.token).to.exist;
        user1.token = loginResult1.token;
        user2.token = loginResult2.token;
        done();
      } catch (err) {
        done(err);
      }
    }, global.ventCatchUpMS);
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
  }).timeout(global.testTimeoutMS);

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
    }, global.ventCatchUpMS);
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
    }, global.ventCatchUpMS);
  }).timeout(10000);

  it('Should create privatePackage1 by user1', async () => {
    // CREATE ARCHETYPE PACKAGE
    let data = await api.createArchetypePackage(privatePackage1, user1.token);
    privatePackage1.id = data.id;
    expect(privatePackage1.id).to.exist;
  }).timeout(10000);

  it('Should fail to create publicArchetype1 by user1 in publicPackage2 created by user2', async () => {
    // CREATE ARCHETYPE
    publicArchetype1.documents[0].grant = hoardGrant;
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
    }, global.ventCatchUpMS);
  }).timeout(10000);

  it('Should deactivate publicArchetype1 by user1', done => {
    setTimeout(async () => {
      try {
        await assert.isFulfilled(api.deactivateArchetype(publicArchetype1.address, user1.token));
        done();
      } catch (err) {
        done(err);
      }
    }, global.ventCatchUpMS);
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
          maxNumberOfAttachments: 5,
        }
        await assert.isRejected(api.createAgreement(agr, user1.token));
        done();
      } catch (err) {
        done(err);
      }
    }, global.ventCatchUpMS);
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
    }, global.ventCatchUpMS);
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
    }, global.ventCatchUpMS);
  }).timeout(10000);

  it('Should fail to add publicArchetype1 created by user1 to publicPackage2 created by user2', async () => {
    // User1 attempts to add publicArchetype1 to publicPackage2 and fails since he did not author publicPackage2
    await assert.isRejected(api.addArchetypeToPackage(publicPackage2.id, publicArchetype1.address, user1.token));
  }).timeout(10000);

  it('Should create privateArchetype1 by user2 with no package id', async () => {
    // CREATE ARCHETYPE
    privateArchetype1.documents[0].grant = hoardGrant;
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
    }, global.ventCatchUpMS);
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

/**
 * ######## Governing Archetypes and Agreements  ###############################################################################################################
 */
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
    maxNumberOfAttachments: 5,
    governingAgreements: []
  };
  let ndaAgreement = {
    name: 'NDA Agreement ' + new Date().getMilliseconds(),
    archetype: '',
    isPrivate: false,
    parties: [],
    parameters: [],
    maxNumberOfAttachments: 5,
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
        await api.activateUser(user1);
        let loginResult1 = await api.loginUser(user1);
        expect(loginResult1.token).to.exist;
        user1.token = loginResult1.token;
        done();
      } catch (err) {
        done(err);
      }
    }, global.ventCatchUpMS);
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
    }, global.ventCatchUpMS);
  }).timeout(global.testTimeoutMS);

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
      grant: hoardGrant,
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
    maxNumberOfAttachments: 0,
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
        await api.activateUser(registeredUser);
        const loginResult = await api.loginUser(registeredUser);
        expect(loginResult.token).to.exist;
        registeredUser.token = loginResult.token;
        done();
      } catch (err) {
        done(err);
      }
    }, global.ventCatchUpMS);
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
  }).timeout(global.testTimeoutMS);

  it('Should create an archetype', done => {
    // CREATE ARCHETYPE
    setTimeout(async () => {
      try {
        archetype.documents[0].grant = hoardGrant;
        Object.assign(archetype, await api.createArchetype(archetype, registeredUser.token));
        expect(String(archetype.address)).match(/[0-9A-Fa-f]{40}/).to.exist;
        agreement.archetype = archetype.address;
        done();
      } catch (err) {
        done(err);
      }
    }, global.ventCatchUpMS);
  }).timeout(10000);

  it('Should create an agreement with emails in the user/org/signatory parameters', done => {
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
        Object.assign(agreement, await api.createAgreement(agreement, registeredUser.token));
        expect(String(agreement.address)).match(/[0-9A-Fa-f]{40}/).to.exist;
        done();
      } catch (err) {
        done(err);
      }
    }, global.ventCatchUpMS);
  }).timeout(10000);

  it('Should create new users when an unknown email is given', done => {
    // CHECK USER CREATION
    setTimeout(async () => {
      try {
        const user1 = await contracts.getUserById(crypto.createHash('sha256').update(externalUser1.email.toLowerCase()).digest('hex'));
        const user2 = await contracts.getUserById(crypto.createHash('sha256').update(externalUser2.email.toLowerCase()).digest('hex'));
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
    }, global.ventCatchUpMS);
  }).timeout(10000);

  it('Should not create multiple users for the same email address (case insensitive)', done => {
    // CHECK USER CREATION
    setTimeout(async () => {
      try {
        await assert.isRejected(contracts.getUserById(crypto.createHash('sha256').update(externalUser1.email.toUpperCase()).digest('hex')));
        done();
      } catch (err) {
        done(err);
      }
    }, global.ventCatchUpMS);
  }).timeout(10000);

  let parameters;

  it('Should use the address of the already registered user when a known email address is given', done => {
    // CHECK AGREEMENT PARAMETERS
    setTimeout(async () => {
      try {
        ({ parameters } = await api.getAgreement(agreement.address, registeredUser.token));
        expect(parameters.find(({ name }) => name === 'RegisteredByEmail').value).to.equal(registeredUser.address);
        done();
      } catch (err) {
        done(err);
      }
    }, global.ventCatchUpMS);
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
    }, global.ventCatchUpMS);
  }).timeout(10000);

  it('Should allow external user to register', async () => {
    // REGISTER USER
    externalUser1.username = `new_username_${rid(5, 'aA0')}`;
    externalUser1.password = 'externaluser';
    const registerResult = await api.registerUser({
      email: externalUser1.email,
      username: externalUser1.username,
      password: externalUser1.password,
    });
    expect(registerResult.address).to.equal(externalUser1.address);
  }).timeout(5000);

});

describe(':: Public/Private Agreement Parameters ::', () => {
  let user = {
    username: `user${rid(5, 'aA0')}`,
    password: 'password',
    email: `${rid(10, 'aA0')}@test.com`,
  };

  const formation = {
    filePath: 'test/data/inc-formation.bpmn',
    process: {},
    id: rid(16, 'aA0'),
    name: 'Incorporation-Formation'
  };
  const execution = {
    filePath: 'test/data/inc-execution.bpmn',
    process: {},
    id: rid(16, 'aA0'),
    name: 'Incorporation-Execution'
  };
  const archetype = {
    name: 'Incorporation Archetype',
    description: 'Incorporation Archetype',
    price: 10,
    isPrivate: 1,
    active: 1,
    parameters: [
      { type: 0, name: 'Signed' },
      { type: 8, name: 'Receiver' },
      { type: 8, name: 'Confirmer' },
      { type: 1, name: 'Unused String in Model' },
      { type: 2, name: 'Extra Number Parameter' },
    ],
    documents: [{
      name: 'doc1.md',
      grant: hoardGrant,
    }],
    jurisdictions: [],
    executionProcessDefinition: '',
    formationProcessDefinition: '',
    governingArchetypes: []
  };
  const agreement = {
    name: 'Pub/Priv Parameters',
    archetype: '',
    isPrivate: false,
    parameters: [
      { type: 0, name: 'Signed', value: false },
      { type: 8, name: 'Receiver', value: '4D546B1481B5DC02BCB4EB8237234872DF9FF4C0' },
      { type: 8, name: 'Confirmer', value: '4D546B1481B5DC02BCB4EB8237234872DF9FF4C0' },
      { type: 1, name: 'Unused String in Model', value: 'Should be private' },
      { type: 2, name: 'Extra Number Parameter', value: 9 }, // should also be private
    ],
    maxNumberOfEvents: 0,
    governingAgreements: []
  };

  it('Should register user', async () => {
    // REGISTER USER
    const registerResult = await api.registerUser(user);
    user.address = registerResult.address;
    expect(user.address).to.exist
  }).timeout(5000);

  it('Should login user', (done) => {
    // LOGIN USER
    setTimeout(async () => {
      try {
        await api.activateUser(user);
        const loginResult = await api.loginUser(user);
        expect(loginResult.token).to.exist;
        user.token = loginResult.token;
        done();
      } catch (err) {
        done(err);
      }
    }, global.ventCatchUpMS);
  }).timeout(10000);

  it('Should deploy formation and execution models', async () => {
    // DEPLOY FORMATION MODEL
    let xml = api.generateModelXml(formation.id, formation.filePath);
    let deployed = await api.createAndDeployModel(xml, user.token);
    expect(deployed).to.exist;
    archetype.formationProcessDefinition = deployed.processes[0].address;
    expect(String(archetype.formationProcessDefinition).match(/[0-9A-Fa-f]{40}/)).to.exist;
    // DEPLOY EXECUTION MODEL
    xml = api.generateModelXml(execution.id, execution.filePath);
    deployed = await api.createAndDeployModel(xml, user.token);
    expect(deployed).to.exist;
    archetype.executionProcessDefinition = deployed.processes[0].address;
    expect(String(archetype.executionProcessDefinition).match(/[0-9A-Fa-f]{40}/)).to.exist;
  }).timeout(global.testTimeoutMS);

  it('Should create an archetype', done => {
    // CREATE ARCHETYPE
    setTimeout(async () => {
      try {
        archetype.documents[0].grant = hoardGrant;
        Object.assign(archetype, await api.createArchetype(archetype, user.token));
        expect(String(archetype.address)).match(/[0-9A-Fa-f]{40}/).to.exist;
        agreement.archetype = archetype.address;
        done();
      } catch (err) {
        done(err);
      }
    }, global.ventCatchUpMS);
  }).timeout(10000);

  it('Should create an agreement', done => {
    // CREATE AGREEMENT
    setTimeout(async () => {
      try {
        Object.assign(agreement, await api.createAgreement(agreement, user.token));
        expect(String(agreement.address)).match(/[0-9A-Fa-f]{40}/).to.exist;
        done();
      } catch (err) {
        done(err);
      }
    }, global.ventCatchUpMS);
  }).timeout(10000);
});

describe(':: Agreement Attachments (External References) ::', () => {
  const user1 = {
    username: `registeredUser${rid(5, 'aA0')}`,
    password: 'registeredUser',
    email: `${rid(10, 'aA0')}@test.com`,
  };
  const user2 = {
    username: `registeredUser${rid(5, 'aA0')}`,
    password: 'registeredUser',
    email: `${rid(10, 'aA0')}@test.com`,
  };

  const formation = {
    filePath: 'test/data/inc-formation.bpmn',
    process: {},
    id: rid(16, 'aA0'),
    name: 'Incorporation-Formation'
  }
  const execution = {
    filePath: 'test/data/inc-execution.bpmn',
    process: {},
    id: rid(16, 'aA0'),
    name: 'Incorporation-Execution'
  }

  const archetype = {
    name: 'Incorporation Archetype',
    description: 'Incorporation Archetype',
    price: 10,
    isPrivate: 1,
    active: 1,
    parameters: [
      { type: 8, name: 'Party' },
    ],
    documents: [],
    jurisdictions: [],
    executionProcessDefinition: '',
    formationProcessDefinition: '',
    governingArchetypes: []
  }
  const agreement = {
    name: 'Attachments Agreement',
    archetype: '',
    isPrivate: false,
    parameters: [],
    maxNumberOfAttachments: 2,
    governingAgreements: []
  }

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
      try {
        await api.activateUser(user1);
        let loginResult = await api.loginUser(user1);
        expect(loginResult.token).to.exist;
        user1.token = loginResult.token;
        await api.activateUser(user2);
        loginResult = await api.loginUser(user2);
        expect(loginResult.token).to.exist;
        user2.token = loginResult.token;
        done();
      } catch (err) {
        done(err);
      }
    }, global.ventCatchUpMS);
  }).timeout(10000);

  it('Should deploy formation and execution models', async () => {
    // DEPLOY FORMATION MODEL
    let xml = api.generateModelXml(formation.id, formation.filePath);
    let deployed = await api.createAndDeployModel(xml, user1.token);
    expect(deployed).to.exist;
    archetype.formationProcessDefinition = deployed.processes[0].address;
    expect(String(archetype.formationProcessDefinition).match(/[0-9A-Fa-f]{40}/)).to.exist;
    // DEPLOY EXECUTION MODEL
    xml = api.generateModelXml(execution.id, execution.filePath);
    deployed = await api.createAndDeployModel(xml, user1.token);
    expect(deployed).to.exist;
    archetype.executionProcessDefinition = deployed.processes[0].address;
    expect(String(archetype.executionProcessDefinition).match(/[0-9A-Fa-f]{40}/)).to.exist;
  }).timeout(global.testTimeoutMS);

  it('Should create an archetype', done => {
    // CREATE ARCHETYPE
    setTimeout(async () => {
      try {
        Object.assign(archetype, await api.createArchetype(archetype, user1.token));
        expect(String(archetype.address)).match(/[0-9A-Fa-f]{40}/).to.exist;
        agreement.archetype = archetype.address;
        done();
      } catch (err) {
        done(err);
      }
    }, global.ventCatchUpMS);
  }).timeout(10000);

  it('Should create an agreement', done => {
    // CREATE AGREEMENT
    setTimeout(async () => {
      try {
        Object.assign(agreement, await api.createAgreement(agreement, user1.token));
        expect(String(agreement.address)).match(/[0-9A-Fa-f]{40}/).to.exist;
        done();
      } catch (err) {
        done(err);
      }
    }, global.ventCatchUpMS);
  }).timeout(10000);

  it('Should return an empty string for the attachments reference if not attachments have been added', done => {
    // INITIAL ATTACHMENTS FILE REFERENCE
    setTimeout(async () => {
      try {
        const { attachmentsFileReference } = await api.getAgreement(agreement.address, user1.token);
        expect(attachmentsFileReference).to.equal('');
        done();
      } catch (err) {
        done(err);
      }
    }, global.ventCatchUpMS);
  }).timeout(10000);

  it('Should not allow user 2 to upload an attachment to the agreement', async () => {
    // CHECK AUTHORIZATION
    await assert.isRejected(api.uploadAttachmentFile(agreement.address, user2.token));
  }).timeout(10000);

  let attachmentsFileReference;
  let attachments;

  it('Should allow user 1 to upload a file as an attachment to the agreement', async () => {
    // ATTACHMENT FILE UPLOAD
    ({ attachmentsFileReference, attachments } = await api.uploadAttachmentFile(agreement.address, user1.token));
    expect(attachmentsFileReference).to.be.a('string');
    expect(attachmentsFileReference).not.to.equal('');
    expect(attachments).to.be.a('array');
    expect(attachments.length).to.equal(1);
    const attachment = attachments[0];
    expect(attachment).to.be.a('object');
    expect(attachment.name).to.equal('web-api-test.js');
    expect(attachment.content).to.be.a('string');
    expect(attachment.submitter).to.equal(user1.address);
    expect(attachment.contentType).to.equal('fileReference');
  }).timeout(10000);

  it('Should allow user 1 to upload an object as an attachment to the agreement', async () => {
    // ATTACHMENT OBJECT UPLOAD
    const res = await api.uploadAttachmentObject(agreement.address, {
      name: 'attachment title', content: 'attachment body',
    }, user1.token);
    expect(res.attachmentsFileReference).to.be.a('string');
    expect(res.attachmentsFileReference).not.to.equal('');
    expect(res.attachmentsFileReference).not.to.equal(attachmentsFileReference);
    expect(res.attachments).to.be.a('array');
    expect(res.attachments.length).to.equal(2);
    const attachment = res.attachments[1];
    expect(attachment).to.be.a('object');
    expect(attachment.name).to.equal('attachment title');
    expect(attachment.content).to.be.a('string');
    expect(attachment.content).to.equal('attachment body');
    expect(attachment.submitter).to.equal(user1.address);
    expect(attachment.contentType).to.equal('plaintext');
    attachmentsFileReference = res.attachmentsFileReference;
  }).timeout(10000);

  it("Should not allow user 1 to upload more attachments than the agreement's maxNumberOfAttachments", async () => {
    // CHECK MAX ATTACHMENTS
    await assert.isRejected(api.uploadAttachmentFile(agreement.address, user1.token));
  }).timeout(10000);

  it('Should allow user 1 to get attachments file from hoard', async () => {
    // GET ATTACHMENTS
    const contentDisposition = await api.getHoard(attachmentsFileReference);
    console.log('****contentDisposition, ', contentDisposition);
    expect(contentDisposition).to.equal('attachment; filename=\"agreement_attachments.json\"'); // This is the default name of the attachments file given by the API
  }).timeout(10000);

  it('Should allow user 1 to get attachment from hoard', async () => {
    // GET ATTACHMENTS
    const contentDisposition = await api.getHoard(attachments[0].content);
    expect(contentDisposition).to.equal('attachment; filename=\"web-api-test.js\"'); // This is the file we are using as the attachment (see uploadAttachmentFile in api-helper)
  }).timeout(10000);

});
