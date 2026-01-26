import '../core/base_lint_rule.dart';
import '../core/analyzers/forbid_helper_util_naming_analyzer.dart';
import '../core/analyzers/base_analyzer.dart';

/// Lint rule that forbids class names containing 'Helper' or 'Util'.
///
/// This rule applies to both production code (lib/) and test code (test/)
/// to encourage more descriptive, domain-specific class names throughout
/// the codebase.
class ForbidHelperUtilNaming extends BaseLintRule {
  ForbidHelperUtilNaming()
    : super(BaseLintRule.createLintCode(_analyzer), includeTests: true);

  static final _analyzer = ForbidHelperUtilNamingAnalyzer();

  @override
  BaseAnalyzer get analyzer => _analyzer;
}
