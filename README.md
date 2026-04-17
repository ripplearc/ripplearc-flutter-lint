# Custom Lint Library

A Dart/Flutter library providing custom lint rules for better code quality and testing practices.

## Project Structure

```
lib/
  core/                     # Core framework and base classes
    analyzers/              # All analyzer implementations
      base_analyzer.dart
      prefer_fake_over_mock_analyzer.dart
      no_optional_operators_in_tests_analyzer.dart
      ...more analyzers
    base_lint_rule.dart     # Base class for all lint rules
    models/
      lint_issue.dart       # Data model for lint issues
  custom_lint_rules/        # All lint rule implementations
    prefer_fake_over_mock_rule.dart
    no_optional_operators_in_tests.dart
    ...more rules
  ripplearc_linter.dart  # Main plugin entry point
  custom_lint_package.dart     # Package configuration
test/
  custom_lint_rules/        # All rule tests go here
    prefer_fake_over_mock_rule_test.dart
    no_optional_operators_in_tests_test.dart
    ...more tests
  utils/                    # Test utilities
    custom_lint_resolver.dart
    test_error_reporter.dart
example/                    # Example files demonstrating rules
  example_prefer_fake_over_mock_rule.dart
  example_no_optional_operators_in_tests_rule.dart
  ...more examples
```

## Registering a Custom Lint Rule

To register a custom lint rule in your package, follow these steps:

1. **Create the Analyzer**: Implement your analyzer by extending `BaseAnalyzer` in `lib/core/analyzers/`. For example:

   ```dart
   class ForcedUnwrappingAnalyzer extends BaseAnalyzer {
     @override
     String get ruleName => 'forbid_forced_unwrapping';

     @override
     String get problemMessage => 'Forced unwrapping (!) is not allowed in production code.';

     @override
     String get correctionMessage => 'Use null-safe alternatives like null coalescing (??) or explicit null checks.';

     @override
     List<LintIssue> analyze(CompilationUnit node) {
       final issues = <LintIssue>[];
       // Implement your analysis logic here
       return issues;
     }
   }
   ```

2. **Create the Lint Rule**: Implement your lint rule by extending `BaseLintRule` in `lib/custom_lint_rules/`. For example:

   ```dart
   import '../core/base_lint_rule.dart';
   import '../core/analyzers/forced_unwrapping_analyzer.dart';
   import '../core/analyzers/base_analyzer.dart';

   class ForbidForcedUnwrapping extends BaseLintRule {
     ForbidForcedUnwrapping() : super(BaseLintRule.createLintCode(_analyzer));

     static final _analyzer = ForcedUnwrappingAnalyzer();

     @override
     BaseAnalyzer get analyzer => _analyzer;
   }
   ```

3. **Write Unit Tests**: Create unit tests in `test/custom_lint_rules/` to verify your rule works as expected:

   ```dart
   void main() {
     group('ForbidForcedUnwrapping', () {
       late ForbidForcedUnwrapping rule;
       late TestErrorReporter reporter;

       setUp(() {
         rule = ForbidForcedUnwrapping();
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

4. **Create an Example File**: Create an example in `example/` that demonstrates both the violation and correct usage:

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

5. **Register the Rule**: In `lib/ripplearc_linter.dart`, add your rule to the list:

   ```dart
   class _RipplearcFlutterLint extends PluginBase {
     @override
     List<LintRule> getLintRules(CustomLintConfigs configs) => [
       ForbidForcedUnwrapping(),
       // ... other rules
     ];
   }
   ```

6. **Configure the Linter**: Copy the existing configuration from `example/custom_lint.yaml` to your project root:
   ```bash
   cp example/custom_lint.yaml custom_lint.yaml
   ```

7. **Run the Linter**: Use `dart run custom_lint` to verify your rule works as expected.

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
- `avoid_static_colors` - Enforce theme-based colors instead of static color usage
- `avoid_static_typography` - Enforce theme-based typography instead of static typography or raw TextStyle/GoogleFonts usage
- `prefer_fake_over_mock` - Prefer using Fake over Mock for test doubles
- `forbid_forced_unwrapping` - Forbid forced unwrapping in production code
- `forbid_modular_get_outside_module` - Forbid `Modular.get<T>()` outside `*_module.dart` files; enforce constructor injection
- `no_optional_operators_in_tests` - Forbid optional operators in test files
- `no_direct_instantiation` - Enforce dependency injection by forbidding direct class instantiation
- `document_fake_parameters` - Enforce documentation on Fake classes and their non-private members
- `todo_with_story_links` - Ensure TODO comments include YouTrack story links
- `no_internal_method_docs` - Forbid documentation on private methods to reduce noise
- `document_interface` - Enforce documentation on abstract classes and their public methods
- `prevent_feature_module_dependencies` - Enforce feature module independence by preventing features from depending on other features
- `prevent_library_module_dependencies` - Enforce library module independence by preventing libraries from depending on features

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

To update your project to use the latest version of `ripplearc_linter` and enable new rules:

1. **Update your pubspec.yaml**
   - Change the version of `ripplearc_linter` to the latest version:
     ```yaml
     dependencies:
       ripplearc_linter: ^<latest_version>
     ```
   - Run `dart pub get` to fetch the updated package.

2. **Update your custom_lint.yaml**
   - Add or update the rules you want to enforce. For example:
     ```yaml
     rules:
       - avoid_static_colors
       - prefer_fake_over_mock
       - forbid_forced_unwrapping
       - forbid_modular_get_outside_module
       - no_optional_operators_in_tests
       - no_direct_instantiation
       - document_fake_parameters
       - document_interface
       - todo_with_story_links
       - no_internal_method_docs
       - prevent_feature_module_dependencies
       - prevent_library_module_dependencies
     ```
   - Only include the rules you want to enforce in your project.

> **Tip:** After updating, run your linter to ensure the new rules are active and working as expected. 

## Testing Integration

To test the integration of this custom lint library in your project, you can point to a specific branch in your `pubspec.yaml`:

```yaml
dependencies:
  ripplearc_linter: 
    git:
      url: https://github.com/ripplearc/ripplearc-flutter-lint.git
      ref: chore/no-direct-instantiation-exception
```

This allows you to test changes from a specific branch before they are published to pub.dev. Replace `chore/no-direct-instantiation-exception` with the branch name you want to test.