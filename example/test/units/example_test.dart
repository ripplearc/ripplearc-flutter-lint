import 'package:test/test.dart';

class TestData {
  final String? value;
  TestData(this.value);
}

void main() {
  group('Example Tests', () {
    test('should pass basic test', () {
      expect(1 + 1, equals(2));
    });

    test('should handle string operations', () {
      expect('Hello' + ' World', equals('Hello World'));
    });
    
    test('test with optional operator - should be flagged', () {
      final TestData? data = TestData('test');
      final result = data?.value;  // This should trigger lint if rule works
      expect(result, equals('test'));
    });
  });
}
