import '../core/base_lint_rule.dart';
import '../core/analyzers/private_subject_analyzer.dart';
import '../core/analyzers/base_analyzer.dart';

class PrivateSubject extends BaseLintRule {
  PrivateSubject() : super(BaseLintRule.createLintCode(_analyzer));

  static final _analyzer = PrivateSubjectAnalyzer();

  @override
  BaseAnalyzer get analyzer => _analyzer;
}
