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
  List<int>? someList;

  test('should trigger no_optional_operators_in_tests', () {
    final result = someObject?.someProperty; // LINT
    const value = someValue ?? defaultValue; // LINT
    expect(result, equals(expected));
    expect(value, equals(expectedValue));
  });

  test('null-aware assignment triggers lint', () {
    String? name;
    name ??= 'default'; // LINT
  });

  test('null-aware index triggers lint', () {
    final item = someList?[0]; // LINT
  });

  testWidgets('testWidgets triggers lint', (tester) async {
    final result = someObject?.someProperty; // LINT
  });

  setUpAll(() {
    final result = someObject?.someProperty; // OK - excluded
  });

  tearDownAll(() {
    final result = someObject?.someProperty; // OK - excluded
  });
}
