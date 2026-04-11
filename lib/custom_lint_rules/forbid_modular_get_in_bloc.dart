import '../core/base_lint_rule.dart';
import '../core/analyzers/base_analyzer.dart';
import '../core/analyzers/forbid_modular_get_in_bloc_analyzer.dart';

/// Forbids calling `Modular.get<T>()` inside BLoC files.
///
/// BLoCs must receive dependencies through their constructor. The DI container
/// (`Modular.get<T>()`) is only permitted in module registration files
/// (`*_module.dart`), where the object graph is assembled.
///
/// **Exception**: `Modular.get<T>()` is allowed in files ending with
/// `_module.dart`.
class ForbidModularGetInBloc extends BaseLintRule {
  ForbidModularGetInBloc() : super(BaseLintRule.createLintCode(_analyzer));

  static final _analyzer = ForbidModularGetInBlocAnalyzer();

  @override
  BaseAnalyzer get analyzer => _analyzer;
}
