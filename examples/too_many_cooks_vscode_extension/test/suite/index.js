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

// Set test server path - MUST use server_node.js (has node_preamble)!
const serverPath = path.resolve(__dirname, '../../../../too_many_cooks/build/bin/server_node.js');
if (fs.existsSync(serverPath)) {
  globalThis._tooManyCooksTestServerPath = serverPath;
  log(`[INDEX] Set server path: ${serverPath}`);
} else {
  log(`[INDEX] WARNING: Server not found at ${serverPath}`);
}

function run() {
  log('[INDEX] run() called');

  const mocha = new Mocha({
    ui: 'tdd',
    color: true,
    timeout: 30000,
  });

  // Expose Mocha TDD globals BEFORE loading test files
  mocha.suite.emit('pre-require', globalThis, null, mocha);
  log('[INDEX] Mocha TDD globals exposed');

  const testsRoot = path.resolve(__dirname, '.');
  log(`[INDEX] testsRoot: ${testsRoot}`);

  return new Promise((resolve, reject) => {
    glob('**/**.test.js', { cwd: testsRoot })
      .then((files) => {
        log(`[INDEX] Found ${files.length} test files: ${JSON.stringify(files)}`);

        files.forEach((f) => {
          const fullPath = path.resolve(testsRoot, f);
          log(`[INDEX] Requiring: ${fullPath}`);
          try {
            require(fullPath);
            log(`[INDEX] Required OK: ${f}`);
          } catch (e) {
            log(`[INDEX] ERROR requiring ${f}: ${e.message}`);
            log(`[INDEX] Stack: ${e.stack}`);
          }
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
