import '../core/base_lint_rule.dart';
import '../core/analyzers/document_enum_analyzer.dart';
import '../core/analyzers/base_analyzer.dart';

class DocumentEnum extends BaseLintRule {
  DocumentEnum()
    : super(BaseLintRule.createLintCode(_analyzer), includeTests: true);

  static final _analyzer = DocumentEnumAnalyzer();

  @override
  BaseAnalyzer get analyzer => _analyzer;
}
