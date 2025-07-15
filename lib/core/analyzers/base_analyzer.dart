import 'package:analyzer/dart/ast/ast.dart';
import '../models/lint_issue.dart';

abstract class BaseAnalyzer {
  String get ruleName;
  String get problemMessage;
  String get correctionMessage;
  String get severity => 'ERROR';

  /// Common utility to check if a file is a test file
  static bool isTestFile(String path) {
    return path.contains('_test.dart') || path.contains('/test/');
  }

  /// Core analysis method - implement rule-specific logic
  List<LintIssue> analyze(CompilationUnit unit);

  /// Helper to create issues with consistent formatting
  LintIssue createIssue(AstNode node, {String? customMessage}) {
    final root = node.root;
    final lineInfo = root is CompilationUnit ? root.lineInfo : null;
    final location = lineInfo?.getLocation(node.offset);

    return LintIssue(
      offset: node.offset,
      length: node.length,
      line: location?.lineNumber ?? 0,
      column: location?.columnNumber ?? 0,
      ruleName: ruleName,
      message: customMessage ?? problemMessage,
      correctionMessage: correctionMessage,
      severity: severity,
    );
  }
}
