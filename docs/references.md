# Documentation Reference

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
