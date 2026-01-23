import '../core/base_lint_rule.dart';
import '../core/analyzers/direct_instantiation_analyzer.dart';
import '../core/analyzers/base_analyzer.dart';

class NoDirectInstantiation extends BaseLintRule {
  NoDirectInstantiation() : super(BaseLintRule.createLintCode(_analyzer), includeTests: true);

  static final _analyzer = DirectInstantiationAnalyzer();

  @override
  BaseAnalyzer get analyzer => _analyzer;
}
