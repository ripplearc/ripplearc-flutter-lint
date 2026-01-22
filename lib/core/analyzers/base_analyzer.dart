import 'package:analyzer/dart/ast/ast.dart';
import '../models/lint_issue.dart';

/// The base interface for all custom lint analyzers.
///
/// Implement this to define a custom lint rule. Each analyzer is responsible for
/// analyzing a Dart AST [CompilationUnit] and returning a list of [LintIssue]s
/// that represent violations of the rule.
abstract class BaseAnalyzer {
  /// The unique name of the lint rule implemented by this analyzer.
  String get ruleName;

  /// The main problem message shown when this rule is violated.
  String get problemMessage;

  /// The suggested correction message for fixing a violation of this rule.
  String get correctionMessage;

  /// The severity of the lint rule (e.g., 'ERROR', 'WARNING').
  String get severity => 'ERROR';

  /// Utility to check if a file is a test file (by path).
  ///
  /// Returns true if the file path contains '_test.dart' or is under a 'test/' directory.
  /// Normalizes path separators to work on both Windows and Unix.
  static bool isTestFile(String path) {
    final normalizedPath = path.replaceAll('\\', '/');
    return normalizedPath.contains('_test.dart') ||
        normalizedPath.contains('/test/');
  }

  /// Analyze the given [CompilationUnit] and return a list of [LintIssue]s.
  ///
  /// Implement this method to provide the core logic for your custom lint rule.
  List<LintIssue> analyze(CompilationUnit unit);

  /// Returns true if the file at [path] should be skipped by this analyzer.
  ///
  /// Called before analysis to exclude files or directories from this rule.
  bool shouldSkipFile(String path) {
    return false;
  }

  /// Analyze the given [CompilationUnit] with resolver context and return a list of [LintIssue]s.
  ///
  /// This method provides access to the resolver for file path and other context information.
  /// Default implementation calls analyze(unit) for backward compatibility.
  List<LintIssue> analyzeWithResolver(CompilationUnit unit, dynamic resolver) {
    return analyze(unit);
  }

  /// Helper to create a [LintIssue] from an [AstNode] with consistent formatting.
  ///
  /// Optionally provide a [customMessage] to override the default problem message.
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
