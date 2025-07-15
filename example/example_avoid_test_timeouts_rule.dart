import 'dart:async';
import 'package:test/test.dart';

class ExampleAvoidTestTimeoutsRule extends Module {
  // ❌ Bad: Using .timeout() and Future.delayed() in tests
  Future<void> test() async {
    await getFuture().timeout(getDuration()); // LINT: Can cause flaky tests
    await getDelayedFuture(); // LINT: Can cause flaky tests
  }

  // ❌ Bad: Direct use of Future.delayed() in tests
  Future<void> test2() async {
    await Future.delayed(
        const Duration(seconds: 1)); // LINT: Can cause flaky tests
  }

  // ✅ Good: Using expectLater and proper async/await patterns
  Future<void> test3() async {
    await expectLater(
        getStream(), emits('expected')); // Good: Proper stream testing
    await pumpAndSettle(); // Good: Proper widget testing
  }

// Mock functions that return existing objects (would be provided by DI in real code)
  Future<String> getFuture() async => 'result';
  Stream<String> getStream() => getExistingStream();
  Duration getDuration() => getExistingDuration();
  Future<void> getDelayedFuture() async => await getExistingDelayedFuture();

  // These would be provided by dependency injection in real code
  Stream<String> getExistingStream() => StreamModule().createStream();
  Duration getExistingDuration() => Duration.zero;
  Future<void> getExistingDelayedFuture() async {}

  Future<void> pumpAndSettle() async {}

  Future<void> expectLater(Stream<String> stream, dynamic matcher) async {}

  dynamic emits(dynamic value) => value;
}

class StreamModule extends Module {
  Stream<String> createStream() {
    Stream<String> stream = const Stream.empty();
    return stream;
  }
}

/// Dummy base class to satisfy `no_direct_instantiation` rule
abstract class Module {}
