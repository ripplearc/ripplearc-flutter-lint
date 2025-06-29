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
test/
  rules/                    # All rule tests go here
    prefer_fake_over_mock_rule_test.dart
    no_optional_operators_in_tests_test.dart
    forbid_forced_unwrapping_test.dart
    no_direct_instantiation_test.dart
example/                    # Example files demonstrating rules
  example_prefer_fake_over_mock_rule.dart
  example_no_optional_operators_in_tests_rule.dart
  example_forbid_forced_unwrapping_rule.dart
  example_no_direct_instantiation_rule.dart
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

Enforces dependency injection by forbidding direct class instantiation. This rule flags direct instantiations of classes to ensure proper dependency injection is used, improving testability and maintainability. Classes that extend `Module` or have factory constructors are excluded.

#### Bad ❌
```dart
// Bad: Direct instantiation - will be flagged
final syncService = SyncService(); // LINT: Direct instantiation not allowed

// Bad: Direct instantiation with parameters - will be flagged
final notificationService = NotificationService('token'); // LINT: Direct instantiation not allowed

// Bad: Using new keyword - will be flagged
final anotherService = new SyncService(); // LINT: Direct instantiation not allowed
```

#### Good ✅
```dart
// Good: Using dependency injection
final authService = Modular.get<AuthService>();
final userService = Modular.get<UserService>();

// Good: Module instantiation - should not be flagged
final module = AppModule();

// Good: Factory class instantiation - should not be flagged
final factoryService = AuthService();
final factoryServiceWithParams = UserService('api-key');

// Good: Static factory method - should not be flagged
final staticFactory = AuthService.create();
```

#### Excluded Classes
- **Module classes**: Classes that extend `Module`
- **Factory classes**: Classes with factory constructors
- **Static factory methods**: Classes with static factory methods

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