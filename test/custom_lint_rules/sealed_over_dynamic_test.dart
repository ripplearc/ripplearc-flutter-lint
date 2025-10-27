import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';
import 'package:ripplearc_lint_rules/custom_lint_rules/sealed_over_dynamic.dart';
import '../utils/custom_lint_resolver.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('SealedOverDynamic', () {
    late SealedOverDynamic rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = SealedOverDynamic();
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

    test('flags dynamic sync result', () async {
      const source = '''
      void main() async {
        dynamic syncResult = await powersync.execute('query');
      }
      final powersync = _PowerSync();
      class _PowerSync {
        Future<dynamic> execute(String query) async => null;
      }
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isNotEmpty);
    });

    test('allows sealed class sync result', () async {
      const source = '''
      sealed class SyncResult {}
      void main() async {
        SyncResult result = await powersync.execute('query');
      }
      final powersync = _PowerSync();
      class _PowerSync {
        Future<SyncResult> execute(String query) async => SyncResultImpl();
      }
      class SyncResultImpl extends SyncResult {}
      ''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });
  });
}
