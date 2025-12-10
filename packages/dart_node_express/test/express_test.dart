/// Express package tests - factory tests and type tests.
/// Actual Express server requires Node.js runtime.
import 'package:dart_node_express/dart_node_express.dart';
import 'package:test/test.dart';

void main() {
  group('express factory', () {
    test('express function exists', () {
      expect(express, isA<Function>());
    });

    test('handler function exists', () {
      expect(handler, isA<Function>());
    });
  });

  group('middleware', () {
    test('middleware function exists', () {
      expect(middleware, isA<Function>());
    });

    test('chain function exists', () {
      expect(chain, isA<Function>());
    });
  });

  group('types', () {
    test('RequestHandler typedef accepts correct signature', () {
      // Verify the type signature compiles
      RequestHandler? testHandler;
      expect(testHandler, isNull);
    });

    test('MiddlewareHandler typedef accepts correct signature', () {
      // Verify the type signature compiles
      MiddlewareHandler? testHandler;
      expect(testHandler, isNull);
    });

    test('NextFunction typedef accepts correct signature', () {
      // Verify the type signature compiles
      NextFunction? testFn;
      expect(testFn, isNull);
    });
  });

  group('Router', () {
    test('Router factory exists', () {
      // Router() factory requires Node.js runtime
      // Just verify the type exists
      expect(Router, isNotNull);
    });
  });

  group('ExpressApp extension type', () {
    test('ExpressApp type exists', () {
      // ExpressApp requires Node.js runtime
      // Just verify the type compiles
      ExpressApp? app;
      expect(app, isNull);
    });
  });

  group('Request extension type', () {
    test('Request type exists', () {
      Request? req;
      expect(req, isNull);
    });
  });

  group('Response extension type', () {
    test('Response type exists', () {
      Response? res;
      expect(res, isNull);
    });
  });
}
