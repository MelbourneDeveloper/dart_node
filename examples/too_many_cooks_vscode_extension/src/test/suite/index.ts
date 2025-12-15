/**
 * Test suite index - Mocha test runner configuration
 */

import * as path from 'path';
import * as fs from 'fs';
import Mocha from 'mocha';
import { glob } from 'glob';

// Set test server path BEFORE extension activates (critical for tests)
// __dirname at runtime is out/test/suite, so go up 4 levels to examples/, then into too_many_cooks
const serverPath = path.resolve(__dirname, '../../../../too_many_cooks/build/bin/server.js');
if (fs.existsSync(serverPath)) {
  (globalThis as Record<string, unknown>)._tooManyCooksTestServerPath = serverPath;
  console.log(`[TEST INDEX] Set server path: ${serverPath}`);
} else {
  console.error(`[TEST INDEX] WARNING: Server not found at ${serverPath}`);
}

export function run(): Promise<void> {
  const mocha = new Mocha({
    ui: 'tdd',
    color: true,
    timeout: 30000,
  });

  const testsRoot = path.resolve(__dirname, '.');

  return new Promise((resolve, reject) => {
    glob('**/**.test.js', { cwd: testsRoot })
      .then((files) => {
        files.forEach((f) => mocha.addFile(path.resolve(testsRoot, f)));

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
          const error = err instanceof Error ? err : new Error(String(err));
          reject(error);
        }
      })
      .catch((err: unknown) => {
        const error = err instanceof Error ? err : new Error(String(err));
        reject(error);
      });
  });
}
