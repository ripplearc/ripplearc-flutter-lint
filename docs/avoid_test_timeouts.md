# avoid_test_timeouts

Forbids fixed waits in tests to prevent flaky tests. A fixed wait can be too short on a slow CI machine, and it can pass before the code under test has run. Flags:

- `.timeout()`, `Future.delayed()` and `Future.microtask()` in `test`, `group`, `testWidgets`, and lifecycle methods (`setUp`, `tearDown`, `setUpAll`, `tearDownAll`), except inside `fakeAsync`.
- The `wait:` argument of `blocTest`, whatever its value.
- `pumpEventQueue()` anywhere in a test file, except inside `testWidgets` and `fakeAsync`.

Only test files are checked. These are not flagged:

- `tester.pump(Duration)` and `pumpAndSettle()`. Widget tests run on a fake clock, so they do not wait in real time.
- `.timeout()`, `Future.delayed()`, `Future.microtask()` and `pumpEventQueue()` inside `fakeAsync((async) {...})`. Their timers and microtasks only run when the test calls `async.elapse`, `async.flushTimers` or `async.flushMicrotasks`, so they do not wait in real time either.
- `pumpEventQueue()` inside `testWidgets`, for a different reason: a bare call there never finishes, because its timer only fires when the test pumps. The test times out, so it cannot pass by luck. Use `tester.pump()` there instead.

## When there is no event to wait on

To check that something has **not** happened yet, run the test in `fakeAsync` and call `async.elapse(Duration.zero)` before the check. It runs every pending microtask and zero-length timer, and no real time passes. Hold the step that must stay open with a `Completer` in the fake, check, then complete it, call `async.elapse(Duration.zero)` again, and check the result.

## Known limits

- `pumpEventQueue()` inside `tester.runAsync(...)` is a real wait, and it is not flagged.
- Only the `fakeAsync(...)` function is treated as a fake clock. `FakeAsync().run(...)` is not.
- The rule matches by name, not by resolved type. A `pumpEventQueue()` in a top-level helper that only `testWidgets` calls is flagged, and a custom widget-test wrapper is not treated as `testWidgets`.

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

test('holds the write until it is released', () {
  fakeAsync((async) {
    final release = Completer<void>();
    repository.acceptanceCompleter = release;
    var settled = false;
    repository.recordAcceptance().then((_) => settled = true);

    async.elapse(Duration.zero);
    expect(settled, isFalse);  // Nothing happened yet

    release.complete();
    async.elapse(Duration.zero);
    expect(settled, isTrue);
  });
});

// For a debounce, make the debounce time a parameter.
blocTest<SearchBloc, SearchState>(
  'debounces the query',
  build: () => SearchBloc(debounce: Duration.zero),
  act: (bloc) => bloc.add(QueryChanged('a')),
  expect: () => [isA<SearchLoaded>()],
);
```
