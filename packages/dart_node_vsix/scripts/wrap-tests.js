#!/usr/bin/env node
// Wraps dart2js test output for Mocha compatibility
const fs = require('fs');
const path = require('path');

const buildDir = path.join(__dirname, '../build/test/suite');
const outDir = path.join(__dirname, '../out/test/suite');

fs.mkdirSync(outDir, { recursive: true });

const testFiles = fs.readdirSync(buildDir).filter(f => f.endsWith('.js'));

for (const file of testFiles) {
  const dartJs = fs.readFileSync(path.join(buildDir, file), 'utf8');
  const testName = file.replace('.js', '.test.js');

  const wrapped = `// VSCode test wrapper for dart2js output
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

  // Expose Mocha TDD functions on globalThis for @JS annotations
  // These functions are defined by Mocha in the module context
  if (typeof suite !== 'undefined') globalThis.suite = suite;
  if (typeof test !== 'undefined') globalThis.test = test;
  if (typeof suiteSetup !== 'undefined') globalThis.suiteSetup = suiteSetup;
  if (typeof suiteTeardown !== 'undefined') globalThis.suiteTeardown = suiteTeardown;
  if (typeof setup !== 'undefined') globalThis.setup = setup;
  if (typeof teardown !== 'undefined') globalThis.teardown = teardown;

  // Run the dart2js code
  ${dartJs}
})();
`;

  fs.writeFileSync(path.join(outDir, testName), wrapped);
  console.log('[wrap-tests] Created out/test/suite/' + testName);
}
