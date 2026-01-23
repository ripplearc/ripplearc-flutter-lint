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
      reporter.errors.clear();
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

    group('TypeChecker - Allowed package prefixes', () {
      test('does not flag Widget class instantiation from Flutter', () async {
        const source = '''
      import 'package:flutter/widgets.dart';
      
      void main() {
        final widget = Container(); // Should NOT be flagged (from Flutter package)
      }
      ''';
        await analyzeCode(source);
        expect(reporter.errors, isEmpty);
      });

      test(
        'does not flag classes from allowed dart: and package: prefixes',
        () async {
        const source = '''
      import 'dart:async';
      import 'dart:core';
      import 'package:uuid/uuid.dart';
      import 'package:intl/intl.dart';
      
      void main() {
        final date = DateTime.now(); // Should NOT be flagged (dart:core)
        final uri = Uri.parse('https://example.com'); // Should NOT be flagged (dart:core)
        final uuid = Uuid(); // Should NOT be flagged (package:uuid)
        final completer = Completer<String>(); // Should NOT be flagged (dart:async)
        final controller = StreamController<String>(); // Should NOT be flagged (dart:async)
        final dateFormat = DateFormat.yMd(); // Should NOT be flagged (package:intl)
        final numberFormat = NumberFormat.currency(); // Should NOT be flagged (package:intl)
      }
      ''';
          await analyzeCode(source);
          expect(reporter.errors, isEmpty);
        },
      );

      test('does not flag Supabase Attributes classes', () async {
        const source = '''
      import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
      
      void main() {
        final attributes = supabase.UserAttributes(password: 'test'); // Should NOT be flagged (Supabase package)
      }
      ''';
        await analyzeCode(source);
        expect(reporter.errors, isEmpty);
      });
    });

    group('ContextChecker - Ignored base classes', () {
      test('does not flag classes that extend ignored base classes', () async {
        const source = '''
      class Equatable {}
      class UserEvent extends Equatable {}
      class UserDto extends Equatable {}
      class UserEntity extends Equatable {}
      class UserModel extends Equatable {}
      class LoginParams extends Equatable {}
      class UserValue extends Equatable {}
      
      void main() {
        final dto = UserDto(); // Should NOT be flagged (extends Equatable)
        final entity = UserEntity(); // Should NOT be flagged (extends Equatable)
        final model = UserModel(); // Should NOT be flagged (extends Equatable)
        final params = LoginParams(); // Should NOT be flagged (extends Equatable)
        final value = UserValue(); // Should NOT be flagged (extends Equatable)
      }
      ''';
        await analyzeCode(source);
        expect(reporter.errors, isEmpty);
      });

      test('does not flag nested ignored base class inheritance', () async {
        const source = '''
      class Equatable {}
      class BaseState extends Equatable {}
      class AuthState extends BaseState {}
      class AuthInitial extends AuthState {}
      
      
      void main() {
        final state = AuthInitial(); // Should NOT be flagged (indirect extends Equatable)
      }
      ''';
        await analyzeCode(source);
        expect(reporter.errors, isEmpty);
      });

      test('does not flag Exception class instantiation', () async {
        const source = '''
      class AuthException implements Exception{
        final String message;
        AuthException(this.message);
      }
      void main() {
        final exception = AuthException('Invalid'); // Should NOT be flagged
      }
      ''';
        await analyzeCode(source);
        expect(reporter.errors, isEmpty);
      });

      test('does not flag Error class instantiation', () async {
        const source = '''
      class AuthError extends Error{
        final String message;
        AuthError(this.message);
      }
      void main() {
        final error = AuthError('Invalid'); // Should NOT be flagged
      }
      ''';
        await analyzeCode(source);
        expect(reporter.errors, isEmpty);
      });
    });

    test('flags instantiation in test files', () async {
      const source = '''
      class AuthService {}
      void main() {
        final service = AuthService(); // Should be flagged in test files
      }
      ''';
      await analyzeCode(source, path: 'test/auth_service_test.dart');
      expect(reporter.errors, isNotEmpty);
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


    test(
      'does not flag private constructor called inside the same class',
      () async {
        const source = '''
      class MyClass {
        MyClass._private();
        
        // Private constructor called inside the same class - allowed
        MyClass create() => MyClass._private();
      }
      ''';
        await analyzeCode(source);
        expect(reporter.errors, isEmpty);
      },
    );



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

    test('does not flag sealed class instantiation', () async {
      const source = '''
      sealed class Result<T> {}
      class Success<T> extends Result<T> {
        final T value;
        Success(this.value);
      }
      class Failure<T> extends Result<T> {
        final String error;
        Failure(this.error);
      }
      void main() {
        final success = Success<String>('data'); // Should NOT be flagged (sealed class)
        final failure = Failure<String>('error'); // Should NOT be flagged (sealed class)
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });



    test('does not flag instantiation in super constructor invocation', () async {
      const source = '''
      class Parent {
        Parent(Child child);
      }
      class Child {}
      class MyClass extends Parent {
        MyClass() : super(Child()); // Should NOT be flagged (super constructor)
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('does not flag instantiation in constructor initializer', () async {
      const source = '''
      class OtherClass {}
      class MyClass {
        final OtherClass other;
        MyClass() : other = OtherClass(); // Should NOT be flagged (constructor initializer)
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

  });
}
