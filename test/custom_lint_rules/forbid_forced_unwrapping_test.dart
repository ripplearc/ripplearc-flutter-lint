import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:ripplearc_linter/custom_lint_rules/forbid_forced_unwrapping.dart';
import 'package:test/test.dart';
import '../utils/custom_lint_resolver.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('ForbidForcedUnwrapping', () {
    late ForbidForcedUnwrapping rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = ForbidForcedUnwrapping();
      reporter = TestErrorReporter();
    });

    Future<void> analyzeCode(String sourceCode, {required String path}) async {
      final parseResult = parseString(content: sourceCode);
      unit = parseResult.unit;
      rule.run(
        TestCustomLintResolver(unit, path: path),
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
      expect(reporter.errors, isNotEmpty);
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

    test(
      'should not flag forced unwrapping in /testing/ with fake in the path',
      () async {
        const source = '''
      void main() {
        final String? name = null;
        final value = name!;  // Should not flag this in /testing/**/fake* files
        print(value);
      }
      ''';
        await analyzeCode(source, path: 'lib/testing/fake_user.dart');
        expect(reporter.errors, isNotEmpty);
      },
    );

    test(
      'should not flag forced unwrapping in freezed-generated files',
      () async {
        const source = '''
      void main() {
        final String? name = null;
        final value = name!;  // Should not flag this in *.freezed.dart files
        print(value);
      }
      ''';
        await analyzeCode(source, path: 'lib/models/user.freezed.dart');
        expect(reporter.errors, isNotEmpty);
      },
    );

    test(
      'should not flag forced unwrapping in json_serializable-generated .g.dart files',
      () async {
        const source = '''
      void main() {
        final String? name = null;
        final value = name!;  // Should not flag this in *.g.dart files
        print(value);
      }
      ''';
        await analyzeCode(source, path: 'lib/models/auth_state.g.dart');
        expect(reporter.errors, isNotEmpty);
      },
    );
  });
}
