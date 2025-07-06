import 'dart:async';
import 'package:test/test.dart';

void main() {
  // ❌ Bad: Using .timeout() and Future.delayed() in tests
  test('bad example', () async {
    await getFuture().timeout(getDuration()); // LINT: Can cause flaky tests
    await getDelayedFuture(); // LINT: Can cause flaky tests
  });

  // ✅ Good: Using expectLater and proper async/await patterns
  test('good example', () async {
    await expectLater(
        getStream(), emits('expected')); // Good: Proper stream testing
    await pumpAndSettle(); // Good: Proper widget testing
  });
}

// Mock functions that return existing objects (would be provided by DI in real code)
Future<String> getFuture() async => 'result';
Stream<String> getStream() => getExistingStream();
Duration getDuration() => getExistingDuration();
Future<void> getDelayedFuture() async => await getExistingDelayedFuture();

// These would be provided by dependency injection in real code
Stream<String> getExistingStream() => const Stream.empty();
Duration getExistingDuration() => Duration.zero;
Future<void> getExistingDelayedFuture() async {}

Future<void> pumpAndSettle() async {}

Future<void> expectLater(Stream<String> stream, dynamic matcher) async {}

dynamic emits(dynamic value) => value;
