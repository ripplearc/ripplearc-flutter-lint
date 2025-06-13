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