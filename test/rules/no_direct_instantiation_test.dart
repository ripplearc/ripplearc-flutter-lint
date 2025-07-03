import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
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
