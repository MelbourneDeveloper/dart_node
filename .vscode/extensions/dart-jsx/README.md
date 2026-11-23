# Dart JSX Syntax Extension

This is a local VS Code extension that provides syntax highlighting for JSX syntax in Dart files with the `.jsx` extension.

## Features

- Syntax highlighting for JSX tags (`<div>`, `</div>`, `<Component />`)
- Syntax highlighting for JSX attributes (`className`, `onClick`, etc.)
- Syntax highlighting for JSX expressions (`{expression}`)
- Full Dart syntax support for non-JSX code
- Embedded Dart expressions within JSX

## Installation

This extension is automatically available when you open this workspace in VS Code. No manual installation required.

## Usage

Create files with the `.jsx` extension and they will automatically use the Dart JSX syntax highlighting.

## Scopes

The following TextMate scopes are used:

- `entity.name.tag.jsx` - JSX tag names
- `support.class.component.jsx` - JSX component names
- `entity.other.attribute-name.jsx` - JSX attribute names
- `punctuation.definition.tag.jsx` - JSX tag brackets (`<`, `>`, `</`, `/>`)
- `punctuation.section.embedded.jsx` - JSX expression braces (`{`, `}`)
- `string.quoted.double.jsx` - Double-quoted strings in JSX
- `string.quoted.single.jsx` - Single-quoted strings in JSX
- `meta.embedded.expression.jsx` - JSX embedded expressions

Colors can be customized in workspace settings under `editor.tokenColorCustomizations.textMateRules`.
