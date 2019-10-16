const binstring = require('binstring');
const burrow = require('@hyperledger/burrow');
const EventEmitter = require('events');
const util = require('util');
const logger = require(`${global.__common}/logger`);
const I = require('iteray');
const R = require('ramda');
const stream = require('stream');

(function startBurrowDb() {
  const log = logger.getLogger('burrow');

  // EventEmitter
  function ChainEvents() {
    EventEmitter.call(this);
  }

  util.inherits(ChainEvents, EventEmitter);

  /**
     * Constructor for a Wrapper instance to talk to a specific chain
     */
  function BurrowDB(chainURL, account) {
    if (!account) {
      log.error('No account specified for BurrowDB!');
    }

    const observer = asyncIterable => R.pipe(I.map(event => `${JSON.stringify(event, null, 2)}\n\n`), I.to(stream.Readable))(asyncIterable).pipe(process.stderr);

    const self = this;
    self.chainURL = chainURL;
    self.burrow = burrow.createInstance(self.chainURL, account, { objectReturn: true });
    // self.contractManager = burrow.newContractManagerDev(self.chainURL, account, {signbyaddress: true, observer: process.env.DEBUG ? observer : I.sink});
    self.listen = new ChainEvents();
    // self.mdb = mdb.createInstance(self.chainURL)
    log.info(`Connection established with node at URL: ${self.chainURL}`);
  }

  BurrowDB.prototype.events = {}; // TODO to be defined, e.g. contract added event

  // /**
  //  * Creates and returns a contractFactory for the given ABI.
  //  */
  // BurrowDB.prototype.createContractFactory = function(abi, jsonOutput) {

  //     //TODO check inputs, check existing contract at name
  //     log.trace('Creating contract factory from ABI.');
  //     // instantiate the contract factory using the abi.
  //     var factory = this.contractManager.newContractFactory(abi);

  //     if(jsonOutput) {
  //         log.trace('Enabling json output on contract factory.');
  //         factory.setOutputFormatter(burrow.outputFormatters.jsonStrings);
  //     }
  //     return factory;
  // }

  /**
     * Wraps the given callback and executes the 'convert' function on the result,
     * if there is one, before invoking the callback(error, result).
     */
  BurrowDB.prototype.convertibleCallback = (callback, convert) => (err, res) => {
    callback(err, (res && convert) ? convert(res) : res);
  };

  /* Converts given string to hex */
  BurrowDB.prototype.str2hex = str => binstring(str, { in: 'binary', out: 'hex' });

  /* Converts given hex to string and removes trailing null character */
  BurrowDB.prototype.hex2str = hexx => String(Buffer.from(hexx, 'hex')).replace(/\0/g, '');

  module.exports = {
    Connection: BurrowDB,
  };
}());
