let dbm;
let type;
let seed;

/**
 * We receive the dbmigrate dependency from dbmigrate initially.
 * This enables us to not have to rely on NODE_PATH.
 */
exports.setup = (options, seedLink) => {
  dbm = options.dbmigrate;
  type = dbm.dataType;
  seed = seedLink;
};

exports.up = async (db) => {
  await db.runSql(`CREATE TABLE parameter_types (
    id int PRIMARY KEY,
    data_type int NOT NULL,
    label VARCHAR(255) NOT NULL
  );`);
  await db.runSql(`INSERT INTO parameter_types(id, data_type, label) VALUES
    (0, 1, 'Boolean'),
    (1, 2, 'Text (short)'),
    (2, 18, 'Number'),
    (3, 8, 'Date'),
    (4, 8, 'Datetime'),
    (5, 18, 'Monetary Amount'),
    (6, 40, 'User/Organization'),
    (7, 40, 'Contract Address'),
    (8, 40, 'Signing Party'),
    (9, 59, 'Bytes32'),
    (10, 2, 'Document'),
    (11, 2, 'Text (large)'),
    (12, 8, 'Number (positive)'),
    (13, 2, 'Duration');`);
};

exports.down = async (db) => {
  await db.runSql('DROP TABLE parameter_types;');
};

exports._meta = {
  version: 1,
};
