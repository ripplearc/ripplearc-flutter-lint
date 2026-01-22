import '../core/base_lint_rule.dart';
import '../core/analyzers/restrict_core_icon_data_analyzer.dart';
import '../core/analyzers/base_analyzer.dart';

class RestrictCoreIconData extends BaseLintRule {
  RestrictCoreIconData()
    : super(BaseLintRule.createLintCode(_analyzer), bothFiles: true);

  static final _analyzer = RestrictCoreIconDataAnalyzer();

  @override
  BaseAnalyzer get analyzer => _analyzer;
}
