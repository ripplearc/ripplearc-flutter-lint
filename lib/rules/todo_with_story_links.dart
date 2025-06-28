import 'dart:convert';
import 'package:analyzer/dart/ast/ast.dart';
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
  ) {
    context.registry.addCompilationUnit((node) {
      if (_isTestFile(resolver.path)) return;
      final source = node.toSource();
      final lines = const LineSplitter().convert(source);
      int offset = 0;
      for (final line in lines) {
        final trimmed = line.trim();
        if (_isTodoComment(trimmed) && !_hasYouTrackUrl(trimmed)) {
          reporter.atOffset(
            offset: offset + line.indexOf('//'),
            length: line.length - line.indexOf('//'),
            errorCode: TodoWithStoryLinks._code,
          );
        }
        offset += line.length + 1; // +1 for newline
      }
    });
  }

  bool _isTestFile(String path) {
    return path.contains('_test.dart') ||
        path.contains('/test/') ||
        path.contains('/example/') ||
        path.contains('example_');
  }

  bool _isTodoComment(String line) {
    return line.startsWith('//TODO:') || line.startsWith('// TODO:');
  }

  bool _hasYouTrackUrl(String line) {
    // YouTrack URL pattern: https://ripplearc.youtrack.cloud/issue/PROJECT-123
    final youTrackPattern = RegExp(
      r'https://ripplearc\.youtrack\.cloud/issue/[A-Z]+-\d+',
      caseSensitive: false,
    );

    return youTrackPattern.hasMatch(line);
  }
}
