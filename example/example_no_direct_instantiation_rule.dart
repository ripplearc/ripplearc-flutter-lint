// Bad: Direct instantiation of classes
class BadService {
  void doSomething() {
    final service = AuthService(); // LINT: Direct instantiation not allowed
    final wrapper =
        FakeSupabaseWrapper(); // LINT: Direct instantiation not allowed
  }
}

// Good: Using dependency injection
class GoodService {
  void doSomething() {
    final service = Modular.get<AuthService>(); // Good: Using DI
    final wrapper = Modular.get<FakeSupabaseWrapper>(); // Good: Using DI
  }
}

// Good: Factory classes can be instantiated directly
class FactoryExample {
  void createFactory() {
    final fileProcessorFactory = FileProcessorFactory(); // Good: Factory class
  }
}

// Good: Module classes can be instantiated directly
class ModuleExample {
  void createModule() {
    final module = AppModule(); // Good: Module class
  }
}

// Good: Instantiation inside Module class
class AppModule extends Module {
  AppModule() {
    final service = AuthService(); // ✅ Allowed: Inside Module class
    final wrapper = FakeSupabaseWrapper(); // ✅ Allowed: Inside Module class
  }
}

// Supporting classes
class Module {}

class AuthService {}

class FakeSupabaseWrapper {}

class FileProcessorFactory {}
