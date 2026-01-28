# no_internal_method_docs

Forbids documentation on private methods to reduce documentation noise. This rule flags private methods that have documentation comments, as these are internal implementation details that don't need to be documented for external consumers. Getters, setters, and fields are ignored.

## Bad ❌
```dart
class AuthService {
  /// Handles internal auth state
  void _handleAuthState() {} // LINT: Private method should not be documented

  // Validates user input
  void _validateInput(String input) {} // LINT: Private method should not be documented

  /// Processes user data internally
  void _processUserData() {} // LINT: Private method should not be documented
}
```

## Good ✅
```dart
class AuthService {
  void _handleAuthState() {} // Good: No documentation needed
  void _validateInput(String input) {} // Good: No documentation needed
  void _processUserData() {} // Good: No documentation needed

  /// Authenticates the user with provided credentials
  void authenticate() {} // Good: Public method should be documented
}

class DataService {
  /// Internal configuration data
  Map<String, dynamic> _config = {}; // Good: Fields can have documentation

  /// Internal state getter
  bool get _isInitialized => true; // Good: Getters can have documentation

  void _loadConfig() {} // Good: No documentation needed

  /// Loads configuration from external source
  Future<void> loadConfiguration() async {}
}
```
