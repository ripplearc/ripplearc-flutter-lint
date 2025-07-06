import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';
import 'package:ripplearc_flutter_lint/rules/sealed_over_dynamic.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('SealedOverDynamic', () {
    late SealedOverDynamic rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = const SealedOverDynamic();
      reporter = TestErrorReporter();
    });

    Future<void> analyzeCode(String sourceCode) async {
      final parseResult = parseString(content: sourceCode);
      unit = parseResult.unit;
      rule.run(_TestResolver(unit), reporter, _TestContext(unit));
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
      expect(
        reporter.errors.first.errorCode.name,
        equals('sealed_over_dynamic'),
      );
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
