import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:test/test.dart';
import 'package:ripplearc_flutter_lint/rules/no_optional_operators_in_tests.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('NoOptionalOperatorsInTests', () {
    late NoOptionalOperatorsInTests rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = const NoOptionalOperatorsInTests();
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
      expect(reporter.errors, hasLength(1));
      expect(reporter.errors.first.errorCode.name, equals('no_optional_operators_in_tests'));
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
      expect(reporter.errors, hasLength(1));
      expect(reporter.errors.first.errorCode.name, equals('no_optional_operators_in_tests'));
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

class TestCustomLintResolver implements CustomLintResolver {
  TestCustomLintResolver(this.unit);
  final CompilationUnit unit;

  @override
  Future<ResolvedUnitResult> getResolvedUnitResult() async {
    throw UnimplementedError();
  }

  @override
  LineInfo get lineInfo => throw UnimplementedError();

  @override
  String get path => 'test/example_test.dart';

  @override
  Source get source => throw UnimplementedError();
}

class _MockLintRuleNodeRegistry implements LintRuleNodeRegistry {
  final CompilationUnit unit;

  _MockLintRuleNodeRegistry(this.unit);

  @override
  void addCompilationUnit(Function(CompilationUnit) callback) {
    callback(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class TestCustomLintContext implements CustomLintContext {
  TestCustomLintContext(this.unit);
  final CompilationUnit unit;

  void addCompilationUnit(Function(CompilationUnit) callback) {
    callback(unit);
  }

  @override
  void addPostRunCallback(Function() callback) {}

  @override
  Pubspec get pubspec => throw UnimplementedError();

  @override
  Map<String, dynamic> get sharedState => {};

  @override
  LintRuleNodeRegistry get registry => _MockLintRuleNodeRegistry(unit);
} 