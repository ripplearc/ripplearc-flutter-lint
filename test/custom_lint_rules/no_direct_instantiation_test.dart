import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:ripplearc_linter/custom_lint_rules/no_direct_instantiation.dart';
import 'package:test/test.dart';
import '../utils/custom_lint_resolver.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('NoDirectInstantiation', () {
    late NoDirectInstantiation rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = NoDirectInstantiation();
      reporter = TestErrorReporter();
    });

    Future<void> analyzeCode(
      String sourceCode, {
      String path = 'lib/example.dart',
    }) async {
      final parseResult = parseString(content: sourceCode);
      unit = parseResult.unit;
      reporter.errors.clear(); // Clear previous errors
      rule.run(
        TestCustomLintResolver(unit, path: path),
        reporter,
        TestCustomLintContext(unit),
      );
    }

    test('flags direct instantiation of regular class', () async {
      const source = '''
      class AuthService {}
      void main() {
        final a = AuthService(); // Should be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isNotEmpty);
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
        expect(reporter.errors, isNotEmpty);
      },
    );

    test('does not flag const constructor instantiation', () async {
      const source = '''
      class MyClass {
        const MyClass();
      }
      void main() {
        const instance = MyClass(); // Should NOT be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('does not flag instantiation inside const list', () async {
      const source = '''
      class MyClass {}
      void main() {
        const list = [MyClass()]; // Should NOT be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('does not flag factory constructor instantiation', () async {
      const source = '''
      class MyClass {
        factory MyClass() => MyClass._();
        MyClass._();
      }
      void main() {
        final instance = MyClass(); // Should NOT be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('does not flag instantiation in Module binds method', () async {
      const source = '''
      class AuthService {}
      class Module {}
      class AppModule extends Module {
        void binds() {
          final service = AuthService(); // Should NOT be flagged
        }
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test(
      'does not flag instantiation in Module exportedBinds method',
      () async {
        const source = '''
      class AuthService {}
      class Module {}
      class AppModule extends Module {
        void exportedBinds() {
          final service = AuthService(); // Should NOT be flagged
        }
      }
      ''';
        await analyzeCode(source);
        expect(reporter.errors, isEmpty);
      },
    );

    test('does not flag Widget class instantiation', () async {
      const source = '''
      class MyWidget {}
      void main() {
        final widget = MyWidget(); // Should NOT be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('does not flag State class instantiation', () async {
      const source = '''
      class LoadingState {}
      void main() {
        final state = LoadingState(); // Should NOT be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('does not flag Event class instantiation', () async {
      const source = '''
      class UserEvent {}
      void main() {
        final event = UserEvent(); // Should NOT be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('does not flag DTO class instantiation', () async {
      const source = '''
      class UserDto {}
      void main() {
        final dto = UserDto(); // Should NOT be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('does not flag Entity class instantiation', () async {
      const source = '''
      class UserEntity {}
      void main() {
        final entity = UserEntity(); // Should NOT be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('does not flag Model class instantiation', () async {
      const source = '''
      class UserModel {}
      void main() {
        final model = UserModel(); // Should NOT be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('does not flag Exception class instantiation', () async {
      const source = '''
      class AuthException {}
      void main() {
        final exception = AuthException(); // Should NOT be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('does not flag Error class instantiation', () async {
      const source = '''
      class AuthError {}
      void main() {
        final error = AuthError(); // Should NOT be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('does not flag Params class instantiation', () async {
      const source = '''
      class LoginParams {}
      void main() {
        final params = LoginParams(); // Should NOT be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('does not flag Value class instantiation', () async {
      const source = '''
      class UserValue {}
      void main() {
        final value = UserValue(); // Should NOT be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('does not flag instantiation in test files', () async {
      const source = '''
      class AuthService {}
      void main() {
        final service = AuthService(); // Should NOT be flagged in test files
      }
      ''';
      await analyzeCode(source, path: 'test/auth_service_test.dart');
      expect(reporter.errors, isEmpty);
    });

    test('does not flag instantiation in test directory', () async {
      const source = '''
      class AuthService {}
      void main() {
        final service = AuthService(); // Should NOT be flagged in test directory
      }
      ''';
      await analyzeCode(source, path: 'test/unit/auth_service_test.dart');
      expect(reporter.errors, isEmpty);
    });

    test('does not flag instantiation in model files', () async {
      const source = '''
      class UserModel {}
      void main() {
        final model = UserModel(); // Should NOT be flagged in model files
      }
      ''';
      await analyzeCode(source, path: 'lib/data/models/user_model.dart');
      expect(reporter.errors, isEmpty);
    });

    test('does not flag instantiation in DTO files', () async {
      const source = '''
      class UserDto {}
      void main() {
        final dto = UserDto(); // Should NOT be flagged in DTO files
      }
      ''';
      await analyzeCode(source, path: 'lib/data/user_dto.dart');
      expect(reporter.errors, isEmpty);
    });

    test('does not flag instantiation in main.dart', () async {
      const source = '''
      class AppService {}
      void main() {
        final service = AppService(); // Should NOT be flagged in main.dart
      }
      ''';
      await analyzeCode(source, path: 'lib/main.dart');
      expect(reporter.errors, isEmpty);
    });

    test('does not flag instantiation in domain entities directory', () async {
      const source = '''
      class UserEntity {}
      void main() {
        final entity = UserEntity(); // Should NOT be flagged in entities directory
      }
      ''';
      await analyzeCode(source, path: 'lib/domain/entities/user_entity.dart');
      expect(reporter.errors, isEmpty);
    });

    test(
      'does not flag instantiation of class imported from domain entity',
      () async {
        const source = '''
      import 'package:myapp/domain/entities/user_entity.dart';
      
      void main() {
        final user = UserEntity(); // Should NOT be flagged (imported from domain entity)
      }
      ''';
        await analyzeCode(source);
        expect(reporter.errors, isEmpty);
      },
    );

    test('does not flag instantiation of class imported from model', () async {
      const source = '''
      import 'package:myapp/data/models/user_model.dart';
      
      void main() {
        final user = UserModel(); // Should NOT be flagged (imported from model)
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('does not flag private named constructor instantiation', () async {
      const source = '''
      class MyClass {
        MyClass._private();
      }
      void main() {
        final instance = MyClass._private(); // Should NOT be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('does not flag Event pattern class instantiation', () async {
      const source = '''
      class LoginEvent {}
      void main() {
        final event = LoginEvent(); // Should NOT be flagged (ends with Event)
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('does not flag Initial state class', () async {
      const source = '''
      class AuthInitial {}
      void main() {
        final state = AuthInitial(); // Should NOT be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('does not flag Loading state class', () async {
      const source = '''
      class AuthLoading {}
      void main() {
        final state = AuthLoading(); // Should NOT be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('does not flag Success state class', () async {
      const source = '''
      class AuthSuccess {}
      void main() {
        final state = AuthSuccess(); // Should NOT be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('does not flag Failure state class', () async {
      const source = '''
      class AuthFailure {}
      void main() {
        final state = AuthFailure(); // Should NOT be flagged
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test(
      'flags regular class even if it contains pattern-like substring',
      () async {
        const source = '''
      class StateManager {} // Contains "State" but doesn't end with it
      void main() {
        final manager = StateManager(); // Should be flagged
      }
      ''';
        await analyzeCode(source);
        expect(reporter.errors, isNotEmpty);
      },
    );
  });
}
