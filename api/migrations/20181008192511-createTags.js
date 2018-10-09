"use strict";

var dbm;
var type;
var seed;

/**
 * We receive the dbmigrate dependency from dbmigrate initially.
 * This enables us to not have to rely on NODE_PATH.
 */
exports.setup = function(options, seedLink) {
  dbm = options.dbmigrate;
  type = dbm.dataType;
  seed = seedLink;
};

exports.up = async function(db) {
  await db.runSql(`CREATE TABLE tags (
    id SERIAL PRIMARY KEY,
    owner_address VARCHAR(40) NOT NULL,
    text VARCHAR(40) NOT NULL
  );`);
  await db.runSql('CREATE UNIQUE INDEX tags_owner_address_upper_text_lower_idx ON tags (UPPER(owner_address), LOWER(text));');
  await db.runSql('CREATE UNIQUE INDEX tags_text_lower_owner_address_upper_idx ON tags (LOWER(text), UPPER(owner_address));');
};

exports.down = async function(db) {
  await db.dropTable('tags');
};

exports._meta = {
  version: 1
};
