import '../core/base_lint_rule.dart';
import '../core/analyzers/document_interface_analyzer.dart';
import '../core/analyzers/base_analyzer.dart';

class DocumentInterface extends BaseLintRule {
  DocumentInterface() : super(BaseLintRule.createLintCode(_analyzer));

  static final _analyzer = DocumentInterfaceAnalyzer();

  @override
  BaseAnalyzer get analyzer => _analyzer;
}
