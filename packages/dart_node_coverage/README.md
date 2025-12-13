# dart_node_coverage

Code coverage collection for Dart code compiled with dart2js and executed in Node.js.

## Architecture

This package provides compile-time instrumentation for Dart source code to enable line coverage tracking when running tests in Node.js via dart2js.

See [lib/src/architecture.dart](lib/src/architecture.dart) for detailed architecture documentation.

## Key Features

- **Compile-time instrumentation**: Insert coverage probes before dart2js compilation
- **LCOV output**: Standard format compatible with genhtml, coveralls, etc.
- **Integration with dart test**: Works with existing test workflows
- **Zero runtime overhead when disabled**: No cost without instrumentation

## How It Works

1. **Analyze** Dart source to identify executable lines
2. **Instrument** source by inserting coverage probe calls
3. **Compile** instrumented source with dart2js
4. **Execute** tests in Node.js (coverage collected automatically)
5. **Generate** LCOV report from coverage data

## Status

This package is in early development. The architecture is defined and implementation is in progress.
