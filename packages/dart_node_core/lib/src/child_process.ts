// Node.js child_process bindings for TypeScript.
//
// Node.js child_process.spawn directly.

import { EventEmitter } from 'events';
import { spawn as nodeSpawn, SpawnOptions, ChildProcess as NodeChildProcess } from 'child_process';

// Use require - Node.js accesses via globalThis
const _require = (module: string): any => {
  return require(module);
};

/// A spawned child process with typed streams.
///
/// Wraps the Node.js ChildProcess object without exposing JS types.
class Process {
  private _jsProcess: NodeChildProcess;
  private _stdoutController: NodeJS.ReadableStream;
  private _stderrController: NodeJS.ReadableStream;

  private constructor(jsProcess: NodeChildProcess) {
    this._jsProcess = jsProcess;
    this._stdoutController = jsProcess.stdout!;
    this._stderrController = jsProcess.stderr!;
  }

  /// Stream of stdout data.
  get stdout(): NodeJS.ReadableStream {
    return this._stdoutController;
  }

  /// Stream of stderr data.
  get stderr(): NodeJS.ReadableStream {
    return this._stderrController;
  }

  /// Write data to the process stdin.
  write(data: string): void {
    this._jsProcess.stdin?.write(data);
  }

  /// Kill the process with an optional signal.
  kill(signal?: string): void {
    this._jsProcess.kill(signal);
  }

  /// Listen for process exit. Returns the exit code (null if killed).
  onExit(callback: (code: number | null) => void): void {
    this._jsProcess.on('close', (code: number | null) => {
      callback(code);
    });
  }

  /// Wait for the process to exit and return the exit code.
  get exitCode(): Promise<number | null> {
    return new Promise((resolve) => {
      this.onExit((code) => {
        resolve(code);
      });
    });
  }
}

/// Spawn a child process.
///
/// [command] - The command to run.
/// [args] - Arguments to pass to the command.
/// [shell] - Whether to run the command in a shell.
function spawn(command: string, args: string[], options?: { shell?: boolean }): Process {
  const shell = options?.shell ?? false;
  const spawnOptions: SpawnOptions = {
    shell: shell,
    stdio: ['pipe', 'pipe', 'pipe'] as any
  };
  
  const jsProcess = nodeSpawn(command, args, spawnOptions);
  return new Process(jsProcess);
}

export {
  Process,
  spawn
};