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
        functions: new Map(), // Use Map to properly merge function coverage
      };
    }

    // Merge functions by their offset ranges
    if (entry.functions) {
      for (const func of entry.functions) {
        const rangeKey = `${func.ranges[0].startOffset}-${func.ranges[0].endOffset}`;
        const existing = mergedV8[key].functions.get(rangeKey);

        if (!existing) {
          // Clone the function data
          mergedV8[key].functions.set(rangeKey, JSON.parse(JSON.stringify(func)));
        } else {
          // Merge counts for each range
          for (let i = 0; i < func.ranges.length; i++) {
            if (existing.ranges[i]) {
              existing.ranges[i].count = Math.max(
                existing.ranges[i].count,
                func.ranges[i].count
              );
            }
          }
        }
      }
    }
  }
}

// Convert Map back to array for v8-to-istanbul
for (const key of Object.keys(mergedV8)) {
  mergedV8[key].functions = Array.from(mergedV8[key].functions.values());
}

// Convert to Istanbul format and generate reports
const istanbulCoverage = {};

// Use a temp directory for v8-to-istanbul source files
const tempDir = path.join(coverageDir, '.temp-sources');
if (!fs.existsSync(tempDir)) fs.mkdirSync(tempDir, { recursive: true });

for (const [url, v8Data] of Object.entries(mergedV8)) {
  const fileName = url.split('/').pop() || 'unknown.js';
  // Use a temp file for v8-to-istanbul, but map to real source path
  const tempFile = path.join(tempDir, fileName);
  const realSourceFile = path.join(srcDir, fileName);

  // Write source to temp file for v8-to-istanbul to read
  fs.writeFileSync(tempFile, v8Data.source);

  try {
    const converter = v8toIstanbul(tempFile, 0, { source: v8Data.source });
    await converter.load();

    // Apply V8 coverage
    converter.applyCoverage(v8Data.functions);

    // Get Istanbul format
    const istanbul = converter.toIstanbul();

    // Remap the path to the real source file
    for (const [tempPath, data] of Object.entries(istanbul)) {
      data.path = realSourceFile;
      istanbulCoverage[realSourceFile] = data;
    }
  } catch (err) {
    console.error(`Error converting ${fileName}:`, err.message);
  }
}

// Clean up temp directory
fs.rmSync(tempDir, { recursive: true, force: true });

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
