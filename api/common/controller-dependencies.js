const crypto = require('crypto');
const _ = require('lodash');
const boom = require('boom');

const logger = require(`${global.__common}/monax-logger`);
const log = logger.getLogger('monax.controllers');
const { appPool, chainPool } = require(`${global.__common}/postgres-db`);
const {
  DATA_TYPES,
  PARAMETER_TYPE,
} = global.__monax_constants;


const dependencies = {
  rightPad: (hex, len) => {
    const need = 2 * len - hex.length;
    let paddedHex = hex;
    for (let i = 0; i < need; i += 1) {
      paddedHex += '0';
    }
    return paddedHex;
  },

  formatItem: (item) => {
    if (typeof item === 'object') {
      return `'${JSON.stringify(item)}'`;
    }
    if (typeof item === 'string') {
      return `'${item}'`;
    }
    return item;
  },

  /**
   * Formats selected fields of the given object depending on
   * the specified type and returns the object.
   */
  format: (type, obj) => {
    const element = Object.assign({}, obj);
    const err = new Error();
    switch (type) {
      case 'Organization':
        break;
      case 'User':
        delete element.organization;
        Object.keys(element).forEach((key) => {
          const camelKey = _.camelCase(key);
          if (key !== camelKey) {
            element[camelKey] = element[key];
            delete element[key];
          }
        });
        break;
      case 'Access Point':
        element.accessPointId = global.hexToString(element.accessPointId);
        break;
      case 'Archetype':
        if (!_.isEmpty(element.description)) element.description = _.unescape(element.description);
        if (element.successor) element.successor = Number(element.successor) === 0 ? null : element.successor;
        if (element.price) element.price = parseInt(element.price, 10) / 100; // converting to dollars from cents (recorded uint on chain)
        if (Number(element.formationProcessDefinition) === 0) element.formationProcessDefinition = null;
        if (Number(element.executionProcessDefinition) === 0) element.executionProcessDefinition = null;
        break;
      case 'Archetype Package':
        element.active = Boolean(element.active);
        element.isPrivate = Boolean(element.isPrivate);
        break;
      case 'Agreement':
        element.isPrivate = Boolean(element.isPrivate);
        break;
      case 'Application':
        element.id = global.hexToString(element.id);
        element.webForm = global.hexToString(element.webForm);
        break;
      case 'Country': // TODO Temporary until front-end is updated to rely on alpha2
        element.country = element.alpha2;
        break;
      case 'Currency':
        element.currency = global.hexToString(element.currency);
        element.alpha3 = global.hexToString(element.alpha3);
        element.m49 = global.hexToString(element.m49);
        break;
      case 'Data':
        if (element.dataType === DATA_TYPES.BYTES32) element.value = global.hexToString(element.value);
        break;
      case 'Data Mapping':
        if (element.accessPath) element.accessPath = global.hexToString(element.accessPath);
        if (element.dataMappingId) element.dataMappingId = global.hexToString(element.dataMappingId);
        if (element.dataPath) element.dataPath = global.hexToString(element.dataPath);
        if (element.dataStorageId) element.dataStorageId = global.hexToString(element.dataStorageId);
        break;
      case 'Department':
        element.id = global.hexToString(element.id);
        break;
      case 'Document':
        // obj.name = global.hexToString(obj.name);
        break;
      case 'Parameter':
        element.name = global.hexToString(element.name);
        element.label = global.hexToString(element.label);
        break;
      case 'Party':
        if (element.signatureTimestamp) element.signatureTimestamp *= 1000;
        if (element.organizationName) element.organizationName = global.hexToString(element.organizationName);
        break;
      case 'Model':
        if ('active' in element) element.active = element.active === 1;
        element.isPrivate = Boolean(element.isPrivate);
        break;
      case 'Region':
        element.country = global.hexToString(element.country);
        element.alpha2 = global.hexToString(element.alpha2);
        element.code2 = global.hexToString(element.code2);
        element.code3 = global.hexToString(element.code3);
        break;
      case 'Definition':
        if (element.processDefinitionId != null) element.processDefinitionId = global.hexToString(element.processDefinitionId);
        if (element.interfaceId != null) element.interfaceId = global.hexToString(element.interfaceId);
        if (element.modelId != null) element.modelId = global.hexToString(element.modelId);
        element.isPrivate = Boolean(element.isPrivate);
        break;
      case 'Task':
        if (element.scope && element.scope !== element.organizationKey) {
          // organizationKey was originally entered in bytes32 and doesn't need to be converted to string
          element.scope = global.hexToString(element.scope || '');
        }
        break;
      case 'ParameterType':
        element.label = global.hexToString(element.label || '');
        break;
      case 'Parameter Value': {
        err.status = 400;
        const paramTypeInt = parseInt(element.parameterType, 10);
        if (paramTypeInt === PARAMETER_TYPE.BOOLEAN) {
          if (element.value === 'false' || element.value === '0' || !element.value) {
            element.value = 0;
          } else if (element.value === '1' || element.value === true || element.value === 'true') {
            element.value = 1;
          } else {
            err.message = 'Invalid boolean value';
            throw err;
          }
        } else if (paramTypeInt === PARAMETER_TYPE.STRING && typeof element.value !== 'string') {
          element.value = JSON.stringify(element.value);
        } else if (paramTypeInt === PARAMETER_TYPE.NUMBER) {
          if (typeof element.value === 'string') {
            element.value = parseFloat(element.value, 10);
          }
          if (!Number.isInteger(element.value)) {
            err.message = 'Number values must be integers';
            throw err;
          }
        } else if (paramTypeInt === PARAMETER_TYPE.DATE || paramTypeInt === PARAMETER_TYPE.DATETIME) {
          if (typeof element.value === 'string') {
            element.value = new Date(element.value).getTime();
            if (Number.isNaN(parseInt(element.value, 10))) {
              err.message = 'Date format not readable';
              throw err;
            }
          }
        } else if (paramTypeInt === PARAMETER_TYPE.MONETARY_AMOUNT) {
          if (typeof element.value === 'string') {
            element.value = parseFloat(element.value, 10);
          }
          element.value = Math.round(element.value * 100);
        } else if (paramTypeInt === PARAMETER_TYPE.USER_ORGANIZATION ||
          paramTypeInt === PARAMETER_TYPE.CONTRACT_ADDRESS ||
          paramTypeInt === PARAMETER_TYPE.SIGNING_PARTY) {
          if (typeof element.value !== 'string' || !element.value.match(/^[0-9A-Fa-f]{40}$/)) {
            err.message = 'Accounts must be 40-digit hexadecimals';
            throw err;
          }
        }
        return element;
      }
      default:
        log.warn('Invoked format() function with unknown type. Returning same object!');
    }
    return element;
  },

  encrypt: (buffer, password) => {
    if (password == null) return buffer;
    const cipher = crypto.createCipher('aes-256-ctr', password);
    const crypted = Buffer.concat([cipher.update(buffer), cipher.final()]);
    return crypted;
  },

  decrypt: (buffer, password) => {
    if (password == null) return buffer;
    const decipher = crypto.createDecipher('aes-256-ctr', password);
    const dec = Buffer.concat([decipher.update(buffer), decipher.final()]);
    return dec;
  },

  addMeta: (meta, data) => {
    const dataBuf = Buffer.from(data);
    const metaBuf = Buffer.from(JSON.stringify(meta));
    const size = Buffer.alloc(4);
    size.writeUIntBE(metaBuf.length, 0, 4);
    return Buffer.concat([size, metaBuf, dataBuf]);
  },

  splitMeta: (data) => {
    const _data = data.data;
    let retdata;
    try {
      const outSize = _data.readUIntBE(0, 4);
      retdata = {
        meta: JSON.parse(_data.slice(4, outSize + 4).toString()),
        data: _data.slice(outSize + 4),
      };
    } catch (err) {
      retdata = { data: _data };
    }
    return retdata;
  },

  where: (criteria, skipWhere) => {
    // log.debug("whereing")
    // log.debug(criteria)
    if (criteria === undefined) return '';

    let where = skipWhere ? 'AND ' : 'WHERE ';
    const conds = [];

    Object.keys(criteria).forEach((key, i) => {
      // skip 'token' query param
      if (key === 'token') return;

      if (/^null$/i.exec(criteria[key]) != null) {
        conds.push(`${key} IS NULL`);
      } else if (/^notnull$/i.exec(criteria[key]) != null) {
        conds.push(`${key} IS NOT NULL`);
      } else if (/^true$/i.exec(criteria[key]) != null) {
        conds.push(`${key}=1`);
      } else if (/^false$/i.exec(criteria[key]) != null) {
        conds.push(`${key}=0`);
      } else {
        conds.push(`${key} = ${dependencies.formatItem(criteria[key])}`);
      }
    });

    if (conds.length === 0) return '';

    for (let i = 0; i < conds.length; i += 1) {
      if (i !== 0) {
        where += ' AND ';
      }
      where += conds[i];
    }

    return where;
  },

  pgWhere: (obj) => {
    let columns = Object.keys(obj);
    const values = columns.map(col => obj[col]);
    columns = columns.map(col => _.snakeCase(col));
    const text = `WHERE ${columns.map((col, i) => `${col} = $${i + 1}`).join(' AND ')}`;
    return {
      text,
      values,
    };
  },

  pgUpdate: (tableName, obj) => {
    let columns = Object.keys(obj);
    const values = columns.map(col => obj[col]);
    columns = columns.map(col => _.snakeCase(col));
    const text = `UPDATE ${tableName} SET ${columns.map((col, i) => `${col} = $${i + 1}`).join(', ')}`;
    return {
      text,
      values,
    };
  },

  setUserIds: (users, registeredUsersOnly, ...formats) => new Promise((resolve, reject) => {
    const text = `SELECT username AS id, address FROM users 
    WHERE address = ANY ($1)
    ${registeredUsersOnly ? ' AND external_user = false;' : ';'}`;
    try {
      appPool.query({
        text,
        values: [users.map(user => user.address)],
      }, (err, res) => {
        if (err) reject(boom.badImplementation(err));
        const userIds = {};
        res.rows.forEach((user) => {
          userIds[user.address] = user.id;
        });
        const _users = users.map((_user) => {
          let user = Object.assign({}, _user);
          user.id = userIds[user.address];
          formats.forEach((format) => {
            user = dependencies.format(format, user);
          });
          return user;
        }).filter(({ id }) => id);
        resolve(_users);
      });
    } catch (err) {
      reject(err);
    }
  }),

  getNamesOfOrganizations: async (organizations) => {
    try {
      const { rows } = await appPool.query({
        text: 'SELECT DISTINCT address, name FROM organizations WHERE address = ANY ($1)',
        values: [organizations.map(({ address }) => address)],
      });
      const completeOrgs = {};
      organizations.forEach((org) => {
        completeOrgs[org.address] = { ...org, name: '' };
      });
      rows.forEach(({ address, name }) => {
        completeOrgs[address].name = name;
      });
      return Object.values(completeOrgs);
    } catch (err) {
      throw boom.badImplementation(err);
    }
  },

  /**
   * Wrapper for async route handlers to catch promise rejections
   * and pass them to express error handler
   */
  asyncMiddleware: fn => (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch((err) => {
      if (!err.isBoom) {
        return next(boom.badImplementation(err));
      }
      return next(err);
    });
  },

  byteLength: string => string.split('').reduce((acc, el) => {
    const newSum = acc + Buffer.byteLength(el, 'utf8');
    return newSum;
  }, 0),

  getBooleanFromString: (val) => {
    if (val && val.constructor.name === 'Boolean') return val;
    if (val && val.constructor.name === 'String') {
      return val === 'true';
    }
    return false;
  },

  getSHA256Hash: data => crypto.createHash('sha256').update(data).digest('hex'),

};

module.exports = dependencies;
