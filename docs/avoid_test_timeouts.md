# avoid_test_timeouts

Forbids using `.timeout()` and `Future.delayed()` in test blocks to prevent flaky tests. These patterns can cause non-deterministic test failures. Applies to `test`, `group`, `testWidgets`, and lifecycle methods (`setUp`, `tearDown`, `setUpAll`, `tearDownAll`).

## Bad ❌
```dart
test('example', () async {
  await future.timeout(Duration(seconds: 1));  // ERROR
  await Future.delayed(Duration(milliseconds: 10));  // ERROR
});

testWidgets('widget test', (tester) async {
  await Future.delayed(Duration(milliseconds: 100));  // ERROR
});
```

## Good ✅
```dart
test('example', () async {
  await expectLater(stream, emits(expectedValue));
});

testWidgets('widget test', (tester) async {
  await tester.pumpAndSettle();  // Proper widget testing
});
```
