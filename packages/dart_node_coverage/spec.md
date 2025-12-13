# dart_node_coverage Implementation Specification

**READ THIS ENTIRE DOCUMENT BEFORE WRITING ANY CODE. NO EXCEPTIONS.**

## Mission

Build a coverage collector for Dart tests running on Node.js (dart2js compiled). Standard `dart test --coverage` does NOT work with dart2js - it only works on the Dart VM. We need AST instrumentation.

## Required Reading

Before implementing ANYTHING, read these resources:

1. **LCOV Format** - https://manpages.debian.org/unstable/lcov/geninfo.1.en.html
   - Understand SF, DA, LF, LH, end_of_record format
   - This is your OUTPUT format

2. **AST Instrumentation** - https://adamrehn.com/articles/ast-instrumentation-examples-by-language/
   - Core pattern: wrap executable nodes with probe function calls
   - Probe returns original value to maintain semantics

3. **Clang Source-Based Coverage** - https://clang.llvm.org/docs/SourceBasedCodeCoverage.html
   - Industry standard approach
   - Counter insertion at coverage regions

4. **Efficient Instrumentation** - https://www.cs.umd.edu/~hollings/papers/issta02.pdf
   - Academic approach to minimizing overhead

## Architecture Overview

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Dart Source    │────▶│  Instrumenter    │────▶│ Instrumented    │
│  (lib/*.dart)   │     │  (AST analysis)  │     │ Source          │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                                                          │
                                                          ▼
                        ┌──────────────────┐     ┌─────────────────┐
                        │  LCOV Generator  │◀────│  dart2js +      │
                        │  (lcov.info)     │     │  Node.js test   │
                        └──────────────────┘     └─────────────────┘
```

## LCOV Output Format (MANDATORY)

```
SF:/absolute/path/to/file.dart
DA:5,3
DA:8,0
DA:10,1
LF:3
LH:2
end_of_record
```

- `SF:` - Source file absolute path
- `DA:<line>,<count>` - Line number and execution count
- `LF:` - Total lines found (instrumented)
- `LH:` - Lines hit (count > 0)
- `end_of_record` - Terminates file section

## Implementation Components

### 1. Parser (`lib/src/parser.dart`)

Identifies executable lines using Dart analyzer AST.

**Executable lines include:**
- Expression statements
- Variable declarations with initializers
- Return/throw statements
- Control flow (if, switch, for, while, do-while)
- Function/method calls
- Assignments

**NOT executable:**
- Blank lines
- Comments
- Import/export/part directives
- Opening/closing braces only
- Type definitions without initializers

```dart
Result<Set<int>, String> parseExecutableLines(String sourceCode, String filePath);
```

### 2. Instrumenter (`lib/src/instrumenter.dart`)

Injects coverage probes at executable lines.

**Strategy:** Insert `_$cov('file.dart', lineNum);` at start of each executable line.

```dart
// BEFORE
void main() {
  print('hello');
  final x = compute();
}

// AFTER
void main() {
  _$cov('main.dart', 2); print('hello');
  _$cov('main.dart', 3); final x = compute();
}
```

```dart
Result<String, String> instrumentSource({
  required String sourceCode,
  required String filePath,
  required Set<int> executableLines,
});
```

### 3. Runtime Probe (`lib/src/runtime.dart`)

JavaScript interop for coverage collection in Node.js.

```dart
import 'dart:js_interop';

/// Global coverage data stored in JS
@JS('globalThis.__dartCoverage')
external JSObject? get _coverageData;

/// Initialize coverage collection
void initCoverage() {
  // Create globalThis.__dartCoverage = {}
}

/// Record line execution - MUST be fast!
void _$cov(String file, int line) {
  // Increment globalThis.__dartCoverage[file][line]
}

/// Dump coverage as JSON
String dumpCoverage() {
  // Serialize __dartCoverage to JSON string
}
```

**CRITICAL:** The `_$cov` function is called MILLIONS of times. It must be:
- No allocations in hot path
- Direct JS interop, no wrapper objects
- Increment counter, nothing else

### 4. LCOV Generator (`lib/src/lcov.dart`)

Converts coverage data to LCOV format.

```dart
typedef FileCoverage = ({
  String filePath,
  Map<int, int> lineCounts,
});

Result<String, String> generateLcov(List<FileCoverage> coverage);
```

### 5. CLI (`bin/coverage.dart`)

Orchestrates the workflow:

```bash
dart run dart_node_coverage:coverage ./packages/dart_node_core --output coverage/lcov.info
```

Workflow:
1. Find all `lib/**/*.dart` files
2. Parse each for executable lines
3. Instrument source, write to `.dart_node_coverage/` temp dir
4. Copy `test/` directory with modified imports
5. Run `dart test` on instrumented code
6. Parse coverage JSON from stdout/file
7. Generate LCOV
8. Clean up temp files

## Code Rules (from CLAUDE.md)

**ILLEGAL - DO NOT USE:**
- `as` keyword
- `late` keyword
- `!` null assertion
- `.then()` for futures
- Global mutable state

**REQUIRED:**
- `Result<T, E>` from nadz for all fallible operations
- Functions < 20 lines
- Files < 500 LOC
- No code duplication

## File Structure

```
packages/dart_node_coverage/
├── pubspec.yaml
├── analysis_options.yaml
├── dart_test.yaml (platforms: [vm])
├── lib/
│   ├── dart_node_coverage.dart (barrel)
│   └── src/
│       ├── parser.dart
│       ├── instrumenter.dart
│       ├── runtime.dart
│       ├── lcov.dart
│       └── cli.dart
├── bin/
│   └── coverage.dart
└── test/
    ├── parser_test.dart
    ├── instrumenter_test.dart
    └── lcov_test.dart
```

## Testing Strategy

Test with `dart_node_core` package:
1. Run coverage tool
2. Verify lcov.info is generated
3. Verify line counts are non-zero for exercised code
4. Compare against expected coverage

## DO NOT

- Skip reading the reference materials
- Implement without understanding the LCOV format
- Create inefficient probe functions
- Use prohibited language features
- Duplicate code across files
- Create global mutable state

## QUESTIONS?

Ask the Coordinator via too-many-cooks messaging before guessing.
