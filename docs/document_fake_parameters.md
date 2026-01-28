# document_fake_parameters

Enforces documentation on Fake classes and their non-private members. This rule ensures that test helper methods and variables in Fake classes are properly documented for better test maintainability and team collaboration. Only applies to classes that extend `Fake` and implement interfaces.

## Bad ❌
```dart
class FakeAuthService extends Fake implements AuthService {
  void setAuthDelay(Duration delay) {} // Missing documentation
  void triggerAuthFailure() {} // Missing documentation

  @override
  Future<void> authenticate() async {}
}

/// Fake implementation of UserRepository for testing.
class FakeUserRepository extends Fake implements UserRepository {
  void setUserData(User user) {} // Missing documentation
  void triggerNetworkError() {} // Missing documentation

  @override
  Future<User?> getUser(String id) async => null;
```

## Good ✅
```dart
/// Fake implementation of AuthService for testing authentication scenarios.
class FakeAuthService extends Fake implements AuthService {
  /// Sets authentication delay for testing timing scenarios.
  /// Useful for testing timeout handling and loading states.
  void setAuthDelay(Duration delay) {}

  /// Simulates authentication failure for error handling tests.
  /// Triggers the same error conditions as the real service.
  void triggerAuthFailure() {}

  @override
  Future<void> authenticate() async {} // Override - no documentation needed
}

/// Fake implementation of UserRepository for testing.
class FakeUserRepository extends Fake implements UserRepository {
  /// Sets user data for testing scenarios.
  void setUserData(User user) {}

  void _validateUser(User user) {} // Private method - no documentation needed

  @override
  Future<User?> getUser(String id) async => null; // Override - no documentation needed
}
```
