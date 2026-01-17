// ignore_for_file: unused_local_variable

class BadTimeService {
  // Bad: Using DateTime.now() directly - not testable
  DateTime getCurrentTime() {
    return DateTime.now(); // LINT
  }

  // Bad: DateTime.now() in expressions
  int getTimestamp() {
    return DateTime.now().millisecondsSinceEpoch; // LINT
  }

  // Bad: DateTime.now() in comparisons
  bool isExpired(DateTime expirationDate) {
    return DateTime.now().isAfter(expirationDate); // LINT
  }
}

// Good: Using Clock from libraries/time/interfaces/clock.dart
/// An abstraction for getting the current time.
abstract class Clock {
  /// Returns the current date and time.
  DateTime now();
}

class GoodTimeService {
  final Clock clock;

  GoodTimeService({required this.clock});

  // Good: Using injected Clock - testable!
  DateTime getCurrentTime() {
    return clock.now(); // OK - testable
  }

  // Good: Clock in expressions
  int getTimestamp() {
    return clock.now().millisecondsSinceEpoch; // OK - testable
  }

  // Good: Clock in comparisons
  bool isExpired(DateTime expirationDate) {
    return clock.now().isAfter(expirationDate); // OK - testable
  }
}

void main() {
  // Bad: Using DateTime.now() directly
  final now = DateTime.now(); // LINT
  final timestamp = DateTime.now().millisecondsSinceEpoch; // LINT

  // Good: Using other DateTime constructors (not flagged)
  final specificDate = DateTime(2024, 1, 15);
  final parsed = DateTime.parse('2024-01-15');
  final fromEpoch = DateTime.fromMillisecondsSinceEpoch(1705320000000);
}
