// TypeScript version of interop.dart

// Global context interface
interface GlobalContext {
  require: Function;
  console: Console;
}

// Console interface
interface Console {
  log: Function;
  error: Function;
}

// Get the global context
const getGlobalContext = (): GlobalContext => {
  return global as unknown as GlobalContext;
};

// Get a value from the global JavaScript context
const getGlobal = (name: string): any => {
  return (global as any)[name];
};

// Get Node's require function
const require = getGlobalContext().require;

// Get the console object
const console = getGlobalContext().console;

// Log to console (stdout)
const consoleLog = (message: string): void => {
  console.log(message);
};

// Log to console.error (stderr)
const consoleError = (message: string): void => {
  console.error(message);
};

export {
  getGlobal,
  require,
  console,
  consoleLog,
  consoleError
};