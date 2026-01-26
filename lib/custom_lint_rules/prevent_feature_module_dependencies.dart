import '../core/base_lint_rule.dart';
import '../core/analyzers/prevent_feature_module_dependencies_analyzer.dart';
import '../core/analyzers/base_analyzer.dart';

/// Lint rule that prevents feature modules from depending on other feature modules.
///
/// This rule enforces architectural modularity by ensuring that each feature
/// module is independent and does not depend on other feature modules. Features
/// can only depend on core, shared, or external packages.
class PreventFeatureModuleDependencies extends BaseLintRule {
  PreventFeatureModuleDependencies()
    : super(BaseLintRule.createLintCode(_analyzer), includeTests: true);

  static final _analyzer = FeatureModuleIsolationAnalyzer();

  @override
  BaseAnalyzer get analyzer => _analyzer;
}
