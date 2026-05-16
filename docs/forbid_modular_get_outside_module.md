# forbid_modular_get_outside_module

## Description
`Modular.get<T>()` is only allowed in module files (`*_module.dart`). This rule prevents developers from making arbitrary dependencies retrievals inline elsewhere in the application, promoting proper constructor-based dependency injection.

This rule specifically ignores files inside the `test/` directory as well as generated files like `*.g.dart` or `*.freezed.dart`.
All non-module usages are flagged unless the requested type is explicitly listed in `allow_list`.

For project-specific global services, extend the exception list in `analysis_options.yaml`:

```yaml
custom_lint:
  rules:
    forbid_modular_get_outside_module:
      allow_list:
        - AppRouter
        - GlobalAnalytics
```

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

```dart
class AppRouter {}

class AnalyticsConsumer {
  void track() {
    // OK — AppRouter declared in allow_list in analysis_options.yaml
    final router = Modular.get<AppRouter>();
  }
}
```
