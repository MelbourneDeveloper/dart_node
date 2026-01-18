/**
 * Generates manifest.test.js that imports all compiled Dart test files.
 *
 * The Dart test files already contain suite()/test() calls that register
 * with Mocha. This manifest just:
 * 1. Sets up polyfills (navigator, vscode)
 * 2. Imports each compiled .dart.js file so their tests register
 *
 * The manifest itself does NOT define any tests - it just triggers the
 * Dart test registration.
 */
const fs = require('fs');
const path = require('path');

const testDir = path.join(__dirname, '../test/suite');
const outDir = path.join(__dirname, '../out/test/suite');

function parseDartTestFile(content, filename) {
  const result = { suites: [] };
  let currentSuite = null;

  const lines = content.split('\n');
  for (const line of lines) {
    const suiteMatch = line.match(/suite\s*\(\s*['"]([^'"]+)['"]/);
    const testMatch = line.match(/test\s*\(\s*['"]([^'"]+)['"]/);

    if (suiteMatch) {
      currentSuite = { name: suiteMatch[1], tests: [], file: filename };
      result.suites.push(currentSuite);
    } else if (testMatch && currentSuite) {
      currentSuite.tests.push(testMatch[1]);
    }
  }

  return result;
}

function generateManifest(dartFiles) {
  // Just load the wrapped .test.js files - they have polyfills built in
  // and will register their suites/tests with Mocha when loaded
  let code = `// Test manifest - loads all wrapped Dart test files
// Auto-generated - do not edit manually
`;

  for (const dartFile of dartFiles) {
    // commands_test.dart -> commands.test.js (the wrapped file)
    const jsFile = dartFile.replace('_test.dart', '.test.js');
    code += `require('./${jsFile}');\n`;
  }

  return code;
}

async function main() {
  if (!fs.existsSync(outDir)) {
    fs.mkdirSync(outDir, { recursive: true });
  }

  const dartFiles = fs.readdirSync(testDir).filter(f => f.endsWith('_test.dart'));
  let totalSuites = 0;
  let totalTests = 0;

  console.log(`Parsing ${dartFiles.length} Dart test files...`);

  for (const dartFile of dartFiles) {
    const dartPath = path.join(testDir, dartFile);
    const dartContent = fs.readFileSync(dartPath, 'utf8');

    const parsed = parseDartTestFile(dartContent, dartFile);

    for (const suite of parsed.suites) {
      totalSuites++;
      totalTests += suite.tests.length;
      console.log(`  ${dartFile}: suite '${suite.name}' with ${suite.tests.length} tests`);
    }
  }

  const manifest = generateManifest(dartFiles);
  const manifestPath = path.join(outDir, 'manifest.test.js');
  fs.writeFileSync(manifestPath, manifest);

  console.log(`\nGenerated ${manifestPath}`);
  console.log(`Total: ${totalSuites} suites, ${totalTests} tests`);
}

main().catch(console.error);
