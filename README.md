# Custom Lint Library

A Dart/Flutter library providing custom lint rules for better code quality and testing practices.

## Project Structure

```
lib/
  rules/                    # All lint rules go here
    prefer_fake_over_mock_rule.dart
    no_optional_operators_in_tests.dart
    forbid_forced_unwrapping.dart
    no_direct_instantiation.dart
    document_fake_parameters.dart
    todo_with_story_links.dart
    no_internal_method_docs.dart
    document_interface.dart
test/
  rules/                    # All rule tests go here
    prefer_fake_over_mock_rule_test.dart
    no_optional_operators_in_tests_test.dart
    forbid_forced_unwrapping_test.dart
    no_direct_instantiation_test.dart
    document_fake_parameters_test.dart
    todo_with_story_links_test.dart
    no_internal_method_docs_test.dart
    document_interface_test.dart
example/                    # Example files demonstrating rules
  example_prefer_fake_over_mock_rule.dart
  example_no_optional_operators_in_tests_rule.dart
  example_forbid_forced_unwrapping_rule.dart
  example_no_direct_instantiation_rule.dart
  example_document_fake_parameters_rule.dart
  example_todo_with_story_links_rule.dart
  example_no_internal_method_docs_rule.dart
  example_document_interface_rule.dart
```

## Rules

### prefer_fake_over_mock

Recommends using `Fake` instead of `Mock` for test doubles. Fakes provide more realistic behavior and are easier to maintain than mocks.

#### Bad ❌
```dart
class MockUserRepository extends Mock implements UserRepository {}
```

#### Good ✅
```dart
class FakeUserRepository extends Fake implements UserRepository {
  @override
  Future<User> getUser(String id) async => User(id: id, name: 'Test User');
}
```

### forbid_forced_unwrapping

Forbids the use of forced unwrapping (`!`) in production code. This rule encourages the use of null-safe alternatives to prevent runtime null errors.

#### Bad ❌
```dart
final name = user.name!;  // Will crash if name is null
print('User: $name');
```

#### Good ✅
```dart
final name = user.name ?? 'Unknown';  // Safe with default value
print('User: $name');
```

### no_optional_operators_in_tests

Forbids the use of optional operators (`?.`, `??`) in test files. Tests should fail explicitly at the point of failure rather than silently handling null values. This rule is enforced as an error to ensure test reliability.

#### Bad ❌
```dart
test('example', () {
  final result = someObject?.someProperty;  // ERROR: Optional operators not allowed in tests
  expect(result, equals(expected));
});
```

#### Good ✅
```dart
test('example', () {
  final result = someObject.someProperty;  // Will fail explicitly if null
  expect(result, equals(expected));
});
```

### no_direct_instantiation

Enforces dependency injection by forbidding direct class instantiation. This rule flags direct instantiations of classes to ensure proper dependency injection is used, improving testability and maintainability. Classes that extend `Module`, have names ending with "Factory", or any instantiation that occurs inside a class that extends `Module` are excluded.

#### Bad ❌
```dart
// Bad: Direct instantiation of classes
class BadService {
  void doSomething() {
    final service = AuthService(); // LINT: Direct instantiation not allowed
    final wrapper = FakeSupabaseWrapper(); // LINT: Direct instantiation not allowed
  }
}
```

#### Good ✅
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

#### Excluded Classes/Contexts
- **Module classes**: Classes that extend `Module`
- **Factory classes**: Classes whose names end with "Factory" (e.g., `DatabaseFactory`, `HttpClientFactory`)
- **Inside Module**: Any direct instantiation inside a class that extends `Module`

### document_fake_parameters

Enforces documentation on Fake classes and their non-private members. This rule ensures that test helper methods and variables in Fake classes are properly documented for better test maintainability and team collaboration. Only applies to classes that extend `Fake` and implement interfaces.

#### Bad ❌
```dart
class FakeAuthService extends Fake implements AuthService {
  void setAuthDelay(Duration delay) {} // Missing documentation
  void triggerAuthFailure() {} // Missing documentation

  @override
  Future<void> authenticate() async {}
}

/// Fake implementation of UserRepository for testing.
class FakeUserRepository extends Fake implements UserRepository {
  void setUserData(User user) {} // Missing documentation
  void triggerNetworkError() {} // Missing documentation

  @override
  Future<User?> getUser(String id) async => null;
  
### todo_with_story_links

Ensures TODO comments include YouTrack story links for proper project management and technical debt tracking. This rule flags TODO comments that don't include a valid YouTrack URL, ensuring technical debt is properly linked to product backlog items.

#### Bad ❌
```dart
//TODO: Fix this later  // LINT: Missing YouTrack URL
// TODO: Refactor this method  // LINT: Missing YouTrack URL
//TODO: Add error handling  // LINT: Missing YouTrack URL
### no_internal_method_docs

Forbids documentation on private methods to reduce documentation noise. This rule flags private methods that have documentation comments, as these are internal implementation details that don't need to be documented for external consumers. Getters, setters, and fields are ignored.

#### Bad ❌
```dart
class AuthService {
  /// Handles internal auth state
  void _handleAuthState() {} // LINT: Private method should not be documented

  // Validates user input
  void _validateInput(String input) {} // LINT: Private method should not be documented

  /// Processes user data internally
  void _processUserData() {} // LINT: Private method should not be documented

### document_interface

Enforces documentation on abstract classes and their public methods. This rule ensures clear API contracts for modular architecture by requiring `///` documentation for both the class and its public methods. Private methods and concrete classes are ignored.

#### Bad ❌
```dart
abstract class SyncRepository {
  Future<void> syncData();  // Missing method documentation
  Future<void> clearData(); // Missing method documentation
}

/// Repository interface for data synchronization operations.
abstract class UserRepository {
  Future<String> getUser(String id);  // Missing method documentation
}

```

#### Good ✅
```dart

// Good: Using dependency injection
final authService = Modular.get<AuthService>();
final userService = Modular.get<UserService>();

// Good: Module instantiation - should not be flagged
final module = AppModule();

// Good: Factory class instantiation - should not be flagged
final databaseFactory = DatabaseFactory();
final httpClientFactory = HttpClientFactory();
final fileProcessorFactory = FileProcessorFactory();

// Good: Static factory method - should not be flagged
final staticFactory = AuthService.create();
```

#### Excluded Classes
- **Module classes**: Classes that extend `Module`
- **Factory classes**: Classes whose names end with "Factory" (e.g., `DatabaseFactory`, `HttpClientFactory`)

/// Fake implementation of AuthService for testing authentication scenarios.
class FakeAuthService extends Fake implements AuthService {
  /// Sets authentication delay for testing timing scenarios.
  /// Useful for testing timeout handling and loading states.
  void setAuthDelay(Duration delay) {}

  /// Simulates authentication failure for error handling tests.
  /// Triggers the same error conditions as the real service.
  void triggerAuthFailure() {}

  @override
  Future<void> authenticate() async {} // Override - no documentation needed
}

/// Fake implementation of UserRepository for testing.
class FakeUserRepository extends Fake implements UserRepository {
  /// Sets user data for testing scenarios.
  void setUserData(User user) {}

  void _validateUser(User user) {} // Private method - no documentation needed

  @override
  Future<User?> getUser(String id) async => null; // Override - no documentation needed
  
//TODO: https://ripplearc.youtrack.cloud/issue/CA-123
// TODO: https://ripplearc.youtrack.cloud/issue/UI-456
//TODO: https://ripplearc.youtrack.cloud/issue/BE-789 - Fix authentication timeout
```

#### Valid YouTrack URL Format
- **Domain**: `https://ripplearc.youtrack.cloud/issue/`
- **Project code**: Any uppercase letters (e.g., `CA`, `UI`, `BE`, `API`, `PERF`)
- **Issue number**: Any digits (e.g., `123`, `456`, `789`)

#### Excluded Files
- **Test files**: Files with `_test.dart` or in `/test/` directories are ignored
- **Regular comments**: Comments not starting with `TODO:` are ignored
- **Block comments**: `/* TODO: */` and `/** TODO: */` are ignored

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

/// Repository interface for data synchronization operations.
abstract class DataRepository {
  /// Synchronizes local data with remote Supabase instance.
  /// Returns true if synchronization was successful.
  Future<bool> syncData();

  /// Clears all local data from the repository.
  /// This operation cannot be undone.
  Future<void> clearData();

  /// Retrieves data by its unique identifier.
  /// Returns null if no data is found for the given id.
  Future<String?> getData(String id);
}

// Private methods are ignored (no documentation required)
/// Repository interface for data synchronization operations.
abstract class SecureRepository {
  /// Synchronizes local data with remote Supabase instance.
  Future<bool> syncData();

  Future<void> _validateData(); // Private method - no documentation needed
}
```


## Registering a Custom Lint Rule

To register a custom lint rule in your package, follow these steps:

1. **Create the Lint Rule**: Implement your lint rule by extending `DartLintRule` in `lib/rules/`. For example:

   ```dart
   class ForbidForcedUnwrapping extends DartLintRule {
     const ForbidForcedUnwrapping() : super(code: _code);

     static const _code = LintCode(
       name: 'forbid_forced_unwrapping',
       problemMessage: 'Forced unwrapping (!) is not allowed in production code.',
       correctionMessage: 'Use null-safe alternatives like null coalescing (??) or explicit null checks.',
       errorSeverity: ErrorSeverity.WARNING,
     );

     @override
     void run(
       CustomLintResolver resolver,
       ErrorReporter reporter,
       CustomLintContext context,
     ) {
       context.registry.addCompilationUnit((node) {
         if (_isTestFile(resolver.path)) return;
         _checkForForcedUnwrapping(node, reporter);
       });
     }
   }
   ```

2. **Write Unit Tests**: Create unit tests in `test/rules/` to verify your rule works as expected:

   ```dart
   void main() {
     group('ForbidForcedUnwrapping', () {
       late ForbidForcedUnwrapping rule;
       late TestErrorReporter reporter;

       setUp(() {
         rule = const ForbidForcedUnwrapping();
         reporter = TestErrorReporter();
       });

       test('should flag forced unwrapping in production code', () async {
         const source = '''
         void main() {
           final String? name = null;
           final value = name!;  // Should flag this
           print(value);
         }
         ''';
         await analyzeCode(source, path: 'lib/example.dart');
         expect(reporter.errors, hasLength(1));
         expect(reporter.errors.first.errorCode.name, equals('forbid_forced_unwrapping'));
       });
     });
   }
   ```

3. **Create an Example File**: Create an example in `example/` that demonstrates both the violation and correct usage:

   ```dart
   class User {
     final String? name;
     User({this.name});
   }

   void main() {
     final user = User(name: null);
     
     // Bad: Using forced unwrapping
     final name = user.name!;  // LINT
     print('User: $name');     // Will crash at runtime
     
     // Good: Using null-safe alternatives
     final safeName = user.name ?? 'Unknown';
     print('User: $safeName'); // Safe, will print "User: Unknown"
   }
   ```

4. **Register the Rule**: In `lib/ripplearc_flutter_lint.dart`, add your rule to the list:

   ```dart
   class _RipplearcFlutterLint extends PluginBase {
     @override
     List<LintRule> getLintRules(CustomLintConfigs configs) => [
           const ForbidForcedUnwrapping(),
           // ... other rules
         ];
   }
   ```

5. **Configure the Linter**: Copy the existing configuration from `example/custom_lint.yaml` to your project root:
   ```bash
   cp example/custom_lint.yaml custom_lint.yaml
   ```

6. **Run the Linter**: Use `dart run custom_lint` to verify your rule works as expected.

By following these steps, you can successfully register and use custom lint rules in your Dart/Flutter project.

## Configuration Files

### analysis_options.yaml
This file configures the Dart analyzer and enables the custom lint plugin. Place it in your project root:

```yaml
analyzer:
  plugins:
    - custom_lint  # Enables the custom_lint plugin
```

### custom_lint.yaml
This configuration file includes all our custom lint rules:
- `prefer_fake_over_mock` - Prefer using Fake over Mock for test doubles
- `forbid_forced_unwrapping` - Forbid forced unwrapping in production code
- `no_optional_operators_in_tests` - Forbid optional operators in test files
- `no_direct_instantiation` - Enforce dependency injection by forbidding direct class instantiation
- `document_fake_parameters` - Enforce documentation on Fake classes and their non-private members
- `todo_with_story_links` - Ensure TODO comments include YouTrack story links
- `no_internal_method_docs` - Forbid documentation on private methods to reduce noise
- `document_interface` - Enforce documentation on abstract classes and their public methods

#### Rule Configuration
- Each rule is listed under the `rules` section
- Rules are enabled by default when listed
- The order of rules doesn't matter
- All rules from the library are available to use

#### Plugin Configuration
- The `analyzer.plugins` section must include `custom_lint_library`
- This enables our custom lint rules to be loaded
- Multiple plugins can be listed if needed

By following these steps, you can successfully register and use custom lint rules in your Dart/Flutter project.

## Publishing & Updating the Package

To update and publish a new version to pub.dev:

1. **Add notes to the changelog**
   - Edit `CHANGELOG.md` and add a section for the new version, describing the changes and new rules.
2. **Run a dry run**
   - Execute `dart pub publish --dry-run` to check for issues or warnings before publishing.
3. **Fix any issues**
   - Address any errors or important warnings reported by the dry run (e.g., dependency constraints, missing files, linter errors).
4. **Publish**
   - Update the version in `pubspec.yaml`.
   - Run `dart pub publish` and follow the prompts to publish your package to pub.dev.

> **Note:** You cannot re-publish the same version. Always increment the version number for each release.

## Using the Latest Lint Rules in Your Project

To update your project to use the latest version of `ripplearc_flutter_lint` and enable new rules:

1. **Update your pubspec.yaml**
   - Change the version of `ripplearc_flutter_lint` to the latest version:
     ```yaml
     dependencies:
       ripplearc_flutter_lint: ^<latest_version>
     ```
   - Run `dart pub get` to fetch the updated package.

2. **Update your custom_lint.yaml**
   - Add or update the rules you want to enforce. For example:
     ```yaml
     rules:
       - prefer_fake_over_mock
       - forbid_forced_unwrapping
       - no_optional_operators_in_tests
       - no_direct_instantiation
       - document_fake_parameters
       - document_interface
       - todo_with_story_links
       - no_internal_method_docs
     ```
   - Only include the rules you want to enforce in your project.

> **Tip:** After updating, run your linter to ensure the new rules are active and working as expected. 