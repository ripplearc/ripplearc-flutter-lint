import '../core/base_lint_rule.dart';
import '../core/analyzers/avoid_static_colors_analyzer.dart';
import '../core/analyzers/base_analyzer.dart';

class AvoidStaticColors extends BaseLintRule {
  AvoidStaticColors() : super(BaseLintRule.createLintCode(_analyzer));

  static final _analyzer = AvoidStaticColorsAnalyzer();

  @override
  BaseAnalyzer get analyzer => _analyzer;
}



