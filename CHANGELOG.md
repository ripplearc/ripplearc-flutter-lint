# Changelog

## 0.2.0

Added five new lint rules:

- `todo_with_story_links` (**warning**): Ensures TODO comments include YouTrack story links for proper project management and technical debt tracking.
- `no_internal_method_docs` (**warning**): Forbids documentation on private methods to reduce documentation noise.
- `no_direct_instantiation` (**error**): Enforces dependency injection by forbidding direct class instantiation, except for Factory/Module classes or inside Module classes.
- `document_fake_parameters` (**error**): Enforces documentation on Fake classes and their non-private members for better test maintainability.
- `document_interface` (**error**): Enforces documentation on abstract classes and their public methods for clear API contracts.

## 0.1.0

Initial release with three lint rules:

- `prefer_fake_over_mock`: Recommends using `Fake` instead of `Mock` for test doubles
- `forbid_forced_unwrapping`: Forbids forced unwrapping (`!`) in production code
- `no_optional_operators_in_tests`: Forbids optional operators (`?.`, `??`) in test files 