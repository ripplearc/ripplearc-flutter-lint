import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:ripplearc_flutter_lints/custom_lint_rules/no_direct_instantiation.dart';
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

    Future<void> analyzeCode(String sourceCode) async {
      final parseResult = parseString(content: sourceCode);
      unit = parseResult.unit;
      rule.run(
        TestCustomLintResolver(unit),
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
  });
}
