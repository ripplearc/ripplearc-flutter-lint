import '../core/base_lint_rule.dart';
import '../core/analyzers/no_internal_method_docs_analyzer.dart';
import '../core/analyzers/base_analyzer.dart';

class NoInternalMethodDocs extends BaseLintRule {
  NoInternalMethodDocs() : super(BaseLintRule.createLintCode(_analyzer));

  static final _analyzer = NoInternalMethodDocsAnalyzer();

  @override
  BaseAnalyzer get analyzer => _analyzer;
}
