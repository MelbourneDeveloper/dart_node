import 'package:dart_node_statecore/dart_node_statecore.dart';
import 'package:test/test.dart';

void main() {
  group('compose', () {
    test('composes functions right to left', () {
      int add1(int x) => x + 1;
      int multiply2(int x) => x * 2;
      int subtract3(int x) => x - 3;

      final composed = compose([subtract3, multiply2, add1]);
      // (5 + 1) * 2 - 3 = 9
      expect(composed(5), equals(9));
    });

    test('returns identity for empty list', () {
      final composed = compose<int>([]);
      expect(composed(42), equals(42));
    });

    test('returns single function for single element', () {
      int add1(int x) => x + 1;
      final composed = compose([add1]);
      expect(composed(5), equals(6));
    });

    test('works with string transformations', () {
      String toUpper(String s) => s.toUpperCase();
      String addExclaim(String s) => '$s!';
      String wrap(String s) => '[$s]';

      final composed = compose([wrap, addExclaim, toUpper]);
      expect(composed('hello'), equals('[HELLO!]'));
    });
  });

  group('pipe2', () {
    test('pipes two functions left to right', () {
      String toString(int x) => x.toString();
      String addExclaim(String s) => '$s!';

      final piped = pipe2(toString, addExclaim);
      expect(piped(42), equals('42!'));
    });
  });

  group('pipe3', () {
    test('pipes three functions', () {
      String toString(int x) => x.toString();
      String addExclaim(String s) => '$s!';
      int getLength(String s) => s.length;

      final piped = pipe3(toString, addExclaim, getLength);
      expect(piped(42), equals(3)); // "42!".length = 3
    });
  });

  group('pipe4', () {
    test('pipes four functions', () {
      int add1(int x) => x + 1;
      int multiply2(int x) => x * 2;
      int subtract3(int x) => x - 3;
      String toString(int x) => x.toString();

      final piped = pipe4(add1, multiply2, subtract3, toString);
      // ((5 + 1) * 2) - 3 = 9
      expect(piped(5), equals('9'));
    });
  });

  group('pipe5', () {
    test('pipes five functions', () {
      int add1(int x) => x + 1;
      int multiply2(int x) => x * 2;
      int subtract3(int x) => x - 3;
      int divide2(int x) => x ~/ 2;
      String toString(int x) => x.toString();

      final piped = pipe5(add1, multiply2, subtract3, divide2, toString);
      // (((5 + 1) * 2) - 3) ~/ 2 = 9 ~/ 2 = 4
      expect(piped(5), equals('4'));
    });
  });
}
