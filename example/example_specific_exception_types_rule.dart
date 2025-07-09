class ExceptionModule extends Module {
  // ❌ Bad: Throwing generic Exception
  void bad() {
    throw Exception('This should trigger the specific_exception_types rule');
  }

  // ✅ Good: Throwing a specific exception type
  void good() {
    throw ConfigurationException('Specific error');
  }
}

class ConfigurationException implements Exception {
  final String message;
  ConfigurationException(this.message);

  @override
  String toString() => 'ConfigurationException: $message';
}

/// Dummy base class to satisfy `no_direct_instantiation` rule
abstract class Module {}
