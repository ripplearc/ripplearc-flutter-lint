import '../core/base_lint_rule.dart';
import '../core/analyzers/avoid_test_timeouts_analyzer.dart';
import '../core/analyzers/base_analyzer.dart';

class AvoidTestTimeouts extends BaseLintRule {
  AvoidTestTimeouts()
    : super(BaseLintRule.createLintCode(_analyzer), testOnly: true);

  static final _analyzer = AvoidTestTimeoutsAnalyzer();

  @override
  BaseAnalyzer get analyzer => _analyzer;
}
