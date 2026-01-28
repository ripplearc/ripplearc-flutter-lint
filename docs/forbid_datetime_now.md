# forbid_datetime_now

Forbids the use of `DateTime.now()` in production code. This rule enforces the use of the custom `Clock` interface from `libraries/time/interfaces/clock.dart` instead, enabling deterministic testing and time mocking in widget and unit tests.

**Exception**: `DateTime.now()` is allowed in `system_clock_impl.dart` where the Clock implementation is defined.

## Bad ❌
```dart
class TimeService {
  DateTime getCurrentTime() {
    return DateTime.now();  // LINT
  }

  bool isExpired(DateTime expirationDate) {
    return DateTime.now().isAfter(expirationDate);  // LINT
  }
}
```

## Good ✅
```dart
import 'libraries/time/interfaces/clock.dart';

class TimeService {
  final Clock clock;
  TimeService({required this.clock});

  DateTime getCurrentTime() {
    return clock.now();  // OK - testable
  }

  bool isExpired(DateTime expirationDate) {
    return clock.now().isAfter(expirationDate);  // OK - testable
  }
}

// Good: DateTime.now() is allowed in system_clock_impl.dart
class SystemClock implements Clock {
  @override
  DateTime now() {
    return DateTime.now();  // OK - allowed in system_clock_impl.dart
  }
}
```
