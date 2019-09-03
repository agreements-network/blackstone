const boom = require('@hapi/boom');
const { format, asyncMiddleware } = require('../common/controller-dependencies');
const sqlCache = require('./postgres-query-helper');

module.exports = {
  getCountries: asyncMiddleware(async (req, res, next) => {
    const countries = [];
    const data = await sqlCache.getCountries();
    data.forEach((elem) => {
      countries.push(format('Country', elem));
    });
    res.locals.data = countries;
    res.status(200);
    return next();
  }),

  getAlpha2Countries: asyncMiddleware(async (req, res, next) => {
    if (!req.params.alpha2) throw boom.badRequest('Country alpha2 identifier required');
    const { alpha2 } = req.params;
    const data = await sqlCache.getCountryByAlpha2Code(alpha2);
    res.locals.data = format('Country', data);
    res.status(200);
    return next();
  }),

  getAlpha2CountryRegions: asyncMiddleware(async (req, res, next) => {
    if (!req.params.alpha2) throw boom.badRequest('Country alpha2 identifier required');
    const { alpha2 } = req.params;
    res.locals.data = await sqlCache.getRegionsOfCountry(alpha2);
    res.status(200);
    return next();
  }),

  getCurrencies: asyncMiddleware(async (req, res, next) => {
    res.locals.data = await sqlCache.getCurrencies();
    res.status(200);
    return next();
  }),

  getAlpha3Currencies: asyncMiddleware(async (req, res, next) => {
    if (!req.params.alpha3) throw boom.badRequest('Currency alpha3 identifier required');
    const { alpha3 } = req.params;
    res.locals.data = await sqlCache.getCurrencyByAlpha3Code(alpha3);
    res.status(200);
    return next();
  }),

  getParameterType: asyncMiddleware(async (req, res, next) => {
    if (!req.params.id) throw boom.badRequest('Parameter id is required');
    res.locals.data = await sqlCache.getParameterType(req.params.id);
    res.status(200);
    return next();
  }),

  getParameterTypes: asyncMiddleware(async (req, res, next) => {
    res.locals.data = await sqlCache.getParameterTypes();
    res.status(200);
    return next();
  }),

  getCollectionTypes: asyncMiddleware((req, res, next) => {
    const collectionTypes = [{
      collectionType: 0,
      label: 'Case',
    },
    {
      collectionType: 1,
      label: 'Deal',
    },
    {
      collectionType: 2,
      label: 'Dossier',
    },
    {
      collectionType: 3,
      label: 'Folder',
    },
    {
      collectionType: 4,
      label: 'Matter',
    },
    {
      collectionType: 5,
      label: 'Package',
    },
    {
      collectionType: 6,
      label: 'Project',
    },
    ];
    res.locals.data = collectionTypes;
    res.status(200);
    return next();
  }),

};
