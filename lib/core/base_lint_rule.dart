import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'analyzers/base_analyzer.dart';

/// Abstract base class for custom lint rules that use analyzers.
///
/// This class provides a common implementation for integrating analyzers
/// with custom lint rules, reducing code duplication across rule implementations.
///
/// Subclasses should:
/// 1. Extend this class
/// 2. Implement the analyzer getter
/// 3. Create their own LintCode in the constructor
abstract class BaseLintRule extends DartLintRule {
  BaseLintRule(LintCode code, {bool testOnly = false})
    : _testOnly = testOnly,
      super(code: code);

  /// Whether this rule should only run on test files (true) or skip test files (false).
  final bool _testOnly;

  /// The analyzer instance that implements the lint logic.
  BaseAnalyzer get analyzer;

  /// Helper method to create a LintCode from an analyzer.
  static LintCode createLintCode(BaseAnalyzer analyzer) {
    return LintCode(
      name: analyzer.ruleName,
      problemMessage: analyzer.problemMessage,
      correctionMessage: analyzer.correctionMessage,
      errorSeverity: ErrorSeverity.ERROR,
    );
  }

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final isTestFile = BaseAnalyzer.isTestFile(resolver.path);

    // Skip based on test file preference
    if (_testOnly && !isTestFile) return;
    if (!_testOnly && isTestFile) return;

    context.registry.addCompilationUnit((node) {
      // Use shared analyzer
      final issues = analyzer.analyze(node);

      // Report issues to custom_lint
      for (final issue in issues) {
        reporter.atOffset(
          offset: issue.offset,
          length: issue.length,
          errorCode: code,
        );
      }
    });
  }
}
