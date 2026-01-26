import '../core/base_lint_rule.dart';
import '../core/analyzers/prevent_library_module_dependencies_analyzer.dart';
import '../core/analyzers/base_analyzer.dart';

/// Lint rule that prevents library modules from depending on feature modules.
///
/// This rule enforces architectural modularity by ensuring that library
/// modules remain reusable and do not have feature-specific dependencies.
/// Libraries can only depend on other libraries, core packages, or external packages.
class PreventLibraryModuleDependencies extends BaseLintRule {
  PreventLibraryModuleDependencies()
    : super(BaseLintRule.createLintCode(_analyzer), includeTests: true);

  static final _analyzer = LibraryModuleDependenciesAnalyzer();

  @override
  BaseAnalyzer get analyzer => _analyzer;
}
