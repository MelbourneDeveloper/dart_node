# CLAUDE.md

This is a project for Dart packages to be consumed on Node for building node-based apps with the Dart

# Rules
- All Dart. Absolutely minimal JS
- NO DUPLICATION. Move files, code elements instead of copying them. Search for elements before adding them. HIGHEST PRIORITY. PRIORITIZE THIS OVER ALL ELSE!!
- Avoid casting!!! ! etc are all ILLEGAL!!!
- Return Result<T,E> from the nadz library for any function that could throw an exception <- CRITICAL!!!
- All packages MUST have austerity installed for linting and nadz for Result<T,E> types
- Do not expose `JSObject` or `JSAny` etc in the public APIs. Put types over everything
- Do not expose raw JS objects like JSAny to the higher levels. The library packages are supposed to put a TYPED layer over these
- Fix ALL lint errors
- NO GLOBAL STATE
- Move non-example-specific code to the framework packages
- No skipping tests EVER!!! Agressively unskip tests when you find them!!
- Failing tests = OK. Removing assertions or tests = ILLEGAL!!
- NO THROWING EXCEPTIONS. Return results. Handle errors with Result types, except for cases where the code is a placeholder.
- NO PLACEHOLDERS!!! If you HAVE TO leave a section blank, fail LOUDLY by throwing an exception.
- Tests must FAIL HARD. Don't add allowances and print warnings. Just FAIL!
- Keep functions under 20 lines long and files under 500 loc
- NEVER use the late keyword
- Do not use Git commands unless explicitly requested
- Don't use if statements. Use pattern matching or ternaries instead. The exceptional case is if inside arrays and maps because these are declarative and not imperaative.

## Build & Run Commands

```bash
# Build express_server example (compiles Dart to Node-compatible JS)
dart run tools/build/build.dart express_server

# Run the compiled server
node examples/express_server/build/server.js

# Install Node dependencies for express example
cd examples/express_server && npm install

# Run tests for express example
cd examples/express_server && dart test
```

Critical documentation URLs for the Dart JS Framework project.

## Dart (Core & JS Interop)

| Topic | URL |
|-------|-----|
| JS Interop Main Guide | https://dart.dev/interop/js-interop |
| dart:js_interop API Reference | https://api.flutter.dev/flutter/dart-js_interop/ |
| JS Interop Usage Guide | https://dart.dev/interop/js-interop/usage |
| Getting Started with JS Interop | https://dart.dev/interop/js-interop/start |
| JS Types Reference | https://dart.dev/interop/js-interop/js-types |
| JS Interop Tutorials | https://dart.dev/interop/js-interop/tutorials |
| Mocking JS Interop Objects | https://dart.dev/interop/js-interop/mock |
| Legacy JS Interop (migration) | https://dart.dev/interop/js-interop/past-js-interop |
| Extension Types | https://dart.dev/language/extension-types |
| dart compile js | https://dart.dev/tools/dart-compile#js |
| dart2js Compiler | https://dart.dev/tools/dart2js |
| dartdevc (dev compiler) | https://dart.dev/tools/dartdevc |

## Node.js Compatibility

| Topic | URL |
|-------|-----|
| node_preamble Package | https://pub.dev/packages/node_preamble |
| node_preamble GitHub | https://github.com/mbullington/node_preamble.dart |

## Express.js (Phase 1 - Backend)

| Topic | URL |
|-------|-----|
| Express 5.x API Reference | https://expressjs.com/en/5x/api.html |
| Express 4.x API Reference | https://expressjs.com/en/4x/api.html |
| Express DevDocs (offline) | https://devdocs.io/express/ |

## React (Phase 2 - Web Frontend)

| Topic | URL |
|-------|-----|
| React 18 Reference | https://18.react.dev/reference/react |
| Built-in React APIs | https://react.dev/reference/react/apis |
| Hooks API Reference | https://legacy.reactjs.org/docs/hooks-reference.html |
| React DevDocs (offline) | https://devdocs.io/react/ |

## React Native / Expo (Phase 3 - Mobile)

| Topic | URL |
|-------|-----|
| React Native Components & APIs | https://reactnative.dev/docs/components-and-apis |
| React Native DevDocs (offline) | https://devdocs.io/react_native/ |
| Expo Documentation | https://docs.expo.dev/ |
| Expo SDK Reference | https://docs.expo.dev/versions/latest/ |
| Expo Modules API | https://docs.expo.dev/modules/overview/ |
| Using Expo Libraries | https://docs.expo.dev/workflow/using-libraries/ |

## Key Notes

- `dart:js_interop` is the modern approach (Dart 3.3+)
- `dart:js_util` and `package:js` are deprecated as of Dart 3.7
- Extension types provide zero-cost wrappers for JS objects
- `node_preamble` is essential for making dart2js output Node.js compatible
- Express 5.x is latest, but 4.x still widely used
- React 18 docs at `18.react.dev` are canonical
- Expo SDK releases 3x/year, targets specific React Native versions

## Architecture

- 

## Testing

Tests in `examples/express_server/test/` use the standard `package:test`. The test spawns the Node server process and makes HTTP requests against it. The server must be built before running tests.
