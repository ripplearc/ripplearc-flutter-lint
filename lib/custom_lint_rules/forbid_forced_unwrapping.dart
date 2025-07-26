import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import '../core/analyzers/forced_unwrapping_analyzer.dart';
import '../core/analyzers/base_analyzer.dart';

class ForbidForcedUnwrapping extends DartLintRule {
  ForbidForcedUnwrapping() : super(code: _code);

  static final _analyzer = ForcedUnwrappingAnalyzer();

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
    // Skip test files using shared logic
    if (BaseAnalyzer.isTestFile(resolver.path)) return;

    context.registry.addCompilationUnit((node) {
      // Use shared analyzer
      final issues = _analyzer.analyze(node);

      // Report issues to custom_lint
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
