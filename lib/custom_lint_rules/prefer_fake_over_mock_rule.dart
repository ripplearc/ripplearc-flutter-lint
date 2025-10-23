import '../core/base_lint_rule.dart';
import '../core/analyzers/prefer_fake_over_mock_analyzer.dart';
import '../core/analyzers/base_analyzer.dart';

class PreferFakeOverMockRule extends BaseLintRule {
  PreferFakeOverMockRule() : super(BaseLintRule.createLintCode(_analyzer), testOnly: true);

  static final _analyzer = PreferFakeOverMockAnalyzer();

  @override
  BaseAnalyzer get analyzer => _analyzer;
}
