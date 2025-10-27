# Changelog

## 0.1.0 - Initial Release

A comprehensive custom lint library for Dart/Flutter projects with 13 carefully crafted lint rules to enforce best practices, improve code quality, and ensure robust testing standards.

### Lint Rules

#### Error-Level Rules

- **`forbid_forced_unwrapping`**: Forbids forced unwrapping (`!`) in production code. Exceptions: test files, `/testing/` fakes, and generated files (`.freezed.dart`, `.g.dart`).

- **`no_optional_operators_in_tests`**: Forbids optional operators (`?.`, `??`) in test files to ensure explicit test failures.

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
