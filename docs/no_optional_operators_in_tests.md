# no_optional_operators_in_tests

Forbids the use of optional operators (`?.`, `??`, `??=`, `?[]`) in test files. Tests should fail explicitly at the point of failure rather than silently handling null values. This rule is enforced as an error to ensure test reliability.

## Bad ❌
```dart
test('example', () {
  final result = someObject?.someProperty;  // ERROR
  final value = someValue ?? defaultValue;  // ERROR
  someValue ??= defaultValue;  // ERROR
  final item = someList?[0];  // ERROR
});
```

## Good ✅
```dart
test('example', () {
  final result = someObject.someProperty;  // Will fail explicitly if null
  expect(result, equals(expected));
});
```
