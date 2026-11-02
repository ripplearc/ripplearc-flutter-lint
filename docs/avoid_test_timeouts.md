# avoid_test_timeouts

Forbids fixed waits in tests to prevent flaky tests. A fixed wait can be too short on a slow CI machine, and it can pass before the code under test has run. Flags:

- `.timeout()`, `Future.delayed()` and `Future.microtask()` in `test`, `group`, `testWidgets`, and lifecycle methods (`setUp`, `tearDown`, `setUpAll`, `tearDownAll`).
- The `wait:` argument of `blocTest`, whatever its value.
- `pumpEventQueue()` anywhere in a test file, except inside `testWidgets`.

Only test files are checked. Inside `testWidgets` the clock is fake, so `tester.pump(Duration)`, `pumpAndSettle()` and `pumpEventQueue()` do not wait in real time and are not flagged.

## Bad ❌
```dart
test('example', () async {
  await future.timeout(Duration(seconds: 1));  // ERROR
  await Future.delayed(Duration(milliseconds: 10));  // ERROR
  await pumpEventQueue();  // ERROR
});

testWidgets('widget test', (tester) async {
  await Future.delayed(Duration(milliseconds: 100));  // ERROR
});

blocTest<SearchBloc, SearchState>(
  'debounces the query',
  build: () => SearchBloc(),
  act: (bloc) => bloc.add(QueryChanged('a')),
  wait: const Duration(milliseconds: 310),  // ERROR
  expect: () => [isA<SearchLoaded>()],
);
```

## Good ✅
```dart
test('example', () async {
  await expectLater(bloc.stream, emitsInOrder([isA<Loading>(), isA<Loaded>()]));
  await stream.firstWhere((state) => state is Loaded);
});

testWidgets('widget test', (tester) async {
  await tester.pump(const Duration(milliseconds: 400));  // Fake clock
  await tester.pumpAndSettle();
});

// For a debounce, make the debounce time a parameter.
blocTest<SearchBloc, SearchState>(
  'debounces the query',
  build: () => SearchBloc(debounce: Duration.zero),
  act: (bloc) => bloc.add(QueryChanged('a')),
  expect: () => [isA<SearchLoaded>()],
);
```
