import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import '../core/analyzers/prefer_fake_over_mock_analyzer.dart';
import '../core/analyzers/base_analyzer.dart';

class PreferFakeOverMockRule extends DartLintRule {
  PreferFakeOverMockRule() : super(code: _code);

  static final _analyzer = PreferFakeOverMockAnalyzer();
  static final _code = LintCode(
    name: _analyzer.ruleName,
    problemMessage: _analyzer.problemMessage,
    correctionMessage: _analyzer.correctionMessage,
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (BaseAnalyzer.isTestFile(resolver.path)) return;
    context.registry.addCompilationUnit((node) {
      final issues = _analyzer.analyze(node);
      for (final issue in issues) {
        reporter.atOffset(
          offset: issue.offset,
          length: issue.length,
          errorCode: _code,
        );
      }
    });
  }
}
