#!/usr/bin/env node
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { execSync } from 'child_process';
import v8toIstanbul from 'v8-to-istanbul';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const websiteDir = path.join(__dirname, '..');
const coverageDir = path.join(websiteDir, 'coverage');
const srcDir = path.join(websiteDir, 'src', 'assets', 'js');
const nycOutputDir = path.join(coverageDir, '.nyc_output');

// Ensure directories exist
if (!fs.existsSync(nycOutputDir)) fs.mkdirSync(nycOutputDir, { recursive: true });

// Read all coverage files
const files = fs.readdirSync(coverageDir)
  .filter(f => f.startsWith('coverage-') && f.endsWith('.json'));

if (files.length === 0) {
  console.log('No coverage files found');
  process.exit(0);
}

// Merge V8 coverage data
const mergedV8 = {};

for (const file of files) {
  const content = fs.readFileSync(path.join(coverageDir, file), 'utf-8');
  if (content.trim() === '[]' || content.trim() === '') continue;

  const data = JSON.parse(content);

  for (const entry of data) {
    if (!entry.url || !entry.source) continue;

    const key = entry.url;
    if (!mergedV8[key]) {
      mergedV8[key] = {
        url: entry.url,
        scriptId: entry.scriptId || '0',
        source: entry.source,
        functions: [],
      };
    }

    // Merge functions
    if (entry.functions) {
      mergedV8[key].functions.push(...entry.functions);
    }
  }
}

// Convert to Istanbul format and generate reports
const istanbulCoverage = {};

for (const [url, v8Data] of Object.entries(mergedV8)) {
  const fileName = url.split('/').pop() || 'unknown.js';
  // Use the actual source file path so nyc can find it
  const sourceFile = path.join(srcDir, fileName);

  // Make sure source file exists with the exact content
  fs.writeFileSync(sourceFile, v8Data.source);

  try {
    const converter = v8toIstanbul(sourceFile, 0, { source: v8Data.source });
    await converter.load();

    // Apply V8 coverage
    converter.applyCoverage(v8Data.functions);

    // Get Istanbul format
    const istanbul = converter.toIstanbul();
    Object.assign(istanbulCoverage, istanbul);
  } catch (err) {
    console.error(`Error converting ${fileName}:`, err.message);
  }
}

// Write Istanbul coverage
const istanbulFile = path.join(nycOutputDir, 'coverage.json');
fs.writeFileSync(istanbulFile, JSON.stringify(istanbulCoverage, null, 2));

// Generate HTML and LCOV reports using nyc
console.log('\nGenerating coverage reports...\n');

try {
  execSync(`npx nyc report --reporter=html --reporter=lcov --reporter=text --temp-dir="${nycOutputDir}" --report-dir="${coverageDir}" --include="src/assets/js/**/*.js"`, {
    cwd: websiteDir,
    stdio: 'inherit',
  });
} catch (err) {
  console.error('Failed to generate reports:', err.message);
}

// Clean up individual coverage files
for (const file of files) {
  fs.unlinkSync(path.join(coverageDir, file));
}

console.log(`\nHTML report: ${path.join(coverageDir, 'index.html')}`);
console.log(`LCOV report: ${path.join(coverageDir, 'lcov.info')}`);
console.log('');
