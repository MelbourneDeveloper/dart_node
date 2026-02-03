/**
 * Test suite index - Mocha test runner that loads compiled Dart tests.
 *
 * This file is NOT compiled from Dart - it's the JavaScript bootstrap
 * that sets up Mocha and loads the Dart-compiled test file.
 */

const path = require('path');
const fs = require('fs');
const Mocha = require('mocha');

// Set test server path BEFORE extension activates (critical for tests)
const serverPath = path.resolve(
  __dirname,
  '../../too_many_cooks/build/bin/server.js',
);
if (fs.existsSync(serverPath)) {
  globalThis._tooManyCooksTestServerPath = serverPath;
  console.log(`[TEST INDEX] Set server path: ${serverPath}`);
} else {
  console.error(`[TEST INDEX] WARNING: Server not found at ${serverPath}`);
}

function run() {
  const mocha = new Mocha({
    ui: 'tdd',
    color: true,
    timeout: 60000,
  });

  // The compiled Dart tests file
  const dartTestsPath = path.resolve(
    __dirname,
    '../out/integration_tests.dart.js',
  );

  return new Promise((resolve, reject) => {
    // Check if the Dart tests are compiled
    if (!fs.existsSync(dartTestsPath)) {
      reject(
        new Error(
          `Dart tests not compiled!\n` +
            `Expected: ${dartTestsPath}\n` +
            `Run: npm run compile:tests`,
        ),
      );
      return;
    }

    // Load the compiled Dart tests - this registers the suites with Mocha
    console.log(`[TEST INDEX] Loading Dart tests from: ${dartTestsPath}`);
    require(dartTestsPath);

    try {
      mocha.run((failures) => {
        if (failures > 0) {
          reject(new Error(`${failures} tests failed.`));
        } else {
          resolve();
        }
      });
    } catch (err) {
      console.error(err);
      reject(err instanceof Error ? err : new Error(String(err)));
    }
  });
}

module.exports = { run };
