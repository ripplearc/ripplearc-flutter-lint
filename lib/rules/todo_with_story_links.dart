import 'dart:io';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that ensures TODO comments include YouTrack story links.
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
class TodoWithStoryLinks extends DartLintRule {
  const TodoWithStoryLinks() : super(code: _code);

  static const _code = LintCode(
    name: 'todo_with_story_links',
    problemMessage: 'TODO comments must include a YouTrack story link.',
    correctionMessage:
        'Add a YouTrack URL after TODO: (e.g., https://ripplearc.youtrack.cloud/issue/CA-123)',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) async {
    // Skip test files
    if (_isTestFile(resolver.path)) return;

    String source;
    try {
      final file = File(resolver.path);
      if (await file.exists()) {
        source = await file.readAsString();
      } else {
        // For test environments where file doesn't exist on disk
        return;
      }
    } catch (e) {
      // If file reading fails, skip this file
      return;
    }

    checkSourceForTodoComments(source, reporter);
  }

  /// Check source code for TODO comments without YouTrack URLs.
  /// This method is exposed for testing purposes.
  void checkSourceForTodoComments(String source, ErrorReporter reporter) {
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
        // Report at the start of the TODO comment
        final todoIndex = line.indexOf('TODO:');
        reporter.atOffset(
          offset: offset + (todoIndex > 0 ? todoIndex - 2 : 0),
          length: line.length - (todoIndex > 0 ? todoIndex - 2 : 0),
          errorCode: _code,
        );
      }
      offset += line.length + 1; // +1 for the newline
    }
  }

  bool _isTestFile(String path) {
    return path.contains('_test.dart') || path.contains('/test/');
  }
}
