import '../core/base_lint_rule.dart';
import '../core/analyzers/avoid_static_colors_agent_test_analyzer.dart';
import '../core/analyzers/base_analyzer.dart';

/// Enforces theme-context-based color access for proper light/dark mode support.
///
/// This rule flags static color usage that breaks theme switching (e.g. `Colors.white`,
/// `CoreTextColors.headline`, `Color(0xFF...)`). Use
/// `Theme.of(context).extension<AppColorsExtension>()` instead.
///
/// Example of code that triggers this rule:
/// ```dart
/// // Static CoreUI tokens
/// Text(style: TextStyle(color: CoreTextColors.headline));
///
/// // Flutter Colors class
/// Container(color: Colors.white);
/// Container(color: Colors.grey[700]);
///
/// // CupertinoColors
/// Container(color: CupertinoColors.systemRed);
///
/// // Direct Color definitions
/// Container(color: Color(0xFF015B7C));
/// Container(color: Color.fromARGB(255, 0, 0, 0));
///
/// // Prefixed imports
/// Container(color: material.Colors.red);
/// ```
///
/// Example of correct usage:
/// ```dart
/// final colors = Theme.of(context).extension<AppColorsExtension>()!;
///
/// Text(style: TextStyle(color: colors.textHeadline));
/// Container(color: colors.pageBackground);
/// Container(color: colors.lineLight);
/// ```
class AvoidStaticColorsAgentTest extends BaseLintRule {
  AvoidStaticColorsAgentTest()
      : super(BaseLintRule.createLintCode(_analyzer), includeTests: true);

  static final _analyzer = AvoidStaticColorsAgentTestAnalyzer();

  @override
  BaseAnalyzer get analyzer => _analyzer;
}
