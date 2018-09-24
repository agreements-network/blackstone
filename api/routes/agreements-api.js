const {
  getArchetypes,
  getArchetype,
  createArchetype,
  activateArchetype,
  deactivateArchetype,
  setArchetypeSuccessor,
  setArchetypePrice,
  createArchetypePackage,
  getArchetypePackages,
  getArchetypePackage,
  addArchetypeToPackage,
  activateArchetypePackage,
  deactivateArchetypePackage,
  createAgreement,
  getAgreements,
  getAgreement,
  updateAgreementEventLog,
  signAgreement,
  cancelAgreement,
  createAgreementCollection,
  getAgreementCollections,
  getAgreementCollection,
  addAgreementToCollection,
} = require(`${global.__controllers}/agreements-controller`);

const { ensureAuth } = require(`${global.__common}/middleware`);

// APIs defined according to specification found here -> http://apidocjs.com
module.exports = (app) => {
/* ***********
* Archetypes
*********** */

  /**
 * @api {get} /archetypes Read Archetypes
 * @apiName ReadArchetypes
 * @apiGroup Archetypes
 *
 * @apiDescription Retrieves archetype information. Within the
 * Agreements Network, Archetypes are the fundamental, top level
 * objects. They are holders for a set of information which
 * allows users to creat Active Agreements within the Platform.
 * The returned list will include archetypes that are:
 *    a. authored by the authenticated user, or
 *    b. public (ie. `isPrivate` property is `false`) and activated (ie. `active` property is true)
 *
 * @apiExample {curl} Simple:
 *     curl -i /archetypes
 *
 * @apiSuccess {String} address Archetype's address
 * @apiSuccess {String} name Human readable name of the Archetype
 * @apiSuccess {String} author Controller contract of the user or organization
 * that created the Archetype
 * @apiSuccess {String} description description of the Archetype
 * @apiSuccess {Boolean} active Whether the Archetype can be used to create
 * new Active Agreements or not
 * @apiSuccess {Boolean} isPrivate Whether the encryption framework of the Archetype
 * is operational or not
 * @apiSuccess {Number} numberOfParameters The number of custom parameters used by the Archetype
 * @apiSuccess {Number} numberOfDocuments The number of documents registered against the Archetype
 * @apiSuccess {String[]} countries The jurisdictions in which the Archetype has been
 * registered to be active
 * @apiSuccessExample {json} Success Objects Array
  [{
    "address": "707791D3BBD4FDDE615D0EC4BB0EB3D909F66890",
    "name": "TestType1",
    "author": "6EDC6101F0B64156ED867BAE925F6CD240635656",
    "description": "This archetype is for testing purposes.",
    "active": false,
    "isPrivate": false,
    "numberOfParameters": 2,
    "numberOfDocuments": 1,
    "countries": ["US", "CA"]
  }]
*/
  app.get('/archetypes', ensureAuth, getArchetypes);

  /**
 * @api {get} /archetypes/:address Read an Archetype
 * @apiName ReadArchetype
 * @apiGroup Archetypes
 *
 * @apiDescription Retrieves archetype information for a single Archetype.
 * This endpoint will return a `404` if:
 *    a. the archetype is not found, or
 *    b. the archetype is private and the authenticated user is not its author.
 * Note: if the password provided is incorrect or a hoard reference which
 * does not exist was passed to the posted archetype this get will return a `401`.
 *
 * @apiExample {curl} Simple:
 *     curl -i /archetypes/707791D3BBD4FDDE615D0EC4BB0EB3D909F66890
 *
 * @apiQueryParameter password The password to trigger the decryption key for an
 * opaque Archetype
 *
 * @apiSuccess {String} address Archetype's address
 * @apiSuccess {String} name Human readable name of the Archetype
 * @apiSuccess {String} author Controller contract of the user or organization
 * that created the Archetype
 * @apiSuccess {String} description Description of the archetype
 * @apiSuccess {Number} price Price of the archetype
 * @apiSuccess {Boolean} active Whether the Archetype can be used to create
 * new Active Agreements or not
 * @apiSuccess {Boolean} isPrivate Whether the encryption framework of the Archetype
 * is operational or not
 * @apiSuccess {String} successor Address of the successor archetype
 * @apiSuccess {Object[]} parameters The "name" and "type" of all custom parameters used
 * by the Archetype
 * @apiSuccess {Object[]} documents The "name", "hoardAddress" and "secretKey" (if any)
 * sufficient to provide the information regarding the relevant documents associated with
 * the Archetype
 * @apiSuccess {Object[]} jurisdictions The "country" and "regions" which the Archetype
 * has been registered as relevant to. The "country" is registered as an ISO standard
 * two character string and "regions" is an array of addresses relating to the controlling
 * contracts for the region (see [ISO standards manipulation](#) section).
 * @apiSuccess {Object[]} packages The "id" and "name" of each of the packages that the archetype has been added to
 * @apiSuccessExample {json} Success Object
  {
    "address": "707791D3BBD4FDDE615D0EC4BB0EB3D909F66890",
    "name": "TestType1",
    "author": "6EDC6101F0B64156ED867BAE925F6CD240635656",
    "description": "rental archetype",
    "price": 10,
    "active": false,
    "isPrivate": false,
    "successor": "ED867101F0B64156ED867BAE925F6CD2406350B6",
    "parameters": [{
        "name": "NumberOfTeenageDaughters",
        "type": 2,
        "label": "Number"
      },
      {
        "name": "ExitClause",
        "type": 1,
        "label": "String"
      }
    ],
    "documents": [{
      "name": "Dok1",
      "hoardAddress": "E73C56F6124813EF082D8CDD2C5EC63AFFF95E562F9BE65720C9F69E3B3541A0",
      "secretKey": "87A822883515B65247CBF5A2EE68AF72CB7C2B65B7103CB4340E0C1202FD325E"
    }],
    "jurisdictions": [{
        "country": "US",
        "regions": ["0304CA03C4E9DD0F9676A4463D42BCB686331A5361570D9BF7BC211C1BCA9F1E", "04E01B41ABD856ECAE38A06FB81005A911271B4BF483C10F31C539031C399101"]
      },
      {
        "country": "CA",
        "regions": ["0000000000000000000000000000000000000000000000000000000000000000"]
      }
    ],
    "packages": [{
      "id": "86401D45D372B3E036F91F7DDC87006E069AFCB96B3708B2FBA722D0672DDA7C",
      "name": "Drone Lease Package"
    }],
    "governingArchetypes": [{
      "address": "4EF5DAB8CE089AD7F2CE7A04A7CB5DB1C58DB707",
      "name": "NDA Archetype"
    }]
  }
*/
  app.get('/archetypes/:address', ensureAuth, getArchetype);

  /**
 * @api {post} /archetypes Create an Archetype
 * @apiName CreateArchetype
 * @apiGroup Archetypes
 *
 *
 * @apiExample {curl} Simple:
 *     curl -iX POST /archetypes
 *
 * @apiBodyParameter {String} name Human readable name of the Archetype (limit: 32 ASCII characters)
 * @apiBodyParameter {String} author Controller contract of the user or organization
 * that created the Archetype. Note that currently the author is forced to be the logged-in-user's address
 * since we do not yet have a review/approval process for changes made to an organization-authored archetype by a user who is part of that organization
 * @apiBodyParameter {String} description Short human readable description of the Archetype
 * @apiBodyParameter {Integer} price Price of the archetype, in cents (Optional- this field can be edited later through a `PUT` request to '/archetypes/:address/price')
 * @apiBodyParameter {Boolean} isPrivate **(Optional)** Whether the encryption framework of
 * the Archetype is operational or not
 * @apiBodyParameter {String} password A secret string which is used to trigger the encryption
 * system for the Archetype's documents
 * @apiBodyParameter {Object[]} parameters **(Optional)** The "name" (limit: 32 ASCII characters) and "type" of all custom parameters used
 * by the Archetype
 * @apiBodyParameter {Object[]} documents **(Optional)**  The "name", "hoardAddress" and "secretKey" (if any)
 * sufficient to provide the information regarding the relevant documents associated with
 * the Archetype
 * @apiBodyParameter {Object[]} jurisdictions The "country" and "regions" which the Archetype
 * has been registered as relevant to. The "country" is registered as an ISO standard
 * two character string and "regions" is an array of addresses relating to the controlling
 * contracts for the region (see [ISO standards manipulation](#) section).
 * @apiBodyParameter {String} formationProcessDefinition Address of the formation process definition
 * controller
 * @apiBodyParameter {String} executionProcessDefinition Address of the execution process definition
 * controller
 * @apiBodyParameter {String[]} governingArchetypes Array of contract addresses of the archetypes to govern this new one
 * of the rights and conditions of the contract
 * @apiBodyParameterExample {json} Success Object
{
  "name": "Archetype 2",
    "description": "Test Archetype",
    "price": "19.55",
    "isPrivate": 0,
  "password": "A Secret String",
    "parameters": [
      { "type": 8, "name": "Assignee", "signatory": true },
      { "type": 2, "name": "NumberOfTeenageDaughters" },
      { "type": 1, "name": "Exit Clause" }
    ],
    "documents": [
      {
        "name": "test&stuff.pdf",
        "hoardAddress": "e73c56f6124813ef082d8cdd2c5ec63afff95e562f9be65720c9f69e3b3541a0",
        "secretKey": "87a822883515b65247cbf5a2ee68af72cb7c2b65b7103cb4340e0c1202fd325e"
    },
    {
        "name": "Untitled document.docx",
        "hoardAddress": "1385440dd77393038d465314bb565d3fe8b7de2a97d122ddf4cbdb979716828e",
        "secretKey": "06b35f914ef79d3fe890693d5f8af4cc58674ceb729f5b29df1166fad9de4a63"
    }
  ],
    "jurisdictions": [
      {
      "country": "US",
        "regions": [
          "281BAF100FF362D83EB90B4C84F978390AA0B063080858DBCA94546629974832",
          "C45A6B6C560B1DD579D17FC80B8E320E9A400AE3CB7EF61EC0EA95A69302767F"
        ]
    }
  ],
    "formationProcessDefinition": "1671227FBC248B809F74D9BA29B4731F130BCD93",
    "executionProcessDefinition": "E6534E45E2B26AF4FBB64E42CE7FC66688696483",
    "governingArchetypes": ["ADB20020CE08E2DF5ABB3818590C3E2BA2035202"]
}

*
* @apiSuccess {json} The address of the created Archetype
* @apiSuccessExample {json} Success-Response:
{
  "address": "6EDC6101F0B64156ED867BAE925F6CD240635656"
}
*
* @apiUse NotLoggedIn
* @apiUse AuthTokenRequired
*/
  app.post('/archetypes', ensureAuth, createArchetype);

  /**
 * @api {put} /archetypes/:address/activate Activate an archetype
 * @apiName ActivateArchetype
 * @apiGroup Archetypes
 * @apiDescription Activates the archetype so that agreements can be created from it.
 * An archetype can only be activated by its author. This action will fail if the archetype
 * has a successor set.
 *
 * @apiExample {curl} Simple:
 *     curl -iX PUT /archetypes/6EDC6101F0B64156ED867BAE925F6CD240635656/activate
 *
 * @apiURLParameter address Archetype address
 *
 * @apiUse NotLoggedIn
 * @apiUse AuthTokenRequired
 */
  app.put('/archetypes/:address/activate', ensureAuth, activateArchetype);

  /**
 * @api {put} /archetypes/:address/successor/:successor Set successor for an archetype
 * @apiName SetArchetypeSuccessor
 * @apiGroup Archetypes
 * @apiDescription Sets the successor of given archetype. This action automatically
 * makes the archetype inactive. Note that an archetype cannot point to itself as its
 * successor. It also validates if this action will result in a circular dependency
 * between two archetypes. A succcessor may only be set by the author of the archetype.
 *
 * @apiExample {curl} Simple:
 *     curl -iX PUT /archetypes/6EDC6101F0B64156ED867BAE925F6CD240635656/successor/ED867101F0B64156ED867BAE925F6CD2406350B6
 *
 * @apiURLParameter address Archetype address
 * @apiURLParameter address Successor address
 *
 * @apiUse NotLoggedIn
 * @apiUse AuthTokenRequired
 */
  app.put('/archetypes/:address/successor/:successor', ensureAuth, setArchetypeSuccessor);

  /**
 * @api {put} /archetypes/:address/price Set price of an archetype
 * @apiName SetArchetypePrice
 * @apiGroup Archetypes
 * @apiDescription Sets the price of given archetype
 *
 * @apiExample {curl} Simple:
 *     curl -iX PUT /archetypes/6EDC6101F0B64156ED867BAE925F6CD240635656/price
 *
 * @apiURLParameter address Archetype address
 * @apiBodyParameter {Number} price Price of the archetype
 *
 * @apiUse NotLoggedIn
 * @apiUse AuthTokenRequired
 */
  app.put('/archetypes/:address/price', ensureAuth, setArchetypePrice);

  /**
 * @api {put} /archetypes/:address/deactivate Deactivate an archetype
 * @apiName DeactivateArchetype
 * @apiGroup Archetypes
 * @apiDescription Deactivates the archetype so that agreements cannot be created from it.
 * An archetype can only be deactivated by its author. Once an archetype is deactivated by
 * its author, it will not be included in `GET /archetypes`
 * responses made by users other than the author.
 *
 * @apiExample {curl} Simple:
 *     curl -iX PUT /archetypes/6EDC6101F0B64156ED867BAE925F6CD240635656/activate
 *
 * @apiURLParameter address Archetype address
 *
 * @apiUse NotLoggedIn
 * @apiUse AuthTokenRequired
 */
  app.put('/archetypes/:address/deactivate', ensureAuth, deactivateArchetype);

  /**
 * @api {get} /archetypes Read Archetype Packages
 * @apiName ReadArchetypePackages
 * @apiGroup Archetypes
 *
 * @apiDescription Retrieves archetype package information. Within the
 * Agreements Network, Archetype Packages are collections of archetypes that are
 * related in some way.
 * Returns all packages that are either public or authored by the authenticated user
 *
 * @apiExample {curl} Simple:
 *     curl -i /archetype-packages
 *
 * @apiSuccess {String} id Archetype Package id
 * @apiSuccess {String} name Human readable name of the Archetype Pacakge
 * @apiSuccess {String} author Controller contract of the user or organization
 * @apiSuccess {String} description Description of the package
 * @apiSuccess {Boolean} isPrivate Indicates whether the package can be read/used publicly
 * @apiSuccess {Boolean} active Indicates whether the package has been activated and available for creating collections with.
 * that created the package
 * @apiSuccessExample {json} Success Objects Array
  [{
    "id": "7F2CA849A318E7FA2473B3442B7AC86A84DD3AA054F567BCF5D27D9622FCD0BD",
    "name": "Package1",
    "description": "package description"
    "author": "6EDC6101F0B64156ED867BAE925F6CD240635656",
    "isPrivate": false,
    "active": true
  }]
*/
  app.get('/archetype-packages', ensureAuth, getArchetypePackages);

  /**
 * @api {get} /archetype-packages/:id Read an Archetype Package
 * @apiName ReadArchetypePackage
 * @apiGroup Archetypes
 *
 * @apiDescription Retrieves information for a single archetype package.
 * Returns a `404` if the package is private or not active and the authenticated user is not its author.
 * @apiExample {curl} Simple:
 *     curl -i /archetype-packages/7F2CA849A318E7FA2473B3442B7AC86A84DD3AA054F567BCF5D27D9622FCD0BD
 *
 * @apiSuccess {String} id Archetype Package id
 * @apiSuccess {String} name Human readable name of the Archetype Package
 * @apiSuccess {String} description Human readable description of the Archetype Package
 * @apiSuccess {String} author Controller contract of the user or organization
 * @apiSuccess {Boolean} isPrivate Indicates whether the package can be read/used publicly
 * @apiSuccess {Boolean} active Indicates whether the package has been activated and available for creating collections with.
 * @apiSuccess {Object[]} archetypes Array of archetypes with name, address, and active keys
 * that are included in the Archetype Package
 * @apiSuccessExample {json} Success Object
  {
    "id": "7F2CA849A318E7FA2473B3442B7AC86A84DD3AA054F567BCF5D27D9622FCD0BD",
    "name": "Package1",
    "description": "Package Description",
    "author": "6EDC6101F0B64156ED867BAE925F6CD240635656",
    "isPrivate": false,
    "active": true,
    "archetypes": [{
        "name": "Archetype 1",
        "address": "4156ED867BAE4156ED867BAE925F6CD240635656",
        "active": true
      },
      {
        "name": "Archetype 2",
        "address": "406356867BAE4156ED867BAE925F6CD240635656",
        "active": false
      }
    ]
  }
*/
  app.get('/archetype-packages/:package_key', ensureAuth, getArchetypePackage);

  /**
 * @api {post} /archetypes/packages Create an Archetype Package
 * @apiName CreateArchetypePackage
 * @apiGroup Archetypes
 *
 *
 * @apiExample {curl} Simple:
 *     curl -iX POST /archetype-packages
 *
 * @apiBodyParameter {String} name Human readable name of the Archetype Package
 * @apiBodyParameter {String} description Human readable description of the Archetype Package
 * @apiBodyParameter [String] author Controller contract of the user or organization. Will be set to the authenticated user's address if not provided.
 * that created the Archetype Package
 * @apiBodyParameter {Boolean} isPrivate Human readable description of the Archetype Package
 * @apiBodyParameter {Boolean} active Optional- will default to false
 *
 * @apiBodyParameterExample {json} Success Object
  {
    "name": "Drone Lease Package",
    "description": "Package of archetypes for leasing drones in US-NY",
    "author": "6EDC6101F0B64156ED867BAE925F6CD240635656",
    "isPrivate": false,
    "active": true
  }
*
* @apiSuccess {json} The id of the created Archetype Package
* @apiSuccessExample {json} Success-Response:
  {
    "id": "7F2CA849A318E7FA2473B3442B7AC86A84DD3AA054F567BCF5D27D9622FCD0BD"
  }
*
* @apiUse NotLoggedIn
* @apiUse AuthTokenRequired
*/
  app.post('/archetype-packages', ensureAuth, createArchetypePackage);

  /**
 * @api {put} /archetype-packages/:id/archetype/:address Add an archetype to a package
 * @apiName AddArchetypeToPackage
 * @apiGroup Archetypes
 *
 * @apiExample {curl} Simple:
 *     curl -iX PUT /archetype-packages/7F2CA849A318E7FA2473B3442B7AC86A84DD3AA054F567BCF5D27D9622FCD0BD/archetype/707791D3BBD4FDDE615D0EC4BB0EB3D909F66890
 *
 * @apiURLParameter address Archetype address
 * @apiURLParameter id Package Id
 *
 * @apiUse NotLoggedIn
 * @apiUse AuthTokenRequired
 */
  app.put('/archetype-packages/:packageId/archetype/:archetypeAddress', ensureAuth, addArchetypeToPackage);

  /**
 * @api {put} /archetype-packages/:id/activate Activate an archetype package
 * @apiName ActivateArchetypePackage
 * @apiGroup Archetypes
 * @apiDescription Activates the archetype package
 * An archetype package can only be activated by its author.
 *
 * @apiExample {curl} Simple:
 *     curl -iX PUT /archetype-packages/7F2CA849A318E7FA2473B3442B7AC86A84DD3AA054F567BCF5D27D9622FCD0BD/activate
 *
 * @apiURLParameter address Archetype package id
 *
 * @apiUse NotLoggedIn
 * @apiUse AuthTokenRequired
 */
  app.put('/archetype-packages/:id/activate', ensureAuth, activateArchetypePackage);

  /**
 * @api {put} /archetype-packages/:id/deactivate deactivate an archetype package
 * @apiName DeactivateArchetypePackage
 * @apiGroup Archetypes
 * @apiDescription Deactivates the archetype package
 * An archetype package can only be deactivated by its author. Once an archetype package is deactivated by
 * its author, it will not be included in `GET /archetype-packges` or `GET /archetype-packages/:id`
 * responses made by users other than the author.
 *
 * @apiExample {curl} Simple:
 *     curl -iX PUT /archetype-packages/7F2CA849A318E7FA2473B3442B7AC86A84DD3AA054F567BCF5D27D9622FCD0BD/deactivate
 *
 * @apiURLParameter address Archetype package id
 *
 * @apiUse NotLoggedIn
 * @apiUse AuthTokenRequired
 */
  app.put('/archetype-packages/:id/deactivate', ensureAuth, deactivateArchetypePackage);

  /* ***********
  * Agreements
  *********** */

  /**
 * @api {get} /agreements Read Agreements
 * @apiName ReadAgreements
 * @apiGroup Agreements
 *
 * @apiDescription Retrieves Active Agreement information of agreements that are public, or
 * if the `forCurrentUser` query is set to `true`,
 *    a) are authored by the authenticated user,
 *    b) are authored by an organization to which the authenticated user belongs,
 *    c) include the authenticated user in its signatories, or
 *    d) include an organization to which the authenticated user belongs in its signatories
 *
 * @apiExample {curl} Simple:
 *     curl -i /agreements
 *
 * @apiParam {Boolean} [forCurrentUser]  Optional query string parameter to get all agreements pertaining to the currently logged in user
 * @apiSuccess {String} address Active Agreement's address
 * @apiSuccess {String} name Human readable name of the Active Agreement
 * @apiSuccess {String} archetype Address of the parent Archetype of the Active Agreement
 * @apiSuccess {Boolean} isPrivate Whether the encryption framework of the Active Agreement
 * is operational or not
 * @apiSuccess {Number} numberOfParties The number of parties agreeing to the Active Agreement
 * @apiSuccess {String} hoardAddress The hoard content-addressable storage address of the Active Agreement
 * @apiSuccess {String} hoardSecret The hashed hoard secret key
 * @apiSuccessExample {json} Success Objects Array
       [{
         "address": "4AD3C4FA34C8EC5FFBCC4924C2AB16DF72F1EBB8",
         "archetype": "4EF5DAB8CE089AD7F2CE7A04A7CB5DB1C58DB707",
         "name": "Drone Lease",
         "creator": "AB3399395E9CAB5434022D1992D31BB3ACC2E3F1",
         "hoardAddress": "0000000000000000000000000000000000000000000000000000000000000000",
         "hoardSecret": "0000000000000000000000000000000000000000000000000000000000000000",
         "eventLogHoardAddress": "0000000000000000000000000000000000000000000000000000000000000000",
         "eventLogHoardSecret": "0000000000000000000000000000000000000000000000000000000000000000",
         "maxNumberOfEvents": 10,
         "isPrivate": 1,
         "legalState": 1,
         "formationProcessInstance": "038725D6437A809D536B9417047EC74E7FF4D1C0",
         "executionProcessInstance": "0000000000000000000000000000000000000000",
         "numberOfParties": 2
       }]
  *
  * @apiUse NotLoggedIn
  * @apiUse AuthTokenRequired
  *
  */
  app.get('/agreements', ensureAuth, getAgreements);

  /**
 * @api {get} /agreements/:address Read an Agreement
 * @apiName ReadAgreement
 * @apiGroup Agreements
 *
 * @apiDescription Retrieves Active Agreement information for a single Agreement.
 * Notes:
 * - If the password provided is incorrect or a hoard reference which
 * does not exist was passed to the posted Active Agreement this get will return a `401`.
 * - If the agreement was not authored by the logged in user or one of their organizations, or
 * if its signatories does not include the logged in user or one of their organizations,
 * this will return a `404`.
 *
 * @apiExample {curl} Simple:
 *     curl -i /agreements/707791D3BBD4FDDE615D0EC4BB0EB3D909F66890
 *
 * @apiQueryParameter password The password to trigger the decryption key for an
 * opaque Agreement
 *
 * @apiSuccess {String} address Active Agreement's address
 * @apiSuccess {String} name Human readable name of the Active Agreement
 * @apiSuccess {String} archetype Address of the parent Archetype of the Active Agreement
 * @apiSuccess {Boolean} isPrivate Whether the encryption framework of the Active Agreement
 * is operational or not
 * @apiSuccess {String} eventLogHoardAddress Hoard address of where event log is stored
 * @apiSuccess {String} eventLogHoardSecret Hoard secret of where event log is stored
 * @apiSuccess {Number} maxNumberOfEvents Max number of fulfillment events that can be stored in the event log
 * @apiSuccess {Number} legalState Legal state of the agreement
 * @apiSuccess {Number} formationProcessInstance Address of the agreement's formation process instance
 * @apiSuccess {Number} executionProcessInstance Address of the agreement's execution process instance
 * @apiSuccess {String} collectionId Id of the collection the agreement belongs to
 * @apiSuccess {Object[]} parties An array of objects with each party member's address,
 * user id or organization name, signature timestamp, and address of the user that has signed for the party
 * @apiSuccess {Object[]} parameters The "parameter-name" and values of the parameters.
 * @apiSuccess {Object[]} governingAgreements An array of the governing agreements with the `address`, `name`, and `isPrivate` value of each
 * @apiSuccessExample {json} Success Object
       {
         "address": "9F24307DA7E74BC54D1E829764E2DE7AD0D8DF6E",
         "name": "Agreement",
         "archetype": "707791D3BBD4FDDE615D0EC4BB0EB3D909F66890",
         "isPrivate": false,
         "eventLogHoardAddress": "0000000000000000000000000000000000000000000000000000000000000000",
         "eventLogHoardSecret": "0000000000000000000000000000000000000000000000000000000000000000",
         "maxNumberOfEvents": 0,
         "legalState": 1,
         "formationProcessInstance": "413AC7610E6A4E0ACEB29596FFC52D243A2E7CD7",
         "executionProcessInstance": "0000000000000000000000000000000000000000",
         "collectionId": "9FBC54D1E8224307DA7E74BC54D1E829764E2DE7AD0D8DF6EBC54D1E82ADBCFF",
         "parties": [
           "address": "A072341D3BBD4FDD3CD5D0EBADB0EB37887E3311",
           "organizationName": "Drones Delight"
           "signatureTimestamp": 1529588821427,
           "completedBy": "BE98345FEDCD465D0EBADB0EB3789F234ECBD"
         ],
         "parameters": {
           "parameterName": "parameterValue",
           ...
         },
        "governingAgreements": [
            {
                "address": "B3AEAD4717EFF80BDDF5E22110521029A8460FFB",
                "name": "Governing Agreement",
                "isPrivate": false
            }
        ]
      }
  *
  * @apiUse NotLoggedIn
  * @apiUse AuthTokenRequired
  *
  */
  app.get('/agreements/:address', ensureAuth, getAgreement);

  /**
 * @api {post} /agreements Create an Agreement
 * @apiName CreateAgreement
 * @apiGroup Agreements
 *
 * @apiExample {curl} Simple:
 *     curl -iX POST /agreements
 *
 * @apiBodyParameter {String} name Human readable name of the Active Agreement (limit: 32 ASCII characters)
 * @apiBodyParameter {String} archetype Address of the parent Archetype of the Active Agreement
 * @apiBodyParameter {Boolean} isPrivate Whether the encryption framework of the Active Agreement
 * is operational or not
 * @apiBodyParameter {String} password A secret string which is used to trigger the encryption
 * system for the Active Agreements's documents
 * @apiBodyParameter {Integer} maxNumberOfEvents The maximum number of fulfillment events to be logged on the Active Agreement
 * @apiBodyParameter {String[]} parties The addresses of the parties to the Active Agreement
 * @apiBodyParameter {Object[]} parameters The "custom-field-name" and values of the parameters.
 * Note- If a parameter with type 8 (Signing Party) is given, the corresponding value will be added to the agreement's parties.
 * @apiBodyParameter {String[]} governingAgreements If parent archetype has any governing archetypes, agreements for each one must
 * already exist, and their addresses should be given here.
 * @apiBodyParameterExample {json} Success Object
    {
      "name": "Agreement",
      "archetype": "707791D3BBD4FDDE615D0EC4BB0EB3D909F66890",
      "isPrivate": false,
      "password": "secret password"
      "maxNumberOfEvents": "10",
      "parties": ["36ADA22D3A4B841EFB73414CD97C35C0A660C1C2"],
      "parameters": [{
          "name": "Buyer",
          "type": 8,
          "value": "BE98345FEDCD465D0EBADB0EB3789F234ECBD"
        },
        {
          "name": "Quantity",
          "value": 10
        }
      ],
      "governingAgreements": ["B3AEAD4717EFF80BDDF5E22110521029A8460FFB"]
    }
  *
  *
  @apiSuccess {
    json
  }
  The address of the created Agreement *
    @apiSuccessExample {
      json
    }
  Success - Response: {
    "address": "6EDC6101F0B64156ED867BAE925F6CD240635656"
  }
*
*
* @apiUse NotLoggedIn
* @apiUse AuthTokenRequired
*/
  app.post('/agreements', ensureAuth, createAgreement);

  /**
 * @api {put} /agreements/:address/events Add a Fulfillment Event to an Agreement
 * @apiName updateAgreementEventLog
 * @apiGroup Agreements
 *
 * @apiExample {curl} Simple:
 *     curl -iX POST /agreements/707791D3BBD4FDDE615D0EC4BB0EB3D909F66890/events -d '{"eventName":"eventName"}'
 *
 * @apiURLParameter address Agreement address
 * @apiBodyParameter eventName Human readable name of the fulfillment event
 * @apiBodyParameter {String} content Description of the fulfillment event
 * @apiBodyParameterExample {json} Success Object
  {
    "eventName": "Name of Event",
    "content": "A description about the event.",
  }
*
* @apiSuccess {String} address The hoard address of the updated event log
* @apiSuccess {String} secretKey The hoard secret key of the updated event log
* @apiSuccess {String} salt The hoard salt of the updated event log
* @apiSuccessExample {json} Success Object
  {
    "address": "9F24307DA7E74BC54D1E829764E2DE7AD0D8DF6E",
    "secretKey": ABCDEF0123456789ABCDEF0123456789,
    "salt": ""
  }
*
* @apiUse NotLoggedIn
* @apiUse AuthTokenRequired
*/
  app.put('/agreements/:address/events', ensureAuth, updateAgreementEventLog);

  /**
 * @api {put} /agreements Sign an Agreement
 * @apiName signAgreement
 * @apiGroup Agreements
 * @apiDescription Signs an agreement by the authenticated user
 *
 * @apiExample {curl} Simple:
 *     curl -iX PUT /agreements/707791D3BBD4FDDE615D0EC4BB0EB3D909F66890/sign
 *
 * @apiURLParameter address Agreement address
 * @apiUse NotLoggedIn
 * @apiUse AuthTokenRequired
 */
  app.put('/agreements/:address/sign', ensureAuth, signAgreement);

  /**
 * @api {put} /agreements Cancel an Agreement
 * @apiName cancelAgreement
 * @apiGroup Agreements
 * @apiDescription Cancels an agreement if the authenticated user is a member of the agreement parties,
 * or a member of an organization that is an agreement party
 *
 * @apiExample {curl} Simple:
 *     curl -iX PUT /agreements/707791D3BBD4FDDE615D0EC4BB0EB3D909F66890/cancel
 *
 * @apiURLParameter address Agreement address
 * @apiUse NotLoggedIn
 * @apiUse AuthTokenRequired
 */
  app.put('/agreements/:address/cancel', ensureAuth, cancelAgreement);

  /**
 * @api {get} /agreement-collections Read Agreement Collections
 * @apiName ReadAgreementCollections
 * @apiGroup Agreements
 *
 * @apiDescription Retrieves Active Agreement Collection information where the author is the authenticated user,
 * or the organization the user is a member of.
 *
 * @apiExample {curl} Simple:
 *     curl -i /agreement-collections
 *
 * @apiSuccess {String} id Active Agreement Collection id
 * @apiSuccess {String} name Human readable name of the Active Agreement Collection
 * @apiSuccess {String} author Address of the creator (user account or org)
 * @apiSuccess {Number} collectionType Type of collection
 * @apiSuccess {String} packageId The packageId of the archetype package from which the collection was created.
 * @apiSuccessExample {json} Success Objects Array
  [{
    "id": "9FBC54D1E8224307DA7E74BC54D1E829764E2DE7AD0D8DF6EBC54D1E82ADBCFF",
    "name": "Agreement Collection 1",
    "author": "707791D3BBD4FDDE615D0EC4BB0EB3D909F66890",
    "collectionType": 2,
    "packageId": "7F2CA849A318E7FA2473B3442B7AC86A84DD3AA054F567BCF5D27D9622FCD0BD"
  }]
*
* @apiUse NotLoggedIn
* @apiUse AuthTokenRequired
*
*/
  app.get('/agreement-collections', ensureAuth, getAgreementCollections);

  /**
 * @api {get} /agreement-collections/:id Read an Agreement Collection
 * @apiName ReadAgreementCollection
 * @apiGroup Agreements
 *
 * @apiDescription Retrieves information for a single Agreement Collection if the author is the authenticated user
 * or the organization the user is a member of.
 *
 * @apiExample {curl} Simple:
 *     curl -i /agreement-collections/7F2CA849A318E7FA2473B3442B7AC86A84DD3AA054F567BCF5D27D9622FCD0BD
 *
 * @apiSuccess {String} id Agreement Collection id
 * @apiSuccess {String} name Human readable name of the Agreement Collection
 * @apiSuccess {String} author Controller contract of the user or organization
 * @apiSuccess {Number} collectionType Type of collection
 * @apiSuccess {String} packageId The packageId of the archetype package from which the collection was created
 * @apiSuccess {Object[]} agreements Array of agreement objects included in the collection
 * @apiSuccessExample {json} Success Object
  {
    "id": "7F2CA849A318E7FA2473B3442B7AC86A84DD3AA054F567BCF5D27D9622FCD0BD",
    "name": "Agreement Collection 1",
    "author": "707791D3BBD4FDDE615D0EC4BB0EB3D909F66890",
    "collectionType": 2,
    "packageId": "9FBC54D1E8224307DA7E74BC54D1E829764E2DE7AD0D8DF6EBC54D1E82ADBCFF",
    "agreements": [{
      "name": "Agreement 1",
      "address": "E615D0EC4BB0EDDE615D0EC4BB0EB3D909F66890",
      "archetype": "42B7AC86A84DD3AA054F567BCF5D27D9622FCD0B"
    }]
  }
*/
  app.get('/agreement-collections/:id', ensureAuth, getAgreementCollection);

  /**
 * @api {get} /agreement-collections Create a Agreement Collection
 * @apiName CreateAgreementCollection
 * @apiGroup Agreements
 *
 * @apiDescription Creates an Active Agreement Collection.
 *
 * @apiExample {curl} Simple:
 *     curl -iX POST /agreement-collections
 *
 * @apiSuccess {String} name Active Agreement Collection name
 * @apiSuccess {String} author Address of the creator (user account or org), logged in user address will be used if none supplied
 * @apiSuccess {Number} collectionType Type of collection
 * @apiSuccess {String} packageId The packageId of the archetype package from which the collection was created
 * @apiBodyParameterExample {json} Success Object
    {
      "name": "Rental Collection",
      "collectionType": 2,
      "packageId": "7F2CA849A318E7FA2473B3442B7AC86A84DD3AA054F567BCF5D27D9622FCD0BD",
    }
  *
 * @apiSuccessExample {json} Success Object
  {
    "id": "9FBC54D1E8224307DA7E74BC54D1E829764E2DE7AD0D8DF6EBC54D1E82ADBCFF"
  }
*
* @apiUse NotLoggedIn
* @apiUse AuthTokenRequired
*
*/
  app.post('/agreement-collections', ensureAuth, createAgreementCollection);

  /**
 * @api {put} /agreement-collections Add an agreement to a collection
 * @apiName AddAgreementToCollection
 * @apiGroup Agreements
 *
 * @apiExample {curl} Simple:
 *     curl -iX PUT /agreement-collections/7F2CA849A318E7FA2473B3442B7AC86A84DD3AA054F567BCF5D27D9622FCD0BD
 *
 * @apiBodyParameter {String} agreement Address of the agreement to add
 * @apiBodyParameter {String} collectionId Id of the collection to add to
 *
 * @apiUse NotLoggedIn
 * @apiUse AuthTokenRequired
 */
  app.put('/agreement-collections', ensureAuth, addAgreementToCollection);
};
