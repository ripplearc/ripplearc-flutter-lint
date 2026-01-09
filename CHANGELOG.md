# Changelog

## 0.2.3 - No Direct Instantiation Rule Critical Bug Fixes (patch)

### Critical Bug Fixes

- **Fixed rule not detecting violations**: Rule now correctly flags direct instantiations in production code.

- **Fixed false positives in Module classes**: Instantiations in Module `binds()` and `exportedBinds()` methods are now correctly excluded.

- **Fixed missing exclusions for const and factory constructors**: `const` and factory constructors are now correctly excluded.

- **Fixed missing exclusions for Flutter widgets and BLoC patterns**: Flutter widgets, BLoC states, and events are now correctly excluded.

- **Fixed missing exclusions for DTOs, entities, and models**: DTOs, entities, and models are now correctly excluded based on class name patterns, file paths, and import sources.

- **Fixed missing exclusions for test files**: Test files are now correctly excluded.

- **Fixed missing exclusions for whitelisted packages**: Instantiations from Flutter, BLoC, Supabase, and other whitelisted packages are now correctly excluded.


## 0.2.2 - AvoidTestTimeouts Analyzer Bug Fixes (patch)

### Bug Fixes

- **Fixed nested test/group block detection**: Analyzer now correctly tracks nested `test`, `group`, and `testWidgets` blocks using a depth counter.
- **Added `testWidgets` support**: Flutter widget tests using `testWidgets` are now correctly recognized.
- **Added `setUpAll` and `tearDownAll` support**: These test lifecycle methods are now correctly analyzed for timeout violations.

### Technical Details

- Changed `_isInTestBlock` from `bool` to `int _testBlockDepth` with depth tracking to properly handle nested test blocks
- Added `testWidgets`, `setUpAll`, and `tearDownAll` to the set of recognized test block methods
- Consolidated duplicate conditional logic for cleaner, more maintainable code
- All 16 tests passing with comprehensive coverage for nested blocks and lifecycle methods

## 0.2.1 - Theme exclusion fix and rule coverage (patch)

### Bug Fixes

- Corrected theme exclusion paths: `avoid_static_colors` and `avoid_static_typography` now skip files under `lib/src/theme` and `test/theme`.
- Path handling normalized for Windows and Unix compatibility.

### Improvements

- Rules now run on both production and test files while excluding theme files in both locations.

## 0.2.0 - Static Colors & Typography Rules

### New Features

- **`avoid_static_colors`**: Forbids static color definitions and enforces theme-extension based colors.
- **`avoid_static_typography`**: Forbids static typography definitions and enforces typography access via theme extensions.

### Improvements

- **Standalone checker**: `standalone_checker` has been updated to include the new rules so they can be run via the CLI (`--rules avoid_static_colors,avoid_static_typography`).

## 0.1.4 - NoOptionalOperatorsInTests Analyzer Bug Fixes

### Bug Fixes

- **Fixed nested test/group state tracking**: Analyzer now correctly tracks nested blocks using depth counters.
- **Fixed missing `??=` operator detection**: Null-aware assignment operator is now correctly flagged.
- **Fixed missing `?[]` operator detection**: Null-aware index operator is now correctly flagged.
- **Fixed missing `testWidgets` support**: Flutter widget tests using `testWidgets` are now correctly recognized.
- **Fixed missing `setUpAll`/`tearDownAll` exclusion**: These lifecycle methods are now correctly excluded.

## 0.1.3 - Standalone Checker Rule Filtering Fix

### Bug Fixes

- **Fixed rule filtering**: `standalone_checker` now properly filters rules based on file type when both test and production rules are specified.

### Technical Details

- Checker now correctly applies test rules to test files and production rules to production files when both are specified.

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
