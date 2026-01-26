import '../core/base_lint_rule.dart';
import '../core/analyzers/avoid_static_typography_analyzer.dart';
import '../core/analyzers/base_analyzer.dart';

class AvoidStaticTypography extends BaseLintRule {
  AvoidStaticTypography()
    : super(BaseLintRule.createLintCode(_analyzer), includeTests: true);

  static final _analyzer = AvoidStaticTypographyAnalyzer();

  @override
  BaseAnalyzer get analyzer => _analyzer;
}

