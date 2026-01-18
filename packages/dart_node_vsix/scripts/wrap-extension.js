#!/usr/bin/env node
// Wraps dart2js output for VSCode extension compatibility
const fs = require('fs');
const path = require('path');

const buildDir = path.join(__dirname, '../build/bin');
const outDir = path.join(__dirname, '../out/lib');

fs.mkdirSync(outDir, { recursive: true });

const dartJs = fs.readFileSync(path.join(buildDir, 'extension.js'), 'utf8');

const wrapped = `// VSCode extension wrapper for dart2js output
(function() {
  // Polyfill self for dart2js async scheduling
  if (typeof self === 'undefined') {
    globalThis.self = globalThis;
  }

  // Polyfill navigator for dart2js runtime checks
  if (typeof navigator === 'undefined') {
    globalThis.navigator = { userAgent: 'VSCodeExtensionHost' };
  }

  // Make require available on globalThis for dart2js
  if (typeof globalThis.require === 'undefined' && typeof require !== 'undefined') {
    globalThis.require = require;
  }

  // Make vscode module available on globalThis for dart2js
  if (typeof globalThis.vscode === 'undefined') {
    globalThis.vscode = require('vscode');
  }

  // Run the dart2js code
  ${dartJs}
})();

module.exports = { activate, deactivate };
`;

fs.writeFileSync(path.join(outDir, 'extension.js'), wrapped);
console.log('[wrap-extension] Created out/lib/extension.js');
