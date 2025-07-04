// ❌ Bad: Throwing generic Exception
void bad() {
  throw Exception(
      'SUPABASE_URL required'); // LINT: Use a specific exception type
}

// ✅ Good: Throwing a specific exception type
void good() {
  throw ConfigurationException('SUPABASE_URL required');
}

class ConfigurationException implements Exception {
  final String message;
  ConfigurationException(this.message);
  @override
  String toString() => 'ConfigurationException: $message';
}
