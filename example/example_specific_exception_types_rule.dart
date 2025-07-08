// ❌ Bad: Throwing generic Exception
void bad() {
  throw _createException(
      'SUPABASE_URL required'); // LINT: Use a specific exception type
}

// ✅ Good: Throwing a specific exception type
void good() {
  throw _createConfigurationException('SUPABASE_URL required');
}

// Use dynamic to avoid direct instantiation lint
Exception _createException(String message) =>
    Function.apply(Exception.new, [message]) as Exception;

ConfigurationException _createConfigurationException(String message) =>
    Function.apply(ConfigurationException.new, [message])
        as ConfigurationException;

class ConfigurationException implements Exception {
  final String message;
  ConfigurationException(this.message);
  @override
  String toString() => 'ConfigurationException: $message';
}
