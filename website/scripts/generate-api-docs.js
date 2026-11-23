#!/usr/bin/env node

/**
 * Generate API documentation for dart_node packages.
 * Extracts content from dart doc HTML and wraps it in site templates.
 *
 * Structure:
 * /api/ - index of all packages
 * /api/dart_node_core/ - library page (classes, functions, etc.)
 * /api/dart_node_core/ClassName/ - class page
 * /api/dart_node_core/ClassName/method/ - method page
 */

import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { JSDOM } from 'jsdom';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const WEBSITE_DIR = path.dirname(__dirname);
const PROJECT_ROOT = path.dirname(WEBSITE_DIR);
const PACKAGES_DIR = path.join(PROJECT_ROOT, 'packages');
const API_OUTPUT_DIR = path.join(WEBSITE_DIR, 'src', 'api');
const TEMP_DIR = path.join(WEBSITE_DIR, '.dart-doc-temp');

const PACKAGES = [
  'dart_node_core',
  'dart_node_express',
  'dart_node_react',
  'dart_node_react_native',
  'dart_node_ws',
];

// Base URLs for external documentation
const DOC_BASES = {
  react: 'https://react.dev/reference/react',
  reactDom: 'https://react.dev/reference/react-dom',
  reactNative: 'https://reactnative.dev/docs',
  express: 'https://expressjs.com/en/5x/api.html',
  mdn: 'https://developer.mozilla.org/en-US/docs/Web/HTML/Element',
  ws: 'https://github.com/websockets/ws/blob/master/doc/ws.md',
  dartJsInterop: 'https://dart.dev/interop/js-interop',
};

// Package-level external documentation links (for package index pages)
const PACKAGE_DOCS = {
  dart_node_core: [
    { name: 'Dart JS Interop', url: DOC_BASES.dartJsInterop },
    { name: 'dart:js_interop API', url: 'https://api.flutter.dev/flutter/dart-js_interop/dart-js_interop-library.html' },
  ],
  dart_node_express: [
    { name: 'Express.js API', url: DOC_BASES.express },
  ],
  dart_node_react: [
    { name: 'React API Reference', url: DOC_BASES.react },
  ],
  dart_node_react_native: [
    { name: 'React Native Components', url: `${DOC_BASES.reactNative}/components-and-apis` },
    { name: 'Expo SDK', url: 'https://docs.expo.dev/versions/latest/' },
  ],
  dart_node_ws: [
    { name: 'ws (WebSocket) npm', url: 'https://github.com/websockets/ws' },
    { name: 'WebSocket API (MDN)', url: 'https://developer.mozilla.org/en-US/docs/Web/API/WebSocket' },
  ],
};

// Maps element name patterns to doc generators
// Each entry: { pattern: regex or string, generate: (elementName) => [{ name, url }] }
const ELEMENT_DOC_GENERATORS = [
  // React hooks - use* functions
  {
    pattern: /^use[A-Z]/,
    generate: (name) => [{ name: `React ${name}`, url: `${DOC_BASES.react}/${name}` }],
  },

  // HTML elements - *Element types (for dart_node_react)
  // React has official docs for DOM components: https://react.dev/reference/react-dom/components
  {
    pattern: /^(Div|Button|Input|Span|A|Img|P|H1|H2|H3|H4|H5|H6|Ul|Li|Header|Footer|Main|Nav|Section|Article|Form|Label|Textarea|Select|Option|Table|Tr|Td|Th)Element$/,
    generate: (name) => {
      const tag = name.replace(/Element$/, '').toLowerCase();
      // React docs use "common" for generic elements, specific pages for form elements
      const reactDocMap = {
        input: 'input', select: 'select', textarea: 'textarea', form: 'form',
        option: 'option', progress: 'progress', a: 'a', link: 'link',
      };
      const reactDoc = reactDocMap[tag] || 'common';
      return [{ name: `React ${tag} component`, url: `https://react.dev/reference/react-dom/components/${reactDoc}` }];
    },
  },

  // React Native components - RN*Element types
  {
    pattern: /^RN(\w+)Element$/,
    generate: (name) => {
      const component = name.match(/^RN(\w+)Element$/)?.[1]?.toLowerCase();
      return component
        ? [{ name: `React Native ${name.match(/^RN(\w+)Element$/)[1]}`, url: `${DOC_BASES.reactNative}/${component}` }]
        : [];
    },
  },

  // React Native lowercase functions (view, text, button, etc.)
  {
    pattern: /^(view|text|rnButton|rnImage|textInput|scrollView|flatList|touchableOpacity|safeAreaView|rnSwitch|activityIndicator)$/,
    generate: (name) => {
      const componentMap = {
        view: 'view', text: 'text', rnButton: 'button', rnImage: 'image',
        textInput: 'textinput', scrollView: 'scrollview', flatList: 'flatlist',
        touchableOpacity: 'touchableopacity', safeAreaView: 'safeareaview',
        rnSwitch: 'switch', activityIndicator: 'activityindicator',
      };
      const doc = componentMap[name];
      return doc
        ? [{ name: `React Native ${doc.charAt(0).toUpperCase() + doc.slice(1)}`, url: `${DOC_BASES.reactNative}/${doc}` }]
        : [];
    },
  },

  // AppRegistry
  {
    pattern: /^AppRegistry/,
    generate: () => [{ name: 'React Native AppRegistry', url: `${DOC_BASES.reactNative}/appregistry` }],
  },

  // React core types
  {
    pattern: /^React$/,
    generate: () => [{ name: 'React API Reference', url: DOC_BASES.react }],
  },
  {
    pattern: /^ReactDOM$/,
    generate: () => [{ name: 'ReactDOM API', url: DOC_BASES.reactDom }],
  },
  {
    pattern: /^ReactElement$/,
    generate: () => [{ name: 'React createElement', url: `${DOC_BASES.react}/createElement` }],
  },
  {
    pattern: /^ReactRoot$/,
    generate: () => [{ name: 'ReactDOM createRoot', url: `${DOC_BASES.reactDom}/client/createRoot` }],
  },
  {
    pattern: /^createElement$/,
    generate: () => [{ name: 'React createElement', url: `${DOC_BASES.react}/createElement` }],
  },

  // Express types
  {
    pattern: /^(Request|Response|Router|ExpressApp)$/,
    generate: (name) => {
      const anchorMap = { Request: 'req', Response: 'res', Router: 'router', ExpressApp: 'app' };
      return [{ name: `Express ${name}`, url: `${DOC_BASES.express}#${anchorMap[name]}` }];
    },
  },
  {
    pattern: /^express$/,
    generate: () => [{ name: 'Express express()', url: `${DOC_BASES.express}#express` }],
  },

  // WebSocket types
  {
    pattern: /^(WebSocketServer|JSWebSocketServer)$/,
    generate: () => [{ name: 'ws WebSocket.Server', url: `${DOC_BASES.ws}#class-websocketserver` }],
  },
  {
    pattern: /^(WebSocketClient|JSWebSocket)$/,
    generate: () => [{ name: 'ws WebSocket', url: `${DOC_BASES.ws}#class-websocket` }],
  },

  // ReactNative extension type
  {
    pattern: /^ReactNative$/,
    generate: () => [{ name: 'React Native API', url: `${DOC_BASES.reactNative}/components-and-apis` }],
  },
];

// Get external docs for an element using pattern matching
const getExternalDocs = (elementName, packageName) => {
  // Clean up element name - remove suffixes like -extension-type, -class
  const cleanName = elementName
    .replace(/-extension-type$/, '')
    .replace(/-class$/, '');

  // Find matching generator
  const generator = ELEMENT_DOC_GENERATORS.find(g =>
    (typeof g.pattern === 'string')
      ? cleanName === g.pattern
      : g.pattern.test(cleanName)
  );

  return generator ? generator.generate(cleanName) : null;
};

const ensureDir = (dir) => fs.mkdirSync(dir, { recursive: true });

const cleanDir = (dir) => {
  fs.existsSync(dir) && fs.rmSync(dir, { recursive: true });
  ensureDir(dir);
};

const runDartDoc = (packageDir, outputDir) => {
  console.log(`  Running dart pub get...`);
  execSync('dart pub get', { cwd: packageDir, stdio: 'inherit' });
  console.log(`  Running dart doc...`);
  execSync(`dart doc --output="${outputDir}"`, { cwd: packageDir, stdio: 'inherit' });
};

const escapeYaml = (str) => str.replace(/"/g, '\\"').replace(/\n/g, ' ');

const extractContent = (htmlPath, packageName) => {
  const html = fs.readFileSync(htmlPath, 'utf-8');
  const dom = new JSDOM(html);
  const doc = dom.window.document;

  const selfName = doc.querySelector('.self-name');
  const h1 = doc.querySelector('#dartdoc-main-content h1');
  const title = selfName?.textContent?.trim() || h1?.textContent?.trim() || 'API Documentation';

  const metaDesc = doc.querySelector('meta[name="description"]');
  const description = metaDesc?.getAttribute('content') || '';

  const mainContent = doc.querySelector('#dartdoc-main-content');

  return mainContent
    ? { title, description, content: processContent(mainContent, packageName, dom) }
    : null;
};

const processContent = (element, packageName, dom) => {
  const h1 = element.querySelector('h1');
  h1?.remove();

  element.removeAttribute('data-above-sidebar');
  element.removeAttribute('data-below-sidebar');

  // Convert mermaid code blocks
  element.querySelectorAll('pre.language-mermaid, pre code.language-mermaid').forEach(el => {
    const pre = el.tagName === 'PRE' ? el : el.parentElement;
    const code = el.tagName === 'CODE' ? el.textContent : el.querySelector('code')?.textContent || el.textContent;
    const mermaidDiv = dom.window.document.createElement('div');
    mermaidDiv.className = 'mermaid';
    mermaidDiv.textContent = code;
    pre.replaceWith(mermaidDiv);
  });

  // Fix internal links for new flat structure
  element.querySelectorAll('a').forEach(a => {
    const href = a.getAttribute('href');
    (!href || href.startsWith('http') || href.startsWith('#')) && null;

    href && !href.startsWith('http') && !href.startsWith('#') && (() => {
      let newHref = href.replace(/\.html$/, '/');

      // Links like ../dart_node_ws/Foo.html -> /api/dart_node_ws/Foo/
      // (removing the duplicate package/package structure)
      newHref.startsWith('../') && (newHref = newHref.replace(/^\.\.\//, `/api/`));

      // Links like Foo.html -> Foo/ (relative, stays same level)
      // Links like Foo/bar.html -> Foo/bar/

      a.setAttribute('href', newHref);
    })();
  });

  return element.innerHTML;
};

const createMdFile = (outputPath, title, description, packageName, content, elementName = null) => {
  // Get element-specific docs only - no fallbacks
  const externalLinks = elementName
    ? (getExternalDocs(elementName, packageName) || [])
    : (PACKAGE_DOCS[packageName] || []);

  const linksHtml = externalLinks.length > 0
    ? `<div class="external-docs">
<h4>External Documentation</h4>
<ul>
${externalLinks.map(link => `<li><a href="${link.url}" target="_blank" rel="noopener">${link.name} ↗</a></li>`).join('\n')}
</ul>
</div>

`
    : '';

  const md = `---
layout: layouts/api.njk
title: "${escapeYaml(title)}"
description: "${escapeYaml(description)}"
package: "${packageName}"
---

${linksHtml}${content}
`;
  fs.writeFileSync(outputPath, md);
};

const processPackage = async (packageName) => {
  const packageDir = path.join(PACKAGES_DIR, packageName);

  !fs.existsSync(packageDir) && console.log(`Warning: Package not found: ${packageDir}`);

  fs.existsSync(packageDir) && (() => {
    console.log(`\n=== Processing ${packageName} ===`);

    const tempDocDir = path.join(TEMP_DIR, packageName);
    ensureDir(tempDocDir);
    runDartDoc(packageDir, tempDocDir);

    const outputDir = path.join(API_OUTPUT_DIR, packageName);
    ensureDir(outputDir);

    // Use LIBRARY index.html as the package index
    // dart doc creates: tempDocDir/packageName/index.html (the library page)
    const indexHtml = path.join(tempDocDir, packageName, 'index.html');

    fs.existsSync(indexHtml) && (() => {
      const data = extractContent(indexHtml, packageName);
      data && createMdFile(
        path.join(outputDir, 'index.md'),
        `${packageName} library`,
        data.description,
        packageName,
        data.content
      );
    })();

    // Process all other files in library directory - put them DIRECTLY under package
    const libDir = path.join(tempDocDir, packageName);
    fs.existsSync(libDir) && processLibraryDir(libDir, outputDir, packageName);

    console.log(`Documentation processed for ${packageName}`);
  })();
};

const processLibraryDir = (libDir, outputDir, packageName) => {
  const entries = fs.readdirSync(libDir, { withFileTypes: true });

  entries.forEach(entry => {
    const fullPath = path.join(libDir, entry.name);

    // Skip the library index files - already processed as package index
    const skipFiles = [`${packageName}-library.html`, `${packageName}-library-sidebar.html`, 'index.html'];

    entry.isFile() && entry.name.endsWith('.html') && !skipFiles.includes(entry.name) && (() => {
      const data = extractContent(fullPath, packageName);
      const baseName = path.basename(entry.name, '.html');
      // Put class files directly under package: /api/package/ClassName/
      const classDir = path.join(outputDir, baseName);
      ensureDir(classDir);
      data && createMdFile(
        path.join(classDir, 'index.md'),
        data.title,
        data.description,
        packageName,
        data.content,
        baseName  // Pass element name for specific external docs
      );
    })();

    // Process subdirectories (class methods, properties, etc.)
    entry.isDirectory() && (() => {
      const subOutputDir = path.join(outputDir, entry.name);
      const parentElementName = entry.name;  // The class/type name
      ensureDir(subOutputDir);

      fs.readdirSync(fullPath)
        .filter(f => f.endsWith('.html'))
        .forEach(file => {
          const data = extractContent(path.join(fullPath, file), packageName);
          const baseName = path.basename(file, '.html');
          const methodDir = path.join(subOutputDir, baseName);
          ensureDir(methodDir);
          data && createMdFile(
            path.join(methodDir, 'index.md'),
            data.title,
            data.description,
            packageName,
            data.content,
            parentElementName  // Use parent class name for external docs
          );
        });
    })();
  });
};

const createMainIndex = () => {
  const content = `---
layout: layouts/api.njk
title: API Reference
description: Complete API documentation for all dart_node packages
---

<p>Select a package to view its API documentation:</p>

<h2>Packages</h2>

<div class="features-grid">
  <a href="/api/dart_node_core/" class="feature-card">
    <h3>dart_node_core</h3>
    <p>Core JS interop utilities and foundation for all other packages.</p>
  </a>

  <a href="/api/dart_node_express/" class="feature-card">
    <h3>dart_node_express</h3>
    <p>Express.js bindings for building HTTP servers and REST APIs.</p>
  </a>

  <a href="/api/dart_node_react/" class="feature-card">
    <h3>dart_node_react</h3>
    <p>React bindings for building web applications.</p>
  </a>

  <a href="/api/dart_node_react_native/" class="feature-card">
    <h3>dart_node_react_native</h3>
    <p>React Native bindings for mobile apps with Expo.</p>
  </a>

  <a href="/api/dart_node_ws/" class="feature-card">
    <h3>dart_node_ws</h3>
    <p>WebSocket bindings for real-time communication.</p>
  </a>
</div>
`;
  fs.writeFileSync(path.join(API_OUTPUT_DIR, 'index.md'), content);
};

const main = async () => {
  console.log('Generating API documentation for dart_node packages...');
  console.log(`Packages directory: ${PACKAGES_DIR}`);
  console.log(`Output directory: ${API_OUTPUT_DIR}`);

  cleanDir(TEMP_DIR);
  cleanDir(API_OUTPUT_DIR);

  for (const pkg of PACKAGES) {
    await processPackage(pkg);
  }

  createMainIndex();
  fs.rmSync(TEMP_DIR, { recursive: true });

  console.log('\n=== API documentation generation complete ===');
  console.log(`Output: ${API_OUTPUT_DIR}`);
};

main().catch(err => {
  console.error('Error generating API docs:', err);
  process.exit(1);
});
