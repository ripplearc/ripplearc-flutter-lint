import '../core/base_lint_rule.dart';
import '../core/analyzers/base_analyzer.dart';
import '../core/analyzers/forbid_modular_get_outside_module_analyzer.dart';

/// Forbids calling `Modular.get<T>()` outside of module files.
///
/// Classes should receive dependencies through their constructor. The DI container
/// (`Modular.get<T>()`) is only permitted in module registration files
/// (`*_module.dart`), where the object graph is assembled.
///
/// **Exceptions**: 
/// - `Modular.get<T>()` is allowed in files ending with `_module.dart`.
/// - Test files (`test/`) and generated files (`.g.dart`, `.freezed.dart`) are skipped.
class ForbidModularGetOutsideModule extends BaseLintRule {
  ForbidModularGetOutsideModule() : super(BaseLintRule.createLintCode(_analyzer));

  /// The analyzer instance used by this lint rule.
  static final _analyzer = ForbidModularGetOutsideModuleAnalyzer();

  /// Gets the analyzer instance that performs the actual AST traversal and linting logic.
  @override
  BaseAnalyzer get analyzer => _analyzer;
}
