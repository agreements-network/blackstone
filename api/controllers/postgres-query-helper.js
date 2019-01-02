const boom = require('boom');
const {
  where,
  setUserIds,
  getNamesOfOrganizations,
} = require(`${global.__common}/controller-dependencies`);
const { DEFAULT_DEPARTMENT_ID } = global.__monax_constants;
const logger = require(`${global.__common}/monax-logger`);
const log = logger.getLogger('monax.controllers');
const { appPool, chainPool } = require(`${global.__common}/postgres-db`);

const runQuery = (pool, queryString, values = []) => pool
  .connect()
  .then(client => client.query(queryString, values).then((res) => {
    log.trace('Running query by PG-Query-Helper: ');
    log.trace(queryString, values);
    client.release();
    return res.rows;
  }).catch((err) => {
    client.release();
    throw boom.badImplementation(err);
  }));

const runAppDbQuery = (queryString, values = []) => runQuery(appPool, queryString, values);
const runChainDbQuery = (queryString, values = []) => runQuery(chainPool, queryString, values);

const getOrganizations = (queryParams) => {
  const queryString = 'SELECT o.organization_address AS address, encode(o.organization_id::bytea, \'hex\') as "organizationKey", oa.approver_address as approver ' +
    `FROM organization_accounts o JOIN organization_approvers oa ON (o.organization_address = oa.organization_address) ${where(queryParams)}`;
  return runChainDbQuery(queryString)
    .catch((err) => { throw boom.badImplementation(`Failed to get organizations: ${err.stack}`); });
};

const getOrganization = (orgAddress) => {
  const queryString =
    'SELECT o.organization_address AS address, encode(o.organization_id::bytea, \'hex\') as "organizationKey", oa.approver_address AS approver, ou.user_address AS user, encode(od.department_id::bytea, \'hex\') AS department, od.name AS "departmentName", du.user_address as "departmentUserKey"' +
    'FROM organization_accounts o JOIN organization_approvers oa ON (o.organization_address = oa.organization_address) ' +
    'LEFT JOIN organization_users ou ON (o.organization_address = ou.organization_address) ' +
    'LEFT JOIN organization_departments od ON (o.organization_address = od.organization_address) ' +
    'LEFT JOIN department_users du ON (od.department_id = du.department_id) AND (du.user_address = ou.user_address) AND (od.organization_address = du.organization_address) ' +
    'WHERE o.organization_address = $1 ';
  return runChainDbQuery(queryString, [orgAddress])
    .catch((err) => { throw boom.badImplementation(`Failed to get data for organization at ${orgAddress}: ${err.stack}`); });
};

const getUsers = (queryParams) => {
  const _queryParams = Object.assign({}, queryParams);
  if (_queryParams.id) _queryParams.id = `\\x${queryParams.id}`;
  const queryString = `SELECT user_account_address AS address FROM user_accounts ${(queryParams ? `${where(_queryParams, false)}` : '')}`;
  return runChainDbQuery(queryString)
    .then((data) => {
      try {
        return setUserIds(data, true, 'User');
      } catch (userIdErr) {
        throw boom.badImplementation(`Failed to get User Ids: ${userIdErr.stack}`);
      }
    })
    .catch((err) => { throw boom.badImplementation(`Failed to get users: ${err.stack}`); });
};

const getProfile = (userAddress) => {
  const queryString =
    'SELECT u.user_account_address AS address, encode(o.organization_id::bytea, \'hex\') AS "organizationKey", ou.organization_address as organization, encode(du.department_id::bytea, \'hex\') AS department, od.name AS "departmentName" ' +
    'FROM USER_ACCOUNTS u LEFT JOIN ORGANIZATION_USERS ou ON u.user_account_address = ou.user_address ' +
    'LEFT JOIN organization_accounts o ON o.organization_address = ou.organization_address ' +
    'LEFT JOIN organization_departments od ON ou.organization_address = od.organization_address ' +
    'LEFT JOIN department_users du ON (od.department_id = du.department_id) AND (du.user_address = ou.user_address) AND (ou.organization_address = du.organization_address) ' +
    'WHERE u.user_account_address = $1';
  return runChainDbQuery(queryString, [userAddress])
    .catch((err) => { throw boom.badImplementation(`Failed to get profile data for user at ${userAddress}: ${err.stack}`); });
};

const getCountries = () => {
  const queryString = 'SELECT m49, name, alpha2, alpha3 FROM COUNTRIES';
  return runChainDbQuery(queryString)
    .catch((err) => { throw boom.badImplementation(`Failed to get countries data: ${err}`); });
};

const getCountryByAlpha2Code = (alpha2) => {
  const queryString = 'SELECT m49, name, alpha2, alpha3 FROM COUNTRIES WHERE alpha2 = $1';
  return runChainDbQuery(queryString, [alpha2])
    .then((data) => {
      if (data.length === 0) throw boom.notFound(`No country found with given alpha2 code ${alpha2}`);
      return data[0];
    })
    .catch((err) => {
      if (err.isBoom) throw err;
      throw boom.badImplementation(`Failed to get country by alpha2 code ${alpha2}: ${err}`);
    });
};

const getRegionsOfCountry = (alpha2) => {
  const queryString = 'SELECT country, encode(region::bytea, \'hex\') AS region, code2, code3, name FROM REGIONS WHERE country = $1';
  return runChainDbQuery(queryString, [alpha2])
    .catch((err) => { throw boom.badImplementation(`Failed to get regions of country ${alpha2}: ${err}`); });
};

const getCurrencies = () => {
  const queryString = 'SELECT alpha3, m49, name FROM CURRENCIES';
  return runChainDbQuery(queryString)
    .catch((err) => { throw boom.badImplementation(`Failed to get currencies data: ${err}`); });
};

const getCurrencyByAlpha3Code = (alpha3) => {
  const queryString = 'SELECT alpha3, m49, name FROM CURRENCIES WHERE alpha3 = $1';
  return runChainDbQuery(queryString, [alpha3])
    .then((data) => {
      if (data.length === 0) throw boom.notFound(`No currency found with given alpha3 code ${alpha3}`);
      return data[0];
    })
    .catch((err) => {
      if (err.isBoom) throw err;
      throw boom.badImplementation(`Failed to get currency by alpha3 code ${alpha3}: ${err}`);
    });
};

const getParameterType = (paramType) => {
  const queryString = 'SELECT CAST(parameter_type AS INTEGER) AS "parameterType", label FROM PARAMETER_TYPES WHERE parameter_type = $1';
  return runChainDbQuery(queryString, [paramType])
    .then((data) => {
      if (!data) throw boom.notFound(`Parameter type ${paramType} not found`);
      return data;
    })
    .catch((err) => {
      if (err.isBoom) throw err;
      throw boom.badImplementation(`Failed to get parameter type ${paramType}: ${err}`);
    });
};

const getParameterTypes = () => {
  const queryString = 'SELECT CAST(parameter_type AS INTEGER) AS "parameterType", label FROM PARAMETER_TYPES';
  return runChainDbQuery(queryString)
    .catch((err) => { throw boom.badImplementation(`Failed to get parameter types: ${err}`); });
};

const getArchetypeData = (queryParams, userAccount) => {
  const queryString = 'SELECT a.archetype_address as address, a.name, a.author, a.description, a.price, a.active, a.is_private as "isPrivate", ' +
    '(SELECT cast(count(ad.archetype_address) as integer) FROM archetype_documents ad WHERE a.archetype_address = ad.archetype_address) AS "numberOfDocuments", ' +
    '(SELECT cast(count(af.archetype_address) as integer) FROM archetype_parameters af WHERE a.archetype_address = af.archetype_address) AS "numberOfParameters" ' +
    'FROM archetypes a ' +
    `WHERE (a.is_private = $1 AND a.active = $2 ${(queryParams ? `${where(queryParams, true)})` : ')')}` +
    `OR (a.author = $3 ${(queryParams ? `${where(queryParams, true)})` : ')')}`;
  return runChainDbQuery(queryString, [false, true, userAccount])
    .catch((err) => { throw boom.badImplementation(`Failed to get archetype data: ${err}`); });
};

const getArchetypeDataWithProcessDefinitions = (archetypeAddress, userAccount) => {
  const queryString =
    'SELECT a.archetype_address as address, a.name, a.author, a.description, a.price, a.active, a.is_private as "isPrivate", a.successor, a.formation_process_definition as "formationProcessDefinition", a.execution_process_definition as "executionProcessDefinition", ' +
    'd.model_id as "formationModelId", e.model_id as "executionModelId", ' +
    'd.model_address as "formationModelAddress", e.model_address as "executionModelAddress", ' +
    'd.id as "formationProcessId", e.id as "executionProcessId" ' +
    'FROM ARCHETYPES a ' +
    'LEFT JOIN process_definitions d ON a.formation_process_definition = d.process_definition_address ' +
    'LEFT JOIN process_definitions e ON a.execution_process_definition = e.process_definition_address ' +
    'WHERE archetype_address = $1 ' +
    'AND (a.is_private = $2 OR a.author = $3)';
  return runChainDbQuery(queryString, [archetypeAddress, false, userAccount])
    .then((data) => {
      if (data.length === 0) throw boom.notFound(`No archetypes found at address ${archetypeAddress}`);
      return data[0];
    })
    .catch((err) => {
      if (err.isBoom) throw err;
      throw boom.badImplementation(`Failed to get archetype data: ${err}`);
    });
};

const getArchetypeParameters = (archetypeAddress) => {
  const queryString =
    'SELECT ap.parameter_name AS name, ap.parameter_type AS type, pt.label AS label ' +
    'FROM ARCHETYPE_PARAMETERS ap ' +
    'JOIN PARAMETER_TYPES pt on ap.parameter_type = pt.parameter_type WHERE archetype_address = $1 ' +
    'ORDER BY ap.position';
  return runChainDbQuery(queryString, [archetypeAddress])
    .catch((err) => { throw boom.badImplementation(`Failed to get archetype parameters: ${err}`); });
};

const getArchetypeJurisdictionsAll = () => {
  const queryString = 'SELECT DISTINCT archetype_address AS address, country from archetype_jurisdictions';
  return runChainDbQuery(queryString)
    .catch((err) => { throw boom.badImplementation(`Failed to get all archetype jurisdictions: ${err}`); });
};

const getArchetypeJurisdictions = (archetypeAddress) => {
  const queryString = 'SELECT country, encode(region::bytea, \'hex\') AS region FROM archetype_jurisdictions WHERE archetype_address = $1';
  return runChainDbQuery(queryString, [archetypeAddress])
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
};

const getArchetypeDocuments = (archetypeAddress) => {
  const queryString = 'SELECT document_key AS name, encode(hoard_address::bytea, \'hex\') as "hoardAddress", ' +
    'encode(secret_key:: bytea, \'hex\') as "secretKey" FROM archetype_documents WHERE archetype_address = $1';
  return runChainDbQuery(queryString, [archetypeAddress])
    .catch((err) => { throw boom.badImplementation(`Failed to get documents for archetype: ${err}`); });
};

const getPackagesOfArchetype = (archetypeAddress) => {
  const queryString = 'SELECT UPPER(encode(ap.package_id::bytea, \'hex\')) AS id, p.name ' +
    'FROM archetype_to_package ap ' +
    'JOIN archetype_packages p ON ap.package_id = p.package_id ' +
    'WHERE ap.archetype_address = $1';
  return runChainDbQuery(queryString, [archetypeAddress])
    .catch((err) => { throw boom.badImplementation(`Failed to get packages of archetype: ${err}`); });
};

const getGoverningArchetypes = (archetypeAddress) => {
  const queryString = 'SELECT governing_archetype_address as address, governing_archetype_name as name ' +
    'FROM GOVERNING_ARCHETYPES ' +
    'WHERE archetype_address = $1';
  return runChainDbQuery(queryString, [archetypeAddress])
    .catch((err) => { throw boom.badImplementation(`Failed to get governing archetypes: ${err}`); });
};

const getArchetypePackages = (queryParams, userAccount) => {
  const queryString = 'SELECT UPPER(encode(package_id::bytea, \'hex\')) AS id, name, description, author, is_private as "isPrivate", active ' +
    'FROM ARCHETYPE_PACKAGES ' +
    `WHERE (is_private = $1 AND active = $2 ${(queryParams ? `${where(queryParams, true)})` : ')')}` +
    `OR (author = $3 ${(queryParams ? `${where(queryParams, true)})` : ')')}`;
  return runChainDbQuery(queryString, [false, true, userAccount])
    .then(data => data)
    .catch((err) => {
      if (err.isBoom) throw err;
      throw boom.badImplementation(`Failed to get archetype packages: ${err}`);
    });
};

const getArchetypePackage = (id, userAccount) => {
  const queryString = 'SELECT UPPER(encode(package_id::bytea, \'hex\')) AS id, name, description, author, is_private as "isPrivate", active ' +
    'FROM ARCHETYPE_PACKAGES ' +
    'WHERE ((is_private = FALSE AND active = TRUE) OR author = $1) AND ' +
    'package_id = $2;';
  return runChainDbQuery(queryString, [userAccount, `\\x${id}`])
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
};

const getArchetypesInPackage = (packageId) => {
  const queryString = 'SELECT a.name, a.archetype_address as address, a.active from ARCHETYPES a ' +
    'JOIN ARCHETYPE_TO_PACKAGE ap ON a.archetype_address = ap.archetype_address ' +
    'WHERE ap.package_id = $1';
  return runChainDbQuery(queryString, [`\\x${packageId}`])
    .catch((err) => { throw boom.badImplementation(`Failed to get archetypes in package ${packageId}: ${err}`); });
};

const currentUserAgreements = userAccount => `(
    a.creator = '${userAccount}' OR (
      ap.party = '${userAccount}'
    ) OR (
      a.creator IN (SELECT ou.organization_address FROM organization_users ou WHERE ou.user_address = '${userAccount}')
    ) OR (
      ap.party IN (SELECT ou.organization_address FROM organization_users ou WHERE ou.user_address = '${userAccount}')
    )
  ) `;

const getAgreements = (queryParams, forCurrentUser, userAccount) => {
  const queryString = 'SELECT DISTINCT(a.agreement_address) as address, a.archetype_address as archetype, a.name, a.creator, ' +
    'encode(a.hoard_address::bytea, \'hex\') as "hoardAddress", encode(a.hoard_secret::bytea, \'hex\') as "hoardSecret", ' +
    'encode(a.event_log_hoard_address::bytea, \'hex\') as "eventLogHoardAddress", encode(a.event_log_hoard_secret::bytea, \'hex\') as "eventLogHoardSecret", ' +
    'a.max_event_count::integer as "maxNumberOfEvents", a.is_private as "isPrivate", a.legal_state as "legalState", ' +
    'a.formation_process_instance as "formationProcessInstance", a.execution_process_instance as "executionProcessInstance", ' +
    '(SELECT count(ap.agreement_address) FROM agreement_to_party ap WHERE a.agreement_address = ap.agreement_address)::integer AS "numberOfParties" ' +
    'FROM agreements a ' +
    'LEFT JOIN agreement_to_party ap ON a.agreement_address = ap.agreement_address ' +
    `WHERE ${forCurrentUser ? currentUserAgreements(userAccount) : 'a.is_private = $1 '} ` +
    `${queryParams ? where(queryParams, true) : ''};`;
  const values = !forCurrentUser ? [false] : [];
  return runChainDbQuery(queryString, values)
    .catch((err) => { throw boom.badImplementation(`Failed to get agreement(s): ${err}`); });
};

const getAgreementData = (agreementAddress, userAccount) => {
  const queryString = 'SELECT a.agreement_address as address, a.archetype_address as archetype, a.name, a.creator, ' +
    'encode(a.hoard_address::bytea, \'hex\') as "hoardAddress", encode(a.hoard_secret::bytea, \'hex\') as "hoardSecret", ' +
    'encode(a.event_log_hoard_address::bytea, \'hex\') as "eventLogHoardAddress", encode(a.event_log_hoard_secret::bytea, \'hex\') as "eventLogHoardSecret", ' +
    'a.max_event_count::integer as "maxNumberOfEvents", a.is_private as "isPrivate", a.legal_state as "legalState", ' +
    'a.formation_process_instance as "formationProcessInstance", a.execution_process_instance as "executionProcessInstance", ' +
    'UPPER(encode(ac.collection_id::bytea, \'hex\')) as "collectionId", arch.formation_process_definition as "formationProcessDefinition", arch.execution_process_definition as "executionProcessDefinition" ' +
    'FROM agreements a ' +
    'LEFT JOIN agreement_to_collection ac ON a.agreement_address = ac.agreement_address ' +
    'LEFT JOIN agreement_to_party ap ON a.agreement_address = ap.agreement_address ' +
    'JOIN archetypes arch ON a.archetype_address = arch.archetype_address ' +
    `WHERE a.agreement_address = $1 AND (a.is_private = $2 OR ${currentUserAgreements(userAccount)})`;
  return runChainDbQuery(queryString, [agreementAddress, false])
    .catch((err) => { throw boom.badImplementation(`Failed to get agreement data: ${err}`); });
};

const getAgreementParties = (agreementAddress) => {
  const queryString = 'SELECT parties.party AS address, parties.signature_timestamp::integer as "signatureTimestamp", parties.signed_by as "signedBy", encode(user_accounts.id::bytea, \'hex\') as id ' +
    'FROM agreement_to_party parties ' +
    'LEFT JOIN user_accounts ON parties.party = user_accounts.user_account_address WHERE parties.agreement_address = $1;';
  return runChainDbQuery(queryString, [agreementAddress])
    .then(async (data) => {
      try {
        let users = [];
        let organizations = [];
        data.forEach((_party) => {
          if (_party.id) users.push(_party);
          else organizations.push(_party);
        });
        users = await setUserIds(users);
        organizations = await getNamesOfOrganizations(organizations);
        return users.concat(organizations);
      } catch (err) {
        throw boom.badImplementation(`Failed to get user/organization details for parties: ${err}`);
      }
    })
    .catch((err) => { throw boom.badImplementation(`Failed to get agreement parties: ${err}`); });
};

const getGoverningAgreements = (agreementAddress) => {
  const queryString = 'SELECT governing_agreement_address as address, governing_agreement_name as name ' +
    'FROM GOVERNING_AGREEMENTS ' +
    'WHERE agreement_address = $1';
  return runChainDbQuery(queryString, [agreementAddress])
    .catch((err) => { throw boom.badImplementation(`Failed to get governing agreements: ${err}`); });
};

const getAgreementEventLogDetails = (agreementAddress) => {
  const queryString = 'SELECT ' +
    'encode(a.event_log_hoard_address:: bytea, \'hex\') as "eventLogHoardAddress", encode(a.event_log_hoard_secret::bytea, \'hex\') as "eventLogHoardSecret", ' +
    'a.max_event_count::integer as "maxNumberOfEvents" FROM agreements a WHERE agreement_address = $1;';
  return runChainDbQuery(queryString, [agreementAddress])
    .then((data) => {
      if (!data.length) throw boom.notFound(`Agreement at address ${agreementAddress} not found`);
      return data[0];
    })
    .catch((err) => { throw boom.badImplementation(`Failed to get event log details of agreement: ${err}`); });
};

const getAgreementCollections = (userAccount) => {
  const queryString = 'SELECT UPPER(encode(collection_id::bytea, \'hex\')) as "id", name, author, collection_type::integer as "collectionType", UPPER(encode(package_id::bytea, \'hex\')) as "packageId" ' +
    'FROM AGREEMENT_COLLECTIONS ' +
    'WHERE author = $1 OR author IN (SELECT organization_address FROM organization_users WHERE user_address = $2)';
  return runChainDbQuery(queryString, [userAccount, userAccount])
    .catch((err) => { throw boom.badImplementation(`Failed to get agreement collections: ${err}`); });
};

const getAgreementCollectionData = (collectionId) => {
  const queryString = 'SELECT UPPER(encode(c.collection_id::bytea, \'hex\')) as id, c.name, c.author, c.collection_type::integer as "collectionType", UPPER(encode(c.package_id::bytea, \'hex\')) as "packageId", ' +
    'ac.agreement_address as "agreementAddress", ac.agreement_name as "agreementName", ac.archetype_address as archetype FROM AGREEMENT_COLLECTIONS c ' +
    'LEFT JOIN AGREEMENT_TO_COLLECTION ac ON ac.collection_id = c.collection_id ' +
    'WHERE c.collection_id = $1;';
  return runChainDbQuery(queryString, [`\\x${collectionId}`])
    .then((data) => {
      if (!data.length) throw boom.notFound(`Collection with id ${collectionId} not found`);
      return data;
    })
    .catch((err) => {
      if (err.isBoom) throw err;
      throw boom.badImplementation(`Failed to get details of agreement collection with id ${collectionId}: ${err}`);
    });
};

const getAgreementsInCollection = (collectionId) => {
  const queryString = 'SELECT agreement_address as "agreementAddress", agreement_name as "agreementName", archetype_address as archetype from AGREEMENT_TO_COLLECTION where collection_id = $1';
  return runChainDbQuery(queryString, [`\\x${collectionId}`])
    .catch((err) => { throw boom.badImplementation(`Failed to get agreements in collection ${collectionId}: ${err}`); });
};

const getActivityInstances = ({ processAddress, agreementAddress }) => {
  const queryString = 'SELECT ' +
    'DISTINCT(UPPER(encode(ai.activity_instance_id::bytea, \'hex\'))) as "activityInstanceId", ' +
    'ai.process_instance_address AS "processAddress",  ' +
    'ai.activity_id as "activityId",  ' +
    'ai.created::integer,  ' +
    'ai.completed::integer,  ' +
    'ai.performer,  ' +
    'ai.completed_by as "completedBy",  ' +
    'ai.state::integer, ' +
    'ai._height AS "blockNumber", ' +
    'ai._txhash AS "transactionHash", ' +
    'pd.model_address as "modelAddress",  ' +
    'pm.id as "modelId",  ' +
    'pd.id as "processDefinitionId",  ' +
    'pd.process_definition_address as "processDefinitionAddress",  ' +
    'pdat.address_value as "agreementAddress",  ' +
    'agr.name as "agreementName",  ' +
    'ad.task_type as "taskType"  ' +
    'FROM activity_instances ai  ' +
    'JOIN process_instances pi ON ai.process_instance_address = pi.process_instance_address ' +
    'JOIN activity_definitions ad ON ai.activity_id = ad.activity_id AND pi.process_definition_address = ad.process_definition_address ' +
    'JOIN process_definitions pd ON pd.process_definition_address = pi.process_definition_address ' +
    'JOIN process_models pm ON pm.model_address = pd.model_address ' +
    'LEFT JOIN process_data pdat ON ai.process_instance_address = pdat.process_instance_address ' +
    'LEFT JOIN agreements agr ON agr.agreement_address = pdat.address_value ' +
    'WHERE pdat.data_id = \'agreement\'' + // Hard-coded dataId 'agreement' which all processes in the Agreements Network have
    `${(processAddress ? ` AND ai.process_instance_address = '${processAddress}'` : '')}` +
    `${(agreementAddress ? ` AND pdat.address_value = '${agreementAddress}';` : ';')}`;
  return runChainDbQuery(queryString)
    .catch((err) => { throw boom.badImplementation(`Failed to get activities: ${err}`); });
};

const getActivityInstanceData = (id, userAddress) => {
  const queryString = `SELECT ai.state, ai.process_instance_address as "processAddress", UPPER(encode(ai.activity_instance_id::bytea, 'hex')) as "activityInstanceId", ai.activity_id as "activityId", ai.created, ai.performer, ai.completed, ad.task_type as "taskType", ad.application as application,
      pd.model_address as "modelAddress", pm.id as "modelId", pd.id as "processDefinitionId", pd.process_definition_address as "processDefinitionAddress", app.web_form as "webForm", app.application_type as "applicationType",
      pdat.address_value as "agreementAddress", pm.author as "modelAuthor", pm.is_private AS "isModelPrivate", agr.name as "agreementName", encode(scopes.fixed_scope, 'hex') AS scope, encode(o.organization_id::bytea, 'hex') as "organizationKey" 
    FROM activity_instances ai
    JOIN process_instances pi ON ai.process_instance_address = pi.process_instance_address
    JOIN activity_definitions ad ON ai.activity_id = ad.activity_id AND pi.process_definition_address = ad.process_definition_address
    JOIN process_definitions pd ON pd.process_definition_address = pi.process_definition_address
    JOIN process_models pm ON pm.model_address = pd.model_address
    LEFT JOIN process_data pdat ON ai.process_instance_address = pdat.process_instance_address
    LEFT JOIN agreements agr ON agr.agreement_address = pdat.address_value
    LEFT JOIN applications app ON app.application_id = ad.application
    LEFT JOIN organization_accounts o ON o.organization_address = ai.performer 
    LEFT JOIN process_instance_address_scopes scopes ON (
      scopes.process_instance_address = pdat.process_instance_address 
      AND scopes.key_address = ai.performer 
      AND scopes.key_context = ai.activity_id
    )
    WHERE ai.activity_instance_id = $1
    AND (
      ai.performer = $2 OR (
        ai.performer IN (
          select organization_address FROM organization_users ou WHERE ou.user_address = $2
        ) AND (
          (
            scopes.fixed_scope IS NULL AND UPPER('${DEFAULT_DEPARTMENT_ID}') IN (
              SELECT department_id FROM department_users du WHERE du.user_address = $2 AND du.organization_address = ai.performer
            )
          ) OR encode(scopes.fixed_scope, 'hex') IN (
            select RPAD(encode(department_id::bytea, 'hex'), 64, '0') FROM department_users du WHERE du.user_address = $2 AND du.organization_address = ai.performer
          ) OR scopes.fixed_scope = (
            select organization_id FROM organization_accounts o WHERE o.organization_address = ai.performer
          ) OR (
            scopes.fixed_scope IS NOT NULL AND encode(scopes.fixed_scope, 'hex') NOT IN (
              select RPAD(encode(department_id::bytea, 'hex'), 64, '0') FROM organization_departments od WHERE od.organization_address = ai.performer
            ) AND '${DEFAULT_DEPARTMENT_ID}' IN (
              SELECT department_id FROM department_users du WHERE du.user_address = $2 AND du.organization_address = performer
            )
          )
        )
      )
    )
    AND pdat.data_id = 'agreement'`; // Hard-coded dataId 'agreement' which all processes in the Agreements Network have
  return runChainDbQuery(queryString, [`\\x${id}`, userAddress])
    .then((data) => {
      if (!data) throw boom.notFound(`Activity ${id} not found`);
      return data;
    })
    .catch((err) => {
      if (err.isBoom) throw err;
      throw boom.badImplementation(`Failed to get activity instance ${id}: ${err}`);
    });
};

const getAccessPointDetails = (dataMappings = [], applicationId) => {
  const dataMappingIds = dataMappings.map(d => d.dataMappingId);
  const queryString = 'SELECT access_point_id as "accessPointId", data_type as "dataType", direction ' +
    'FROM application_access_points WHERE application_id = $1 ' +
    `AND access_point_id IN ('${dataMappingIds.join("', '")}')`;
  return runChainDbQuery(queryString, [applicationId])
    .catch((err) => { throw boom.badImplementation(`Failed to get data types for data mappings ids ${JSON.stringify(dataMappings)}: ${err}`); });
};

const getTasksByUserAddress = (userAddress) => {
  // IMPORTANT: The below query uses two LEFT JOIN to retrieve data from the agreement that is attached to the process in one single query.
  // This relies on the fact that all processes in the Agreements Network have a process data with the ID "agreement".
  // If we ever want to retrieve more process data (from other data objects in the process or flexibly retrieve data based on a future process configuration aka 'descriptors'), multiple queries will have to be used
  const queryString = `SELECT ai.state, ai.process_instance_address as "processAddress", UPPER(encode(ai.activity_instance_id::bytea, 'hex')) as "activityInstanceId", ai.activity_id as "activityId", ai.created, ai.performer, 
    pd.model_address as "modelAddress", pd.process_definition_address as "processDefinitionAddress", pd.id as "processDefinitionId", 
    agr.name as "agreementName", pm.id as "modelId", pdat.address_value as "agreementAddress", encode(scopes.fixed_scope::bytea, 'hex') AS scope, encode(o.organization_id::bytea, 'hex') as "organizationKey"
    FROM activity_instances ai
    JOIN process_instances pi ON ai.process_instance_address = pi.process_instance_address
    JOIN activity_definitions ad ON ai.activity_id = ad.activity_id AND pi.process_definition_address = ad.process_definition_address
    JOIN process_definitions pd ON pd.process_definition_address = pi.process_definition_address
    JOIN process_models pm ON pm.model_address = pd.model_address
    LEFT JOIN process_data pdat ON ai.process_instance_address = pdat.process_instance_address
    LEFT JOIN agreements agr ON agr.agreement_address = pdat.address_value
    LEFT JOIN organization_accounts o ON o.organization_address = ai.performer
    LEFT JOIN process_instance_address_scopes scopes ON (
      scopes.process_instance_address = pdat.process_instance_address
      AND scopes.key_address = ai.performer 
      AND scopes.key_context = ai.activity_id
    )
    WHERE ad.task_type = 1
    AND ai.state = 4
    AND (
      performer = $1 OR (
        performer IN (
          select organization_address FROM organization_users ou WHERE ou.user_address = $1
        ) AND (
          (
            scopes.fixed_scope IS NULL AND '${DEFAULT_DEPARTMENT_ID}' IN (
              SELECT department_id FROM department_users du WHERE du.user_address = $1 AND du.organization_address = ai.performer
            )
          ) OR encode(scopes.fixed_scope, 'hex') IN (
            select RPAD(encode(department_id::bytea, 'hex'), 64, '0') FROM department_users du WHERE du.user_address = $1 AND du.organization_address = ai.performer
          ) OR scopes.fixed_scope = (
            select organization_id FROM organization_accounts o WHERE o.organization_address = ai.performer
          ) OR (
            scopes.fixed_scope IS NOT NULL AND encode(scopes.fixed_scope, 'hex') NOT IN (
              select RPAD(encode(department_id::bytea, 'hex'), 64, '0') FROM organization_departments od WHERE od.organization_address = ai.performer
            ) AND '${DEFAULT_DEPARTMENT_ID}' IN (
              SELECT department_id FROM department_users du WHERE du.user_address = $1 AND du.organization_address = performer
            )
          )
        )
      )
    )
    AND pdat.data_id = 'agreement';`; // Hard-coded dataId 'agreement' which all processes in the Agreements Network have
  return runChainDbQuery(queryString, [userAddress])
    .catch((err) => { throw boom.badImplementation(`Failed to get tasks assigned to user: ${err}`); });
};

const getModels = (author) => {
  const queryString = 'SELECT model_address as "modelAddress", ' +
    'id, name, author, is_private as "isPrivate", active, ' +
    'encode(diagram_address:: bytea, \'hex\') as "diagramAddress", ' +
    'encode(diagram_secret::bytea, \'hex\') as "diagramSecret", ' +
    'CAST(version_major AS INTEGER) AS "versionMajor", ' +
    'CAST(version_minor AS INTEGER) AS "versionMinor", ' +
    'CAST(version_patch AS INTEGER) AS "versionPatch" ' +
    'FROM process_models WHERE is_private = $1 OR author = $2';
  return runChainDbQuery(queryString, [false, author])
    .catch((err) => { throw boom.badImplementation(`Failed to get process model(s): ${err}`); });
};

const getApplications = () => {
  const queryString = 'SELECT encode(a.application_id::bytea, \'hex\') AS id, a.application_type as "applicationType", a.location, encode(a.web_form::bytea, \'hex\') as "webForm", ' +
    'encode(aap.access_point_id::bytea, \'hex\') as "accessPointId", aap.data_type as "dataType", aap.direction ' +
    'FROM applications a LEFT JOIN application_access_points aap ON aap.application_id = a.application_id';
  return runChainDbQuery(queryString)
    .catch((err) => { throw boom.badImplementation(`Failed to get applications: ${err}`); });
};

const getProcessDefinitions = (author, interfaceId) => {
  const queryString = 'SELECT pd.id as "processDefinitionId", pd.process_definition_address AS address, pd.model_address as "modelAddress", pd.interface_id as "interfaceId", pm.id as "modelId", encode(pm.diagram_address::bytea, \'hex\') as "diagramAddress", encode(pm.diagram_secret::bytea, \'hex\') as "diagramSecret", pm.is_private as "isPrivate", pm.author ' +
    'FROM process_definitions pd JOIN process_models pm ' +
    'ON pd.model_address = pm.model_address ' +
    `WHERE pm.is_private = $1 OR pm.author = $2 ${(interfaceId ? 'AND interfaceId = $3;' : ';')}`;
  const params = [false, author];
  if (interfaceId) params.push(interfaceId);
  return runChainDbQuery(queryString, params)
    .catch((err) => { throw boom.badImplementation(`Failed to get process definitions: ${err}`); });
};

const getProcessDefinitionData = (address) => {
  const queryString = 'SELECT pd.id as "processDefinitionId", pd.process_definition_address AS address, pd.model_address as "modelAddress", pd.interface_id as "interfaceId", encode(pm.diagram_address::bytea, \'hex\') as "diagramAddress", encode(pm.diagram_secret::bytea, \'hex\') as "diagramSecret", pm.is_private as "isPrivate", pm.author, pm.id as "modelId" ' +
    'FROM process_definitions pd JOIN process_models pm ' +
    'ON pd.model_address = pm.model_address WHERE pd.process_definition_address = $1;';
  return runChainDbQuery(queryString, [address])
    .catch((err) => { throw boom.badImplementation(`Failed to get process definition: ${err}`); });
};

const getProcessModelData = (address) => {
  const queryString = 'SELECT model_address as "modelAddress", id, name, author, is_private as "isPrivate", active, encode(diagram_address::bytea, \'hex\') as "diagramAddress", encode(diagram_secret::bytea, \'hex\') as "diagramSecret", version_major as "versionMajor", version_minor as "versionMinor", version_patch as "versionPatch" FROM process_models pm ' +
    'WHERE pm.model_address = $1;';
  return runChainDbQuery(queryString, [address])
    .catch((err) => { throw boom.badImplementation(`Failed to get process model: ${err}`); });
};

const getActivityDetailsFromCache = (activityId, modelId, processId) => {
  const queryString = 'SELECT activity_name as "activityName", process_name as "processName" FROM activity_details WHERE activity_id = $1 AND process_id = $2 AND model_id = $3';
  return runAppDbQuery(queryString, [activityId, processId, modelId])
    .then(rows => rows[0] || {});
};

const updateActivityDetailsCache = (modelId, processDefinitionId, processName, activityId, name) => {
  const queryString = 'INSERT INTO ACTIVITY_DETAILS (model_id, process_id, process_name, activity_id, activity_name) VALUES($1, $2, $3, $4, $5) ' +
    'ON CONFLICT ON CONSTRAINT activity_details_pkey DO UPDATE SET activity_name = $5';
  return runAppDbQuery(queryString, [modelId, processDefinitionId, processName, activityId, name]);
};

const getProcessDetailsFromCache = (modelId, processId) => {
  const queryString = 'SELECT process_id as "processDefinitionId", process_name as "processName" FROM PROCESS_DETAILS WHERE model_id = $1 AND process_id = $2;';
  return runAppDbQuery(queryString, [modelId, processId])
    .then(rows => rows[0] || {});
};

const updateProcessDetailsCache = (modelId, processDefinitionId, processName) => {
  const queryString = 'INSERT INTO PROCESS_DETAILS (model_id, process_id, process_name) VALUES($1, $2, $3) ' +
    'ON CONFLICT ON CONSTRAINT process_details_pkey DO UPDATE SET process_name = $3';
  return runAppDbQuery(queryString, [modelId, processDefinitionId, processName]);
};

const getUserByActivationCode = (activationCode) => {
  const queryString = 'SELECT u.address, u.id as "userId" FROM user_activation_requests uar JOIN users u ON uar.user_id = u.id WHERE activation_code_digest = $1';
  return runAppDbQuery(queryString, [activationCode]);
};

const updateUserActivation = async (userAddress, userId, activated, activationCodeHex) => {
  // set user to activated
  try {
    const updateUsersQuery = 'UPDATE users SET activated = $1 WHERE address = $2';
    await runAppDbQuery(updateUsersQuery, [activated, userAddress]);
  } catch (err) {
    throw boom.badImplementation(`Failed to set user to activated for user at ${userAddress}: ${err.stack}`);
  }
  // delete user activation code from table
  try {
    const deleteCodeQuery = 'DELETE FROM user_activation_requests WHERE user_id = $1 AND activation_code_digest = $2';
    await runAppDbQuery(deleteCodeQuery, [userId, activationCodeHex]);
  } catch (err) {
    log.error(`Failed to delete row in user_activation_requests for user id ${userId} at ${userAddress}: ${err.stack}`);
  }
};

const getDbUserIdByAddress = (userAddress) => {
  const queryString = 'SELECT id from users WHERE address = $1';
  return runAppDbQuery(queryString, [userAddress]);
};

module.exports = {
  getOrganizations,
  getOrganization,
  getUsers,
  getProfile,
  getCountries,
  getCountryByAlpha2Code,
  getRegionsOfCountry,
  getCurrencies,
  getCurrencyByAlpha3Code,
  getParameterType,
  getParameterTypes,
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
  getAgreementParties,
  getGoverningAgreements,
  getAgreementEventLogDetails,
  getAgreementCollections,
  getAgreementCollectionData,
  getAgreementsInCollection,
  getActivityInstances,
  getActivityInstanceData,
  getAccessPointDetails,
  getTasksByUserAddress,
  getModels,
  getApplications,
  getProcessDefinitions,
  getProcessDefinitionData,
  getProcessModelData,
  getActivityDetailsFromCache,
  updateActivityDetailsCache,
  getProcessDetailsFromCache,
  updateProcessDetailsCache,
  getUserByActivationCode,
  updateUserActivation,
  getDbUserIdByAddress,
};
