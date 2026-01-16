#!/usr/bin/env node

/**
 * Copies package README.md files to docs directories at build time.
 *
 * Maps each package README to its corresponding docs folder, adding
 * the necessary Eleventy frontmatter for the docs layout.
 */

import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rootDir = join(__dirname, '..', '..');
const docsDir = join(__dirname, '..', 'src', 'docs');

// Mapping from package directory name to docs slug
const packageToDocsMap = {
  'dart_node_core': { slug: 'core', title: 'dart_node_core', order: 1 },
  'dart_node_express': { slug: 'express', title: 'dart_node_express', order: 2 },
  'dart_node_react': { slug: 'react', title: 'dart_node_react', order: 3 },
  'dart_node_react_native': { slug: 'react-native', title: 'dart_node_react_native', order: 4 },
  'dart_node_ws': { slug: 'websockets', title: 'dart_node_ws', order: 5 },
  'dart_node_better_sqlite3': { slug: 'sqlite', title: 'dart_node_better_sqlite3', order: 6 },
  'dart_node_mcp': { slug: 'mcp', title: 'dart_node_mcp', order: 7 },
  'dart_logging': { slug: 'logging', title: 'dart_logging', order: 8 },
  'reflux': { slug: 'reflux', title: 'reflux', order: 9 },
  'dart_jsx': { slug: 'jsx', title: 'dart_jsx', order: 10 },
};

function generateFrontmatter(config) {
  return `---
layout: layouts/docs.njk
title: ${config.title}
eleventyNavigation:
  key: ${config.title}
  parent: Packages
  order: ${config.order}
---

`;
}

function processReadme(content, packageName) {
  // Remove the first heading (# package_name) as it will be in the frontmatter title
  const lines = content.split('\n');
  let startIndex = 0;

  // Find and skip the first H1 heading
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].startsWith('# ')) {
      startIndex = i + 1;
      // Skip any blank lines immediately after the heading
      while (startIndex < lines.length && lines[startIndex].trim() === '') {
        startIndex++;
      }
      break;
    }
  }

  return lines.slice(startIndex).join('\n').trim();
}

function main() {
  console.log('Copying package READMEs to docs...\n');

  for (const [packageDir, config] of Object.entries(packageToDocsMap)) {
    const readmePath = join(rootDir, 'packages', packageDir, 'README.md');
    const docsPath = join(docsDir, config.slug);
    const outputPath = join(docsPath, 'index.md');

    if (!existsSync(readmePath)) {
      console.log(`  SKIP: ${packageDir} (no README.md)`);
      continue;
    }

    // Ensure docs directory exists
    if (!existsSync(docsPath)) {
      mkdirSync(docsPath, { recursive: true });
      console.log(`  CREATE: ${config.slug}/`);
    }

    // Read README content
    const readmeContent = readFileSync(readmePath, 'utf-8');

    // Process and write to docs
    const frontmatter = generateFrontmatter(config);
    const processedContent = processReadme(readmeContent, packageDir);
    const finalContent = frontmatter + processedContent + '\n';

    writeFileSync(outputPath, finalContent);
    console.log(`  COPY: ${packageDir}/README.md -> docs/${config.slug}/index.md`);
  }

  console.log('\nDone!');
}

main();
