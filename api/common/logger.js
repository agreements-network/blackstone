const log4js = require('log4js');
const fs = require('fs');
process.env.API_LOG_LEVEL = process.env.API_LOG_LEVEL || 'DEBUG';

log4js.addLayout('json', config => (_logEvent) => {
  const logEvent = Object.assign({}, _logEvent);
  delete logEvent['level'];
  delete logEvent['context'];
  delete logEvent['pid'];
  return JSON.stringify(logEvent);
});

(function bootstrapLogger() {
  const initLogger = log4js.getLogger('log4js');
  initLogger.info('Initializing LOG4JS ...');

  if (!fs.existsSync('logs')) {
    initLogger.info('Creating missing logs/ default directory.');
    fs.mkdirSync('logs');
  }

  const configFile = String(process.env.NODE_ENV).startsWith('dev') ? 'development-log4js.js' : 'production-log4js.js';
  const config = require(`../config/${configFile}`);
  log4js.configure(config);

  module.exports = log4js;
}());
