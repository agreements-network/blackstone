const boom = require('boom');
const contracts = require('./contracts-controller');
const {
  where,
  format,
  setUserIds,
  rightPad,
  getNamesOfOrganizations,
} = require(`${global.__common}/controller-dependencies`);
const pool = require(`${global.__common}/postgres-db`);
const { DEFAULT_DEPARTMENT_ID } = global.__monax_constants;

const getOrganizations = queryParams => new Promise((resolve, reject) => {
  const queryString = 'SELECT o.organization AS address, oa.approverKey as approver ' +
      `FROM organizations o JOIN organization_approvers oa ON (o.organization = oa.organization) ${where(queryParams)}`;
  contracts.cache.db.all(queryString, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get organizations: ${err}`));
    return resolve(data);
  });
});

const getOrganization = orgAddress => new Promise((resolve, reject) => {
  const queryString =
      'SELECT o.organization AS address, o.organizationKey, oa.approverKey AS approver, ou.userKey AS user, od.departmentKey AS department, od.name AS departmentName, du.departmentUserKey ' +
      'FROM organizations o JOIN organization_approvers oa ON (o.organization = oa.organization) ' +
      'LEFT JOIN organization_users ou ON (o.organization = ou.organization) ' +
      'LEFT JOIN organization_departments od ON (o.organization = od.organization) ' +
      'LEFT JOIN department_users du ON (od.departmentKey = du.departmentKey) AND (du.departmentUserKey = ou.userKey) AND (od.organization = du.organization) ' +
      'WHERE o.organization = ? ';
  contracts.cache.db.all(queryString, orgAddress, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get data for organization at ${orgAddress}: ${err}`));
    if (!data || !data.length) { return reject(boom.notFound(`No organization found at address ${orgAddress}`)); }
    return resolve(data);
  });
});

const getUsers = queryParams => new Promise((resolve, reject) => {
  const queryString = `SELECT userAccount AS address FROM users ${(queryParams ? `${where(queryParams, false)}` : '')}`;
  contracts.cache.db.all(queryString, async (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get users: ${err}`));
    try {
      return resolve(await setUserIds(data, true, 'User'));
    } catch (userIdErr) {
      return reject(boom.badImplementation(`Failed to get users: ${userIdErr}`));
    }
  });
});

const getProfile = userAddress => new Promise((resolve, reject) => {
  const queryString =
      'SELECT u.userAccount AS address, o.organizationKey, ou.organization, du.departmentKey AS department, od.name AS departmentName ' +
      'FROM USERS u LEFT JOIN ORGANIZATION_USERS ou ON u.userAccount = ou.userKey ' +
      'LEFT JOIN organizations o ON o.organization = ou.organization ' +
      'LEFT JOIN organization_departments od ON ou.organization = od.organization ' +
      'LEFT JOIN department_users du ON (od.departmentKey = du.departmentKey) AND (du.departmentUserKey = ou.userKey) AND (ou.organization = du.organization) ' +
      'WHERE u.userAccount = ?';
  contracts.cache.db.all(queryString, userAddress, async (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get profile for user at ${userAddress}`));
    if (!data.length) return reject(boom.notFound(`No user found with given address: ${userAddress}`));
    return resolve(data);
  });
});

const getCountries = () => new Promise((resolve, reject) => {
  const queryString = 'SELECT * FROM COUNTRIES';
  contracts.cache.db.all(queryString, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get countries data: ${err}`));
    return resolve(data);
  });
});

const getCountryByAlpha2Code = alpha2 => new Promise((resolve, reject) => {
  const hexAlpha2 = global.stringToHex(alpha2);
  const queryString = 'SELECT * FROM COUNTRIES WHERE country = ?';
  contracts.cache.db.all(queryString, hexAlpha2, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get country by alpha2 code ${alpha2}: ${err}`));
    if (data.length > 0) return resolve(data[0]);
    return reject(boom.notFound(`No country found with given alpha2 code ${alpha2}`));
  });
});

const getRegionsOfCountry = alpha2 => new Promise((resolve, reject) => {
  const hexAlpha2 = global.stringToHex(alpha2);
  const queryString = 'SELECT * FROM REGIONS WHERE country = ?';
  contracts.cache.db.all(queryString, hexAlpha2, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get regions of country ${alpha2}: ${err}`));
    return resolve(data);
  });
});

const getCurrencies = () => new Promise((resolve, reject) => {
  const queryString = 'SELECT * FROM CURRENCIES';
  contracts.cache.db.all(queryString, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get currencies data: ${err}`));
    return resolve(data);
  });
});

const getCurrencyByAlpha3Code = alpha3 => new Promise((resolve, reject) => {
  const hexAlpha3 = global.stringToHex(alpha3);
  const queryString = 'SELECT * FROM CURRENCIES WHERE alpha3 = ?';
  contracts.cache.db.all(queryString, hexAlpha3, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get currency by alpha3 code ${alpha3}: ${err}`));
    if (data.length > 0) return resolve(data[0]);
    return reject(boom.notFound(`No currency found with given alpha3 code ${alpha3}`));
  });
});

const getParameterTypeById = id => new Promise((resolve, reject) => {
  const queryString = 'SELECT * FROM PARAMETER_TYPES WHERE id = ?';
  contracts.cache.db.get(queryString, id, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get parameter type for id ${id}: ${err}`));
    if (!data) return reject(boom.notFound(`Parameter type with id ${id} not found`));
    return resolve(data);
  });
});

const getParameterTypes = () => new Promise((resolve, reject) => {
  const queryString = 'SELECT * FROM PARAMETER_TYPES';
  contracts.cache.db.all(queryString, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get parameter types: ${err}`));
    return resolve(data);
  });
});

const getArchetypeData = (queryParams, userAccount) => new Promise((resolve, reject) => {
  const queryString = 'SELECT a.address, a.name, a.author, a.description, a.active, a.isPrivate, ' +
      '(SELECT count(ad.address) FROM archetype_documents ad WHERE a.address = ad.address) AS numberOfDocuments, ' +
      '(SELECT count(af.address) FROM archetype_parameters af WHERE a.address = af.address) AS numberOfParameters ' +
      'FROM archetypes a ' +
      `WHERE (a.isPrivate = 0 AND a.active = 1 ${(queryParams ? `${where(queryParams, true)})` : ')')}` +
      `OR (a.author = '${userAccount}' ${(queryParams ? `${where(queryParams, true)})` : ')')}`;
  contracts.cache.db.all(queryString, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get archetype data: ${err}`));
    return resolve(data);
  });
});

const getArchetypeDataWithProcessDefinitions = (archetypeAddress, userAccount) => new Promise((resolve, reject) => {
  const queryString =
    'SELECT a.*, ' +
    'd.modelId as formationModelId, e.modelId as executionModelId, ' +
    'd.modelAddress as formationModelAddress, e.modelAddress as executionModelAddress, ' +
    'd.id as formationProcessId, e.id as executionProcessId ' +
    'FROM ARCHETYPES a ' +
    'LEFT JOIN process_definitions d ON a.formationProcessDefinition = d.processDefinitionAddress ' +
    'LEFT JOIN process_definitions e ON a.executionProcessDefinition = e.processDefinitionAddress ' +
    'WHERE address = ? ' +
    `AND (a.isPrivate = 0 OR a.author = '${userAccount}')`;
  contracts.cache.db.all(queryString, archetypeAddress, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get archetype data: ${err}`));
    return resolve(data[0]);
  });
});

const getArchetypeParameters = archetypeAddress => new Promise((resolve, reject) => {
  const queryString =
      'SELECT af.parameter_key AS name, ft.parameterType AS type, ft.label AS label ' +
      'FROM ARCHETYPE_PARAMETERS af ' +
      'JOIN PARAMETER_TYPES ft on af.parameterType = ft.parameterType WHERE address = ? ' +
      'ORDER BY af.position';
  contracts.cache.db.all(queryString, archetypeAddress, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get archetype parameters: ${err}`));
    const parameters = [];
    data.forEach((elem) => { parameters.push(format('Parameter', elem)); });
    return resolve(parameters);
  });
});

const getArchetypeJurisdictionsAll = () => new Promise((resolve, reject) => {
  const queryString = 'select distinct address, country from archetype_jurisdictions';
  contracts.cache.db.all(queryString, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get all archetype jurisdictions: ${err}`));
    return resolve(data);
  });
});

const getArchetypeJurisdictions = archetypeAddress => new Promise((resolve, reject) => {
  const queryString = 'SELECT * FROM archetype_jurisdictions WHERE address = ?';
  contracts.cache.db.all(queryString, archetypeAddress, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get jurisdictions for archetype: ${err}`));
    const jurisdictions = []; const
      countries = {};
    data.forEach((resultJ) => {
      if (countries[global.hexToString(resultJ.country)]) {
        jurisdictions.forEach((dataJ) => {
          if (
            global.hexToString(resultJ.country) === dataJ.country &&
              resultJ.region.length > 0
          ) { dataJ.regions.push(resultJ.region); }
        });
      } else {
        countries[global.hexToString(resultJ.country)] = 1;
        jurisdictions.push({
          country: global.hexToString(resultJ.country),
          regions: resultJ.region.length > 0 ? [resultJ.region] : [],
        });
      }
    });
    return resolve(jurisdictions);
  });
});

const getArchetypeDocuments = archetypeAddress => new Promise((resolve, reject) => {
  const queryString = 'SELECT document_key AS name, hoardAddress, secretKey FROM archetype_documents WHERE address = ?';
  contracts.cache.db.all(queryString, archetypeAddress, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get documents for archetype: ${err}`));
    return resolve(data);
  });
});

const getPackagesOfArchetype = archetypeAddress => new Promise((resolve, reject) => {
  const queryString = 'SELECT ap.package_key AS id, p.name FROM archetype_to_package ap ' +
                      'JOIN archetype_packages p ON ap.package_key = p.package_key ' +
                      'WHERE ap.archetypeAddress = ?';
  contracts.cache.db.all(queryString, archetypeAddress, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get packages of archetype: ${err}`));
    return resolve(data);
  });
});

const getGoverningArchetypes = archetypeAddress => new Promise((resolve, reject) => {
  const queryString = 'SELECT governingArchetypeAddress as address, name ' +
                      'FROM GOVERNING_ARCHETYPES ' +
                      'WHERE address = ?';
  contracts.cache.db.all(queryString, archetypeAddress, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get governing archetypes: ${err}`));
    return resolve(data);
  });
});

const getArchetypePackages = (queryParams, userAccount) => new Promise((resolve, reject) => {
  const queryString = 'SELECT package_key as id, name, description, author, isPrivate, active ' +
      'FROM ARCHETYPE_PACKAGES ' +
    `WHERE (isPrivate = 0 AND active = 1 ${(queryParams ? `${where(queryParams, true)})` : ')')}` +
    `OR (author = '${userAccount}' ${(queryParams ? `${where(queryParams, true)})` : ')')}`;
  contracts.cache.db.all(queryString, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get archetype packages: ${err}`));
    if (queryParams && queryParams.package_key && data.length > 0) {
      return resolve(data[0]);
    }
    if (queryParams && queryParams.package_key && !data.length) {
      return reject(boom.notFound(`Package with id ${queryParams.package_key} not found`));
    }
    return resolve(data);
  });
});

const getArchetypesInPackage = packageId => new Promise((resolve, reject) => {
  const queryString = 'SELECT a.name, a.address, a.active from ARCHETYPES a ' +
                      'JOIN ARCHETYPE_TO_PACKAGE ap ON a.address = ap.archetypeAddress ' +
                      'WHERE ap.package_key = ?';
  contracts.cache.db.all(queryString, packageId, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get archetypes in package ${packageId}: ${err}`));
    return resolve(data);
  });
});

const currentUserAgreements = userAccount => `(
    a.creator = '${userAccount}' OR (
      ap.partyByAgreement = '${userAccount}'
    ) OR (
      a.creator IN (SELECT ou.organization FROM organization_users ou WHERE ou.userAddress = '${userAccount}')
    ) OR (
      ap.partyByAgreement IN (SELECT ou.organization FROM organization_users ou WHERE ou.userAddress = '${userAccount}')
    )
  ) `;

const getAgreements = (queryParams, forCurrentUser, userAccount) => new Promise((resolve, reject) => {
  const queryString = 'SELECT DISTINCT(a.address), a.*, ' +
      '(SELECT count(ap.address) FROM agreements_to_parties ap WHERE a.address = ap.address) AS numberOfParties ' +
      'FROM agreements a ' +
      'LEFT JOIN agreements_to_parties ap ON a.address = ap.address ' +
      `WHERE ${forCurrentUser ? currentUserAgreements(userAccount) : 'a.isPrivate = 0 '} ` +
      `${queryParams ? where(queryParams, true) : ''};`;
  contracts.cache.db.all(queryString, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get agreement(s): ${err}`));
    return resolve(data);
  });
});

const getAgreementData = (agreementAddress, userAccount) => new Promise((resolve, reject) => {
  const queryString = `SELECT a.address, a.*, ac.collectionId, 
    arch.formationProcessDefinition, arch.executionProcessDefinition FROM agreements a 
    LEFT JOIN agreement_to_collection ac ON a.address = ac.agreementAddress 
    LEFT JOIN agreements_to_parties ap ON a.address = ap.address 
    JOIN archetypes arch ON a.archetype = arch.address 
    WHERE a.address = ? AND (a.isPrivate = 0 OR ${currentUserAgreements(userAccount)})`;
  contracts.cache.db.get(queryString, agreementAddress, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get agreement data: ${err}`));
    return resolve(data);
  });
});

const getAgreementParties = agreementAddress => new Promise((resolve, reject) => {
  const queryString =
      'SELECT parties.partyByAgreement AS address, parties.signatureTimestamp, parties.signedBy, users.id AS id ' +
      'FROM agreements_to_parties parties ' +
      'LEFT JOIN users ON parties.partyByAgreement = users.userAccount WHERE parties.address = ?;';
  contracts.cache.db.all(queryString, agreementAddress, async (err, partyResults) => {
    if (err) return reject(boom.badImplementation(`Failed to get agreement parties: ${err}`));
    try {
      let users = [];
      let organizations = [];
      partyResults.forEach((_party) => {
        const party = format('Party', _party);
        if (party.id) users.push(party);
        else organizations.push(party);
      });
      users = await setUserIds(users);
      organizations = await getNamesOfOrganizations(organizations);
      return resolve(users.concat(organizations));
    } catch (getInfoErr) {
      return reject(boom.badImplementation(`Failed to get agreement parties: ${getInfoErr}`));
    }
  });
});

const getGoverningAgreements = agreementAddress => new Promise((resolve, reject) => {
  const queryString = 'SELECT governingAgreementAddress as address, name ' +
                      'FROM GOVERNING_AGREEMENTS ' +
                      'WHERE address = ?';
  contracts.cache.db.all(queryString, agreementAddress, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get governing agreements: ${err}`));
    return resolve(data);
  });
});

const getAgreementEventLogDetails = agreementAddress => new Promise((resolve, reject) => {
  const queryString = 'SELECT eventLogHoardAddress, eventLogHoardSecret, maxNumberOfEvents FROM agreements WHERE address = ?';
  contracts.cache.db.get(queryString, agreementAddress, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get event log details of agreement: ${err}`));
    return resolve(data);
  });
});

const getAgreementCollections = userAccount => new Promise((resolve, reject) => {
  const queryString = 'SELECT collectionId as id, name, author, collectionType, packageId from AGREEMENT_COLLECTIONS ' +
    'WHERE author = ? OR author IN (SELECT organization FROM organization_users WHERE userKey = ?)';
  contracts.cache.db.all(queryString, userAccount, userAccount, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get agreement collections: ${err}`));
    return resolve(data);
  });
});

const getAgreementCollectionData = collectionId => new Promise((resolve, reject) => {
  const queryString = 'SELECT c.collectionId as id, c.name, c.author, c.collectionType, c.packageId, ' +
    'ac.agreementAddress, ac.agreementName, ac.archetype FROM AGREEMENT_COLLECTIONS c ' +
    'LEFT JOIN AGREEMENT_TO_COLLECTION ac ON ac.collectionId = c.collectionId ' +
    'WHERE c.collectionId = ?';
  contracts.cache.db.all(queryString, collectionId, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get agreement collections: ${err}`));
    if (!data.length) reject(boom.notFound(`Collection with id ${collectionId} not found`));
    return resolve(data);
  });
});

const getAgreementsInCollection = collectionId => new Promise((resolve, reject) => {
  const queryString = 'SELECT agreementAddress, agreementName, archetype from AGREEMENT_TO_COLLECTION where collectionId = ?';
  contracts.cache.db.all(queryString, collectionId, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get agreements in collection ${collectionId}: ${err}`));
    return resolve(data);
  });
});

const getActivityInstances = ({ processAddress, agreementAddress }) => new Promise((resolve, reject) => {
  const queryString = 'SELECT DISTINCT(ai.activityInstanceId), ai.processAddress AS processAddress, ai.activityId, ai.created, ai.completed, ai.performer, ai.completedBy, ai.state, ' +
    'pd.modelAddress as modelAddress, pm.id as modelId, pd.id as processDefinitionId, pd.processDefinitionAddress as processDefinitionAddress, pdat.addressValue as agreementAddress, agr.name as agreementName, ad.taskType ' +
    'FROM activity_instances ai ' +
    'JOIN process_instances pi ON ai.processAddress = pi.processAddress ' +
    'JOIN activity_definitions ad ON ai.activityId = ad.activityDefinitionId AND pi.processDefinition = ad.processDefinitionAddress ' +
    'JOIN process_definitions pd ON pd.processDefinitionAddress = pi.processDefinition ' +
    'JOIN process_models pm ON pm.modelAddress = pd.modelAddress ' +
    'LEFT JOIN process_data pdat ON ai.processAddress = pdat.processAddress ' +
    'LEFT JOIN agreements agr ON agr.address = pdat.addressValue ' +
    'WHERE pdat.dataId = "61677265656D656E740000000000000000000000000000000000000000000000"' + // Hard-coded hex-value of dataId 'agreement' which all processes in the Agreements Network have
    `${(processAddress ? ' AND ai.processAddress = ?' : '')}` +
    `${(agreementAddress ? ' AND pdat.addressValue = ?;' : ';')}`;
  const queryArguments = [queryString];
  if (processAddress) queryArguments.push(processAddress);
  if (agreementAddress) queryArguments.push(agreementAddress);
  contracts.cache.db.all(...queryArguments, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get activities: ${err}`));
    return resolve(data);
  });
});

const getActivityInstanceData = (id, userAddress) => new Promise((resolve, reject) => {
  const hexedDefDepId = rightPad(global.stringToHex(DEFAULT_DEPARTMENT_ID), 32);
  const queryString = `SELECT ai.state, ai.processAddress, ai.activityInstanceId, ai.activityId, ai.created, ai.performer, ai.completed, ad.taskType, ad.application as application,
    pd.modelAddress as modelAddress, pm.id as modelId, pd.id as processDefinitionId, pd.processDefinitionAddress as processDefinitionAddress, app.webForm, app.applicationType,
    pdat.addressValue as agreementAddress, pm.author as modelAuthor, pm.isPrivate AS isModelPrivate, agr.name as agreementName, scopes.fixedScope AS scope, o.organizationKey 
    FROM activity_instances ai
    JOIN process_instances pi ON ai.processAddress = pi.processAddress
    JOIN activity_definitions ad ON ai.activityId = ad.activityDefinitionId AND pi.processDefinition = ad.processDefinitionAddress
    JOIN process_definitions pd ON pd.processDefinitionAddress = pi.processDefinition
    JOIN process_models pm ON pm.modelAddress = pd.modelAddress
    LEFT JOIN process_data pdat ON ai.processAddress = pdat.processAddress
    LEFT JOIN agreements agr ON agr.address = pdat.addressValue
    LEFT JOIN applications app ON app.applicationId = ad.application
    LEFT JOIN organizations o ON o.organization = ai.performer 
    LEFT JOIN process_instance_address_scopes scopes ON (
      scopes.processAddress = pdat.processAddress 
      AND scopes.keyAddress = ai.performer 
      AND scopes.keyContext = ai.activityId
    )
    WHERE ai.activityInstanceId = ?
    AND (
      ai.performer = ? OR (
        ai.performer IN (
          select organization FROM organization_users ou WHERE ou.userKey = ?
        ) AND (
          (
            scopes.fixedScope IS NULL AND UPPER('${hexedDefDepId}') IN (
              SELECT departmentKey FROM department_users du WHERE du.departmentUserKey = ? AND du.organization = ai.performer
            )
          ) OR scopes.fixedScope IN (
            select departmentKey FROM department_users du WHERE du.departmentUserKey = ? AND du.organization = ai.performer
          ) OR scopes.fixedScope = (
            select organizationKey FROM organizations o WHERE o.organization = ai.performer
          ) OR (
            scopes.fixedScope IS NOT NULL AND scopes.fixedScope NOT IN (
              select departmentKey FROM organization_departments od WHERE od.organization = ai.performer
            ) AND UPPER('${hexedDefDepId}') IN (
              SELECT departmentKey FROM department_users du WHERE du.departmentUserKey = ? AND du.organization = performer
            )
          )
        )
      )
    )
    AND pdat.dataId = '61677265656D656E740000000000000000000000000000000000000000000000'`; // Hard-coded hex-value of dataId 'agreement' which all processes in the Agreements Network have
  contracts.cache.db.get(queryString, id, userAddress, userAddress, userAddress, userAddress, userAddress, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get activity instance ${id}`));
    if (!data) return reject(boom.notFound(`Activity ${id} not found`));
    return resolve(data);
  });
});

const getAccessPointDetails = (dataMappings = [], applicationId) => new Promise((resolve, reject) => {
  const appIdHex = rightPad(global.stringToHex(applicationId), 32).toUpperCase();
  const dataMappingIdsHex = dataMappings.map(d => rightPad(global.stringToHex(d.dataMappingId), 32).toUpperCase());
  const queryString = 'SELECT accessPointId, dataType, direction ' +
    `FROM application_access_points WHERE applicationId = '${appIdHex}' ` +
    `AND accessPointId IN ('${dataMappingIdsHex.join("', '")}')`;
  contracts.cache.db.all(queryString, (err, data) => {
    if (err || !data) return reject(boom.badImplementation(`Failed to get data types for data mappings ids ${JSON.stringify(dataMappings)}: ${err}`));
    return resolve(data);
  });
});

const getTasksByUserAddress = userAddress => new Promise((resolve, reject) => {
  // IMPORTANT: The below query uses two LEFT JOIN to retrieve data from the agreement that is attached to the process in one single query.
  // This relies on the fact that all processes in the Agreements Network have a process data with the ID "agreement".
  // If we ever want to retrieve more process data (from other data objects in the process or flexibly retrieve data based on a future process configuration aka 'descriptors'), multiple queries will have to be used
  const hexedDefDepId = rightPad(global.stringToHex(DEFAULT_DEPARTMENT_ID), 32);
  const queryString = `SELECT ai.state, ai.processAddress, ai.activityInstanceId, ai.activityId, ai.created, ai.performer, 
    pd.modelAddress as modelAddress, pd.processDefinitionAddress as processDefinitionAddress, pd.id as processDefinitionId, 
    agr.name as agreementName, pm.id as modelId, pdat.addressValue as agreementAddress, scopes.fixedScope AS scope, o.organizationKey
    FROM activity_instances ai
    JOIN process_instances pi ON ai.processAddress = pi.processAddress
    JOIN activity_definitions ad ON ai.activityId = ad.activityDefinitionId AND pi.processDefinition = ad.processDefinitionAddress
    JOIN process_definitions pd ON pd.processDefinitionAddress = pi.processDefinition
    JOIN process_models pm ON pm.modelAddress = pd.modelAddress
    LEFT JOIN process_data pdat ON ai.processAddress = pdat.processAddress
    LEFT JOIN agreements agr ON agr.address = pdat.addressValue
    LEFT JOIN organizations o ON o.organization = ai.performer 
    LEFT JOIN process_instance_address_scopes scopes ON (
      scopes.processAddress = pdat.processAddress 
      AND scopes.keyAddress = ai.performer 
      AND scopes.keyContext = ai.activityId
    )
    WHERE ad.taskType = 1
    AND ai.state = 4
    AND (
      performer = ? OR (
        performer IN (
          select organization FROM organization_users ou WHERE ou.userKey = ?
        ) AND (
          (
            scopes.fixedScope IS NULL AND UPPER('${hexedDefDepId}') IN (
              SELECT departmentKey FROM department_users du WHERE du.departmentUserKey = ? AND du.organization = performer
            )
          ) OR scopes.fixedScope IN (
            select departmentKey FROM department_users du WHERE du.departmentUserKey = ? AND du.organization = performer
          ) OR scopes.fixedScope = (
            select organizationKey FROM organizations o WHERE o.organization = performer
          ) OR (
            scopes.fixedScope IS NOT NULL AND scopes.fixedScope NOT IN (
              select departmentKey FROM organization_departments od WHERE od.organization = ai.performer
            ) AND UPPER('${hexedDefDepId}') IN (
              SELECT departmentKey FROM department_users du WHERE du.departmentUserKey = ? AND du.organization = performer
            )
          )
        )
      )
    )
    AND pdat.dataId = '61677265656D656E740000000000000000000000000000000000000000000000';`; // Hard-coded hex-value of dataId 'agreement' which all processes in the Agreements Network have
  contracts.cache.db.all(queryString, userAddress, userAddress, userAddress, userAddress, userAddress, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get tasks assigned to user: ${err}`));
    return resolve(data);
  });
});

const getModels = author => new Promise((resolve, reject) => {
  const queryString = `SELECT modelAddress, id, name, author, isPrivate, active, diagramAddress, diagramSecret, versionMajor, versionMinor, versionPatch FROM process_models WHERE isPrivate = 0 OR author = '${author}'`;
  contracts.cache.db.all(queryString, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get process model(s): ${err}`));
    return resolve(data);
  });
});

const getApplications = () => new Promise((resolve, reject) => {
  const queryString = 'SELECT a.applicationId AS id, a.applicationType, a.location, a.webForm, ' +
    'aap.accessPointId, aap.dataType, aap.direction ' +
    'FROM applications a LEFT JOIN application_access_points aap ON aap.applicationId = a.applicationId';
  contracts.cache.db.all(queryString, (err, data) => {
    if (err) return reject(boom.badImplementation('Failed to get applications'));
    return resolve(data);
  });
});

const getProcessDefinitions = (author, interfaceId) => new Promise((resolve, reject) => {
  let hexInterfaceId = Buffer.from(interfaceId || '').toString('hex');
  hexInterfaceId = rightPad(hexInterfaceId.toUpperCase(), 32);
  const queryString = 'SELECT pd.id as processDefinitionId, pd.processDefinitionAddress AS address, pd.modelAddress, pd.interfaceId, pm.id as modelId, pm.diagramAddress, pm.diagramSecret, pm.isPrivate, pm.author ' +
    'FROM process_definitions pd JOIN process_models pm ' +
    'ON pd.modelAddress = pm.modelAddress ' +
    `WHERE pm.isPrivate = 0 OR pm.author = '${author}' ${(interfaceId ? `AND interfaceId = '${hexInterfaceId}'` : '')}`;
  contracts.cache.db.all(queryString, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get process definitions: ${err}`));
    return resolve(data);
  });
});

const getProcessDefinitionData = address => new Promise((resolve, reject) => {
  const queryString = 'SELECT pd.id as processDefinitionId, pd.processDefinitionAddress AS address, pd.modelAddress, pd.interfaceId, pm.diagramAddress, pm.diagramSecret, pm.isPrivate, pm.author, pm.id as modelId ' +
      'FROM process_definitions pd JOIN process_models pm ' +
      'ON pd.modelAddress = pm.modelAddress WHERE pd.processDefinitionAddress = ?;';
  contracts.cache.db.get(queryString, address, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get process definition: ${err}`));
    return resolve(data);
  });
});

const getProcessModelData = address => new Promise((resolve, reject) => {
  const queryString = 'SELECT modelAddress, id, name, author, isPrivate, active, diagramAddress, diagramSecret, versionMajor, versionMinor, versionPatch FROM process_models pm ' +
                        'WHERE pm.modelAddress = ?;';
  contracts.cache.db.get(queryString, address, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get process model: ${err}`));
    return resolve(data);
  });
});

const getManagedOrganizationsOfUser = userAddress => new Promise((resolve, reject) => {
  const queryString = 'SELECT organization FROM organization_approvers WHERE approverAddress = ?;';
  contracts.cache.db.all(queryString, userAddress, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to get managed organizations for user: ${err}`));
    return resolve(data);
  });
});

const userIsAuthorOrPartyOfAgreement = (userAddress, agreementAddress) => new Promise((resolve, reject) => {
  const queryString = `SELECT a.address FROM agreements a
    LEFT JOIN agreements_to_parties ap ON a.address = ap.address
    WHERE (ap.partyByAgreement = ? AND ap.address = ?)
    OR (a.creator = ? AND a.address = ?);`;
  contracts.cache.db.get(queryString, userAddress, agreementAddress, userAddress, agreementAddress, (err, data) => {
    if (err) return reject(boom.badImplementation(`Failed to authorize user for given agreement: ${err}`));
    if (!data) {
      return resolve(false);
    }
    return resolve(true);
  });
});

const getAgreementTags = (agreementAddress, ownerAddresses) => new Promise((resolve, reject) => {
  pool.query({
    text: `SELECT tags.id AS id, text, owner_address AS owner FROM taggings 
    JOIN tags ON taggings.tag_id = tags.id 
    WHERE agreement_address = $1 
    AND owner_address IN (${ownerAddresses.map((owner, i) => `$${i + 2}`)});`,
    values: [agreementAddress].concat(ownerAddresses),
  }, (err, data) => {
    if (err) {
      return reject(boom.badImplementation(err));
    }
    return resolve(data.rows);
  });
});

const getUserTags = ownerAddresses => new Promise((resolve, reject) => {
  pool.query({
    text: `SELECT id, text, owner_address AS owner FROM tags WHERE owner_address IN (${ownerAddresses.map((owner, i) => `$${i + 1}`)})`,
    values: ownerAddresses,
  }, (err, data) => {
    if (err) {
      return reject(boom.badImplementation(err));
    }
    return resolve(data.rows);
  });
});

const createTags = (ownerAddress, tags) => new Promise((resolve, reject) => {
  pool.query({
    text: `INSERT INTO tags(owner_address, text) VALUES ${tags.map((tag, i) => `(UPPER($1), $${i + 2})`)}
    ON CONFLICT (UPPER(owner_address), LOWER(text)) DO NOTHING;`,
    values: [ownerAddress].concat(tags),
  }, (insertErr) => {
    if (insertErr) {
      return reject(boom.badImplementation(insertErr));
    }
    return pool.query({
      text: `SELECT id, text, owner_address AS owner FROM tags
      WHERE owner_address = $1 AND LOWER(text) IN (${tags.map((tag, i) => `LOWER($${i + 2})`)})`,
      values: [ownerAddress].concat(tags),
    }, (selectErr, data) => {
      if (selectErr) {
        return reject(boom.badImplementation(selectErr));
      }
      return resolve(data.rows);
    });
  });
});

const getTag = id => new Promise((resolve, reject) => {
  pool.query({
    text: 'SELECT id, text, UPPER(owner_address) AS owner FROM tags WHERE id = $1;',
    values: [id],
  }, (err, data) => {
    if (err) {
      return reject(boom.badImplementation(err));
    }
    return resolve(data.rows[0]);
  });
});

const updateTag = (id, text) => new Promise((resolve, reject) => {
  pool.query({
    text: 'UPDATE tags SET text = $1 WHERE id = $2;',
    values: [text, id],
  }, (err) => {
    if (err) {
      if (err.code === '23505') {
        // Violates unique constraint
        return reject(boom.badData(err));
      }
      return reject(boom.badImplementation(err));
    }
    return resolve();
  });
});

const deleteTag = id => new Promise((resolve, reject) => {
  pool.query({
    text: 'DELETE FROM tags WHERE id = $1;',
    values: [id],
  }, (err) => {
    if (err) {
      return reject(boom.badImplementation(err));
    }
    return resolve();
  });
});

const getTagsById = tagIds => new Promise((resolve, reject) => {
  pool.query({
    text: `SELECT UPPER(owner_address) AS owner, id, text FROM tags WHERE id IN (${tagIds.map((tag, i) => `$${i + 1}`)})`,
    values: tagIds,
  }, (err, data) => {
    if (err) {
      return reject(boom.badImplementation(err));
    }
    return resolve(data.rows);
  });
});

const applyTags = (agreementAddress, tagIds) => new Promise((resolve, reject) => {
  pool.query({
    text: `INSERT INTO taggings(agreement_address, tag_id) VALUES ${tagIds.map((row, i) => `(UPPER($1), $${i + 2})`)}
    ON CONFLICT (UPPER(agreement_address), tag_id) DO NOTHING;`,
    values: [agreementAddress].concat(tagIds),
  }, (err) => {
    if (err) {
      return reject(boom.badImplementation(err));
    }
    return resolve();
  });
});

const removeTag = (agreementAddress, id) => new Promise((resolve, reject) => {
  pool.query({
    text: 'DELETE FROM taggings WHERE UPPER(agreement_address) = UPPER($1) AND tag_id = $2;',
    values: [agreementAddress, id],
  }, (err) => {
    if (err) {
      return reject(boom.badImplementation(err));
    }
    return resolve();
  });
});

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
  getParameterTypeById,
  getParameterTypes,
  getArchetypeData,
  getArchetypeJurisdictionsAll,
  getArchetypeJurisdictions,
  getArchetypeParameters,
  getArchetypeDocuments,
  getArchetypeDataWithProcessDefinitions,
  getPackagesOfArchetype,
  getGoverningArchetypes,
  getArchetypePackages,
  getArchetypesInPackage,
  getAgreements,
  getAgreementData,
  getAgreementParties,
  getGoverningAgreements,
  getAgreementEventLogDetails,
  getAgreementCollections,
  getAgreementCollectionData,
  getAgreementsInCollection,
  getModels,
  getApplications,
  getActivityInstances,
  getActivityInstanceData,
  getAccessPointDetails,
  getTasksByUserAddress,
  getProcessDefinitions,
  getProcessDefinitionData,
  getProcessModelData,
  userIsAuthorOrPartyOfAgreement,
  getManagedOrganizationsOfUser,
  getAgreementTags,
  getUserTags,
  createTags,
  getTag,
  updateTag,
  deleteTag,
  getTagsById,
  applyTags,
  removeTag,
};
