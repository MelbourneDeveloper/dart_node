/**
 * Runs the VSCode extension tests using @vscode/test-electron.
 */

const path = require('path');
const { runTests } = require('@vscode/test-electron');

async function main() {
  const extensionDevelopmentPath = path.resolve(__dirname, '..');
  const extensionTestsPath = path.resolve(__dirname, '../out/test/suite/index.js');

  console.log('Extension development path:', extensionDevelopmentPath);
  console.log('Extension tests path:', extensionTestsPath);

  const vscodeExecutablePath =
    process.env.VSCODE_EXECUTABLE_PATH ||
    '/Applications/Visual Studio Code.app/Contents/MacOS/Electron';

  try {
    const exitCode = await runTests({
      extensionDevelopmentPath,
      extensionTestsPath,
      vscodeExecutablePath,
      launchArgs: ['--user-data-dir', '/tmp/vsc-tmc-test'],
      extensionTestsEnv: {
        VERBOSE_LOGGING: 'true',
      },
    });

    console.log('Exit code:', exitCode);
    process.exit(exitCode);
  } catch (err) {
    console.error('Failed:', err);
    process.exit(1);
  }
}

main();
