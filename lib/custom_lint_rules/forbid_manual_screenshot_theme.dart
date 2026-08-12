import '../core/base_lint_rule.dart';
import '../core/analyzers/forbid_manual_screenshot_theme_analyzer.dart';
import '../core/analyzers/base_analyzer.dart';

/// Lint rule that forbids the manual dual-theme pattern in screenshot tests.
///
/// Flags [ThemeData?] nullable parameters and hard-coded `_dark.png` suffixes
/// in `matchesGoldenFile` calls inside `*_screenshot_test.dart` files.
/// Use `screenshotThemeGroups` instead. See [ForbidManualScreenshotThemeAnalyzer]
/// for detection logic.
class ForbidManualScreenshotTheme extends BaseLintRule {
  ForbidManualScreenshotTheme()
    : super(BaseLintRule.createLintCode(_analyzer), testOnly: true);
  // testOnly: true so BaseLintRule.run() passes test files through to the
  // analyzer; shouldSkipFile then narrows scope to *_screenshot_test.dart only.

  static final _analyzer = ForbidManualScreenshotThemeAnalyzer();

  @override
  BaseAnalyzer get analyzer => _analyzer;
}
