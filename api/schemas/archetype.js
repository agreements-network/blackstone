const Joi = require('@hapi/joi');

/*

sample archetype:
{
  name: 'archetype name',
  author: '36ADA22D3A4B841EFB73414CD97C35C0A660C1C2',
  owner: '36ADA22D3A4B841EFB73414CD97C35C0A660C1C2',
  description: 'things about this archetype',
  isPrivate: 1,
  active: 1,
  parameters: [
    { type: 0, name: 'bool' },
    { type: 1, name: 'string' },
    { type: 2, name: 'num' },
    { type: 3, name: 'date' },
    { type: 4, name: 'datetime' },
    { type: 5, name: 'money' },
    { type: 6, name: 'user' },
    { type: 7, name: 'addr' },
    { type: 8, name: 'signatory' },
  ],
  executionProcessDefinition: '8010494870E1A8B2BA3F05CCCCDBFA337BF5F064',
  formationProcessDefinition: '0506903B34830785168D840BB70D7D48D31A5C1F',
  jurisdictions: [
    {
      country: 'CA',
      regions: [
        '9CD6EEC0C135A0DEC4176812CE66259A61CB5075E1494A123383E2A12A45691C',
        '26F96B983F45DA344CE851B10C57D7E35063D70F08D07E6B9DE9EDC171292FFB',
        '6B76BFAF03C7F62FBAB330430E56863F149153120FC38638930BEEC724089C06',
      ],
    },
    { country: 'US', regions: ['0000000000000000000000000000000000000000000000000000000000000000'] },
  ],
  documents: [
    {
      name: 'pdf-test.pdf',
      grant: 'eyJTcGVjIjp7IlBsYWludGV4dCI6bnVsbCwiU3ltbWV0cmljIjp7IlNlY3JldElEIjoiczNjcjN0In0sIk9wZW5QR1AiOm51bGx9LCJFbmNyeXB0ZWRSZWZlcmVuY2UiOiJxeFBQaXp1UThZNG5iektXMlh1ZEZlNWdoTklqWlhUcWFxSEhTQ1Boc0lJZTFkSWZDNVRRSjNUYmhDYW02V2pjb2NBVGpkakxMWWFzUjJLbkkvenJISHNjR3dqTW13bzlkdnVuUEx0UXhnT2FzQXk4Wno3VUZRaWRNUVFLcWF3SDRVdnF2UVF2QkQzSUpVb0cwcWxJaVZSZERNMzgwWXUySG9KMXc4L1ZTdXU5cTM0QThOSzhSV1EyNjdQNU5XcXhvUEJoQlNoY2UwWGRlSmhsVG11L0RORlh4SnN0M0piUVBBME9HbmRuU2JBMEQzRS9wM212IiwiVmVyc2lvbiI6MH0='
    },
    {
      name: 'test.md',
      grant: 'eyJTcGVjIjp7IlBsYWludGV4dCI6bnVsbCwiU3ltbWV0cmljIjp7IlNlY3JldElEIjoiczNjcjN0In0sIk9wZW5QR1AiOm51bGx9LCJFbmNyeXB0ZWRSZWZlcmVuY2UiOiJxeFBQaXp1UThZNG5iektXMlh1ZEZlNWdoTklqWlhUcWFxSEhTQ1Boc0lJZTFkSWZDNVRRSjNUYmhDYW02V2pjb2NBVGpkakxMWWFzUjJLbkkvenJISHNjR3dqTW13bzlkdnVuUEx0UXhnT2FzQXk4Wno3VUZRaWRNUVFLcWF3SDRVdnF2UVF2QkQzSUpVb0cwcWxJaVZSZERNMzgwWXUySG9KMXc4L1ZTdXU5cTM0QThOSzhSV1EyNjdQNU5XcXhvUEJoQlNoY2UwWGRlSmhsVG11L0RORlh4SnN0M0piUVBBME9HbmRuU2JBMEQzRS9wM212IiwiVmVyc2lvbiI6MH0='
    },
  ],
  packageId: '9BBC0DA311D1C72DF9287B49E0DF1D2AF3BA26375BB3B546C679DD8B4FC21252',
  governingArchetypes: [
    '686b6aefa7467db432903d4fed9cd23c2ee6bd57'
    '3a2629aa5ad584877212e16dc4b2b0e778acf4b9'
    'c969b9e29fb9f65299b474c18e4bbd5340124db2'
    'd2534600f8bdf6eadfe360bf2ff3f2c8e5514e71'
  ]
};
*/

const archetypeSchema = Joi.object().keys({
  name: Joi.string()
    .required().max(255, 'utf8'),
  password: Joi.string().optional(),
  author: Joi.string()
    .hex()
    .required(),
  owner: Joi.string()
    .hex()
    .required(),
  description: Joi.string().required(),
  price: Joi.number().optional().precision(2).default(0),
  isPrivate: [
    Joi.boolean(),
    Joi.number()
      .integer()
      .min(0)
      .max(1),
  ],
  active: [
    Joi.boolean(),
    Joi.number()
      .integer()
      .min(0)
      .max(1),
  ],
  formationProcessDefinition: Joi.string()
    .hex()
    .required(),
  executionProcessDefinition: Joi.string()
    .hex()
    .required(),
  jurisdictions: Joi.array().items(
    Joi.object().keys({
      country: Joi.string()
        .alphanum()
        .required(),
      regions: Joi.array()
        .items(Joi.string().hex())
        .required(),
    }),
  ),
  documents: Joi.array().items(
    Joi.object().keys({
      name: Joi.string(),
      grant: Joi.string(),
    }),
  ),
  parameters: Joi.array().items(
    Joi.object().keys({
      type: Joi.number()
        .min(0)
        .max(13),
      name: Joi.string().max(32, 'utf8'),
      signatory: Joi.boolean(),
    }),
  ),
  packageId: Joi.string().optional().default(''),
  governingArchetypes: Joi.array().items(Joi.string().hex()).optional().default([]),
});

module.exports = archetypeSchema;
