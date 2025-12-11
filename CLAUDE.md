# CLAUDE.md

This is a project for Dart packages to be consumed on Node for building node-based apps with the Dart

MANDATORY: TOO MANY COOKS
 - check your messages regularly
 - lock files with too many cooks before editing, and unlock afterwards
 - do not edit files that others have locked up
 - always signal your intent to other agents
 - If you are coordinator, keep delegating until the grande scheme has been achieved
 - If you are not coordinator, don't stop and keep asking for something to do
 - Routinely clean up expired locks
 - If you find yourself with nothing to do, check someone else's plan and help them

# Rules
- All Dart. Absolutely minimal JS
- Use async/await. Do not use `.then`
- NO DUPLICATION. Move files, code elements instead of copying them. Search for elements before adding them. HIGHEST PRIORITY. PRIORITIZE THIS OVER ALL ELSE!!
- Prefer typedef records with named fields instead of classes for data (structural typing). This mimics Typescript better
- Shoot for 100% test coverage on each package with HIGH LEVEL, MEANINGFUL tests. Avoid unit tests and mocking.
- Return Result<T,E> from the nadz library for any function that could throw an exception. NO THROWING EXCEPTIONS.
- Don't make consecutive log calls. Use string interpolation
- Avoid casting!!! [! `as` `late`] are all ILLEGAL!!! U
- Don't break tests into groups. Break them into files instead!!
- Use pattern matching switch expressions or ternaries. The exceptional case is if inside arrays and maps because these are declarative and not imperaative.
- All packages MUST have austerity installed for linting and nadz for Result<T,E> types
- Do not expose `JSObject` or `JSAny` etc in the public APIs. Put types over everything. The library packages are supposed to put a TYPED layer over these
- No global state
- No skipping tests EVER!!! Agressively unskip tests when you find them!!
- Failing tests = OK. Removing assertions or tests = ILLEGAL!!
- NO PLACEHOLDERS!!! If you HAVE TO leave a section blank, fail LOUDLY by throwing an exception. This is the only time exceptions are allowed. Tests must FAIL HARD. Don't add allowances and print warnings. Just FAIL!
- Keep functions under 20 lines long and files under 500 loc
- Do not use Git commands unless explicitly requested

## Build & Run Commands

```bash
// Build everything
sh run_dev.sh
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

## React

| Topic | URL |
|-------|-----|
| React 18 Reference | https://18.react.dev/reference/react |
| Built-in React APIs | https://react.dev/reference/react/apis |
| Hooks API Reference | https://legacy.reactjs.org/docs/hooks-reference.html |
| React DevDocs (offline) | https://devdocs.io/react/ |

## React Native / Expo

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


## Testing

All projects MUST have tests. Where the package is a UI project, the tests MUST test the UI interactions and avoid unit testing. Tests are Dart only. No Javascript unless it's necessary to test the underlying interop.
