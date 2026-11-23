/**
 * Test suite index - Mocha test runner configuration
 */

import * as path from 'path';
import Mocha from 'mocha';
import { glob } from 'glob';

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
