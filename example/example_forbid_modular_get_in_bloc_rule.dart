// ignore_for_file: unused_local_variable

// This package only reports this rule on files named *_bloc.dart.
// This example file is for documentation; place real BLoCs in *_bloc.dart files.

class Modular {
  static T get<T>() => throw UnimplementedError();
}

class ProjectRepository {
  Future<List<Object>> fetchAll() async => [];
}

class Bloc<E, S> {
  Bloc(S initial);
  void on<X>(void Function(X, void Function(S)) handler) {}
}

class ProjectDropdownEvent {}
class LoadProjects extends ProjectDropdownEvent {}
class ProjectDropdownState {}
class ProjectDropdownInitial extends ProjectDropdownState {}
class ProjectDropdownLoaded extends ProjectDropdownState {
  ProjectDropdownLoaded(List<Object> _);
}

// Bad (in a *_bloc.dart file): service locator inside the BLoC
class BadProjectDropdownBloc extends Bloc<ProjectDropdownEvent, ProjectDropdownState> {
  BadProjectDropdownBloc() : super(ProjectDropdownInitial()) {
    final repo = Modular.get<ProjectRepository>(); // LINT
    on<LoadProjects>((event, emit) async {
      final projects = await repo.fetchAll();
      emit(ProjectDropdownLoaded(projects));
    });
  }
}

// Good: constructor injection
class GoodProjectDropdownBloc extends Bloc<ProjectDropdownEvent, ProjectDropdownState> {
  final ProjectRepository _repo;

  GoodProjectDropdownBloc({required ProjectRepository repo})
      : _repo = repo,
        super(ProjectDropdownInitial()) {
    on<LoadProjects>((event, emit) async {
      final projects = await _repo.fetchAll();
      emit(ProjectDropdownLoaded(projects));
    });
  }
}

// Good: Modular.get in a module — always allowed in *_module.dart
class Module {
  void binds(dynamic i) {}
}

class ExampleProjectModule extends Module {
  @override
  void binds(i) {
    i.addFactory<GoodProjectDropdownBloc>(
      () => GoodProjectDropdownBloc(repo: Modular.get<ProjectRepository>()), // OK
    );
  }
}
