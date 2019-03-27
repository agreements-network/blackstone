// Timeouts
global.ventCatchUpMS = 1000;
global.testTimeoutMS = 60000;
global.sleep = delay => new Promise((resolve, reject) => setTimeout(() => resolve(), delay));

