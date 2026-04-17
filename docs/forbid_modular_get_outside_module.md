# forbid_modular_get_outside_module

## Description
`Modular.get<T>()` is only allowed in module files (`*_module.dart`). This rule prevents developers from making arbitrary dependencies retrievals inline elsewhere in the application, promoting proper constructor-based dependency injection.

This rule specifically ignores files inside the `test/` directory as well as generated files like `*.g.dart` or `*.freezed.dart`.

## Bad
```dart
// Normal production file (not _module.dart)
class UserService {
  final _http = Modular.get<HttpClient>(); // LINT: Modular.get should only be inside _module.dart files
  
  void fetch() {
     // LINT: Modular.get not allowed here
    final repo = Modular.get<UserRepository>();
  }
}
```

## Good
```dart
// Properly injecting via constructor
class UserService {
  final HttpClient _http;
  final UserRepository _repo;
  
  UserService(this._http, this._repo);
}

// And injecting dependencies where allowed (inside a _module.dart)
class AppCoreModule extends Module {
  @override
  void binds(Injector i) {
    i.addSingleton(HttpClient.new);
    i.addSingleton(UserRepository.new);
    i.addFactory<UserService>(
      () => UserService(Modular.get<HttpClient>(), Modular.get<UserRepository>()) // OK
    );
  }
}
```
