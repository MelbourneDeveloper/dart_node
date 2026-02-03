/**
 * Test suite index - Mocha test runner configuration
 */

const path = require('path');
const fs = require('fs');
const Mocha = require('mocha');
const { glob } = require('glob');

// FIRST THING: Write to a log file to prove this ran
const logFile = '/tmp/tmc-test.log';
const log = (msg) => {
  const line = `[${new Date().toISOString()}] ${msg}\n`;
  console.log(msg);
  fs.appendFileSync(logFile, line);
};

// Clear and start log
fs.writeFileSync(logFile, '');
log('[INDEX] Test runner started!');

// Note: VSIX uses DirectDbClient for direct SQLite access - no MCP server needed

function run() {
  log('[INDEX] run() called');

  const mocha = new Mocha({
    ui: 'tdd',
    color: true,
    timeout: 30000,
  });

  // Load the TDD interface to expose globals
  // dart2js accesses suite/test via init.G which is set to `self` or `globalThis`
  const tddInterface = require('mocha/lib/interfaces/tdd');
  tddInterface(mocha.suite);

  // Emit pre-require with globalThis as the context
  // The TDD interface listener will set suite, test, etc. on this context
  mocha.suite.emit('pre-require', globalThis, null, mocha);

  // Also set on `self` since dart2js prefers `self` over `globalThis`
  if (typeof self !== 'undefined' && self !== globalThis) {
    mocha.suite.emit('pre-require', self, null, mocha);
  }

  // Verify TDD globals are actually available
  log(`[INDEX] globalThis.suite available: ${typeof globalThis.suite === 'function'}`);
  log(`[INDEX] self defined: ${typeof self !== 'undefined'}`);
  if (typeof self !== 'undefined') {
    log(`[INDEX] self.suite available: ${typeof self.suite === 'function'}`);
    log(`[INDEX] self === globalThis: ${self === globalThis}`);
  }

  // If still not available, something is very wrong
  if (typeof globalThis.suite !== 'function') {
    log('[INDEX] ERROR: TDD globals not set by pre-require! Creating manual wrappers...');

    // Create manual wrappers that work with Mocha's internals
    const common = require('mocha/lib/interfaces/common')([mocha.suite], globalThis, mocha);

    globalThis.setup = common.beforeEach;
    globalThis.teardown = common.afterEach;
    globalThis.suiteSetup = common.before;
    globalThis.suiteTeardown = common.after;

    globalThis.suite = function(title, fn) {
      return common.suite.create({ title, fn });
    };

    globalThis.test = function(title, fn) {
      return common.test.create({ title, fn });
    };

    log(`[INDEX] After manual setup - suite available: ${typeof globalThis.suite === 'function'}`);
  }

  const testsRoot = path.resolve(__dirname, '.');
  log(`[INDEX] testsRoot: ${testsRoot}`);

  return new Promise((resolve, reject) => {
    glob('**/**.test.js', { cwd: testsRoot })
      .then((files) => {
        log(`[INDEX] Found ${files.length} test files: ${JSON.stringify(files)}`);

        files.forEach((f) => {
          const fullPath = path.resolve(testsRoot, f);
          log(`[INDEX] Adding file: ${fullPath}`);
          // Use addFile for proper Mocha integration instead of manual require
          mocha.addFile(fullPath);
        });

        log('[INDEX] Running mocha...');
        mocha.run((failures) => {
          log(`[INDEX] Mocha finished with ${failures} failures`);
          if (failures > 0) {
            reject(new Error(`${failures} tests failed.`));
          } else {
            resolve();
          }
        });
      })
      .catch((err) => {
        log(`[INDEX] Glob error: ${err}`);
        reject(err);
      });
  });
}

module.exports = { run };
