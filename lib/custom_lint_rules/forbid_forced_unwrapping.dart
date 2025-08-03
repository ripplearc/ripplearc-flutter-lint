import '../core/base_lint_rule.dart';
import '../core/analyzers/forced_unwrapping_analyzer.dart';
import '../core/analyzers/base_analyzer.dart';

class ForbidForcedUnwrapping extends BaseLintRule {
  ForbidForcedUnwrapping() : super(BaseLintRule.createLintCode(_analyzer));

  static final _analyzer = ForcedUnwrappingAnalyzer();

  @override
  BaseAnalyzer get analyzer => _analyzer;
}
