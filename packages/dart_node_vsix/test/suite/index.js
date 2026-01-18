/**
 * Test suite index - Mocha test runner configuration.
 *
 * This is JavaScript (not Dart) that bootstraps Mocha and loads
 * the dart2js-compiled test files.
 */

const path = require('path');
const Mocha = require('mocha');
const { glob } = require('glob');

function run() {
  const mocha = new Mocha({
    ui: 'tdd',
    color: true,
    timeout: 60000,
  });

  const testsRoot = path.resolve(__dirname, '.');

  return new Promise((resolve, reject) => {
    glob('*.test.js', { cwd: testsRoot })
      .then((files) => {
        files.forEach((f) => {
          mocha.addFile(path.resolve(testsRoot, f));
        });

        mocha.run((failures) => {
          if (failures > 0) {
            reject(new Error(`${failures} tests failed.`));
          } else {
            resolve();
          }
        });
      })
      .catch(reject);
  });
}

module.exports = { run };
