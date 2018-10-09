const chai = require('chai');
const path = require('path');
const fs = require('fs');
const _ = require('lodash');
const logger = require(__common + '/monax-logger');
const log = logger.getLogger('agreements.tests.api.helper');

module.exports = (server) => {
  return {
    registerUser: (user) => {
      return new Promise((resolve, reject) => {
        chai
          .request(server)
          .post('/users')
          .send(user)
          .end((err, res) => {
            if (err) return reject(err);
            else return resolve({
              address: res.body.address
            });
          });
      });
    },
  
    loginUser: (user) => {
      return new Promise((resolve, reject) => {
        chai
          .request(server)
          .put('/users/login')
          .send(user)
          .end((err, res) => {
            if (err) return reject(err);
            let cookie = res.headers['set-cookie'][0];
            let token = cookie.split('access_token=')[1].split(';')[0];
            return resolve({
              token,
              loggedInUser: res.body
            });
          });
      })
    },
  
    createAndDeployModel: (xml, token) => {
      return new Promise((resolve, reject) => {
        chai
          .request(server)
          .post(`/bpm/process-models`)
          .set('Cookie', [`access_token=${token}`])
          .set('content-type', 'application/xml')
          .send(xml)
          .end((err, res) => {
            if (err) return reject(err);
            if (res.status !== 200) return reject(new Error('creating and deploying model NOT OK'));
            return resolve(res.body);
          });
      });
    },

    getDiagram: (modelAddress, accept) => {
      return new Promise((resolve, reject) => {
        chai.request(server)
        .get(`/bpm/process-models/${modelAddress}/diagram`)
        .set('Cookie', [`access_token=${token}`])
        .set('Accept', accept)
        .end((err, res) => {
          if (err) return reject(err);
          if (res.status !== 200) return reject(new Error('get diagram NOT OK'));
          return resolve(res.body);
        });
      });
    },

    getProcessDefinition: (processAddress, token) => {
      return new Promise((resolve, reject) => {
        chai.request(server)
        .get(`/bpm/process-definitions/${processAddress}`)
        .set('Cookie', [`access_token=${token}`])
        .end((err, res) => {
          if (err) return reject(err);
          if (res.status !== 200) return reject(new Error('get diagram NOT OK'));
          return resolve(res.body);
        });
      });
    },

    createArchetypePackage: (package, token) => {
      return new Promise((resolve, reject) => {
        chai
        .request(server)
          .post('/archetype-packages')
          .set('Cookie', [`access_token=${token}`])
          .send(package)
          .end((err, res) => {
            if (err) return reject(err);
            if (res.status !== 200) return reject(new Error('archetype package creation NOT OK'));
            log.debug('Archetype Package id: ' + res.body.id);
            return resolve({ id: res.body.id });
          });
      });
    },

    addArchetypeToPackage: (packageId, archetypeAddress, token) => {
      return new Promise((resolve, reject) => {
        chai
        .request(server)
          .put(`/archetype-packages/${packageId}/archetype/${archetypeAddress}`)
          .set('Cookie', [`access_token=${token}`])
          .end((err, res) => {
            if (err) return reject(err);
            if (res.status !== 200) return reject(new Error('adding archetype to package NOT OK'));
            return resolve();
          });
      });
    },

    getArchetypePackages: (token) => {
      return new Promise((resolve, reject) => {
        chai
          .request(server)
          .get(`/archetype-packages`)
          .set('Cookie', [`access_token=${token}`])
          .end((err, res) => {
            if (err) return reject(err);
            if (res.status !== 200) return reject(new Error('get archetype packages NOT OK'));
            return resolve(res.body);
          });
      });
    },

    activateArchetypePackage: (packageId, token) => {
      return new Promise((resolve, reject) => {
        chai
          .request(server)
          .put(`/archetype-packages/${packageId}/activate`)
          .set('Cookie', [`access_token=${token}`])
          .end((err, res) => {
            if (err) return reject(err);
            if (res.status !== 200) return reject(new Error('activate archetype package NOT OK'));
            return resolve();
          });
      })
    },

    deactivateArchetypePackage: (packageId, token) => {
      return new Promise((resolve, reject) => {
        chai
          .request(server)
          .put(`/archetype-packages/${packageId}/deactivate`)
          .set('Cookie', [`access_token=${token}`])
          .end((err, res) => {
            if (err) return reject(err);
            if (res.status !== 200) return reject(new Error('deactivate archetype package NOT OK'));
            return resolve();
          });

      })
    },
  
    createArchetype: (archetype, token) => {
      return new Promise((resolve, reject) => {
        chai
          .request(server)
          .post('/archetypes')
          .set('Cookie', [`access_token=${token}`])
          .send(archetype)
          .end((err, res) => {
            if (err) return reject(err);
            if (res.status !== 200) return reject(new Error('archetype creation NOT OK'));
            log.debug('Archetype Address: ' + res.body.address);
            return resolve({ address: res.body.address });
          });
      });
    },

    getArchetypes: (token) => {
      return new Promise((resolve, reject) => {
        chai
          .request(server)
          .get('/archetypes')
          .set('Cookie', [`access_token=${token}`])
          .end((err, res) => {
            if (err) return reject(err);
            if (res.status !== 200) return reject(new Error('get archetypes NOT OK'));
            return resolve(res.body);
          });
      });
    },

    getArchetype: (address, token) => {
      return new Promise((resolve, reject) => {
        chai
          .request(server)
          .get(`/archetypes/${address}`)
          .set('Cookie', [`access_token=${token}`])
          .end((err, res) => {
            if (err) return reject(err);
            if (res.status !== 200) return reject(new Error('get archetype NOT OK'));
            return resolve(res.body);
          });
      });
    },

    activateArchetype: (archetypeAddress, token) => {
      return new Promise((resolve, reject) => {
        chai
          .request(server)
          .put(`/archetypes/${archetypeAddress}/activate`)
          .set('Cookie', [`access_token=${token}`])
          .end((err, res) => {
            if (err) return reject(err);
            if (res.status !== 200) return reject(new Error('activate archetype NOT OK'));
            return resolve();
          });
      })
    },

    deactivateArchetype: (archetypeAddress, token) => {
      return new Promise((resolve, reject) => {
        chai
          .request(server)
          .put(`/archetypes/${archetypeAddress}/deactivate`)
          .set('Cookie', [`access_token=${token}`])
          .end((err, res) => {
            if (err) return reject(err);
            if (res.status !== 200) return reject(new Error('deactivate archetype NOT OK'));
            return resolve();
          });
      })
    },

    setArchetypeSuccessor: (archetypeAddress, successorAddress, token) => {
      return new Promise((resolve, reject) => {
        chai
          .request(server)
          .put(`/archetypes/${archetypeAddress}/successor/${successorAddress}`)
          .set('Cookie', [`access_token=${token}`])
          .end((err, res) => {
            if (err) return reject(err);
            if (res.status !== 200) return reject(new Error('set archetype successor NOT OK'));
            return resolve();
          });
      })
    },

    createAgreementCollection: (collection, token) => {
      return new Promise((resolve, reject) => {
        chai
        .request(server)
          .post('/agreement-collections')
          .set('Cookie', [`access_token=${token}`])
          .send(collection)
          .end((err, res) => {
            if (err) return reject(err);
            if (res.status !== 200) return reject(new Error('agreement collection creation NOT OK'));
            log.debug('Agreement Collection id: ' + res.body.id);
            return resolve({ id: res.body.id });
          });
      });
    },

    getAgreementCollection: (collectionId, token) => {
      return new Promise((resolve, reject) => {
        chai
        .request(server)
          .get('/agreement-collections/' + collectionId)
          .set('Cookie', [`access_token=${token}`])
          .end((err, res) => {
            if (err) return reject(err);
            if (res.status !== 200) return reject(new Error('get agreement collection NOT OK'));
            log.debug('Agreement Collection: ' + res.body);
            return resolve(res.body);
          });
      });
    },
  
    createAgreement: (agreement, token) => {
      return new Promise((resolve, reject) => {
        chai
          .request(server)
          .post('/agreements')
          .set('Cookie', [`access_token=${token}`])
          .send(agreement)
          .end((err, res) => {
            if (err) return reject(err);
            if (res.status !== 200) return reject(new Error('agreement creation NOT OK'));
            log.debug('Agreement Address: ' + res.body.address);
            return resolve({ address: res.body.address });
          });
      });
    },

    getAgreement: (agreementAddress, token) => {
      return new Promise((resolve, reject) => {
        chai
          .request(server)
          .get(`/agreements/${agreementAddress}`)
          .set('Cookie', [`access_token=${token}`])
          .end((err, res) => {
            if (err) return reject(err);
            if (res.status !== 200) return reject(new Error('getting agreement NOT OK'));
            return resolve(res.body);
          });
      });
    },

    getAgreements: (token, query = '') => {
      return new Promise((resolve, reject) => {
        chai
          .request(server)
          .get(`/agreements${query}`)
          .set('Cookie', [`access_token=${token}`])
          .end((err, res) => {
            if (err) return reject(err);
            if (res.status !== 200) return reject(new Error('getting agreements NOT OK'));
            return resolve(res.body);
          });
      });
    },
  
    getTasksForUser: (token) => {
      return new Promise((resolve, reject) => {
        chai
          .request(server)
          .get('/tasks')
          .set('Cookie', [`access_token=${token}`])
          .end((err, res) => {
            if (err) return reject(err);
            if (res.status !== 200) return reject(new Error('getting tasks for user NOT OK'));
            log.debug('User Tasks: ' + JSON.stringify(res.body));
            return resolve(res.body);
          });
      });
    },

    getActivityInstance: (activityInstanceId, token) => {
      return new Promise((resolve, reject) => {
        chai
          .request(server)
          .get(`/bpm/activity-instances/${activityInstanceId}`)
          .set('Cookie', [`access_token=${token}`])
          .end((err, res) => {
            if (err) return reject(err);
            if (res.status !== 200) return reject(new Error('set data value NOT OK'));
            return resolve(res.body);
          });
      });
    },

    setActivityDataValue: (activityInstanceId, dataMappingId, value, token) => {
      return new Promise((resolve, reject) => {
        chai
          .request(server)
          .put(`/bpm/activity-instances/${activityInstanceId}/data-mappings/${dataMappingId}`)
          .set('Cookie', [`access_token=${token}`])
          .send({value})
          .end((err, res) => {
            if (err) return reject(err);
            if (res.status !== 200) return reject(new Error('set data value NOT OK'));
            return resolve();
          });
      });
    },

    setActivityDataValues: (activityInstanceId, data, token) => {
      return new Promise((resolve, reject) => {
        chai
          .request(server)
          .put(`/bpm/activity-instances/${activityInstanceId}/data-mappings`)
          .set('Cookie', [`access_token=${token}`])
          .send(data)
          .end((err, res) => {
            if (err) return reject(err);
            if (res.status !== 200) return reject(new Error('set data value NOT OK'));
            return resolve();
          });
      });
    },

    getActivityDataValue: (activityInstanceId, dataMappingId, token) => {
      return new Promise((resolve, reject) => {
        chai
          .request(server)
          .get(`/bpm/activity-instances/${activityInstanceId}/data-mappings/${dataMappingId}`)
          .set('Cookie', [`access_token=${token}`])
          .end((err, res) => {
            if (err) return reject(err);
            if (res.status !== 200) return reject(new Error('set data value NOT OK'));
            return resolve(res.body);
          });
      });
    },

    getActivityDataValues: (activityInstanceId, token) => {
      return new Promise((resolve, reject) => {
        chai
          .request(server)
          .get(`/bpm/activity-instances/${activityInstanceId}/data-mappings`)
          .set('Cookie', [`access_token=${token}`])
          .end((err, res) => {
            if (err) return reject(err);
            if (res.status !== 200) return reject(new Error('set data value NOT OK'));
            return resolve(res.body);
          });
      });
    },
  
    completeTaskForUser: (activityInstanceId, data, token) => {
      return new Promise((resolve, reject) => {
        chai
          .request(server)
          .put(`/tasks/${activityInstanceId}/complete`)
          .set('Cookie', [`access_token=${token}`])
          .send(data ? { data } : {})
          .end((err, res) => {
            if (err) return reject(err);
            if (res.status !== 200) return reject(new Error('complete task for user NOT OK'));
            return resolve();
          });
      });
    },
  
    completeAndSignTaskForUser: (activityInstanceId, agreement, token) => {
      return new Promise((resolve, reject) => {
        chai
          .request(server)
          .put(`/tasks/${activityInstanceId}/complete/${agreement}/sign`)
          .set('Cookie', [`access_token=${token}`])
          .end((err, res) => {
            if (err) return reject(err);
            if (res.status !== 200) return reject(new Error('complete and sign task for user NOT OK'));
            return resolve();
          });
      });
    },
  
    cancelAgreement: (agreement, token) => {
      return new Promise((resolve, reject) => {
        chai
          .request(server)
          .put(`/agreements/${agreement}/cancel`)
          .set('Cookie', [`access_token=${token}`])
          .end((err, res) => {
            if (err) return reject(err);
            if (res.status !== 200) return reject(new Error('cancel agreement NOT OK'));
            return resolve();
          });
      });
    },
  
    generateModelXml: (modelId, modelPath) => {
      let xml = fs.readFileSync(path.resolve(modelPath), 'utf8');
      xml = _.replace(xml, new RegExp('###MODEL_ID###', 'g'), modelId);
      return xml;
    },

    createTags: (tags, owner, token) => {
      return new Promise((resolve, reject) => {
        chai
          .request(server)
          .post(`/agreement-tags`)
          .send({ tags, owner })
          .set('Cookie', [`access_token=${token}`])
          .end((err, res) => {
            if (err) return reject(err);
            if (res.status !== 200) return reject(new Error('create tags NOT OK'));
            return resolve(res.body);
          });
      });
    },

    applyTags: (tagIds, agreement, token) => {
      return new Promise((resolve, reject) => {
        chai
          .request(server)
          .put(`/agreements/${agreement}/tags`)
          .send({ tagIds })
          .set('Cookie', [`access_token=${token}`])
          .end((err, res) => {
            if (err) return reject(err);
            if (res.status !== 200) return reject(new Error('apply tags NOT OK'));
            return resolve();
          });
      });
    },

    removeTag: (tagId, agreement, token) => {
      return new Promise((resolve, reject) => {
        chai
          .request(server)
          .delete(`/agreements/${agreement}/tags/${tagId}`)
          .set('Cookie', [`access_token=${token}`])
          .end((err, res) => {
            if (err) return reject(err);
            if (res.status !== 200) return reject(new Error('remove tag NOT OK'));
            return resolve();
          });
      });
    },

    createOrganization: (organization, token) => {
      return new Promise((resolve, reject) => {
        chai
          .request(server)
          .post(`/organizations`)
          .send(organization)
          .set('Cookie', [`access_token=${token}`])
          .end((err, res) => {
            if (err) return reject(err);
            if (res.status !== 200) return reject(new Error('create organization NOT OK'));
            return resolve(res);
          });
      });
    },
  }
}