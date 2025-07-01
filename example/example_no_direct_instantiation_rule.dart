// Example for the no_direct_instantiation rule
// This rule enforces dependency injection for better testability of auth/sync components.

// ✅ Allowed: Class ending with 'Factory'
class FileProcessorFactory {}

// ✅ Allowed: Module base class and class extending Module
class Module {}

class AppModule extends Module {}

// ❌ Not allowed: Regular class
class AuthService {}

// Mock DI container for demonstration
class Modular {
  static T get<T>() => throw UnimplementedError();
}

void main() {
  // ✅ Allowed: Using dependency injection
  final authService = Modular.get<AuthService>();
  final factory = FileProcessorFactory();
  final module = AppModule();

  // ❌ Not allowed: Direct instantiation (should be flagged)
  final badAuthService =
      AuthService(); // LINT: Direct instantiation not allowed

  // ✅ Allowed: Instantiating a Factory class
  final goodFactory = FileProcessorFactory();

  // ✅ Allowed: Instantiating a Module class
  final goodModule = AppModule();
}
