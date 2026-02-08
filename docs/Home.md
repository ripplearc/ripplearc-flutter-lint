# RippleArc Flutter Lint Documentation

Welcome to the RippleArc Flutter Lint documentation wiki! This comprehensive guide provides everything you need to know about our custom lint rules designed to enforce code quality, maintainability, and best practices in Flutter development.

## Getting Started
Dive into our collection of custom lint rules that help teams write cleaner, more maintainable Flutter code. This documentation covers detailed rule implementations, practical examples, configuration options, and best practices for effectively using and extending our lint rule suite.

## Documentation

| Rules | Descriptions |
|-------|-------------|
| [avoid_static_colors](avoid_static_colors.md) | Enforces theme-context-based color access for proper light/dark mode support |
| [avoid_static_typography](avoid_static_typography.md) | Disallows static typography definitions and enforces theme-based typography |
| [prefer_fake_over_mock](prefer_fake_over_mock.md) | Recommends using Fake instead of Mock for test doubles |
| [forbid_forced_unwrapping](forbid_forced_unwrapping.md) | Forbids forced unwrapping in production code to prevent runtime errors |
| [no_optional_operators_in_tests](no_optional_operators_in_tests.md) | Forbids optional operators in test files for explicit failure handling |
| [avoid_test_timeouts](avoid_test_timeouts.md) | Forbids timeout patterns in tests to prevent flaky test failures |
| [no_direct_instantiation](no_direct_instantiation.md) | Enforces dependency injection by forbidding direct class instantiation |
| [document_fake_parameters](document_fake_parameters.md) | Enforces documentation on Fake classes and their non-private members |
| [todo_with_story_links](todo_with_story_links.md) | Ensures TODO comments include YouTrack story links for project management |
| [no_internal_method_docs](no_internal_method_docs.md) | Forbids documentation on private methods to reduce documentation noise |
| [document_interface](document_interface.md) | Enforces documentation on abstract classes and their public methods |
| [prevent_feature_module_dependencies](prevent_feature_module_dependencies.md) | Prevents feature modules from depending on other feature modules |
| [prevent_library_module_dependencies](prevent_library_module_dependencies.md) | Prevents library modules from importing feature modules |
| [forbid_helper_util_naming](forbid_helper_util_naming.md) | Forbids generic Helper/Util class names for better clarity |
| [restrict_core_icon_data](restrict_core_icon_data.md) | Restricts CoreIconData usage to icons directory for consistent management |
| [document_enum](document_enum.md) | Enforces documentation on enums and their values |
| [forbid_datetime_now](forbid_datetime_now.md) | Forbids DateTime.now() in production code for testability |
