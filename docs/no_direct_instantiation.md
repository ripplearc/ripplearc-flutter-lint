# no_direct_instantiation

Enforces dependency injection by forbidding direct class instantiation. This rule flags direct instantiations of classes to ensure proper dependency injection is used, improving testability and maintainability. Classes that extend `Module`, have names ending with "Factory", or any instantiation that occurs inside a class that extends `Module` are excluded.

## Bad ❌
```dart
// Bad: Direct instantiation of classes
class BadService {
  void doSomething() {
    final service = AuthService(); // LINT: Direct instantiation not allowed
    final wrapper = FakeSupabaseWrapper(); // LINT: Direct instantiation not allowed
  }
}
```

## Good ✅
```dart
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
    final factory = FileProcessorFactory(); // Good: Factory class
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
```

## Excluded Classes/Contexts
- **Module classes**: Classes that extend `Module`
- **Factory classes**: Classes whose names end with "Factory" (e.g., `DatabaseFactory`, `HttpClientFactory`)
- **Inside Module**: Any direct instantiation inside a class that extends `Module`

## Configuration: Allowing Classes and Packages

You can configure allowed classes and packages in your `analysis_options.yaml` file to allow direct instantiation:

```yaml
custom_lint:
  no_direct_instantiation:
    allowed_package_prefixes:
      - 'package:your_package/'
    ignored_base_classes:
      - 'YourCustomBaseClass'
    safe_value_objects:
      - 'YourValueObject'
    ast_type_suffixes:
      - 'Builder'
    file_path_patterns:
      - '.*/generated/.*'
```

**Example: Allowing Equatable classes**

Classes extending `Equatable` (like BLoC states/events) are allowed by default. You can add more base classes:

```yaml
custom_lint:
  no_direct_instantiation:
    ignored_base_classes:
      - 'Equatable'  # Already in defaults, allows BLoC states/events
```

```dart
// ✅ Good: Allowed because UserState extends Equatable
class UserState extends Equatable {
  final String name;
  UserState(this.name);
  
  @override
  List<Object> get props => [name];
}

void someMethod() {
  final state = UserState('John'); // ✅ Allowed
}
```

**Example: Allowing Dart core packages**

Dart core packages are allowed by default. You can add more packages:

```yaml
custom_lint:
  no_direct_instantiation:
    allowed_package_prefixes:
      - 'dart:'  # Already in defaults, allows core Dart classes
      - 'package:flutter/'  # Already in defaults
      - 'package:your_utils/'  # Add your custom package
```

```dart
import 'dart:io';
import 'dart:convert';

void someMethod() {
  final file = File('path.txt'); // ✅ Allowed (dart:io)
  final encoder = JsonEncoder(); // ✅ Allowed (dart:convert)
}
```

**Note:** Configuration options merge with defaults, so you only need to specify additional allowed classes or packages. The rule will use both your custom configuration and the built-in defaults.
