/// Coverage collection for Dart tests running on Node.js (dart2js)
library;

export 'src/instrumenter.dart' show instrumentSource;
export 'src/lcov.dart';
export 'src/parser.dart' show parseExecutableLines;
export 'src/runtime.dart'
    show cov, getCoverageJson, initCoverage, writeCoverageFile;
