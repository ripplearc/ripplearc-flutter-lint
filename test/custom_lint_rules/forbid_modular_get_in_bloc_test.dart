import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:ripplearc_linter/custom_lint_rules/forbid_modular_get_in_bloc.dart';
import 'package:test/test.dart';
import '../utils/custom_lint_resolver.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('ForbidModularGetInBloc', () {
    late ForbidModularGetInBloc rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = ForbidModularGetInBloc();
      reporter = TestErrorReporter();
    });

    Future<void> analyzeCode(String sourceCode, {required String path}) async {
      final parseResult = parseString(content: sourceCode);
      unit = parseResult.unit;
      rule.run(
        TestCustomLintResolver(unit, path: path),
        reporter,
        TestCustomLintContext(unit),
      );
    }

    group('Modular.get in BLoC files', () {
      test('flags Modular.get in constructor body', () async {
        const source = r'''
        class Modular {
          static T get<T>() => throw UnimplementedError();
        }
        class ProjectRepository {}
        class Bloc<E, S> {
          Bloc(S s);
          void on<X>(void Function(X, void Function(S)) h) {}
        }
        class ProjectDropdownEvent {}
        class ProjectDropdownState {}
        class ProjectDropdownInitial extends ProjectDropdownState {}
        class ProjectDropdownBloc extends Bloc<ProjectDropdownEvent, ProjectDropdownState> {
          ProjectDropdownBloc() : super(ProjectDropdownInitial()) {
            final repo = Modular.get<ProjectRepository>();
            on<ProjectDropdownEvent>((event, emit) async {});
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/features/project_dropdown_bloc.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('flags late assignment from Modular.get', () async {
        const source = r'''
        class Modular {
          static T get<T>() => throw UnimplementedError();
        }
        class AuthRepository {}
        class Bloc<E, S> {
          Bloc(S s);
          void on<X>(void Function(X, void Function(S)) h) {}
        }
        class AuthEvent {}
        class AuthState {}
        class AuthInitial extends AuthState {}
        class AuthBloc extends Bloc<AuthEvent, AuthState> {
          late final AuthRepository _repo;
          AuthBloc() : super(AuthInitial()) {
            _repo = Modular.get<AuthRepository>();
            on<AuthEvent>((event, emit) async {});
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/auth_bloc.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('flags import-prefixed Modular.get', () async {
        await analyzeCode(
          r'''
import 'no_such_lib.dart' as fm;

class R {}
class S {}
class Bloc<E, S> {
  Bloc(S initial);
}
class E {}
class MyBloc extends Bloc<E, S> {
  MyBloc() : super(S()) {
    fm.Modular.get<R>();
  }
}
''',
          path: 'lib/prefixed_bloc.dart',
        );
        expect(reporter.errors, hasLength(1));
      });
    });

    group('allowed locations', () {
      test('does not flag Modular.get in *_module.dart', () async {
        const source = r'''
        class Modular {
          static T get<T>() => throw UnimplementedError();
        }
        class ProjectRepository {}
        class ProjectDropdownBloc {
          ProjectDropdownBloc({required ProjectRepository repo});
        }
        class Module {
          void binds(dynamic i) {}
        }
        class ProjectModule extends Module {
          @override
          void binds(i) {
            i.addFactory<ProjectDropdownBloc>(
              () => ProjectDropdownBloc(repo: Modular.get<ProjectRepository>()),
            );
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/project_module.dart');
        expect(reporter.errors, isEmpty);
      });

      test('does not flag Modular.get in non-bloc lib files', () async {
        const source = r'''
        class Modular {
          static T get<T>() => throw UnimplementedError();
        }
        class Foo {}
        void main() {
          Modular.get<Foo>();
        }
        ''';
        await analyzeCode(source, path: 'lib/some_widget.dart');
        expect(reporter.errors, isEmpty);
      });

      test('does not flag other get() calls on Modular-shaped types', () async {
        const source = r'''
        class NotModular {
          void get() {}
        }
        class Bloc<E, S> {
          Bloc(S s);
        }
        class E {}
        class S {}
        class B extends Bloc<E, S> {
          B() : super(S()) {
            NotModular().get();
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/wrong_target_bloc.dart');
        expect(reporter.errors, isEmpty);
      });
    });

    group('rule metadata', () {
      test('rule name', () {
        expect(rule.code.name, equals('forbid_modular_get_in_bloc'));
      });

      test('problem message mentions constructor and module files', () {
        expect(rule.code.problemMessage, contains('Modular.get'));
        expect(rule.code.problemMessage, contains('_module.dart'));
      });
    });
  });
}
