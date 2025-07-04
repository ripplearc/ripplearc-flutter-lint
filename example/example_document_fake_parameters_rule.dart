// Note: This example assumes you have a Fake class available
// In a real project, you would import the appropriate fake library
// For example: import 'package:mockito/mockito.dart';

class User {
  final String id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});
}

// Mock Fake class for demonstration purposes
class Fake {
  // This is just for the example - in real code you'd use a proper fake library
}

/// Service interface for handling authentication operations.
/// Provides methods for user authentication, logout and checking authentication status.
abstract class AuthService {
  /// Authenticates the user with the service.
  /// Should be called before accessing protected resources.
  Future<void> authenticate();

  /// Logs out the currently authenticated user.
  /// Clears any stored authentication tokens or session data.
  Future<void> logout();

  /// Checks if there is a currently authenticated user.
  /// Returns true if a user is authenticated, false otherwise.
  Future<bool> isAuthenticated();
}

/// Repository interface for managing user data operations.
/// Handles storing and retrieving user information.
abstract class UserRepository {
  /// Retrieves a user by their unique identifier.
  /// Returns null if no user is found with the given id.
  Future<User?> getUser(String id);

  /// Saves or updates a user's information in the repository.
  /// Creates a new user entry if the user doesn't exist.
  Future<void> saveUser(User user);
}

// Bad: Fake class without documentation
class FakeAuthService implements AuthService {
  void setAuthDelay(Duration delay) {}
  void triggerAuthFailure() {}

  @override
  Future<void> authenticate() async {}

  @override
  Future<void> logout() async {}

  @override
  Future<bool> isAuthenticated() async => true;
}

// Bad: Fake class with only class documentation
/// Fake implementation of UserRepository for testing.
class FakeUserRepository implements UserRepository {
  void setUserData(User user) {} // LINT: Missing documentation
  void triggerNetworkError() {} // LINT: Missing documentation

  @override
  Future<User?> getUser(String id) async => null;

  @override
  Future<void> saveUser(User user) async {}
}

// Good: Fake class with proper documentation
/// Fake implementation of AuthService for testing authentication scenarios.
class FakeAuthServiceWithDocs implements AuthService {
  /// Sets authentication delay for testing timing scenarios.
  /// Useful for testing timeout handling and loading states.
  void setAuthDelay(Duration delay) {}

  /// Simulates authentication failure for error handling tests.
  /// Triggers the same error conditions as the real service.
  void triggerAuthFailure() {}

  /// Simulates network connectivity issues.
  /// Useful for testing offline scenarios.
  void simulateNetworkError() {}

  @override
  Future<void> authenticate() async {} // Override - no documentation needed

  @override
  Future<void> logout() async {} // Override - no documentation needed

  @override
  Future<bool> isAuthenticated() async =>
      true; // Override - no documentation needed
}

// Good: Private methods are ignored (no documentation required)
/// Fake implementation of UserRepository for testing.
class FakeUserRepositoryWithPrivate implements UserRepository {
  /// Sets user data for testing scenarios.
  void setUserData(User user) {}

  void _validateUser(User user) {} // Private method - no documentation needed
  void _logUserAction(
      String action) {} // Private method - no documentation needed

  @override
  Future<User?> getUser(String id) async => null;

  @override
  Future<void> saveUser(User user) async {}
}

// Good: Getters and setters are ignored (no documentation required)
/// Fake implementation of AuthService for testing.
class FakeAuthServiceWithGetters implements AuthService {
  /// Sets authentication delay for testing timing scenarios.
  void setAuthDelay(Duration delay) {}

  bool get authStatus => true; // Getter - no documentation needed
  set authStatus(bool value) {} // Setter - no documentation needed

  @override
  Future<void> authenticate() async {}

  @override
  Future<void> logout() async {}

  @override
  Future<bool> isAuthenticated() async => true;
}

// Good: Classes that extend Fake but don't implement interfaces are ignored
class FakeHelper {
  void setAuthDelay(
      Duration delay) {} // No interface - no documentation required
  void triggerAuthFailure() {} // No interface - no documentation required
}

// Good: Classes that implement interfaces but don't extend Fake are ignored
class MockAuthService implements AuthService {
  void setAuthDelay(Duration delay) {} // Not Fake - no documentation required
  void triggerAuthFailure() {} // Not Fake - no documentation required

  @override
  Future<void> authenticate() async {}

  @override
  Future<void> logout() async {}

  @override
  Future<bool> isAuthenticated() async => true;
}
