// Bad: TODO comments without YouTrack URLs
class AuthService {
  //TODO: Fix this later  // LINT: Missing YouTrack URL
  void authenticate() {}

  // TODO: Refactor this method  // LINT: Missing YouTrack URL
  void logout() {}

  //TODO: Add error handling  // LINT: Missing YouTrack URL
  void handleError() {}
}

// Bad: TODO comments with invalid URLs
class UserService {
  //TODO: https://github.com/ripplearc/issues/123  // LINT: Not a YouTrack URL
  void getUser() {}

  // TODO: https://ripplearc.youtrack.cloud/issue/123  // LINT: Invalid format (missing project code)
  void updateUser() {}

  //TODO: https://jira.company.com/browse/PROJ-123  // LINT: Not a YouTrack URL
  void deleteUser() {}
}

// Good: TODO comments with valid YouTrack URLs
class DataService {
  //TODO: https://ripplearc.youtrack.cloud/issue/CA-123
  void processData() {}

  // TODO: https://ripplearc.youtrack.cloud/issue/UI-456
  void validateData() {}

  //TODO: https://ripplearc.youtrack.cloud/issue/BE-789
  void saveData() {}
}

// Good: TODO comments with valid YouTrack URLs and additional text
class NetworkService {
  //TODO: https://ripplearc.youtrack.cloud/issue/CA-123 - Fix authentication timeout
  void authenticate() {}

  // TODO: https://ripplearc.youtrack.cloud/issue/UI-456 - Improve error handling
  void handleResponse() {}

  //TODO: https://ripplearc.youtrack.cloud/issue/BE-789 - Add retry logic
  void makeRequest() {}
}

// Good: Regular comments (not TODO) are ignored
class ConfigService {
  // This is a regular comment
  void loadConfig() {}

  // Another regular comment
  void saveConfig() {}

  // TODO: https://ripplearc.youtrack.cloud/issue/CA-123 - This is valid
  void validateConfig() {}
}

// Good: Block comments are ignored (not single-line TODO)
class LogService {
  /* TODO: Fix this later */ // Good: Block comments are ignored
  void logMessage() {}

  /** TODO: Add more logging */ // Good: Documentation comments are ignored
  void logError() {}

  // TODO: https://ripplearc.youtrack.cloud/issue/CA-123 - This is valid
  void logInfo() {}
}

// Good: Different project codes are valid
class AnalyticsService {
  //TODO: https://ripplearc.youtrack.cloud/issue/AN-123
  void trackEvent() {}

  // TODO: https://ripplearc.youtrack.cloud/issue/API-456
  void sendData() {}

  //TODO: https://ripplearc.youtrack.cloud/issue/PERF-789
  void optimizePerformance() {}
}

// Good: Mixed valid and invalid TODO comments
class MixedService {
  //TODO: Fix this later  // LINT: Missing YouTrack URL

  // TODO: https://ripplearc.youtrack.cloud/issue/CA-123 - This is valid
  void validMethod() {}

  //TODO: https://github.com/issues/123  // LINT: Not a YouTrack URL

  // TODO: https://ripplearc.youtrack.cloud/issue/UI-456 - Another valid one
  void anotherValidMethod() {}
}
