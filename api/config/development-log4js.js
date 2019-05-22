module.exports = {
  reloadSecs: 300,
  appenders: {
    out: {
      type: 'stdout',
      layout: {
        type: 'colored',
      },
    },
  },
  categories: {
    default: {
      appenders: ['out'],
      level: `${process.env.API_LOG_LEVEL}`,
    },
    app: {
      appenders: ['out'],
      level: `${process.env.API_LOG_LEVEL}`,
    },
    controllers: {
      appenders: ['out'],
      level: `${process.env.API_LOG_LEVEL}`,
    },
    burrow: {
      appenders: ['out'],
      level: `${process.env.API_LOG_LEVEL}`,
    },
    'vent-helper': {
      appenders: ['out'],
      level: `${process.env.API_LOG_LEVEL}`,
    },
    scripts: {
      appenders: ['out'],
      level: `${process.env.API_LOG_LEVEL}`,
    },
    tests: {
      appenders: ['out'],
      level: `${process.env.API_LOG_LEVEL}`,
    },
    queries: {
      appenders: ['out'],
      level: `${process.env.API_LOG_LEVEL}`,
    },
    notifications: {
      appenders: ['out'],
      level: `${process.env.API_LOG_LEVEL}`,
    },
    analytics: {
      appenders: ['out'],
      level: `${process.env.API_LOG_LEVEL}`,
    },
  },
};
