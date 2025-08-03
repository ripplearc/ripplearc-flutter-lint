import 'package:analyzer/dart/ast/ast.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';

/// Analyzer that ensures TODO comments include YouTrack story links.
///
/// This rule flags TODO comments that don't include a valid YouTrack URL,
/// ensuring technical debt is properly linked to product backlog items.
///
/// Example of code that triggers this rule:
/// ```dart
/// //TODO: Fix this later  // LINT: Missing YouTrack URL
/// // TODO: Refactor this method  // LINT: Missing YouTrack URL
/// ```
///
/// Example of code that doesn't trigger this rule:
/// ```dart
/// //TODO: https://ripplearc.youtrack.cloud/issue/CA-123
/// // TODO: https://ripplearc.youtrack.cloud/issue/CA-456
/// ```
class TodoWithStoryLinksAnalyzer extends BaseAnalyzer {
  @override
  String get ruleName => 'todo_with_story_links';
  @override
  String get problemMessage =>
      'TODO comments must include a YouTrack story link.';
  @override
  String get correctionMessage =>
      'Add a YouTrack URL after TODO: (e.g., https://ripplearc.youtrack.cloud/issue/CA-123)';
  @override
  String get severity => 'WARNING';

  @override
  List<LintIssue> analyze(CompilationUnit unit) {
    final source = unit.toSource();
    if (source == null) return [];
    final issues = <LintIssue>[];
    final lines = source.split('\n');
    final todoPattern = RegExp(r'//\s*TODO:');
    final youTrackPattern = RegExp(
      r'https://ripplearc\.youtrack\.cloud/issue/[A-Z]+-\d+',
      caseSensitive: false,
    );
    int offset = 0;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (todoPattern.hasMatch(line) && !youTrackPattern.hasMatch(line)) {
        final todoIndex = line.indexOf('TODO:');
        issues.add(
          LintIssue(
            offset: offset + (todoIndex > 0 ? todoIndex - 2 : 0),
            length: line.length - (todoIndex > 0 ? todoIndex - 2 : 0),
            line: i + 1,
            column: (todoIndex > 0 ? todoIndex - 2 : 0) + 1,
            ruleName: ruleName,
            message: problemMessage,
            correctionMessage: correctionMessage,
            severity: severity,
          ),
        );
      }
      offset += line.length + 1;
    }
    return issues;
  }
}
