import '../core/base_lint_rule.dart';
import '../core/analyzers/document_fake_parameters_analyzer.dart';
import '../core/analyzers/base_analyzer.dart';

class DocumentFakeParameters extends BaseLintRule {
  DocumentFakeParameters() : super(BaseLintRule.createLintCode(_analyzer));

  static final _analyzer = DocumentFakeParametersAnalyzer();

  @override
  BaseAnalyzer get analyzer => _analyzer;
}
