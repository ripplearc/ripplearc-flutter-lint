import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';
import 'package:ripplearc_flutter_lint/rules/specific_exception_types.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('SpecificExceptionTypes', () {
    late SpecificExceptionTypes rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = const SpecificExceptionTypes();
      reporter = TestErrorReporter();
    });

    Future<void> analyzeCode(String sourceCode) async {
      final parseResult = parseString(content: sourceCode);
      unit = parseResult.unit;
      rule.run(_TestResolver(unit), reporter, _TestContext(unit));
    }

    test('flags throw Exception', () async {
      const source = '''
      void main() {
        throw Exception('SUPABASE_URL required');
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('allows throw ConfigurationException', () async {
      const source = '''
      class ConfigurationException implements Exception {
        final String message;
        ConfigurationException(this.message);
      }
      void main() {
        throw ConfigurationException('SUPABASE_URL required');
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('allows throw ServerException', () async {
      const source = '''
      abstract class AppException implements Exception {
        final StackTrace stackTrace;
        final Object exception;
        AppException(this.stackTrace, this.exception);
      }
      class ServerException extends AppException {
        ServerException(super.stackTrace, super.exception);
      }
      void main() {
        throw ServerException(StackTrace.current, 'Server error');
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
