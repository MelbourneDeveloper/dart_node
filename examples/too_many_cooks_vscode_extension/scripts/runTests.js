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

  try {
    // Use reuseMachineInstall: false to force isolation
    // and pass environment variables to enable verbose logging
    const exitCode = await runTests({
      extensionDevelopmentPath,
      extensionTestsPath,
      version: '1.80.0',
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
