import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';
import 'package:ripplearc_flutter_lints/custom_lint_rules/no_optional_operators_in_tests.dart';
import '../utils/custom_lint_resolver.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('NoOptionalOperatorsInTests', () {
    late NoOptionalOperatorsInTests rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = NoOptionalOperatorsInTests();
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

    test('should flag optional chaining operator (?.)', () async {
      const source = '''
void main() {
  test('example', () {
    final result = someObject?.someProperty;  // Should flag this
    expect(result, equals(expected));
  });
}
''';
      await analyzeCode(source);
      expect(reporter.errors, isNotEmpty);
    });

    test('should flag null-aware operator (??)', () async {
      const source = '''
void main() {
  test('example', () {
    final result = someValue ?? defaultValue;  // Should flag this
    expect(result, equals(expected));
  });
}
''';
      await analyzeCode(source);
      expect(reporter.errors, isNotEmpty);
    });

    test('should not flag null assertion operator (!)', () async {
      const source = '''
void main() {
  test('example', () {
    final result = someValue!;  // Should not flag this
    expect(result, equals(expected));
  });
}
''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('should not flag non-test files', () async {
      const source = '''
class MyClass {
  void someMethod() {
    final result = someObject?.someProperty;  // Should not flag this
    final value = someValue ?? defaultValue;  // Should not flag this
  }
}
''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('should not flag setup/teardown blocks', () async {
      const source = '''
void main() {
  setUp(() {
    final result = someObject?.someProperty;  // Should not flag this
    final value = someValue ?? defaultValue;  // Should not flag this
  });

  test('example', () {
    // Test implementation
  });
}
''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });
  });
}
