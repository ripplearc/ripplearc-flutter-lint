import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:ripplearc_flutter_lint/rules/forbid_forced_unwrapping.dart';
import 'package:test/test.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('ForbidForcedUnwrapping', () {
    late ForbidForcedUnwrapping rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = const ForbidForcedUnwrapping();
      reporter = TestErrorReporter();
    });

    Future<void> analyzeCode(String sourceCode, {required String path}) async {
      final parseResult = parseString(content: sourceCode);
      unit = parseResult.unit;
      rule.run(
        TestCustomLintResolver(unit, path),
        reporter,
        TestCustomLintContext(unit),
      );
    }

    test('should flag forced unwrapping in production code', () async {
      const source = '''
      void main() {
        final String? name = null;
        final value = name!;  // Should flag this
        print(value);
      }
      ''';
      await analyzeCode(source, path: 'lib/example.dart');
      expect(reporter.errors, hasLength(1));
      expect(reporter.errors.first.errorCode.name, equals('forbid_forced_unwrapping'));
    });

    test('should not flag forced unwrapping in test files', () async {
      const source = '''
      void main() {
        test('example', () {
          final String? name = null;
          final value = name!;  // Should not flag this in test files
          expect(value, equals('test'));
        });
      }
      ''';
      await analyzeCode(source, path: 'test/example_test.dart');
      expect(reporter.errors, isEmpty);
    });
  });
}

class TestCustomLintResolver implements CustomLintResolver {
  TestCustomLintResolver(this.unit, this.path);
  final CompilationUnit unit;
  @override
  final String path;

  @override
  Future<ResolvedUnitResult> getResolvedUnitResult() async {
    throw UnimplementedError();
  }

  @override
  LineInfo get lineInfo => throw UnimplementedError();

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