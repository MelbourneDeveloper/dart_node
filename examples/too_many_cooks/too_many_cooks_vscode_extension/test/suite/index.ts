// Test suite index - Mocha test runner configuration

import * as fs from 'fs';
import * as path from 'path';
import Mocha from 'mocha';
import { glob } from 'glob';

const LOG_DIR: string = path.resolve(__dirname, '..', '..', '..', 'logs');
const FALLBACK_LOG: string = path.join(
  LOG_DIR,
  `test-suite-${new Date().toISOString().replace(/[:.]/g, '-')}.log`,
);

function ensureLogDir(): void {
  if (!fs.existsSync(LOG_DIR)) {
    fs.mkdirSync(LOG_DIR, { recursive: true });
  }
}

function getLogFile(): string {
  return process.env.TMC_TEST_LOG_FILE ?? FALLBACK_LOG;
}

let logStream: fs.WriteStream | null = null;

function writeLog(message: string): void {
  const timestamp: string = new Date().toISOString();
  const line: string = `[${timestamp}] [TEST-SUITE] ${message}\n`;
  if (logStream !== null) {
    logStream.write(line);
  }
  // Always write to console too
  console.log(line.trimEnd());
}

// Intercept process.stdout/stderr.write to capture ALL output
// (including mocha's spec reporter, which bypasses console.log).
function installOutputCapture(): void {
  const originalStdoutWrite = process.stdout.write.bind(process.stdout);
  const originalStderrWrite = process.stderr.write.bind(process.stderr);

  process.stdout.write = (chunk: unknown, ...args: unknown[]): boolean => {
    if (logStream !== null) {
      const text: string = typeof chunk === 'string' ? chunk : String(chunk);
      logStream.write(text);
    }
    return (originalStdoutWrite as Function)(chunk, ...args);
  };

  process.stderr.write = (chunk: unknown, ...args: unknown[]): boolean => {
    if (logStream !== null) {
      const text: string = typeof chunk === 'string' ? chunk : String(chunk);
      logStream.write(`[ERR] ${text}`);
    }
    return (originalStderrWrite as Function)(chunk, ...args);
  };
}

export async function run(): Promise<void> {
  ensureLogDir();
  const logFile: string = getLogFile();
  logStream = fs.createWriteStream(logFile, { flags: 'a' });
  installOutputCapture();

  writeLog(`Log file: ${logFile}`);
  writeLog('Test suite starting...');

  const mocha = new Mocha({
    ui: 'tdd',
    color: true,
    timeout: 5000,
    reporter: 'spec',
  });

  const testsRoot = path.resolve(__dirname, '.');
  const files = await glob('**/*.test.js', { cwd: testsRoot });

  writeLog(`Found ${String(files.length)} test files`);
  for (const f of files) {
    writeLog(`  Adding: ${f}`);
    mocha.addFile(path.resolve(testsRoot, f));
  }

  return new Promise((resolve, reject) => {
    mocha.run((failures) => {
      writeLog(`Test run complete: ${String(failures)} failures`);
      if (logStream !== null) {
        logStream.end();
        logStream = null;
      }
      if (failures > 0) {
        reject(new Error(`${failures} tests failed.`));
      } else {
        resolve();
      }
    });
  });
}
