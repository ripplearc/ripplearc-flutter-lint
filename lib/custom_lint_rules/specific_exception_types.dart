import '../core/base_lint_rule.dart';
import '../core/analyzers/specific_exception_types_analyzer.dart';
import '../core/analyzers/base_analyzer.dart';

class SpecificExceptionTypes extends BaseLintRule {
  SpecificExceptionTypes() : super(BaseLintRule.createLintCode(_analyzer));

  static final _analyzer = SpecificExceptionTypesAnalyzer();

  @override
  BaseAnalyzer get analyzer => _analyzer;
}
