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
  await db.runSql(`CREATE TABLE taggings (
    id SERIAL PRIMARY KEY,
    tag_id INTEGER NOT NULL REFERENCES tags(id) ON DELETE CASCADE ON UPDATE RESTRICT,
    agreement_address VARCHAR(40) NOT NULL
  );`);
  await db.runSql('CREATE UNIQUE INDEX taggings_agreement_address_upper_tag_id_idx ON taggings (UPPER(agreement_address), tag_id);');
  await db.runSql('CREATE UNIQUE INDEX taggings_tag_id_agreement_address_upper_idx ON taggings (tag_id, UPPER(agreement_address));');
};

exports.down = async function(db) {
  await db.dropTable('taggings');
};

exports._meta = {
  version: 1
};
