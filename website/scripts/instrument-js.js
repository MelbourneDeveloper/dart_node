#!/usr/bin/env node
/**
 * Instruments JavaScript files with Istanbul for coverage tracking.
 * This approach tracks all code execution including event handlers.
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { createInstrumenter } from 'istanbul-lib-instrument';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const websiteDir = path.join(__dirname, '..');
const srcDir = path.join(websiteDir, 'src', 'assets', 'js');
const distDir = path.join(websiteDir, '_site', 'assets', 'js');

// Create instrumenter
const instrumenter = createInstrumenter({
  esModules: false,
  compact: false,
  produceSourceMap: true,
  autoWrap: true,
  coverageVariable: '__coverage__',
  coverageGlobalScope: 'window',
  coverageGlobalScopeFunc: false,
});

// Get all JS files in source directory
const jsFiles = fs.readdirSync(srcDir).filter(f => f.endsWith('.js'));

for (const file of jsFiles) {
  const srcPath = path.join(srcDir, file);
  const distPath = path.join(distDir, file);

  // Read source
  const code = fs.readFileSync(srcPath, 'utf-8');

  // Instrument
  const instrumented = instrumenter.instrumentSync(code, srcPath);

  // Write to dist (overwrite the built file)
  fs.writeFileSync(distPath, instrumented);

  console.log(`Instrumented: ${file}`);
}

console.log('\nInstrumentation complete. Run tests now.');
