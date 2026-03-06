/**
 * Wraps the dart2js output to properly export activate/deactivate for VSCode.
 *
 * dart2js sets activate/deactivate on globalThis, but VSCode extension host
 * expects them on module.exports. This script wraps the output to bridge them.
 */
const fs = require('fs');
const path = require('path');

const dartOutput = fs.readFileSync(
  path.join(__dirname, '../out/extension.dart.js'),
  'utf8'
);

const wrapped = `// VSCode extension wrapper for dart2js output

// NODE PREAMBLE (from node_preamble package) - MUST be at global scope
var dartNodeIsActuallyNode = typeof process !== "undefined" && (process.versions || {}).hasOwnProperty('node');
var self = dartNodeIsActuallyNode ? Object.create(globalThis) : globalThis;
self.scheduleImmediate = typeof setImmediate !== "undefined"
    ? function (cb) { setImmediate(cb); }
    : function(cb) { setTimeout(cb, 0); };
if (typeof require !== "undefined") { self.require = require; }
if (typeof exports !== "undefined") { self.exports = exports; }
if (typeof process !== "undefined") { self.process = process; }
if (typeof __dirname !== "undefined") { self.__dirname = __dirname; }
if (typeof __filename !== "undefined") { self.__filename = __filename; }
if (typeof Buffer !== "undefined") { self.Buffer = Buffer; }
if (dartNodeIsActuallyNode) {
  var url = require("url");
  Object.defineProperty(self, "location", {
    value: { get href() { return url.pathToFileURL(process.cwd()).href + "/"; } }
  });
  Object.defineProperty(self, "document", {
    value: { get currentScript() { return {src: __filename}; } }
  });
}

(function() {
  // Make require available on globalThis for dart2js
  // dart2js uses globalThis.require but VSCode has require in local scope
  if (typeof globalThis.require === 'undefined' && typeof require !== 'undefined') {
    globalThis.require = require;
  }

  // Make vscode module available on globalThis for dart2js
  // @JS('vscode.X') annotations compile to globalThis.vscode.X
  if (typeof globalThis.vscode === 'undefined') {
    globalThis.vscode = require('vscode');
  }

  // Run the dart2js code which sets activate/deactivate on globalThis
  try {
    ${dartOutput}
    console.log('[TMC] Dart2js code loaded successfully');
  } catch (e) {
    console.error('[TMC] FATAL: Dart2js code failed to load:', e);
    console.error('[TMC] Stack:', e.stack);
    // Provide fallback activate that logs the error
    self.activate = function(context) {
      const channel = globalThis.vscode.window.createOutputChannel('Too Many Cooks');
      channel.appendLine('[ERROR] Extension failed to load: ' + e.message);
      channel.appendLine('[ERROR] Stack: ' + (e.stack || 'no stack'));
      channel.show(true);
      console.error('[TMC] Extension failed to load:', e);
      return {};
    };
    self.deactivate = function() {};
  }
})();

// Bridge self to module.exports for VSCode using getters
// (dart2js sets activate/deactivate on 'self', not 'globalThis',
// because node_preamble does: var self = Object.create(globalThis))
if (typeof module !== 'undefined' && module.exports) {
  Object.defineProperty(module.exports, 'activate', {
    get: function() {
      var fn = self.activate;
      if (!fn) {
        console.error('[TMC] activate is undefined on self! Keys:', Object.getOwnPropertyNames(self).filter(k => k.includes('activ')));
        console.error('[TMC] globalThis.activate:', typeof globalThis.activate);
      }
      return fn;
    },
    enumerable: true,
    configurable: true
  });
  Object.defineProperty(module.exports, 'deactivate', {
    get: function() { return self.deactivate; },
    enumerable: true,
    configurable: true
  });
}

console.log('[TMC] Extension module loaded. activate:', typeof (self.activate), 'deactivate:', typeof (self.deactivate));
`;

fs.writeFileSync(
  path.join(__dirname, '../out/extension.js'),
  wrapped
);

console.log('Wrapped extension.dart.js -> extension.js');
