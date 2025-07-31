import '../core/base_lint_rule.dart';
import '../core/analyzers/no_optional_operators_in_tests_analyzer.dart';
import '../core/analyzers/base_analyzer.dart';

class NoOptionalOperatorsInTests extends BaseLintRule {
  NoOptionalOperatorsInTests() : super(BaseLintRule.createLintCode(_analyzer));

  static final _analyzer = NoOptionalOperatorsInTestsAnalyzer();

  @override
  BaseAnalyzer get analyzer => _analyzer;
}
