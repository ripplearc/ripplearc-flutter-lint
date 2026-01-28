# prefer_fake_over_mock

Recommends using `Fake` instead of `Mock` for test doubles. Fakes provide more realistic behavior and are easier to maintain than mocks.

## Bad ❌
```dart
class MockUserRepository extends Mock implements UserRepository {}
```

## Good ✅
```dart
class FakeUserRepository extends Fake implements UserRepository {
  @override
  Future<User> getUser(String id) async => User(id: id, name: 'Test User');
}
```
