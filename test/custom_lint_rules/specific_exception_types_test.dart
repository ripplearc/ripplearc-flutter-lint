import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';
import 'package:ripplearc_flutter_lints/custom_lint_rules/specific_exception_types.dart';
import '../utils/custom_lint_resolver.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('SpecificExceptionTypes', () {
    late SpecificExceptionTypes rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = SpecificExceptionTypes();
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
