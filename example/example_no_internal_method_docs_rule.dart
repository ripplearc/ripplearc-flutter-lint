class User {
  final String id;
  final String name;

  User({required this.id, required this.name});
}

// Bad: Private methods with documentation
class AuthService {
  /// Handles internal auth state
  void _handleAuthState() {} // LINT: Private method should not be documented

  // Validates user input
  void _validateInput(
      String input) {} // LINT: Private method should not be documented

  /// Processes user data internally
  void _processUserData() {} // LINT: Private method should not be documented

  /// Authenticates the user with provided credentials
  void authenticate() {} // Good: Public method should be documented
}

// Bad: Multiple private methods with different comment types
class UserService {
  /// Internal user validation
  void _validateUser(
      User user) {} // LINT: Private method should not be documented

  // Internal data processing
  void _processUserData() {} // LINT: Private method should not be documented

  /// Retrieves user from database
  User getUser(String id) {
    return User(id: id, name: 'Test User');
  } // Good: Public method should be documented
}

// Good: Private methods without documentation
class DataService {
  void _handleDataProcessing() {} // Good: No documentation needed
  void _validateData() {} // Good: No documentation needed
  void _cleanupResources() {} // Good: No documentation needed

  /// Processes data and returns result
  String processData(String input) {
    return 'processed';
  } // Good: Public method documented
}

// Good: Public methods with documentation, private methods without
class NetworkService {
  void _makeRequest() {} // Good: No documentation needed
  void _handleResponse() {} // Good: No documentation needed
  void _logError() {} // Good: No documentation needed

  /// Makes HTTP GET request to the specified URL
  Future<String> get(String url) async {
    return 'response';
  }

  /// Makes HTTP POST request with the provided data
  Future<String> post(String url, Map<String, dynamic> data) async {
    return 'response';
  }
}

// Good: Private fields and variables are ignored (no lint)
class ConfigService {
  /// Internal configuration data
  Map<String, dynamic> _config = {}; // Good: Fields can have documentation

  /// Internal cache
  final Map<String, String> _cache = {}; // Good: Fields can have documentation

  void _loadConfig() {} // Good: No documentation needed

  /// Loads configuration from external source
  Future<void> loadConfiguration() async {}
}

// Good: Private getters and setters are ignored (no lint)
class StateService {
  /// Internal state getter
  bool get _isInitialized => true; // Good: Getters can have documentation

  /// Internal state setter
  set _isInitialized(bool value) {} // Good: Setters can have documentation

  void _initialize() {} // Good: No documentation needed

  /// Initializes the service
  Future<void> initialize() async {}
}

// Good: /** */ comments are ignored (no lint)
class LogService {
  /** Handles internal logging */
  void _logMessage(String message) {} // Good: /** */ comments are allowed

  void _formatMessage() {} // Good: No documentation needed

  /// Logs a message with the specified level
  void log(String message, String level) {}
}

// Good: Empty documentation comments are ignored (no lint)
class CacheService {
  ///
  void _clearCache() {} // Good: Empty documentation is allowed

  //
  void _validateCache() {} // Good: Empty documentation is allowed

  /// Clears all cached data
  void clearCache() {}
}
