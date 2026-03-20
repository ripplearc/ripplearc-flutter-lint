# Changelog

## 0.3.1 - AvoidTestTimeouts Detection Fix (patch)

### Bug Fixes

- **Fixed `Future<void>.delayed()` and `Future.microtask()` not being detected**: The `avoid_test_timeouts` rule was missing violations for generic Future calls (`Future<void>.delayed()`, `Future<void>.microtask()`, etc.) because the Dart analyzer parses them as `InstanceCreationExpression` in unresolved mode even though they are static methods. The rule now correctly flags these patterns in test blocks.

## 0.3.0 - New Rules (minor)

### New Rules

- **`forbid_helper_util_naming`**: Forbids class names containing "Helper" or "Util" to encourage more descriptive, domain-specific names (e.g., `AssetHelper` → `AssetLoader`, `StringUtil` → `StringParser`).

- **`forbid_datetime_now`**: Forbids `DateTime.now()` in production code. Use `clock.now()` from dependency injection for testable code.

- **`document_enum`**: Requires documentation on enum declarations, their values, and extensions on enums.

- **`prevent_feature_module_dependencies`**: Prevents feature modules from importing other feature modules. Features can only depend on the same feature, core, shared, or external packages.

- **`prevent_library_module_dependencies`**: Prevents library modules from importing feature modules. Libraries should only depend on other libraries, core packages, or external packages.

- **`restrict_core_icon_data`**: Restricts direct usage of `CoreIconData` and `CoreMaterialIcons`. Use `CoreIcons` constants instead for consistent icon management.

## 0.2.3 - No Direct Instantiation Rule Critical Bug Fixes (patch)

### Critical Bug Fixes

- **Fixed rule not detecting violations**: The `no_direct_instantiation` rule was not flagging direct class instantiations that should have been caught. The rule now correctly identifies and reports violations in production code.

- **Fixed false positives in Module classes**: The rule was incorrectly flagging legitimate instantiations inside Module `binds()` and `exportedBinds()` methods. These are now correctly excluded as they are part of dependency injection setup.

- **Fixed missing exclusions for const and factory constructors**: The rule was flagging `const` constructors and factory constructors, which should be allowed. These are now correctly excluded.

- **Fixed missing exclusions for Flutter widgets and BLoC patterns**: The rule was incorrectly flagging legitimate instantiations of Flutter widgets, BLoC states, and events. These are now correctly excluded.

- **Fixed missing exclusions for DTOs, entities, and models**: The rule was flagging data transfer objects, domain entities, and model classes that should be allowed. These are now correctly excluded based on class name patterns, file paths, and import sources.

- **Fixed missing exclusions for test files**: The rule was flagging instantiations in test files, which should be allowed. Test files are now correctly excluded.

- **Fixed missing exclusions for whitelisted packages**: The rule was flagging instantiations from Flutter, BLoC, Supabase, and other whitelisted packages. These are now correctly excluded.

### Improvements

- **Enhanced exclusion patterns**: The rule now correctly handles 14 categories of legitimate instantiation patterns, including Factory classes, Module classes, const/factory constructors, Flutter widgets, BLoC states/events, DTOs/entities/models, test files, private constructors, sealed classes, and whitelisted packages.

## 0.2.2 - AvoidTestTimeouts Analyzer Bug Fixes (patch)

### Bug Fixes

- **Fixed nested test/group block detection**: The `avoid_test_timeouts` analyzer now correctly tracks nested `test`, `group`, and `testWidgets` blocks using a depth counter instead of a boolean flag. Previously, timeout violations in code between nested blocks were not detected.
- **Added `testWidgets` support**: Flutter widget tests using `testWidgets` are now correctly recognized and analyzed for timeout violations.
- **Added `setUpAll` and `tearDownAll` support**: These test lifecycle methods are now correctly analyzed for timeout violations, matching the existing `setUp` and `tearDown` behavior.

### Technical Details

- Changed `_isInTestBlock` from `bool` to `int _testBlockDepth` with depth tracking to properly handle nested test blocks
- Added `testWidgets`, `setUpAll`, and `tearDownAll` to the set of recognized test block methods
- Consolidated duplicate conditional logic for cleaner, more maintainable code
- All 16 tests passing with comprehensive coverage for nested blocks and lifecycle methods

## 0.2.1 - Theme exclusion fix and rule coverage (patch)

### Bug Fixes

- Corrected theme exclusion paths: `avoid_static_colors` and `avoid_static_typography` now skip files under `lib/src/theme` and `test/theme` (previously missed). Applies to both production and test targets.
- Path handling is normalized so the exclusions work on Windows and Unix.

### Improvements

- The two rules(avoid_static_colors and avoid_static_typography) now run on both production and test files, while still excluding theme files in both locations. This keeps color and typography enforcement consistent across the codebase.

## 0.2.0 - Static Colors & Typography Rules

### New Features

- **`avoid_static_colors`**: New production rule that forbids using static color definitions (e.g., `CoreTextColors`, `Colors.white`, `Color(0xFF...)`) in UI code and enforces theme-extension based colors for proper light/dark support.
- **`avoid_static_typography`**: New production rule that forbids using static typography definitions (`CoreTypography.*`), raw `TextStyle(...)` constructors, and `GoogleFonts.*` in UI code, enforcing typography access via `Theme.of(context).extension<TypographyExtension>()`.

### Improvements

- **Standalone checker**: `standalone_checker` has been updated to include the new rules so they can be run via the CLI (`--rules avoid_static_colors,avoid_static_typography`).

## 0.1.4 - NoOptionalOperatorsInTests Analyzer Bug Fixes

### Bug Fixes

- **Fixed nested test/group state tracking**: The analyzer now correctly tracks nested `test`, `group`, and `testWidgets` blocks using depth counters instead of boolean flags. Previously, optional operators after nested blocks were not detected.
- **Fixed missing `??=` operator detection**: The null-aware assignment operator is now correctly flagged in test blocks.
- **Fixed missing `?[]` operator detection**: The null-aware index operator is now correctly flagged in test blocks.
- **Fixed missing `testWidgets` support**: Flutter widget tests using `testWidgets` are now correctly recognized as test blocks.
- **Fixed missing `setUpAll`/`tearDownAll` exclusion**: These lifecycle methods are now correctly excluded from linting, matching the existing `setUp`/`tearDown` behavior.

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
