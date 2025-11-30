# React Native UI Tests

Full UI interaction tests using React Native Testing Library.

## Setup

```bash
cd packages/react_native/test
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

- `ui_test.dart` - Dart test components (Counter, Form, Toggle, List, Switch, Loading)
- `ui.test.js` - Jest test file using React Native Testing Library
- `jest.setup.js` - Jest configuration and global setup
- `dist/` - Compiled JavaScript output

## Components Tested

1. **Counter** - State updates with increment/decrement/reset
2. **Form** - TextInput handling, validation, submission
3. **Toggle** - Boolean state toggling with TouchableOpacity
4. **List** - Dynamic add/remove items
5. **Switch** - RN Switch component toggle
6. **Loading** - ActivityIndicator loading states

## Shared Test IDs

All components use consistent `testID` attributes defined in:
`packages/ui_testing/lib/src/test_components.dart`

## Note on React Native Testing

React Native Testing Library runs tests in a Node.js environment with mocked
native modules. This allows testing component behavior without requiring a
device or emulator.
