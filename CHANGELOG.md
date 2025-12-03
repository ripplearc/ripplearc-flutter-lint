# Changelog

## 0.1.4 - NoOptionalOperatorsInTests Analyzer Improvements

### Bug Fixes

- **Fixed nested test/group state tracking**: The analyzer now correctly tracks nested `test`, `group`, and `testWidgets` blocks using depth counters instead of boolean flags. Previously, optional operators after nested blocks were not detected.

### New Features

- **Added `??=` operator detection**: The null-aware assignment operator is now flagged in test blocks.
- **Added `?[]` operator detection**: The null-aware index operator is now flagged in test blocks.
- **Added `testWidgets` support**: Flutter widget tests using `testWidgets` are now recognized as test blocks.
- **Added `setUpAll`/`tearDownAll` exclusion**: These lifecycle methods are now excluded from linting, matching the existing `setUp`/`tearDown` behavior.

## 0.1.3 - Standalone Checker Rule Filtering Fix

### Bug Fixes

- **Fixed rule filtering**: Fixed `standalone_checker` to properly filter rules based on file type when both test and production rules are specified together. Test-only rules are now correctly applied only to test files, and production rules are only applied to production files, preventing incorrect rule application.

### Technical Details

- When test rules (e.g., `avoid_test_timeouts`, `no_optional_operators_in_tests`, `prefer_fake_over_mock`, `document_fake_parameters`, `test_file_mutation_coverage`) and production rules are specified together, the checker now correctly applies the appropriate rules to the correct file types.
- This fix ensures that test files are only checked with test-specific rules and production files are only checked with production rules, even when both rule types are enabled in the same command.

## 0.1.2 - Standalone Checker Enhancement

### New Features

- Standalone command-line tool: added `standalone_checker` executable to run specific lint rules quickly.
- Check single rule: `dart run ripplearc_linter:standalone_checker --rules prefer_fake_over_mock lib/`
- Check multiple rules: `dart run ripplearc_linter:standalone_checker --rules rule1,rule2 lib/`
- Check all rules: `dart run ripplearc_linter:standalone_checker lib/`

### Notes

- Added convenience: test files are analyzed when the target path is `test/` (or inside it), or when any test-specific rule is enabled (e.g., `avoid_test_timeouts`, `no_optional_operators_in_tests`, `prefer_fake_over_mock`, `document_fake_parameters`).

## 0.1.1 - Package Renaming

### Breaking Changes

- **Package Renamed**: The package has been renamed from `ripplearc_lint_rules` to `ripplearc_linter` for better naming consistency.
  - Main library file renamed: `lib/ripplearc_lint_rules.dart` → `lib/ripplearc_linter.dart`
  - Update your `pubspec.yaml` to use `ripplearc_linter` instead of `ripplearc_lint_rules`
  - All documentation and examples have been updated to reflect the new package name

### Migration Guide

If you're upgrading from version 0.1.0, update your `pubspec.yaml`:

```yaml
# Old
dependencies:
  ripplearc_lint_rules: ^0.1.0

# New
dependencies:
  ripplearc_linter: ^0.1.1
```

Then run `dart pub get` to fetch the updated package.

## 0.1.0 - Initial Release

A comprehensive custom lint library for Dart/Flutter projects with 13 carefully crafted lint rules to enforce best practices, improve code quality, and ensure robust testing standards.

### Lint Rules

#### Error-Level Rules

- **`forbid_forced_unwrapping`**: Forbids forced unwrapping (`!`) in production code. Exceptions: test files, `/testing/` fakes, and generated files (`.freezed.dart`, `.g.dart`).

- **`no_optional_operators_in_tests`**: Forbids optional operators (`?.`, `??`, `??=`, `?[]`) in test files to ensure explicit test failures.

- **`no_direct_instantiation`**: Enforces dependency injection by forbidding direct class instantiation. Exceptions: Module and Factory classes.

- **`document_fake_parameters`**: Requires documentation on Fake classes and their non-private members.

- **`document_interface`**: Requires documentation on abstract classes and their public methods.

- **`test_file_mutation_coverage`**: Ensures every test file in `test/units` has a corresponding `.xml` mutation file in `test/mutations`.

- **`private_subject`**: Requires Subject variables (BehaviorSubject, ReplaySubject, PublishSubject) to be private with underscore prefix.

- **`sealed_over_dynamic`**: Enforces sealed classes instead of `dynamic` for type-safe sync results.

- **`specific_exception_types`**: Requires specific exception types instead of generic `Exception`.

#### Warning-Level Rules

- **`prefer_fake_over_mock`**: Recommends `Fake` over `Mock` for test doubles.

- **`todo_with_story_links`**: Requires TODO comments to include YouTrack story links.

- **`no_internal_method_docs`**: Forbids documentation on private methods to reduce noise.

- **`avoid_test_timeouts`**: Forbids `.timeout()` and `Future.delayed()` in tests to prevent flaky tests.

### Features

- Clean architecture with base analyzer and lint rule classes
- Extensible framework for adding custom rules
- Comprehensive test coverage for all rules
- Example files demonstrating violations and correct usage
- Support for custom lint configuration via `custom_lint.yaml`
- Integration with Dart analyzer and IDE support
