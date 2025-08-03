import '../core/base_lint_rule.dart';
import '../core/analyzers/todo_with_story_links_analyzer.dart';
import '../core/analyzers/base_analyzer.dart';

class TodoWithStoryLinks extends BaseLintRule {
  TodoWithStoryLinks() : super(BaseLintRule.createLintCode(_analyzer));

  static final _analyzer = TodoWithStoryLinksAnalyzer();

  @override
  BaseAnalyzer get analyzer => _analyzer;
}
