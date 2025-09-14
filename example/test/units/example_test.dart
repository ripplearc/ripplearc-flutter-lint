import 'package:test/test.dart';

void main() {
  group('Example Tests', () {
    test('should pass basic test', () {
      expect(1 + 1, equals(2));
    });

    test('should handle string operations', () {
      expect('Hello' + ' World', equals('Hello World'));
    });
  });
}
