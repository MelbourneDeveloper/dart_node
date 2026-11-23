# Markdown Editor

A Word-style WYSIWYG document editor with a Markdown backend, built entirely in Dart using React via `dart_node_react`.

## Features

- **WYSIWYG Editing**: Rich text editing with toolbar controls for bold, italic, underline, strikethrough
- **Headings**: H1, H2, H3 support via dropdown selector
- **Lists**: Bullet and numbered lists
- **Block Elements**: Code blocks, blockquotes, horizontal rules
- **Links**: Insert and edit hyperlinks with dialog
- **Mode Toggle**: Switch between formatted view and raw Markdown view
- **Live Word Count**: Real-time word count in status bar
- **Dark Theme**: Modern dark UI with gradient accents

## Prerequisites

- Dart SDK 3.10+
- Node.js (for serving the compiled app)

## Running the App

### 1. Install dependencies

```bash
cd examples/markdown_editor
dart pub get
```

### 2. Compile to JavaScript

```bash
dart compile js web/app.dart -o web/build/app.js
```

### 3. Serve the app

Use any static file server to serve the `web/` directory:

```bash
# Using Python
python3 -m http.server 8080 -d web

# Using Node.js (npx)
npx serve web

# Using PHP
php -S localhost:8080 -t web
```

### 4. Open in browser

Navigate to `http://localhost:8080` (or whatever port your server uses).

## Project Structure

```
markdown_editor/
├── lib/
│   ├── markdown_editor.dart          # Library exports
│   └── src/
│       ├── components/
│       │   ├── editor_app.dart       # Main app component
│       │   ├── editor_area.dart      # WYSIWYG contenteditable area
│       │   ├── markdown_view.dart    # Raw markdown textarea
│       │   ├── toolbar.dart          # Formatting toolbar
│       │   └── link_dialog.dart      # Link insertion dialog
│       ├── editor_commands.dart      # execCommand wrappers
│       ├── markdown_parser.dart      # HTML <-> Markdown conversion
│       └── types.dart                # Type definitions
├── web/
│   ├── app.dart                      # Entry point
│   └── index.html                    # HTML shell with styles
├── test/
│   └── editor_test.dart              # UI tests
└── pubspec.yaml
```

## How It Works

The editor uses the browser's `contenteditable` API for WYSIWYG editing, with `document.execCommand` for formatting. Content is converted to Markdown for storage and can be viewed/edited in raw Markdown mode using the `marked.js` library for parsing.

All UI is built with Dart using the `dart_node_react` package, which provides typed bindings to React 18.

## Testing

```bash
dart test
```

Tests run in a browser environment using `dart_test.yaml` configuration.
