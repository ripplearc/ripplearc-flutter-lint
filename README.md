# Custom Lint Library

A Dart/Flutter library providing custom lint rules for better code quality and testing practices.

## Rules

### prefer_fake_over_mock

Recommends using `Fake` instead of `Mock` for test doubles. Fakes provide more realistic behavior and are easier to maintain than mocks.

## Installation

Add this to your `pubspec.yaml`:

```yaml
dev_dependencies:
  custom_lint: ^0.7.4
  custom_lint_library:
    git: https://github.com/your-username/custom_lint_library.git
```

## Configuration

1. Add to your `analysis_options.yaml`:
```yaml
analyzer:
  plugins:
    - custom_lint
```

2. Create a `custom_lint.yaml` file:
```yaml
rules:
  - prefer_fake_over_mock

analyzer:
  plugins:
    - custom_lint_library
```

## Usage

The lint will automatically flag classes extending `Mock` and suggest using `Fake` instead.

### Bad ❌
```dart
class MockUserRepository extends Mock implements UserRepository {}
```

### Good ✅
```dart
class FakeUserRepository extends Fake implements UserRepository {
  @override
  Future<User> getUser(String id) async => User(id: id, name: 'Test User');
}
```

## Registering a Custom Lint Rule

To register a custom lint rule in your package, follow these steps:

1. **Create the Lint Rule**: Implement your lint rule by extending `DartLintRule` and defining the necessary methods. For example, the `NoOptionalOperatorsInTests` rule is implemented as follows:

   ```dart
   class NoOptionalOperatorsInTests extends DartLintRule {
     const NoOptionalOperatorsInTests() : super(code: _code);

     static const _code = LintCode(
       name: 'no_optional_operators_in_tests',
       problemMessage: 'Optional operators (?., ??) are not allowed in test blocks. Tests should fail explicitly at the point of failure.',
       correctionMessage: 'Remove the optional operator and add an explicit null check if needed.',
       errorSeverity: ErrorSeverity.WARNING,
     );

     @override
     void run(
       CustomLintResolver resolver,
       ErrorReporter reporter,
       CustomLintContext context,
     ) {
       context.registry.addCompilationUnit((node) {
         if (!_isTestFile(resolver.path)) return;
         _checkForOptionalOperators(node, reporter);
       });
     }
   }
   ```

2. **Write Unit Tests**: Create unit tests to verify that your rule works as expected. For example, the `NoOptionalOperatorsInTests` rule has tests for various scenarios. Refer to the test file for more details.

   ```dart
   void main() {
     group('NoOptionalOperatorsInTests', () {
       late NoOptionalOperatorsInTests rule;
       late TestErrorReporter reporter;

       setUp(() {
         rule = const NoOptionalOperatorsInTests();
         reporter = TestErrorReporter();
       });

       test('should flag optional chaining operator (?.)', () async {
         const source = '''
         void main() {
           test('example', () {
             final result = someObject?.someProperty;  // Should flag this
             expect(result, equals(expected));
           });
         }
         ''';
         await analyzeCode(source);
         expect(reporter.errors, hasLength(1));
         expect(reporter.errors.first.errorCode.name, equals('no_optional_operators_in_tests'));
       });
     });
   }
   ```

3. **Register and Export the Rule**: In your main library file (e.g., `lib/ripplearc_flutter_lint.dart`), import your rule and add it to the list of rules in your plugin class. For example:

   ```dart
   import 'package:custom_lint_builder/custom_lint_builder.dart';
   import 'rules/prefer_fake_over_mock_rule.dart';
   import 'src/rules/no_optional_operators_in_tests.dart';

   PluginBase createPlugin() => _RipplearcFlutterLint();

   class _RipplearcFlutterLint extends PluginBase {
     @override
     List<LintRule> getLintRules(CustomLintConfigs configs) => [
           const PreferFakeOverMockRule(),
           const NoOptionalOperatorsInTests(), // Add your rule here
         ];
   }
   ```

4. **Create an Example File**: Create an example file to demonstrate the rule in action. For example, `example/example_no_optional_operators_in_tests_rule.dart`:

   ```dart
   import 'package:test/test.dart';

   class Dummy {
     final int? someProperty;
     Dummy(this.someProperty);
   }

   void main() {
     const Dummy? someObject = null;
     const someValue = null;
     const defaultValue = 100;
     const expected = 42;
     const expectedValue = 100;

     test('should trigger no_optional_operators_in_tests', () {
       final result = someObject?.someProperty; // LINT: Using optional operator (?.)
       const value = someValue ?? defaultValue; // LINT: Using null-aware operator (??)
       expect(result, equals(expected));
       expect(value, equals(expectedValue));
     });
   }
   ```

5. **Configure the Linter**: Make sure your `analysis_options.yaml` and `custom_lint.yaml` files are set up to use the custom linter. For example:

   ```yaml
   # analysis_options.yaml
   analyzer:
     plugins:
       - custom_lint
   ```

   ```yaml
   # custom_lint.yaml
   rules:
     - no_optional_operators_in_tests
   ```

6. **Run the Linter**: Use `dart run custom_lint` to run the linter and verify that your rule is working as expected. For example:

   ```bash
   dart run custom_lint
   ```

   Example output:

   ```
   Analyzing...                           0.0s

     example/example_no_optional_operators_in_tests_rule.dart:17:19 • Optional operators (?., ??) are not allowed in test blocks. Tests should fail explicitly at the point of failure. • no_optional_operators_in_tests • WARNING

   1 issue found.
   ```

By following these steps, you can successfully register and use custom lint rules in your Dart/Flutter project. 