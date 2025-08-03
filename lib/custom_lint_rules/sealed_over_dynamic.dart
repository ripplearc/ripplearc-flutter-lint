import '../core/base_lint_rule.dart';
import '../core/analyzers/sealed_over_dynamic_analyzer.dart';
import '../core/analyzers/base_analyzer.dart';

class SealedOverDynamic extends BaseLintRule {
  SealedOverDynamic() : super(BaseLintRule.createLintCode(_analyzer));

  static final _analyzer = SealedOverDynamicAnalyzer();

  @override
  BaseAnalyzer get analyzer => _analyzer;
}
