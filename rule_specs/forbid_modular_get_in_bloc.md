# forbid_modular_get_in_bloc

Forbids calling `Modular.get<T>()` inside BLoC files. BLoCs must receive all dependencies through their constructor; the DI container is only allowed in module registration files.

**Scope**: production only (omit — default)

**Exceptions**: Skip in files ending with `_module.dart`.

## Bad

```dart
// project_dropdown_bloc.dart
class ProjectDropdownBloc extends Bloc<ProjectDropdownEvent, ProjectDropdownState> {
  ProjectDropdownBloc() : super(ProjectDropdownInitial()) {
    final repo = Modular.get<ProjectRepository>(); // LINT
    on<LoadProjects>((event, emit) async {
      final projects = await repo.fetchAll();
      emit(ProjectDropdownLoaded(projects));
    });
  }
}
```

```dart
// auth_bloc.dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  late final AuthRepository _repo;

  AuthBloc() : super(AuthInitial()) {
    _repo = Modular.get<AuthRepository>(); // LINT — late init is still a violation
    on<SignIn>((event, emit) async {
      final user = await _repo.signIn(event.credentials);
      emit(AuthAuthenticated(user));
    });
  }
}
```

## Good

```dart
// project_dropdown_bloc.dart
class ProjectDropdownBloc extends Bloc<ProjectDropdownEvent, ProjectDropdownState> {
  final ProjectRepository _repo;

  ProjectDropdownBloc({required ProjectRepository repo})
      : _repo = repo,
        super(ProjectDropdownInitial()) {
    on<LoadProjects>((event, emit) async {
      final projects = await _repo.fetchAll();
      emit(ProjectDropdownLoaded(projects));
    });
  }
}
```

```dart
// project_module.dart  ← Modular.get<T>() is allowed here
class ProjectModule extends Module {
  @override
  void binds(i) {
    i.addSingleton<ProjectRepository>(ProjectRepositoryImpl.new);
    i.addFactory<ProjectDropdownBloc>(
      () => ProjectDropdownBloc(repo: Modular.get<ProjectRepository>()), // OK
    );
  }
}
```
