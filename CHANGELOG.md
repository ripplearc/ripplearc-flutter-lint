# Changelog

## 0.1.0

Initial release with three lint rules:

- `prefer_fake_over_mock`: Recommends using `Fake` instead of `Mock` for test doubles
- `forbid_forced_unwrapping`: Forbids forced unwrapping (`!`) in production code
- `no_optional_operators_in_tests`: Forbids optional operators (`?.`, `??`) in test files 