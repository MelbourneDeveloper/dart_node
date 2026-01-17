/**
 * Wraps the dart2js test output to handle Node.js/VSCode environment properly.
 *
 * dart2js checks for navigator.userAgent which is deprecated in Node.js.
 * This wrapper provides a polyfill and sets up required globals.
 */
const fs = require('fs');
const path = require('path');
const { glob } = require('glob');

const outDir = path.join(__dirname, '../out/test/suite');

async function main() {
  // Find all compiled test files  
  const testFiles = await glob('*.dart.js', { cwd: outDir });
  
  console.log(`Wrapping ${testFiles.length} test files...`);
  
  for (const testFile of testFiles) {
    const inputPath = path.join(outDir, testFile);
    // *_test.dart.js -> *.test.js for Mocha discovery
    // e.g., commands_test.dart.js -> commands.test.js
    const outputPath = path.join(outDir, testFile.replace('_test.dart.js', '.test.js'));
    
    const dartOutput = fs.readFileSync(inputPath, 'utf8');
    
    const wrapped = `// VSCode test wrapper for dart2js output
(function() {
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
  ${dartOutput}
})();
`;
    
    fs.writeFileSync(outputPath, wrapped);
    console.log('Wrapped ' + testFile + ' -> ' + path.basename(outputPath));
  }
  
  console.log('Done wrapping test files');
}

main().catch(console.error);
