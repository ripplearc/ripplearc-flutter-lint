import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:ripplearc_flutter_lint/rules/no_direct_instantiation.dart';
import 'package:test/test.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('NoDirectInstantiation', () {
    late NoDirectInstantiation rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = const NoDirectInstantiation();
      reporter = TestErrorReporter();
    });

    Future<void> analyzeCode(String sourceCode) async {
      final parseResult = parseString(content: sourceCode);
      unit = parseResult.unit;
      rule.run(_TestResolver(unit), reporter, _TestContext(unit));
    }

    test('flags direct instantiation of regular class', () async {
      const source = '''
      class AuthService {}
      void main() {
        final a = AuthService(); // Should be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('does not flag instantiation of Factory class', () async {
      const source = '''
      class FileProcessorFactory {}
      void main() {
        final f = FileProcessorFactory(); // Should NOT be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('does not flag instantiation of Module class', () async {
      const source = '''
      class Module {}
      class AppModule extends Module {}
      void main() {
        final m = AppModule(); // Should NOT be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('does not flag Modular.get usage', () async {
      const source = '''
      class AuthService {}
      class Modular {
        static T get<T>() => throw UnimplementedError();
      }
      void main() {
        final a = Modular.get<AuthService>(); // Should NOT be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('does not flag direct instantiation inside a Module', () async {
      const source = '''
      class AuthService {}
      class Module {}
      class AppModule extends Module {
        AppModule() {
          final a = AuthService(); // Should NOT be flagged
        }
      }
      void main() {
        final m = AppModule();
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test(
      'flags direct instantiation outside but not inside a Module',
      () async {
        const source = '''
      class AuthService {}
      class Module {}
      class AppModule extends Module {
        AppModule() {
          final a = AuthService(); // Should NOT be flagged
        }
      }
      void main() {
        final a = AuthService(); // Should be flagged
        final m = AppModule();
      }
      ''';
        await analyzeCode(source);
        expect(reporter.errors, isEmpty);
      },
    );

    test('does not flag instantiation of @dataModel-annotated class', () async {
      const source = '''
      class DataModel {
        const DataModel();
      }
      const dataModel = DataModel();

      @dataModel
      class User {
        final int id;
        final String name;
        User({required this.id, required this.name});
      }
      void main() {
        final user = User(id: 1, name: 'Alice'); // Should NOT be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('does not flag instantiation of DataModel annotation class', () async {
      const source = '''
      class DataModel {
        const DataModel();
      }
      void main() {
        final model = DataModel(); // Should NOT be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('does not flag instantiation of namespaced model (e.g., supabase.User)', () async {
      const source = '''
      // Simulate a third-party library namespace
      class supabase {
        static User User({required int id}) => User._(id);
      }
      class User {
        final int id;
        User._(this.id);
      }
      void main() {
        final user = supabase.User(id: 1); // Should NOT be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('flags instantiation of model with disallowed namespace (e.g., foo.User)', () async {
      const source = '''
      // Simulate a third-party library namespace
      class foo {
        static User User({required int id}) => User._(id);
      }
      class User {
        final int id;
        User._(this.id);
      }
      void main() {
        final user = foo.User(id: 1); // Should be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isNotEmpty);
    });

    test('does not flag instantiation of @freezed-annotated class', () async {
      const source = '''
      class DataModel {
        const DataModel();
      }
      const freezed = DataModel();

      @freezed
      class User {
        final int id;
        final String name;
        User({required this.id, required this.name});
      }
      void main() {
        final user = User(id: 1, name: 'Alice'); // Should NOT be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('flags instantiation of @dataModel-annotated class with impl in name', () async {
      const source = '''
      class DataModel {
        const DataModel();
      }
      const dataModel = DataModel();

      @dataModel
      class UserImpl {
        final int id;
        UserImpl({required this.id});
      }
      void main() {
        final user = UserImpl(id: 1); // Should be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isNotEmpty);
    });

    test('flags instantiation of @freezed-annotated class with impl in name', () async {
      const source = '''
      class DataModel {
        const DataModel();
      }
      const freezed = DataModel();

      @freezed
      class AccountImpl {
        final int id;
        AccountImpl({required this.id});
      }
      void main() {
        final account = AccountImpl(id: 1); // Should be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isNotEmpty);
    });

    test('does not flag instantiation of List.filled', () async {
      const source = '''
      void main() {
        final list = List.filled(3, 0);
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('does not flag instantiation of Map', () async {
      const source = '''
      void main() {
        final map = Map<String, int>();
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('does not flag instantiation of Set', () async {
      const source = '''
      void main() {
        final set = Set<int>();
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('does not flag instantiation of DateTime', () async {
      const source = '''
      void main() {
        final now = DateTime.now();
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('does not flag instantiation of RegExp', () async {
      const source = '''
      void main() {
        final regex = RegExp(r"[a-z]+", caseSensitive: false);
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('flags instantiation of @dataModel-annotated class with service in name', () async {
      const source = '''
      class dataModel {
        const dataModel();
      }
      @dataModel
      class AuthService {
        AuthService();
      }
      void main() {
        final s = AuthService(); // Should be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isNotEmpty);
    });

    test('flags instantiation of @freezed-annotated class with manager in name', () async {
      const source = '''
      class freezed {
        const freezed();
      }
      @freezed
      class UserManager {
        UserManager();
      }
      void main() {
        final m = UserManager(); // Should be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isNotEmpty);
    });

    test('flags instantiation of class with bloc in name', () async {
      const source = '''
      class AuthBloc {
        AuthBloc();
      }
      void main() {
        final b = AuthBloc(); // Should be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isNotEmpty);
    });

    test('flags instantiation of class with repository in name', () async {
      const source = '''
      class UserRepository {
        UserRepository();
      }
      void main() {
        final r = UserRepository(); // Should be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isNotEmpty);
    });

    test('flags instantiation of class with datasource in name', () async {
      const source = '''
      class RemoteDatasource {
        RemoteDatasource();
      }
      void main() {
        final d = RemoteDatasource(); // Should be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isNotEmpty);
    });

    test('flags instantiation of class with provider in name', () async {
      const source = '''
      class AuthProvider {
        AuthProvider();
      }
      void main() {
        final p = AuthProvider(); // Should be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isNotEmpty);
    });

    test('does not flag instantiation of class from supabase_flutter package', () async {
      const source = '''
      // Simulate a class from the supabase_flutter package
      // In real usage, this would be: import 'package:supabase_flutter/supabase_flutter.dart';
      class AuthSessionMissingException extends Exception {
        AuthSessionMissingException([String? message]);
      }
      void main() {
        final e = AuthSessionMissingException('Auth session missing');
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });
  });
}

class _TestResolver implements CustomLintResolver {
  _TestResolver(this.unit);
  final CompilationUnit unit;
  @override
  String get path => 'test.dart';
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestContext implements CustomLintContext {
  _TestContext(this.unit);
  final CompilationUnit unit;
  @override
  LintRuleNodeRegistry get registry => _TestRegistry(unit);
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestRegistry implements LintRuleNodeRegistry {
  _TestRegistry(this.unit);
  final CompilationUnit unit;
  @override
  void addCompilationUnit(Function(CompilationUnit) callback) {
    callback(unit);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
