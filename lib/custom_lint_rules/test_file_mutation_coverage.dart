import '../core/base_lint_rule.dart';
import '../core/analyzers/test_file_mutation_coverage_analyzer.dart';
import '../core/analyzers/base_analyzer.dart';

class TestFileMutationCoverage extends BaseLintRule {
  TestFileMutationCoverage()
    : super(BaseLintRule.createLintCode(_analyzer), testOnly: true);

  static final _analyzer = TestFileMutationCoverageAnalyzer();

  @override
  BaseAnalyzer get analyzer => _analyzer;
}
