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

// Define the dataModel annotation
class DataModel {
  const DataModel();
}
const dataModel = DataModel();

// Example of a data model class that can be instantiated directly
@dataModel
class User {
  final int id;
  final String name;
  User({required this.id, required this.name});
}

void main() {
  // This is allowed because User is annotated with @dataModel
  final user = User(id: 1, name: 'Alice');
  print(user);
}

// Example: Instantiating a namespaced model (e.g., supabase.User) is allowed
class supabase {
  static UserProfile UserProfile({required int id}) => UserProfile._(id);
}

void exampleNamespacedModel() {
  // This is allowed and will not be flagged by the rule
  final user = supabase.User(id: 1);
  print(user);
}
