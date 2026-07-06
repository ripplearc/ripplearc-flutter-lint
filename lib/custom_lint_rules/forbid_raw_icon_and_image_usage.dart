import '../core/base_lint_rule.dart';
import '../core/analyzers/forbid_raw_icon_and_image_usage_analyzer.dart';
import '../core/analyzers/base_analyzer.dart';

/// Lint rule that forbids direct usage of raw Flutter icons and [Image.asset].
///
/// Consumers must use [CoreIcons] constants and coreui abstraction components
/// instead. See [ForbidRawIconAndImageUsageAnalyzer] for detection logic.
class ForbidRawIconAndImageUsage extends BaseLintRule {
  ForbidRawIconAndImageUsage()
    : super(BaseLintRule.createLintCode(_analyzer), includeTests: true);

  static final _analyzer = ForbidRawIconAndImageUsageAnalyzer();

  @override
  BaseAnalyzer get analyzer => _analyzer;
}
