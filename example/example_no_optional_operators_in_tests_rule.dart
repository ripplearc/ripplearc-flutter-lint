import 'package:test/test.dart';

class Dummy {
  final int? someProperty;
  Dummy(this.someProperty);
}

void main() {
  const Dummy? someObject = null;
  const someValue = null;
  const defaultValue = 100;
  const expected = 42;
  const expectedValue = 100;

  test('should trigger no_optional_operators_in_tests', () {
    final result = someObject?.someProperty; // LINT
    const value = someValue ?? defaultValue; // LINT
    expect(result, equals(expected));
    expect(value, equals(expectedValue));
  });
} 