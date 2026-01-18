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

  // Join all lines and normalize whitespace for multi-line matching
  // This handles suite( and test( calls where the name is on the next line
  const normalized = content.replace(/\n\s*/g, ' ');

  // Find all suite declarations
  const suiteRegex = /suite\s*\(\s*['"]([^'"]+)['"]/g;
  let suiteMatch;
  const suitePositions = [];
  while ((suiteMatch = suiteRegex.exec(normalized)) !== null) {
    suitePositions.push({ name: suiteMatch[1], pos: suiteMatch.index });
  }

  // Find all test declarations (but not commented out ones)
  // We need to check the ORIGINAL content for comments since normalization loses them
  const testRegex = /test\s*\(\s*['"]([^'"]+)['"]/g;
  let testMatch;
  const tests = [];
  while ((testMatch = testRegex.exec(normalized)) !== null) {
    const testName = testMatch[1];

    // Search for this test name in original content and check if it's commented
    // Escape special regex chars in test name
    const escapedName = testName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const originalTestRegex = new RegExp(`(//\\s*)?test\\s*\\(\\s*['"]${escapedName}['"]`);
    const originalMatch = content.match(originalTestRegex);

    if (originalMatch && originalMatch[1]) {
      // This test is commented out (has // before it)
      continue;
    }

    tests.push({ name: testName, pos: testMatch.index });
  }

  // Assign tests to suites based on position
  for (let i = 0; i < suitePositions.length; i++) {
    const suite = suitePositions[i];
    const nextSuitePos = i + 1 < suitePositions.length
      ? suitePositions[i + 1].pos
      : Infinity;

    const suiteTests = tests
      .filter(t => t.pos > suite.pos && t.pos < nextSuitePos)
      .map(t => t.name);

    result.suites.push({
      name: suite.name,
      tests: suiteTests,
      file: filename
    });
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
