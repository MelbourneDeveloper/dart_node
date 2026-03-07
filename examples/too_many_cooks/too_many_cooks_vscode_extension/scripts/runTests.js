/**
 * Runs the VSCode extension tests using @vscode/test-electron.
 * Captures all stdout/stderr to a timestamped log file.
 */

const fs = require('fs');
const path = require('path');
const { runTests } = require('@vscode/test-electron');

const LOG_DIR = path.resolve(__dirname, '..', 'logs');
const LOG_FILE = path.join(
  LOG_DIR,
  `test-run-${new Date().toISOString().replace(/[:.]/g, '-')}.log`,
);

// Ensure logs directory exists
if (!fs.existsSync(LOG_DIR)) {
  fs.mkdirSync(LOG_DIR, { recursive: true });
}

const logStream = fs.createWriteStream(LOG_FILE, { flags: 'a' });

function logToFile(prefix, ...args) {
  const timestamp = new Date().toISOString();
  const message = args.map(a => (typeof a === 'string' ? a : JSON.stringify(a, null, 2))).join(' ');
  const line = `[${timestamp}] [${prefix}] ${message}\n`;
  logStream.write(line);
  // Also write to original stream so terminal still shows output
  if (prefix === 'ERR') {
    process.stderr.write(line);
  } else {
    process.stdout.write(line);
  }
}

async function main() {
  const extensionDevelopmentPath = path.resolve(__dirname, '..');
  const extensionTestsPath = path.resolve(__dirname, '../out/test/suite/index.js');

  logToFile('INFO', 'Log file:', LOG_FILE);
  logToFile('INFO', 'Extension development path:', extensionDevelopmentPath);
  logToFile('INFO', 'Extension tests path:', extensionTestsPath);

  const vscodeExecutablePath =
    process.env.VSCODE_EXECUTABLE_PATH ||
    '/Applications/Visual Studio Code.app/Contents/MacOS/Electron';

  try {
    const exitCode = await runTests({
      extensionDevelopmentPath,
      extensionTestsPath,
      vscodeExecutablePath,
      launchArgs: ['--user-data-dir', '/tmp/vsc-tmc-test', extensionDevelopmentPath],
      extensionTestsEnv: {
        VERBOSE_LOGGING: 'true',
        TMC_TEST_LOG_FILE: LOG_FILE,
      },
    });

    logToFile('INFO', 'Exit code:', exitCode);
    logStream.end();
    process.exit(exitCode);
  } catch (err) {
    logToFile('ERR', 'Failed:', String(err));
    logStream.end();
    process.exit(1);
  }
}

main();
