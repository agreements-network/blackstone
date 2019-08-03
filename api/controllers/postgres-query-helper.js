const boom = require('@hapi/boom');
const {
  where,
  getSHA256Hash,
} = require(`${global.__common}/controller-dependencies`);
const { DEFAULT_DEPARTMENT_ID, AGREEMENT_PARTIES } = global.__constants;
const logger = require(`${global.__common}/logger`);
const log = logger.getLogger('queries');
const pool = require(`${global.__common}/postgres-db`);

const { app: appDb, chain: chainDb } = global.db.schema;

const QUERIES = {
  insertUser: `INSERT INTO ${appDb}.users(address, username, first_name, last_name, email, password_digest, is_producer) 
    VALUES($1, $2, $3, $4, $5, $6, $7) RETURNING id;`,

  insertOrganization: `INSERT INTO ${appDb}.organizations(address, name) VALUES($1, $2) RETURNING id;`,

  updateOrganization: `UPDATE ${appDb}.organizations SET address = $2, name = $3 WHERE id = $1 OR ($1 IS NULL AND address = $2);`,

  userIsOrganizationApprover: `SELECT (
      $1 IN (
        SELECT approver_address
        FROM ${chainDb}.organization_approvers oa
        WHERE oa.organization_address = $2
      )
    ) AS "isApprover"
    FROM ${chainDb}.organization_approvers;`,

  userStatusInOrganization: `
    SELECT $1 IN (
      SELECT approver_address
      FROM ${chainDb}.organization_approvers oa
      WHERE oa.organization_address = $2
    ) AS "isApprover", $1 IN (
      SELECT user_address
      FROM ${chainDb}.organization_users ou
      WHERE ou.organization_address = $2
    ) AS "isMember"
    FROM ${chainDb}.organization_accounts;`,

  getOrganization: `SELECT o.organization_address AS address, UPPER(encode(o.organization_id::bytea, 'hex')) AS "organizationKey",
    od.name, oa.approver_address AS approver, approver_details.username AS "approverName",
    ou.user_address AS user, member_details.username AS "userName",
    UPPER(dd.id) AS department, dd.name AS "departmentName", du.user_address AS "departmentUser"
    FROM ${chainDb}.organization_accounts o
    JOIN ${chainDb}.organization_approvers oa ON (o.organization_address = oa.organization_address)
    LEFT JOIN ${chainDb}.organization_users ou ON (o.organization_address = ou.organization_address)
    JOIN ${appDb}.organizations od ON (o.organization_address = od.address)
    LEFT JOIN ${appDb}.department_details dd ON (o.organization_address = dd.organization_address)
    LEFT JOIN ${chainDb}.department_users du ON (UPPER(dd.id) = UPPER(encode(du.department_id::bytea, 'hex'))) AND (du.user_address = ou.user_address) AND (dd.organization_address = du.organization_address)
    LEFT JOIN ${appDb}.users member_details ON (ou.user_address = member_details.address)
    LEFT JOIN ${appDb}.users approver_details ON (oa.approver_address = approver_details.address)
    WHERE o.organization_address = $1;`,

  getProfile: `SELECT u.user_account_address AS address, UPPER(encode(o.organization_id::bytea, 'hex')) AS "organizationKey",
    od.name AS "organizationName", ou.organization_address as organization, UPPER(dd.id) AS department, dd.name AS "departmentName"
    FROM ${chainDb}.user_accounts u LEFT JOIN ${chainDb}.organization_users ou ON u.user_account_address = ou.user_address
    LEFT JOIN ${chainDb}.organization_accounts o ON o.organization_address = ou.organization_address
    LEFT JOIN ${appDb}.organizations od ON od.address = o.organization_address
    LEFT JOIN ${appDb}.department_details dd ON ou.organization_address = dd.organization_address
    LEFT JOIN ${chainDb}.department_users du ON (UPPER(dd.id) = UPPER(encode(du.department_id::bytea, 'hex')) AND du.user_address = ou.user_address AND ou.organization_address = du.organization_address)
    WHERE u.user_account_address = $1;`,

  getCountries: `SELECT m49, name, alpha2, alpha3 FROM ${chainDb}.countries`,

  getCountryByAlpha2Code: `SELECT m49, name, alpha2, alpha3 FROM ${chainDb}.countries WHERE alpha2 = $1`,

  getRegionsOfCountry: `SELECT country, encode(region::bytea, 'hex') AS region, code2, code3, name FROM ${chainDb}.regions WHERE country = $1`,

  getCurrencies: `SELECT alpha3, m49, name FROM ${chainDb}.currencies`,

  getCurrencyByAlpha3Code: `SELECT alpha3, m49, name FROM ${chainDb}.currencies WHERE alpha3 = $1`,

  getParameterType: `SELECT CAST(parameter_type AS INTEGER) AS "parameterType", label FROM ${chainDb}.parameter_types WHERE parameter_type = $1`,

  getParameterTypes: `SELECT CAST(parameter_type AS INTEGER) AS "parameterType", label FROM ${chainDb}.parameter_types`,

  getArchetypeData: `
    WITH membered AS (
      SELECT organization_address
      FROM ${chainDb}.organization_users ou
      WHERE ou.user_address = $2
    )

    SELECT a.archetype_address as address, ad.name, a.author, a.owner,
    authors.username AS "authorDisplayName", owners.name AS "ownerDisplayName",
    ad.description, a.price, a.active, a.is_private as "isPrivate",
    (a.owner = $1 OR a.owner IN (SELECT * FROM membered)) AS "isOwner"
    FROM ${chainDb}.archetypes a
    JOIN ${appDb}.archetype_details ad ON a.archetype_address = ad.address
    LEFT JOIN ${appDb}.users authors ON authors.address = a.author
    LEFT JOIN (
      SELECT username AS name, address FROM ${appDb}.users
      UNION
      SELECT name, address FROM ${appDb}.organizations
    ) owners ON owners.address = a.owner
    WHERE
    a.archetype_address = $1 AND (
      (a.is_private = FALSE AND a.active = TRUE) OR (a.owner = $2 OR a.owner IN (SELECT * FROM membered))
    );`,

  getArchetypeDataWithProcessDefinitions: `
    WITH membered AS (
      SELECT organization_address
      FROM ${chainDb}.organization_users ou
      WHERE ou.user_address = $2
    )
    SELECT a.archetype_address as address, ad.name, a.author, a.owner, ad.description, a.price, a.active, a.is_private as "isPrivate",
    authors.username AS "authorDisplayName", owners.name AS "ownerDisplayName",
    a.successor, a.formation_process_definition as "formationProcessDefinition", a.execution_process_definition as "executionProcessDefinition", 
    d.process_name AS "formationProcessName", e.process_name AS "executionProcessName",
    d.model_id as "formationModelId", e.model_id as "executionModelId", 
    d.model_address as "formationModelAddress", e.model_address as "executionModelAddress", 
    d.id as "formationProcessId", e.id as "executionProcessId",
    (a.owner = $2 OR a.owner IN (SELECT * FROM membered)) AS "isOwner"
    FROM ${chainDb}.archetypes a 
    LEFT JOIN (SELECT pd.id, pdet.process_name, pd.interface_id, pd.model_address, pd.model_id, pd.process_definition_address FROM ${chainDb}.process_definitions pd JOIN ${appDb}.process_details pdet ON pd.model_id = pdet.model_id AND pd.id = pdet.process_id) d ON a.formation_process_definition = d.process_definition_address
    LEFT JOIN (SELECT pd.id, pdet.process_name, pd.interface_id, pd.model_address, pd.model_id, pd.process_definition_address FROM ${chainDb}.process_definitions pd JOIN ${appDb}.process_details pdet ON pd.model_id = pdet.model_id AND pd.id = pdet.process_id) e ON a.execution_process_definition = e.process_definition_address
    LEFT JOIN ${appDb}.users authors ON authors.address = a.author
    LEFT JOIN (
      SELECT username AS name, address FROM ${appDb}.users
      UNION
      SELECT name, address FROM ${appDb}.organizations
    ) owners ON owners.address = a.owner
    JOIN ${appDb}.archetype_details ad ON a.archetype_address = ad.address 
    WHERE archetype_address = $1 AND (
      (a.is_private = FALSE AND a.active = TRUE) OR (a.owner = $2 OR a.owner IN (SELECT * FROM membered))
    );`,

  getArchetypeParameters: `SELECT ap.parameter_name AS name, ap.parameter_type AS type, pt.label AS label 
    FROM ${chainDb}.archetype_parameters ap
    JOIN ${chainDb}.parameter_types pt on ap.parameter_type = pt.parameter_type WHERE archetype_address = $1
    ORDER BY ap.position`,

  getArchetypeJurisdictionsAll: `SELECT DISTINCT archetype_address AS address, country FROM ${chainDb}.archetype_jurisdictions`,

  getArchetypeJurisdictions: `SELECT country, encode(region::bytea, 'hex') AS region FROM ${chainDb}.archetype_jurisdictions WHERE archetype_address = $1`,

  getArchetypeDocuments: `SELECT document_reference AS "grant" FROM ${chainDb}.archetype_documents WHERE archetype_address = $1;`,

  getPackagesOfArchetype: `SELECT UPPER(encode(ap.package_id::bytea, 'hex')) AS id, pd.name
    FROM ${chainDb}.archetype_to_package ap
    JOIN ${appDb}.package_details pd ON UPPER(encode(ap.package_id::bytea, 'hex')) = pd.id
    JOIN ${chainDb}.archetype_packages p ON ap.package_id = p.package_id
    WHERE ap.archetype_address = $1;`,

  getGoverningArchetypes: `SELECT governing_archetype_address as address, ad.name
    FROM ${chainDb}.governing_archetypes ga
    JOIN ${appDb}.archetype_details ad ON ga.governing_archetype_address = ad.address
    WHERE archetype_address = $1;`,

  getArchetypePackage: `SELECT UPPER(encode(package_id::bytea, 'hex')) AS id, pd.name, pd.description, p.author,
    p.is_private as "isPrivate", p.active, (p.author = $1) AS "isOwner"
    FROM ${chainDb}.archetype_packages p 
    JOIN ${appDb}.package_details pd ON UPPER(pd.id) = UPPER(encode(package_id::bytea, 'hex')) 
    WHERE ((is_private = FALSE AND active = TRUE) OR author = $1) AND 
    package_id = $2;`,

  getArchetypesInPackage: `SELECT ad.name, a.archetype_address as address, a.active FROM ${chainDb}.archetypes a 
    JOIN ${chainDb}.archetype_to_package ap ON a.archetype_address = ap.archetype_address 
    JOIN ${appDb}.archetype_details ad ON a.archetype_address = ad.address 
    WHERE ap.package_id = $1`,

  getAgreementParties: `SELECT parties.party AS address, parties.signature_timestamp::integer AS "signatureTimestamp",
    parties.signed_by AS "signedBy", COALESCE(party.username, party.name) AS "partyDisplayName",
    signer.username AS "signedByDisplayName", canceler.username AS "canceledByDisplayName",
    parties.cancelation_timestamp::integer AS "cancelationTimestamp", parties.canceled_by AS "canceledBy",
    UPPER(encode(scopes.fixed_scope, 'hex')) AS scope, 
    UPPER(encode(o.organization_id::bytea, 'hex')) AS "organizationKey",
    dd.name AS "scopeDisplayName"
    FROM ${chainDb}.agreement_to_party parties
    LEFT JOIN (SELECT username, NULL AS name, address, external_user FROM ${appDb}.users
      UNION
      SELECT NULL AS username, name, address, FALSE AS external_user FROM ${appDb}.organizations
    ) party ON parties.party = party.address
    LEFT JOIN ${appDb}.users signer ON parties.signed_by = signer.address
    LEFT JOIN ${appDb}.users canceler ON parties.canceled_by = canceler.address
    LEFT JOIN ${chainDb}.entities_address_scopes scopes ON (
      scopes.entity_address = parties.agreement_address 
      AND scopes.scope_address = parties.party 
      AND scopes.scope_context = $2
    )
    LEFT JOIN ${chainDb}.organization_accounts o ON o.organization_address = parties.party 
    LEFT JOIN ${appDb}.department_details dd ON dd.organization_address = o.organization_address AND UPPER(encode(scopes.fixed_scope, 'hex')) = UPPER(dd.id)
    WHERE parties.agreement_address = $1;`,

  getGoverningAgreements: `SELECT governing_agreement_address as address, ad.name
    FROM ${chainDb}.governing_agreements ga
    JOIN ${appDb}.agreement_details ad ON ga.governing_agreement_address = ad.address
    WHERE agreement_address = $1;`,

  getAgreementCollections: `SELECT UPPER(encode(collection_id::bytea, 'hex')) as "id", cd.name, author, collection_type::integer as "collectionType", UPPER(encode(package_id::bytea, 'hex')) as "packageId" 
    FROM ${chainDb}.agreement_collections c 
    JOIN ${appDb}.collection_details cd ON UPPER(cd.id) = UPPER(encode(collection_id::bytea, 'hex')) 
    WHERE author = $1 OR author IN (SELECT organization_address FROM ${chainDb}.organization_users WHERE user_address = $2)`,

  getAgreementCollectionData: `SELECT UPPER(encode(c.collection_id::bytea, 'hex')) as id, cd.name, c.author, c.collection_type::integer as "collectionType",
    UPPER(encode(c.package_id::bytea, 'hex')) as "packageId",
    ac.agreement_address as "agreementAddress", ad.name as "agreementName", agr.archetype_address as archetype
    FROM ${chainDb}.agreement_collections c
    LEFT JOIN ${chainDb}.agreement_to_collection ac ON ac.collection_id = c.collection_id
    LEFT JOIN ${chainDb}.agreements agr ON agr.agreement_address = ac.agreement_address
    JOIN ${appDb}.collection_details cd ON UPPER(cd.id) = UPPER(encode(c.collection_id::bytea, 'hex')) 
    LEFT JOIN ${appDb}.agreement_details ad ON ad.address = ac.agreement_address
    WHERE c.collection_id = $1;`,

  getModels: `SELECT model_address as "modelAddress", 
    id, author, is_private as "isPrivate", active,
    model_file_reference as "modelFileReference",
    CAST(version_major AS INTEGER) AS "versionMajor",
    CAST(version_minor AS INTEGER) AS "versionMinor",
    CAST(version_patch AS INTEGER) AS "versionPatch"
    FROM ${chainDb}.process_models WHERE is_private = $1 OR author = $2;`,

  getApplications: `SELECT (encode(a.application_id::bytea, 'hex')) AS id, a.application_type as "applicationType", a.location, encode(a.web_form::bytea, 'hex') as "webForm",
    encode(aap.access_point_id::bytea, 'hex') as "accessPointId", aap.data_type as "dataType", aap.direction
    FROM ${chainDb}.applications a 
    LEFT JOIN ${chainDb}.application_access_points aap ON aap.application_id = a.application_id`,

  getDataMappingsForActivity: `SELECT dm.data_mapping_id AS "dataMappingId", dm.data_path AS "dataPath", COALESCE(NULLIF(dm.data_storage_id, ''), 'PROCESS_INSTANCE') AS "dataStorageId", dm.direction::integer,
    pmd.parameter_type::integer AS "parameterType", UPPER(encode(scopes.fixed_scope, 'hex')) AS scope
    FROM ${chainDb}.activity_instances ai
    JOIN ${chainDb}.process_instances pi ON ai.process_instance_address = pi.process_instance_address
    JOIN ${chainDb}.process_definitions pd ON pi.process_definition_address = pd.process_definition_address
    JOIN ${chainDb}.process_model_data pmd ON pd.model_address = pmd.model_address
    JOIN ${chainDb}.data_mappings dm ON (
      ai.activity_id = dm.activity_id AND
      pd.process_definition_address = dm.process_definition_address AND
      pmd.data_id = COALESCE(NULLIF(dm.data_storage_id, ''), 'PROCESS_INSTANCE') AND
      pmd.data_path = dm.data_path
    )
    LEFT JOIN ${chainDb}.entities_address_scopes scopes ON (
      ai.process_instance_address = scopes.entity_address AND 
      ai.activity_id = scopes.scope_context AND
      pmd.data_id = COALESCE(NULLIF(scopes.data_storage_id, ''), 'PROCESS_INSTANCE') AND
      pmd.data_path = scopes.data_path
    )
    WHERE UPPER(encode(ai.activity_instance_id::bytea, 'hex')) = $1`,

  getProcessModelData: `SELECT model_address as "modelAddress", id, author, is_private as "isPrivate", active, model_file_reference as "modelFileReference", version_major as "versionMajor", version_minor as "versionMinor", version_patch as "versionPatch" 
    FROM ${chainDb}.process_models pm WHERE pm.model_address = $1;`,

  getArchetypeModelFileReference: `SELECT fpd.id AS "formationProcessId", epd.id AS "executionProcessId",
    fpm.model_file_reference AS "formationModelFileReference", epm.model_file_reference AS "executionModelFileReference"
    FROM ${chainDb}.archetypes a
    LEFT JOIN ${chainDb}.process_definitions fpd on fpd.process_definition_address = a.formation_process_definition
    LEFT JOIN ${chainDb}.process_definitions epd on epd.process_definition_address = a.execution_process_definition
    LEFT JOIN ${chainDb}.process_models fpm ON fpm.model_address = fpd.model_address
    LEFT JOIN ${chainDb}.process_models epm ON epm.model_address = epd.model_address
    WHERE a.archetype_address = $1;`,

  getActivityDetailsFromCache: `SELECT activity_name as "activityName", process_name as "processName" FROM ${appDb}.activity_details WHERE activity_id = $1 AND process_id = $2 AND model_id = $3`,

  saveActivityDetails: `INSERT INTO ${appDb}.activity_details (model_id, process_id, process_name, activity_id, activity_name) VALUES($1, $2, $3, $4, $5) 
    ON CONFLICT ON CONSTRAINT activity_details_pkey DO UPDATE SET activity_name = $5`,

  getProcessDetailsFromCache: `SELECT process_id as "processDefinitionId", process_name as "processName" FROM ${appDb}.process_details WHERE model_id = $1 AND process_id = $2;`,

  saveProcessDetails: `INSERT INTO ${appDb}.process_details (model_id, process_id, process_name) VALUES($1, $2, $3) 
    ON CONFLICT ON CONSTRAINT process_details_pkey DO UPDATE SET process_name = $3`,

  getUserByActivationCode: `SELECT u.address, u.id as "userId" FROM ${appDb}.user_activation_requests uar JOIN ${appDb}.users u ON uar.user_id = u.id WHERE activation_code_digest = $1`,

  updateUserActivation: `UPDATE ${appDb}.users SET activated = $1 WHERE address = $2`,

  deleteUserActivationCode: `DELETE FROM ${appDb}.user_activation_requests WHERE user_id = $1 AND activation_code_digest = $2`,

  getDbUserIdByAddress: `SELECT id FROM ${appDb}.users WHERE address = $1`,

  insertArchetypeDetails: `INSERT INTO ${appDb}.archetype_details(address, name, description) VALUES($1, $2, $3)`,

  insertAgreementDetails: `INSERT INTO ${appDb}.agreement_details(address, name) VALUES($1, $2)`,

  insertPackageDetails: `INSERT INTO ${appDb}.package_details(id, name, description) VALUES($1, $2, $3)`,

  insertCollectionDetails: `INSERT INTO ${appDb}.collection_details(id, name) VALUES($1, $2)`,

  insertDepartmentDetails: `INSERT INTO ${appDb}.department_details(organization_address, id, name) VALUES($1, $2, $3)`,

  removeDepartmentDetails: `DELETE FROM ${appDb}.department_details WHERE organization_address = $1 AND id = $2`,

  insertUserActivationCode: `INSERT INTO ${appDb}.user_activation_requests (user_id, activation_code_digest) VALUES($1, $2);`,

  getParticipantNames: `SELECT address, COALESCE(name, username) AS "displayName"
    FROM (
      SELECT username,
        (
          CASE
            WHEN first_name IS NOT NULL THEN concat_ws(' ', first_name, last_name)
            ELSE NULL
            END
        ) AS name, address FROM ${appDb}.users
      UNION
      SELECT NULL AS username, name, address FROM ${appDb}.organizations
    ) accounts
    WHERE address = ANY($1);`,

  getAgreementValidParameters: `SELECT ap.parameter_name AS name, ap.parameter_type AS "parameterType"
    FROM ${chainDb}.agreements ag
    JOIN ${chainDb}.archetype_parameters ap ON ag.archetype_address = ap.archetype_address
    WHERE ag.agreement_address = $1
    ORDER BY position;`,

  getArchetypeValidParameters: `SELECT ap.parameter_name AS name, ap.parameter_type AS "parameterType"
    FROM ${chainDb}.archetype_parameters ap
    WHERE ap.archetype_address = $1
    ORDER BY position;`,

  validateRecoveryCode: `SELECT *
    FROM ${appDb}.password_change_requests
    WHERE created_at > now() - time '00:15' AND
    recovery_code_digest = $1`,

  getUserByUsernameOrEmail: `SELECT LOWER(email) AS email, LOWER(username) AS username,
    external_user AS "externalUser"
    FROM ${appDb}.users
    WHERE LOWER(email) = LOWER($1) OR LOWER(username) = LOWER($2);`,

  upgradeExternalUser: `UPDATE ${appDb}.users
    SET external_user = false, username = $1, first_name = $2, last_name = $3, password_digest = $4, is_producer = $5
    WHERE email = $6
    RETURNING id, address;`,
};

const runQuery = async (queryString, values = [], existingClient) => {
  const client = existingClient || await pool.connect();
  try {
    log.trace('Running query by PG-Query-Helper: ');
    log.trace(queryString, values);
    const { rows } = await client.query(queryString, values);
    if (!existingClient) client.release();
    return rows;
  } catch (err) {
    if (!existingClient) client.release();
    throw boom.badImplementation(err);
  }
};

const insertUser = (address, username, firstName, lastName, email, passwordHash, isProducer) => runQuery(
  QUERIES.insertUser,
  [address, username, firstName, lastName, email, passwordHash, isProducer],
)
  .then(rows => rows[0].id)
  .catch((err) => { throw boom.badImplementation(`Failed to insert user: ${err.stack}`); });

const insertUserActivationCode = (userId, code) => runQuery(QUERIES.insertUserActivationCode, [userId, code])
  .catch((err) => { throw boom.badImplementation(`Failed to insert user activation code: ${err.stack}`); });

const insertOrganization = (address, name, client) => runQuery(QUERIES.insertOrganization, [address, name], client)
  .then(rows => rows[0])
  .catch((err) => {
    if (err.code === '23505') {
      throw boom.conflict(`Organization with name ${name} already exists`);
    }
    throw boom.badImplementation(`Failed to insert organization in app db: ${err.stack}`);
  });

const updateOrganization = (id, address, name, client) => runQuery(QUERIES.updateOrganization, [id, address, name], client)
  .catch((err) => {
    if (err.code === '23505') {
      throw boom.conflict(`Organization with name ${name} already exists`);
    }
    throw boom.badImplementation(`Failed to update organization ${address}: ${err.stack}`);
  });

const getOrganizations = (queryParams) => {
  const query = where(queryParams);
  const queryString = `SELECT o.organization_address AS address, UPPER(encode(o.organization_id::bytea, 'hex')) AS "organizationKey",
    oa.approver_address AS approver, od.name
    FROM ${chainDb}.organization_accounts o
    JOIN ${appDb}.organizations od ON od.address = o.organization_address
    JOIN ${chainDb}.organization_approvers oa ON (o.organization_address = oa.organization_address)
    WHERE ${query.queryString};`;
  return runQuery(queryString, query.queryVals)
    .catch((err) => { throw boom.badImplementation(`Failed to get organizations: ${err.stack}`); });
};

const userIsOrganizationApprover = (orgAddress, userAccount) => runQuery(
  QUERIES.userIsOrganizationApprover,
  [userAccount, orgAddress],
)
  .then(rows => rows[0].isApprover)
  .catch((err) => { throw boom.badImplementation(`Failed to get user's organization approver status: ${err.stack}`); });

const userStatusInOrganization = (orgAddress, userAccount) => runQuery(
  QUERIES.userStatusInOrganization,
  [userAccount, orgAddress],
)
  .then(rows => rows[0])
  .catch((err) => { throw boom.badImplementation(`Failed to get user's status in organization: ${err.stack}`); });

const getOrganization = orgAddress => runQuery(QUERIES.getOrganization, [orgAddress])
  .catch((err) => { throw boom.badImplementation(`Failed to get data for organization at ${orgAddress}: ${err.stack}`); });

const getUsers = (queryParams) => {
  const query = where(queryParams);
  const queryString = `SELECT user_account_address AS address, users.username, users.id
  FROM ${chainDb}.user_accounts
  JOIN ${appDb}.users users ON users.address = user_accounts.user_account_address
  WHERE ${query.queryString} AND external_user = FALSE;`;
  return runQuery(queryString, query.queryVals)
    .then(data => data)
    .catch((err) => { throw boom.badImplementation(`Failed to get users: ${err.stack}`); });
};

const getProfile = userAddress => runQuery(QUERIES.getProfile, [userAddress])
  .catch((err) => { throw boom.badImplementation(`Failed to get profile data for user at ${userAddress}: ${err.stack}`); });

const getCountries = () => runQuery(QUERIES.getCountries)
  .catch((err) => { throw boom.badImplementation(`Failed to get countries data: ${err}`); });

const getCountryByAlpha2Code = alpha2 => runQuery(QUERIES.getCountryByAlpha2Code, [alpha2])
  .then((data) => {
    if (data.length === 0) throw boom.notFound(`No country found with given alpha2 code ${alpha2}`);
    return data[0];
  })
  .catch((err) => {
    if (err.isBoom) throw err;
    throw boom.badImplementation(`Failed to get country by alpha2 code ${alpha2}: ${err}`);
  });

const getRegionsOfCountry = alpha2 => runQuery(QUERIES.getRegionsOfCountry, [alpha2])
  .catch((err) => { throw boom.badImplementation(`Failed to get regions of country ${alpha2}: ${err}`); });

const getCurrencies = () => runQuery(QUERIES.getCurrencies)
  .catch((err) => { throw boom.badImplementation(`Failed to get currencies data: ${err}`); });

const getCurrencyByAlpha3Code = alpha3 => runQuery(QUERIES.getCurrencyByAlpha3Code, [alpha3])
  .then((data) => {
    if (data.length === 0) throw boom.notFound(`No currency found with given alpha3 code ${alpha3}`);
    return data[0];
  })
  .catch((err) => {
    if (err.isBoom) throw err;
    throw boom.badImplementation(`Failed to get currency by alpha3 code ${alpha3}: ${err}`);
  });

const getParameterType = paramType => runQuery(QUERIES.getParameterType, [paramType])
  .then((data) => {
    if (!data) throw boom.notFound(`Parameter type ${paramType} not found`);
    return data;
  })
  .catch((err) => {
    if (err.isBoom) throw err;
    throw boom.badImplementation(`Failed to get parameter type ${paramType}: ${err}`);
  });

const getParameterTypes = () => runQuery(QUERIES.getParameterTypes)
  .catch((err) => { throw boom.badImplementation(`Failed to get parameter types: ${err}`); });

const getArchetypes = (queryParams, userAccount) => {
  const query = where(queryParams);
  const queryString = `
    WITH membered AS (
      SELECT organization_address
      FROM ${chainDb}.organization_users ou
      WHERE ou.user_address = $${query.queryVals.length + 1}
    )

    SELECT a.archetype_address as address, ad.name, a.author, a.owner, ad.description, a.price, a.active, a.is_private as "isPrivate",
    (SELECT cast(count(ad.archetype_address) as integer) FROM ${chainDb}.archetype_documents ad WHERE a.archetype_address = ad.archetype_address) AS "numberOfDocuments",
    (SELECT cast(count(af.archetype_address) as integer) FROM ${chainDb}.archetype_parameters af WHERE a.archetype_address = af.archetype_address) AS "numberOfParameters",
    array_remove(array_agg(DISTINCT(aj.country)), NULL) AS countries,
    (a.owner = $${query.queryVals.length + 1} OR a.owner IN (SELECT * FROM membered)) AS "isOwner"
    FROM ${chainDb}.archetypes a
    JOIN ${appDb}.archetype_details ad ON a.archetype_address = ad.address
    LEFT JOIN ${chainDb}.archetype_jurisdictions aj ON aj.archetype_address = a.archetype_address
    WHERE
    ${query.queryString} AND (
      (a.is_private = FALSE AND a.active = TRUE) OR (a.owner = $${query.queryVals.length + 1} OR a.owner IN (SELECT * FROM membered))
    )
    GROUP BY a.archetype_address, ad.name, ad.description;`;
  return runQuery(queryString, [...query.queryVals, userAccount])
    .catch((err) => { throw boom.badImplementation(`Failed to get archetype data: ${err}`); });
};

const getArchetypeData = (archetypeAddress, userAccount) => runQuery(QUERIES.getArchetypeData, [archetypeAddress, userAccount])
  .then(rows => rows[0])
  .catch((err) => { throw boom.badImplementation(`Failed to get archetype data: ${err}`); });

const getArchetypeDataWithProcessDefinitions = (archetypeAddress, userAccount) => runQuery(
  QUERIES.getArchetypeDataWithProcessDefinitions,
  [archetypeAddress, userAccount],
)
  .then((data) => {
    if (data.length === 0) throw boom.notFound(`No archetypes found at address ${archetypeAddress}`);
    return data[0];
  })
  .catch((err) => {
    if (err.isBoom) throw err;
    throw boom.badImplementation(`Failed to get archetype data: ${err}`);
  });

const getArchetypeParameters = archetypeAddress => runQuery(QUERIES.getArchetypeParameters, [archetypeAddress])
  .catch((err) => { throw boom.badImplementation(`Failed to get archetype parameters: ${err}`); });

const getArchetypeJurisdictionsAll = () => runQuery(QUERIES.getArchetypeJurisdictionsAll)
  .catch((err) => { throw boom.badImplementation(`Failed to get all archetype jurisdictions: ${err}`); });

const getArchetypeJurisdictions = archetypeAddress => runQuery(QUERIES.getArchetypeJurisdictions, [archetypeAddress])
  .then((data) => {
    const jurisdictions = [];
    const countries = {};
    data.forEach((resultJ) => {
      if (countries[resultJ.country]) {
        jurisdictions.forEach((dataJ) => {
          if (resultJ.country === dataJ.country && resultJ.region.length > 0) {
            dataJ.regions.push(resultJ.region);
          }
        });
      } else {
        countries[resultJ.country] = 1;
        jurisdictions.push({
          country: resultJ.country,
          regions: resultJ.region.length > 0 ? [resultJ.region] : [],
        });
      }
    });
    return jurisdictions;
  })
  .catch((err) => {
    throw boom.badImplementation(`Failed to get jurisdictions for archetype: ${err}`);
  });

const getArchetypeDocuments = archetypeAddress => runQuery(QUERIES.getArchetypeDocuments, [archetypeAddress])
  .catch((err) => { throw boom.badImplementation(`Failed to get documents for archetype: ${err}`); });

const getPackagesOfArchetype = archetypeAddress => runQuery(QUERIES.getPackagesOfArchetype, [archetypeAddress])
  .catch((err) => { throw boom.badImplementation(`Failed to get packages of archetype: ${err}`); });

const getGoverningArchetypes = archetypeAddress => runQuery(QUERIES.getGoverningArchetypes, [archetypeAddress])
  .catch((err) => { throw boom.badImplementation(`Failed to get governing archetypes: ${err}`); });

const getArchetypePackages = (queryParams, userAccount) => {
  const query = where(queryParams);
  const queryString = `SELECT UPPER(encode(package_id::bytea, 'hex')) AS id, pd.name, pd.description,
    p.author, p.is_private as "isPrivate", p.active,
    (p.author = $${query.queryVals.length + 1}) AS "isOwner"
    FROM ${chainDb}.archetype_packages p
    JOIN ${appDb}.package_details pd ON UPPER(pd.id) = UPPER(encode(package_id::bytea, 'hex'))
    WHERE
    ${query.queryString} AND (
      (is_private = FALSE AND active = TRUE) OR author = $${query.queryVals.length + 1}
    );`;
  return runQuery(queryString, [...query.queryVals, userAccount])
    .then(data => data)
    .catch((err) => {
      if (err.isBoom) throw err;
      throw boom.badImplementation(`Failed to get archetype packages: ${err}`);
    });
};

const getArchetypePackage = (id, userAccount) => runQuery(QUERIES.getArchetypePackage, [userAccount, `\\x${id}`])
  .then((data) => {
    if (!data.length) {
      throw boom.notFound(`Package with id ${id} not found`);
    }
    return data[0];
  })
  .catch((err) => {
    if (err.isBoom) throw err;
    throw boom.badImplementation(`Failed to get archetype packages: ${err}`);
  });

const getArchetypesInPackage = packageId => runQuery(QUERIES.getArchetypesInPackage, [`\\x${packageId}`])
  .catch((err) => { throw boom.badImplementation(`Failed to get archetypes in package ${packageId}: ${err}`); });

const checkParties = (userAccount) => {
  const defDepId = getSHA256Hash(DEFAULT_DEPARTMENT_ID);
  return `(a.agreement_address IN (
    SELECT a.agreement_address
    FROM ${chainDb}.agreements a
    LEFT JOIN ${chainDb}.agreement_to_party ap ON a.agreement_address = ap.agreement_address
    LEFT JOIN ${chainDb}.entities_address_scopes scopes ON (
      scopes.entity_address = a.agreement_address 
      AND scopes.scope_address = ap.party 
      AND scopes.scope_context = 'AGREEMENT_PARTIES'
    )
    WHERE (
      ap.party = '${userAccount}' OR (
        ap.party IN (
          select organization_address FROM ${chainDb}.organization_users ou WHERE ou.user_address = '${userAccount}'
        ) AND (
          (
            scopes.fixed_scope IS NULL AND UPPER('${defDepId}') IN (
              SELECT UPPER(encode(department_id::bytea, 'hex')) FROM ${chainDb}.department_users du WHERE du.user_address = '${userAccount}' AND du.organization_address = ap.party
            )
          ) OR scopes.fixed_scope IN (
            select department_id FROM ${chainDb}.department_users du WHERE du.user_address = '${userAccount}' AND du.organization_address = ap.party
          ) OR scopes.fixed_scope = (
            select organization_id FROM ${chainDb}.organization_accounts o WHERE o.organization_address = ap.party
          ) OR (
            scopes.fixed_scope IS NOT NULL AND scopes.fixed_scope NOT IN (
              select department_id FROM ${chainDb}.organization_departments od WHERE od.organization_address = ap.party
            ) AND UPPER('${defDepId}') IN (
              SELECT UPPER(encode(department_id::bytea, 'hex')) FROM ${chainDb}.department_users du WHERE du.user_address = '${userAccount}' AND du.organization_address = ap.party
            )
          )
        )
      )
    )
  ))`;
};
const checkCreator = userAccount => `(a.creator = '${userAccount}')`;
const checkAgreementTasks = (userAccount) => {
  const defDepId = getSHA256Hash(DEFAULT_DEPARTMENT_ID);
  return `(a.agreement_address IN (
    SELECT a.agreement_address
    FROM ${chainDb}.agreements a
    LEFT JOIN ${chainDb}.agreement_to_party ap ON a.agreement_address = ap.agreement_address
    LEFT JOIN ${chainDb}.data_storage ds ON ds.address_value = a.agreement_address
    LEFT JOIN ${chainDb}.activity_instances ai ON ai.process_instance_address = ds.storage_address
    LEFT JOIN ${chainDb}.entities_address_scopes scopes ON (
      scopes.entity_address = a.agreement_address 
      AND scopes.scope_address = ap.party 
      AND scopes.scope_context = ai.activity_id
    )
    WHERE (
      ai.state = 4 AND (
        ai.performer = '${userAccount}' OR (
          ai.performer IN (
            select organization_address FROM ${chainDb}.organization_users ou WHERE ou.user_address = '${userAccount}'
          ) AND (
            (
              scopes.fixed_scope IS NULL AND UPPER('${defDepId}') IN (
                SELECT UPPER(encode(department_id::bytea, 'hex')) FROM ${chainDb}.department_users du WHERE du.user_address = '${userAccount}' AND du.organization_address = ai.performer
              )
            ) OR scopes.fixed_scope IN (
              select department_id FROM ${chainDb}.department_users du WHERE du.user_address = '${userAccount}' AND du.organization_address = ai.performer
            ) OR scopes.fixed_scope = (
              select organization_id FROM ${chainDb}.organization_accounts o WHERE o.organization_address = ai.performer
            ) OR (
              scopes.fixed_scope IS NOT NULL AND scopes.fixed_scope NOT IN (
                select department_id FROM ${chainDb}.organization_departments od WHERE od.organization_address = ai.performer
              ) AND UPPER('${defDepId}') IN (
                SELECT UPPER(encode(department_id::bytea, 'hex')) FROM ${chainDb}.department_users du WHERE du.user_address = '${userAccount}' AND du.organization_address = ai.performer
              )
            )
          )
        )
      )
    )
  ))`;
};

const getAgreements = (queryParams, forCurrentUser, userAccount) => {
  const query = where(queryParams);
  const queryString = `SELECT DISTINCT(a.agreement_address) as address, ad.name, a.creator,
    a.archetype_address as archetype, archd.name AS "archetypeName",
    a.event_log_file_reference AS "attachmentsFileReference",
    a.max_event_count::integer as "maxNumberOfAttachments", a.is_private as "isPrivate", a.legal_state as "legalState",
    a.formation_process_instance as "formationProcessInstance", a.execution_process_instance as "executionProcessInstance",
    (SELECT count(ap.agreement_address) FROM ${chainDb}.agreement_to_party ap WHERE a.agreement_address = ap.agreement_address)::integer AS "numberOfParties"
    FROM ${chainDb}.agreements a
    JOIN ${appDb}.agreement_details ad ON a.agreement_address = ad.address
    JOIN ${appDb}.archetype_details archd ON a.archetype_address = archd.address
    LEFT JOIN ${chainDb}.agreement_to_party ap ON a.agreement_address = ap.agreement_address
    WHERE
    ${query.queryString} AND (
      ${forCurrentUser ? `${checkParties(userAccount)} OR
      ${checkCreator(userAccount)} OR
      ${checkAgreementTasks(userAccount)} ` : 'a.is_private = FALSE'}
    );`;
  return runQuery(queryString, query.queryVals)
    .catch((err) => { throw boom.badImplementation(`Failed to get agreement(s): ${err}`); });
};

const getAgreementData = (agreementAddress, userAccount, includePublic = true) => {
  const queryString = `SELECT a.agreement_address as address, a.archetype_address as archetype, ad.name, a.creator,
    a.event_log_file_reference as "attachmentsFileReference", a.private_parameters_file_reference AS "privateParametersFileReference",
    a.signature_log_file_reference as "signaturesFileReference",
    a.max_event_count::integer as "maxNumberOfAttachments", a.is_private as "isPrivate", a.legal_state as "legalState",
    a.formation_process_instance as "formationProcessInstance", a.execution_process_instance as "executionProcessInstance",
    UPPER(encode(ac.collection_id::bytea, 'hex')) as "collectionId",
    arch.formation_process_definition as "formationProcessDefinition", arch.execution_process_definition as "executionProcessDefinition",
    (
      SELECT COALESCE(creator_account.name, creator_account.username)
      FROM (
        SELECT username, 
          (CASE WHEN u.first_name IS NOT NULL THEN concat_ws(' ', u.first_name, u.last_name) ELSE NULL END) AS name
          FROM ${appDb}.users u WHERE u.address = a.creator
        UNION
        SELECT NULL as username, name
          FROM ${appDb}.organizations o WHERE o.address = a.creator
      ) creator_account
    ) AS "creatorDisplayName",
    (
      SELECT COALESCE(owner_account.name, owner_account.username)
      FROM (
        SELECT username,
          (CASE WHEN u.first_name IS NOT NULL THEN concat_ws(' ', u.first_name, u.last_name) ELSE NULL END) as name
          FROM ${appDb}.users u WHERE u.address = a.owner
        UNION
        SELECT NULL as username, name
          FROM ${appDb}.organizations o WHERE o.address = a.owner
      ) owner_account
    ) AS "ownerDisplayName",
    ${checkParties(userAccount)} AS "isParty",
    ${checkCreator(userAccount)} AS "isCreator",
    ${checkAgreementTasks(userAccount)} AS "isAssignedTask"
    FROM ${chainDb}.agreements a
    LEFT JOIN ${chainDb}.agreement_to_collection ac ON a.agreement_address = ac.agreement_address
    LEFT JOIN ${chainDb}.agreement_to_party ap ON a.agreement_address = ap.agreement_address
    JOIN ${appDb}.agreement_details ad ON a.agreement_address = ad.address
    JOIN ${chainDb}.archetypes arch ON a.archetype_address = arch.archetype_address
    WHERE a.agreement_address = $1 AND (
      ${includePublic ? 'a.is_private = FALSE OR ' : ''}
      ${checkCreator(userAccount)} OR
      ${checkParties(userAccount)} OR
      ${checkAgreementTasks(userAccount)}
    );`;
  return runQuery(queryString, [agreementAddress])
    .then(rows => rows[0])
    .catch((err) => { throw boom.badImplementation(`Failed to get agreement data: ${err}`); });
};

const getAgreementParties = agreementAddress => runQuery(QUERIES.getAgreementParties, [agreementAddress, AGREEMENT_PARTIES])
  .catch((err) => { throw boom.badImplementation(`Failed to get agreement parties: ${err}`); });

const getGoverningAgreements = agreementAddress => runQuery(QUERIES.getGoverningAgreements, [agreementAddress])
  .catch((err) => { throw boom.badImplementation(`Failed to get governing agreements: ${err}`); });

const getAgreementCollections = userAccount => runQuery(QUERIES.getAgreementCollections, [userAccount, userAccount])
  .catch((err) => { throw boom.badImplementation(`Failed to get agreement collections: ${err}`); });

const getAgreementCollectionData = collectionId => runQuery(QUERIES.getAgreementCollectionData, [`\\x${collectionId}`])
  .then((data) => {
    if (!data.length) throw boom.notFound(`Collection with id ${collectionId} not found`);
    return data;
  })
  .catch((err) => {
    if (err.isBoom) throw err;
    throw boom.badImplementation(`Failed to get details of agreement collection with id ${collectionId}: ${err}`);
  });

const getActivityInstances = (userAccount, queryParams) => {
  const query = where(queryParams);
  const defDepId = getSHA256Hash(DEFAULT_DEPARTMENT_ID);
  const queryString = `SELECT 
    DISTINCT(UPPER(encode(ai.activity_instance_id::bytea, 'hex'))) as "activityInstanceId",
    ai.process_instance_address AS "processAddress",
    ai.activity_id as "activityId",
    adet.activity_name as name,
    ai.created::integer,
    ai.completed::integer,
    ai.performer,
    ai.completed_by as "completedBy",
    ai.state::integer,
    ai._height AS "blockNumber",
    ai._txhash AS "transactionHash",
    app.web_form as "webForm",
    pd.model_address as "modelAddress",
    pm.id as "modelId",
    pd.id as "processDefinitionId",
    pd.interface_id as "interfaceId",
    adet.process_name as "processName",
    pd.process_definition_address as "processDefinitionAddress",
    ds.address_value as "agreementAddress",
    agr.name as "agreementName",
    ad.task_type as "taskType",
    ad.application as application,
    completers.username AS "completedByDisplayName",
    COALESCE(performers.username, performers.name) AS "performerDisplayName",
    UPPER(encode(scopes.fixed_scope, 'hex')) AS scope,
    dd.name AS "scopeDisplayName",
    UPPER(encode(o.organization_id::bytea, 'hex')) AS "organizationKey",
    (
      ai.performer = $${query.queryVals.length + 1} OR (
        ai.performer IN (
          select organization_address FROM ${chainDb}.organization_users ou WHERE ou.user_address = $${query.queryVals.length + 1}
        ) AND (
          (
            scopes.fixed_scope IS NULL AND UPPER('${defDepId}') IN (
              SELECT UPPER(encode(department_id::bytea, 'hex')) FROM ${chainDb}.department_users du WHERE du.user_address = $${query.queryVals.length + 1} AND du.organization_address = ai.performer
            )
          ) OR scopes.fixed_scope IN (
            select department_id FROM ${chainDb}.department_users du WHERE du.user_address = $${query.queryVals.length + 1} AND du.organization_address = ai.performer
          ) OR scopes.fixed_scope = (
            select organization_id FROM ${chainDb}.organization_accounts o WHERE o.organization_address = ai.performer
          ) OR (
            scopes.fixed_scope IS NOT NULL AND scopes.fixed_scope NOT IN (
              select department_id FROM ${chainDb}.organization_departments od WHERE od.organization_address = ai.performer
            ) AND UPPER('${defDepId}') IN (
              SELECT UPPER(encode(department_id::bytea, 'hex')) FROM ${chainDb}.department_users du WHERE du.user_address = $${query.queryVals.length + 1} AND du.organization_address = performer
            )
          )
        )
      )
    ) AS "assignedToUser"
    FROM ${chainDb}.activity_instances ai  
    JOIN ${chainDb}.process_instances pi ON ai.process_instance_address = pi.process_instance_address 
    JOIN ${chainDb}.activity_definitions ad ON ai.activity_id = ad.activity_id AND pi.process_definition_address = ad.process_definition_address 
    JOIN ${chainDb}.process_definitions pd ON pd.process_definition_address = pi.process_definition_address 
    LEFT JOIN ${chainDb}.applications app ON app.application_id = ad.application
    JOIN ${chainDb}.process_models pm ON pm.model_address = pd.model_address 
    JOIN ${appDb}.activity_details adet ON pm.id = adet.model_id AND pd.id = adet.process_id AND ad.activity_id = adet.activity_id
    LEFT JOIN ${chainDb}.data_storage ds ON ai.process_instance_address = ds.storage_address 
    LEFT JOIN ${appDb}.agreement_details agr ON agr.address = ds.address_value 
    LEFT JOIN ${appDb}.users completers ON ai.completed_by = completers.address
    LEFT JOIN (SELECT username, NULL AS name, address, external_user FROM ${appDb}.users
      UNION
      SELECT NULL AS username, name, address, FALSE AS external_user FROM ${appDb}.organizations
    ) performers ON ai.performer = performers.address
    LEFT JOIN ${chainDb}.entities_address_scopes scopes ON (
      scopes.entity_address = ds.storage_address 
      AND scopes.scope_address = ai.performer 
      AND scopes.scope_context = ai.activity_id
    )
    LEFT JOIN ${chainDb}.organization_accounts o ON o.organization_address = ai.performer 
    LEFT JOIN ${appDb}.department_details dd ON o.organization_address = dd.organization_address AND UPPER(encode(scopes.fixed_scope, 'hex')) = UPPER(dd.id)
    WHERE ds.data_id = 'agreement'
    AND ${query.queryString}`;
  return runQuery(queryString, [...query.queryVals, userAccount])
    .catch((err) => { throw boom.badImplementation(`Failed to get activities: ${err}`); });
};

const getActivityInstanceData = (id, userAddress) => {
  const defDepId = getSHA256Hash(DEFAULT_DEPARTMENT_ID);
  const queryString = `SELECT ai.state::integer, ai.process_instance_address as "processAddress",
    UPPER(encode(ai.activity_instance_id::bytea, 'hex')) as "activityInstanceId", ai.activity_id as "activityId", adet.activity_name AS name,
    ai.created, ai.performer, ai.completed, ad.task_type as "taskType", ad.application as application,
    pd.model_address as "modelAddress", pd.interface_id as "interfaceId", pm.id as "modelId", pd.id as "processDefinitionId", adet.process_name AS "processName",
    pd.process_definition_address as "processDefinitionAddress", app.web_form as "webForm", app.application_type as "applicationType",
    ds.address_value as "agreementAddress", pm.author as "modelAuthor", pm.is_private AS "isModelPrivate", agrd.name as "agreementName",
    UPPER(encode(scopes.fixed_scope, 'hex')) AS scope, UPPER(encode(o.organization_id::bytea, 'hex')) as "organizationKey",
    COALESCE(accounts.username, accounts.name) AS "performerDisplayName", dd.name AS "scopeDisplayName",
    agr.event_log_file_reference AS "attachmentsFileReference", agr.max_event_count::integer as "maxNumberOfAttachments",
    (
      ai.performer = $2 OR (
        ai.performer IN (
          select organization_address FROM ${chainDb}.organization_users ou WHERE ou.user_address = $2
        ) AND (
          (
            scopes.fixed_scope IS NULL AND UPPER('${defDepId}') IN (
              SELECT UPPER(encode(department_id::bytea, 'hex')) FROM ${chainDb}.department_users du WHERE du.user_address = $2 AND du.organization_address = ai.performer
            )
          ) OR scopes.fixed_scope IN (
            select department_id FROM ${chainDb}.department_users du WHERE du.user_address = $2 AND du.organization_address = ai.performer
          ) OR scopes.fixed_scope = (
            select organization_id FROM ${chainDb}.organization_accounts o WHERE o.organization_address = ai.performer
          ) OR (
            scopes.fixed_scope IS NOT NULL AND scopes.fixed_scope NOT IN (
              select department_id FROM ${chainDb}.organization_departments od WHERE od.organization_address = ai.performer
            ) AND UPPER('${defDepId}') IN (
              SELECT UPPER(encode(department_id::bytea, 'hex')) FROM ${chainDb}.department_users du WHERE du.user_address = $2 AND du.organization_address = performer
            )
          )
        )
      )
    ) AS "assignedToUser"
    FROM ${chainDb}.activity_instances ai
    JOIN ${chainDb}.process_instances pi ON ai.process_instance_address = pi.process_instance_address
    JOIN ${chainDb}.activity_definitions ad ON ai.activity_id = ad.activity_id AND pi.process_definition_address = ad.process_definition_address
    JOIN ${chainDb}.process_definitions pd ON pd.process_definition_address = pi.process_definition_address
    JOIN ${chainDb}.process_models pm ON pm.model_address = pd.model_address
    JOIN ${appDb}.activity_details adet ON pm.id = adet.model_id AND pd.id = adet.process_id AND ad.activity_id = adet.activity_id
    LEFT JOIN ${chainDb}.data_storage ds ON ai.process_instance_address = ds.storage_address
    LEFT JOIN ${appDb}.agreement_details agrd ON agrd.address = ds.address_value 
    LEFT JOIN ${chainDb}.agreements agr ON agr.agreement_address = ds.address_value
    LEFT JOIN ${chainDb}.applications app ON app.application_id = ad.application
    LEFT JOIN ${chainDb}.organization_accounts o ON o.organization_address = ai.performer 
    LEFT JOIN ${chainDb}.entities_address_scopes scopes ON (
      scopes.entity_address = ds.storage_address 
      AND scopes.scope_address = ai.performer 
      AND scopes.scope_context = ai.activity_id
    )
    LEFT JOIN (SELECT username, NULL AS name, address, external_user FROM ${appDb}.users
      UNION
      SELECT NULL AS username, name, address, FALSE AS external_user FROM ${appDb}.organizations
    ) accounts ON ai.performer = accounts.address
    LEFT JOIN ${appDb}.department_details dd ON ai.performer = dd.organization_address AND UPPER(encode(scopes.fixed_scope, 'hex')) = UPPER(dd.id)
    WHERE ai.activity_instance_id = $1
    AND ds.data_id = 'agreement'`; // Hard-coded dataId 'agreement' which all processes in the Agreements Network have
  return runQuery(queryString, [`\\x${id}`, userAddress])
    .catch((err) => {
      throw boom.badImplementation(`Failed to get activity instance ${id}: ${err}`);
    });
};

const getAccessPointDetails = (dataMappings = [], applicationId) => {
  const dataMappingIds = dataMappings.map(d => d.dataMappingId);
  const queryString = `SELECT access_point_id as "accessPointId", data_type as "dataType", direction 
    FROM ${chainDb}.application_access_points WHERE application_id = $1 
    AND access_point_id IN ('${dataMappingIds.join("', '")}')`;
  return runQuery(queryString, [applicationId])
    .catch((err) => { throw boom.badImplementation(`Failed to get data types for data mappings ids ${JSON.stringify(dataMappings)}: ${err}`); });
};

const getTasksByUserAddress = (userAddress) => {
  const defDepId = getSHA256Hash(DEFAULT_DEPARTMENT_ID);
  // IMPORTANT: The below query uses two LEFT JOIN to retrieve data from the agreement that is attached to the process in one single query.
  // This relies on the fact that all processes in the Agreements Network have a process data with the ID "agreement".
  // If we ever want to retrieve more process data (from other data objects in the process or flexibly retrieve data based on a future process configuration aka 'descriptors'), multiple queries will have to be used
  const queryString = `SELECT ai.state::integer, ai.process_instance_address as "processAddress", adet.activity_name AS name,
    UPPER(encode(ai.activity_instance_id::bytea, 'hex')) as "activityInstanceId", ai.activity_id as "activityId", ai.created, ai.performer,
    pd.model_address as "modelAddress", pd.process_definition_address as "processDefinitionAddress", pd.id as "processDefinitionId", 
    adet.process_name AS "processName", agr.name as "agreementName", pm.id as "modelId", ds.address_value as "agreementAddress",
    UPPER(encode(scopes.fixed_scope::bytea, 'hex')) AS scope, UPPER(encode(o.organization_id::bytea, 'hex')) as "organizationKey"
    FROM ${chainDb}.activity_instances ai
    JOIN ${chainDb}.process_instances pi ON ai.process_instance_address = pi.process_instance_address
    JOIN ${chainDb}.activity_definitions ad ON ai.activity_id = ad.activity_id AND pi.process_definition_address = ad.process_definition_address
    JOIN ${chainDb}.process_definitions pd ON pd.process_definition_address = pi.process_definition_address
    JOIN ${chainDb}.process_models pm ON pm.model_address = pd.model_address
    JOIN ${appDb}.activity_details adet ON pm.id = adet.model_id AND pd.id = adet.process_id AND ad.activity_id = adet.activity_id
    LEFT JOIN ${chainDb}.data_storage ds ON ai.process_instance_address = ds.storage_address
    LEFT JOIN ${appDb}.agreement_details agr ON agr.address = ds.address_value 
    LEFT JOIN ${chainDb}.organization_accounts o ON o.organization_address = ai.performer
    LEFT JOIN ${chainDb}.entities_address_scopes scopes ON (
      scopes.entity_address = ds.storage_address
      AND scopes.scope_address = ai.performer 
      AND scopes.scope_context = ai.activity_id
    )
    WHERE ad.task_type = 1
    AND ai.state = 4
    AND (
      performer = $1 OR (
        performer IN (
          select organization_address FROM ${chainDb}.organization_users ou WHERE ou.user_address = $1
        ) AND (
          (
            scopes.fixed_scope IS NULL AND UPPER('${defDepId}') IN (
              SELECT UPPER(encode(department_id::bytea, 'hex')) FROM ${chainDb}.department_users du WHERE du.user_address = $1 AND du.organization_address = ai.performer
            )
          ) OR scopes.fixed_scope IN (
            select department_id FROM ${chainDb}.department_users du WHERE du.user_address = $1 AND du.organization_address = ai.performer
          ) OR scopes.fixed_scope = (
            select organization_id FROM ${chainDb}.organization_accounts o WHERE o.organization_address = ai.performer
          ) OR (
            scopes.fixed_scope IS NOT NULL AND scopes.fixed_scope NOT IN (
              select department_id FROM ${chainDb}.organization_departments od WHERE od.organization_address = ai.performer
            ) AND UPPER('${defDepId}') IN (
              SELECT UPPER(encode(department_id::bytea, 'hex')) FROM ${chainDb}.department_users du WHERE du.user_address = $1 AND du.organization_address = performer
            )
          )
        )
      )
    )
    AND ds.data_id = 'agreement';`; // Hard-coded dataId 'agreement' which all processes in the Agreements Network have
  return runQuery(queryString, [userAddress])
    .catch((err) => { throw boom.badImplementation(`Failed to get tasks assigned to user: ${err}`); });
};

const getModels = author => runQuery(QUERIES.getModels, [false, author])
  .catch((err) => { throw boom.badImplementation(`Failed to get process model(s): ${err}`); });

const getApplications = () => runQuery(QUERIES.getApplications)
  .catch((err) => { throw boom.badImplementation(`Failed to get applications: ${err}`); });

const getDataMappingsForActivity = (activityInstanceId, dataMappingId) => {
  const queryString = `${QUERIES.getDataMappingsForActivity} ${dataMappingId ? 'AND dm.data_mapping_id = $2' : ''};`;
  return runQuery(queryString, dataMappingId ? [activityInstanceId, dataMappingId] : [activityInstanceId])
    .catch((err) => { throw boom.badImplementation(`Failed to get data mappings for activity instance ${activityInstanceId}: ${err}`); });
};

const getProcessDefinitions = (author, { interfaceId, processDefinitionId, modelId }) => {
  const queryString = `SELECT pd.id as "processDefinitionId", pdet.process_name AS "processName", 
    pd.process_definition_address AS address, pd.model_address as "modelAddress", pd.interface_id as "interfaceId", 
    pm.id as "modelId", pm.model_file_reference as "modelFileReference", pm.is_private as "isPrivate", pm.author,
    (SELECT username FROM ${appDb}.users WHERE address = pm.author) AS "authorDisplayName"
    FROM ${chainDb}.process_definitions pd 
    JOIN ${chainDb}.process_models pm ON pd.model_address = pm.model_address
    JOIN ${appDb}.process_details pdet ON pm.id = pdet.model_id AND pd.id = pdet.process_id
    WHERE (pm.is_private = $1 OR pm.author = $2)
    ${(interfaceId ? `AND pd.interface_id = '${interfaceId}'` : '')}
    ${(processDefinitionId ? `AND pd.id = '${processDefinitionId}'` : '')}
    ${(modelId ? `AND pm.id = '${modelId}'` : '')};`;
  const params = [false, author];
  return runQuery(queryString, params)
    .catch((err) => { throw boom.badImplementation(`Failed to get process definitions: ${err}`); });
};

const getProcessDefinitionData = (address, userAddress) => {
  const queryString = `SELECT pd.id as "processDefinitionId", pd.process_definition_address AS address, pdet.process_name AS "processName",
    pd.model_address as "modelAddress", pd.interface_id as "interfaceId", pm.model_file_reference as "modelFileReference",
    pm.is_private as "isPrivate", pm.author, pm.id as "modelId"
    FROM ${chainDb}.process_definitions pd
    JOIN ${chainDb}.process_models pm ON pd.model_address = pm.model_address
    JOIN ${appDb}.process_details pdet ON pm.id = pdet.model_id AND pd.id = pdet.process_id
    LEFT JOIN ${chainDb}.archetypes arch ON (arch.formation_process_definition = pd.process_definition_address OR arch.execution_process_definition = pd.process_definition_address)
    LEFT JOIN ${chainDb}.agreements a ON a.archetype_address = arch.archetype_address
    WHERE pd.process_definition_address = $1 AND (
      pm.is_private = FALSE OR 
      (
        pm.author = '${userAddress}' OR
        pm.author IN (
          SELECT ou.organization_address FROM ${chainDb}.organization_users ou WHERE ou.user_address = '${userAddress}'
        ) OR
        ${checkAgreementTasks(userAddress)} OR
        ${checkParties(userAddress)}
      )
    );`;
  return runQuery(queryString, [address])
    .then((rows) => {
      if (!rows[0]) throw boom.notFound(`Process definition at ${address} not found or user does not have sufficient privileges`);
      return rows[0];
    })
    .catch((err) => {
      if (err.isBoom) throw err;
      throw boom.badImplementation(`Failed to get process definition: ${err}`);
    });
};

const getProcessModelData = address => runQuery(QUERIES.getProcessModelData, [address])
  .catch((err) => { throw boom.badImplementation(`Failed to get process model: ${err}`); });

const getArchetypeModelFileReferences = archetypeAddress => runQuery(QUERIES.getArchetypeModelFileReference, [archetypeAddress])
  .catch((err) => { throw boom.badImplementation(`Failed to get process model file refs for archetype ${archetypeAddress}: ${err}`); });

const getProcessModelFileReference = (address, userAddress) => {
  const queryString = `SELECT model_file_reference as "modelFileReference"
    FROM ${chainDb}.process_models pm
    LEFT JOIN ${chainDb}.process_definitions pd ON pd.model_address = pm.model_address
    LEFT JOIN ${chainDb}.archetypes arch ON (arch.formation_process_definition = pd.process_definition_address OR arch.execution_process_definition = pd.process_definition_address)
    LEFT JOIN ${chainDb}.agreements a ON a.archetype_address = arch.archetype_address
    WHERE pm.model_address = $1 AND (
      pm.is_private = FALSE OR 
      (
        pm.author = '${userAddress}' OR
        pm.author IN (
          SELECT ou.organization_address FROM ${chainDb}.organization_users ou WHERE ou.user_address = '${userAddress}'
        ) OR
        ${checkAgreementTasks(userAddress)} OR
        ${checkParties(userAddress)}
      )
    );`;
  return runQuery(queryString, [address])
    .then((rows) => {
      if (!rows[0]) throw boom.notFound(`Model at ${address} not found or user does not have sufficient privileges`);
      return rows[0].modelFileReference;
    })
    .catch((err) => {
      if (err.isBoom) throw err;
      throw boom.badImplementation(`Failed to get model file reference: ${JSON.stringify(err)}`);
    });
};

const getActivityDetailsFromCache = (activityId, modelId, processId) => runQuery(QUERIES.getActivityDetailsFromCache, [activityId, processId, modelId])
  .then(rows => rows[0] || {})
  .catch((err) => {
    throw boom.badImplementation(`Failed to get activity details for activity ${activityId} in process ${processId} and model ${modelId}: ${err.stack}`);
  });

const saveActivityDetails = (modelId, processDefinitionId, processName, activityId, name) => runQuery(QUERIES.saveActivityDetails, [modelId, processDefinitionId, processName, activityId, name])
  .catch((err) => {
    throw boom.badImplementation(`Failed to update activity_details cache for activity ${name} in process ${processName} in model ${modelId}: ${err.stack}`);
  });

const getProcessDetailsFromCache = (modelId, processId) => runQuery(QUERIES.getProcessDetailsFromCache, [modelId, processId])
  .then(rows => rows[0] || {})
  .catch((err) => { throw boom.badImplementation(`Failed to get process details from cache for process ${processId} in model ${modelId}: ${err.stack}`); });

const saveProcessDetails = (modelId, processDefinitionId, processName) => runQuery(QUERIES.saveProcessDetails, [modelId, processDefinitionId, processName])
  .catch((err) => { throw boom.badImplementation(`Failed to update process_details cache for process ${processDefinitionId} in model ${modelId}: ${err.stack}`); });

const getUserByActivationCode = activationCode => runQuery(QUERIES.getUserByActivationCode, [activationCode])
  .catch((err) => { throw boom.badImplementation(`Failed to get user by activation code: ${err.stack}`); });

const updateUserActivation = async (userAddress, userId, activated, activationCodeHex) => {
  // set user to activated
  try {
    await runQuery(QUERIES.updateUserActivation, [activated, userAddress]);
  } catch (err) {
    throw boom.badImplementation(`Failed to set user to activated for user at ${userAddress}: ${err.stack}`);
  }
  // delete user activation code from table
  try {
    await runQuery(QUERIES.deleteUserActivationCode, [userId, activationCodeHex]);
  } catch (err) {
    log.error(`Failed to delete row in user_activation_requests for user id ${userId} at ${userAddress}: ${err.stack}`);
  }
};

const getDbUserIdByAddress = userAddress => runQuery(QUERIES.getDbUserIdByAddress, [userAddress])
  .catch((err) => { throw boom.badImplementation(`Failed to get user id by address: ${err.stack}`); });

const insertArchetypeDetails = ({ address, name, description }) => runQuery(QUERIES.insertArchetypeDetails, [address, name, description])
  .catch((err) => { throw boom.badImplementation(`Failed to insert archetype details: ${err.stack}`); });

const insertAgreementDetails = ({ address, name }) => runQuery(QUERIES.insertAgreementDetails, [address, name])
  .catch((err) => { throw boom.badImplementation(`Failed to insert agreement details: ${err.stack}`); });

const insertPackageDetails = ({ id, name, description }) => runQuery(QUERIES.insertPackageDetails, [id, name, description])
  .catch((err) => { throw boom.badImplementation(`Failed to insert package details: ${err.stack}`); });

const insertCollectionDetails = ({ id, name }) => runQuery(QUERIES.insertCollectionDetails, [id, name])
  .catch((err) => { throw boom.badImplementation(`Failed to insert collection details: ${err.stack}`); });

const insertDepartmentDetails = ({ organizationAddress, id, name }, client) => runQuery(QUERIES.insertDepartmentDetails, [organizationAddress, id, name], client)
  .catch((err) => { throw boom.badImplementation(`Failed to insert department details: ${err.stack}`); });

const removeDepartmentDetails = ({ organizationAddress, id }) => runQuery(QUERIES.removeDepartmentDetails, [organizationAddress, id])
  .catch((err) => { throw boom.badImplementation(`Failed to remove department details: ${err.stack}`); });

const getParticipantNames = addresses => runQuery(QUERIES.getParticipantNames, [addresses])
  .catch((err) => { throw boom.badImplementation(`Failed to get participant names: ${err.stack}`); });

const getUserByIdType = async ({ idType, id }) => {
  try {
    const text = `SELECT id, username, email, address, password_digest AS "passwordDigest",
    created_at AS "createdAt", activated, first_name AS "firstName", last_name AS "lastName", country, region,
    is_producer AS "isProducer", onboarding
    FROM ${appDb}.users
    WHERE LOWER(${idType}) = LOWER($1)`;
    return (await runQuery(text, [id]))[0];
  } catch (err) {
    throw boom.badImplementation(`Failed to get participant names: ${err.stack}`);
  }
};

const getAgreementValidParameters = agreementAddress => runQuery(QUERIES.getAgreementValidParameters, [agreementAddress])
  .catch((err) => { throw boom.badImplementation(`Failed to get valid parameters for agreement: ${err.stack}`); });

const getArchetypeValidParameters = archetypeAddress => runQuery(QUERIES.getArchetypeValidParameters, [archetypeAddress])
  .catch((err) => { throw boom.badImplementation(`Failed to get valid parameters for agreement: ${err.stack}`); });

const validateRecoveryCode = code => runQuery(QUERIES.validateRecoveryCode, [code])
  .then(rows => rows[0])
  .catch((err) => { throw boom.badImplementation(`Failed to find password recovery code: ${err.stack}`); });

const getUserByUsernameOrEmail = ({ email, username }) => runQuery(QUERIES.getUserByUsernameOrEmail, [email, username])
  .then(rows => rows[0])
  .catch((err) => { throw boom.badImplementation(`Failed to find user by username or email: ${err.stack}`); });

const upgradeExternalUser = ({
  username, firstName, lastName, passwordDigest, isProducer, email,
}) => runQuery(QUERIES.upgradeExternalUser, [username, firstName, lastName, passwordDigest, isProducer, email])
  .then(rows => rows[0])
  .catch((err) => { throw boom.badImplementation(`Failed to upgrade external user: ${err.stack}`); });

module.exports = {
  QUERIES,
  insertUser,
  insertUserActivationCode,
  insertOrganization,
  updateOrganization,
  getOrganizations,
  getOrganization,
  userIsOrganizationApprover,
  userStatusInOrganization,
  getUsers,
  getProfile,
  getCountries,
  getCountryByAlpha2Code,
  getRegionsOfCountry,
  getCurrencies,
  getCurrencyByAlpha3Code,
  getParameterType,
  getParameterTypes,
  getArchetypes,
  getArchetypeData,
  getArchetypeJurisdictionsAll,
  getArchetypeDataWithProcessDefinitions,
  getArchetypeParameters,
  getArchetypeJurisdictions,
  getArchetypeDocuments,
  getPackagesOfArchetype,
  getGoverningArchetypes,
  getArchetypePackages,
  getArchetypePackage,
  getArchetypesInPackage,
  getAgreements,
  getAgreementData,
  checkParties,
  checkCreator,
  checkAgreementTasks,
  getAgreementParties,
  getGoverningAgreements,
  getAgreementCollections,
  getAgreementCollectionData,
  getActivityInstances,
  getActivityInstanceData,
  getAccessPointDetails,
  getTasksByUserAddress,
  getModels,
  getApplications,
  getDataMappingsForActivity,
  getProcessDefinitions,
  getProcessDefinitionData,
  getProcessModelData,
  getArchetypeModelFileReferences,
  getProcessModelFileReference,
  getActivityDetailsFromCache,
  saveActivityDetails,
  getProcessDetailsFromCache,
  saveProcessDetails,
  getUserByActivationCode,
  updateUserActivation,
  getDbUserIdByAddress,
  insertArchetypeDetails,
  insertAgreementDetails,
  insertPackageDetails,
  insertCollectionDetails,
  insertDepartmentDetails,
  removeDepartmentDetails,
  getParticipantNames,
  getUserByIdType,
  getAgreementValidParameters,
  getArchetypeValidParameters,
  validateRecoveryCode,
  getUserByUsernameOrEmail,
  upgradeExternalUser,
};
