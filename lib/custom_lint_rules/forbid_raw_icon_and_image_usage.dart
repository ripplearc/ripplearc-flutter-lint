import '../core/base_lint_rule.dart';
import '../core/analyzers/forbid_raw_icon_and_image_usage_analyzer.dart';
import '../core/analyzers/base_analyzer.dart';

class ForbidRawIconAndImageUsage extends BaseLintRule {
  ForbidRawIconAndImageUsage()
    : super(BaseLintRule.createLintCode(_analyzer), includeTests: true);

  static final _analyzer = ForbidRawIconAndImageUsageAnalyzer();

  @override
  BaseAnalyzer get analyzer => _analyzer;
}
