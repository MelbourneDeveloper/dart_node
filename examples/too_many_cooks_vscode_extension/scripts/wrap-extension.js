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
  ${dartOutput}
})();

// Bridge globalThis to module.exports for VSCode using getters
// (dart2js sets these after the main runner executes)
if (typeof module !== 'undefined' && module.exports) {
  // Wrap activate to log and verify return value
  var originalActivate = null;
  Object.defineProperty(module.exports, 'activate', {
    get: function() {
      if (!originalActivate && globalThis.activate) {
        originalActivate = function(context) {
          console.log('[DART WRAPPER] activate called');
          try {
            var result = globalThis.activate(context);
            console.log('[DART WRAPPER] activate returned:', typeof result, result ? Object.keys(result) : 'null');
            return result;
          } catch (e) {
            console.error('[DART WRAPPER] activate threw error:', e);
            throw e;
          }
        };
      }
      return originalActivate || globalThis.activate;
    },
    enumerable: true,
    configurable: true
  });
  Object.defineProperty(module.exports, 'deactivate', {
    get: function() { return globalThis.deactivate; },
    enumerable: true,
    configurable: true
  });
}
`;

fs.writeFileSync(
  path.join(__dirname, '../out/extension.js'),
  wrapped
);

console.log('Wrapped extension.dart.js -> extension.js');
