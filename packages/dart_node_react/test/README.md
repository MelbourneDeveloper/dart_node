# React UI Tests

Full UI interaction tests using React Testing Library.

## Setup

```bash
cd packages/react/test
npm install
```

## Build Dart Tests

Compile the Dart test components to JavaScript:

```bash
dart compile js test/ui_test.dart -o test/dist/ui_test.js
```

Or from the test directory:

```bash
npm run build:tests
```

## Run Tests

```bash
npm test
```

## Watch Mode

```bash
npm run test:watch
```

## Coverage

```bash
npm run test:coverage
```

## Test Structure

- `ui_test.dart` - Dart test components (Counter, Form, Toggle, List)
- `ui.test.js` - Jest test file using React Testing Library
- `jest.setup.js` - Jest configuration and global setup
- `dist/` - Compiled JavaScript output

## Components Tested

1. **Counter** - State updates with increment/decrement/reset
2. **Form** - Input handling, validation, submission
3. **Toggle** - Boolean state toggling
4. **List** - Dynamic add/remove items

## Shared Test IDs

All components use consistent `data-testid` attributes defined in:
`packages/ui_testing/lib/src/test_components.dart`
