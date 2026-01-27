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

### Quick Start

```bash
cd examples/markdown_editor
./run.sh
```

Then open http://localhost:8080 in your browser.

### Using npm scripts

```bash
cd examples/markdown_editor
dart pub get
npm start
```

### Manual steps

```bash
cd examples/markdown_editor
dart pub get
dart compile js web/app.dart -o web/build/app.js
npx serve web -p 8080
```

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
