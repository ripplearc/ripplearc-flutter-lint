import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';

/// Analyzer that forbids using forced unwrapping (`!`) in production code.
///
/// This rule flags forced unwrapping operators to ensure null values are handled
/// explicitly using null-safe alternatives like null coalescing (`??`) or explicit
/// null checks. This helps prevent runtime crashes and makes the code more robust.
///
/// Example of code that triggers this rule:
/// ```dart
/// final name = user.name!;  // Will crash if name is null
/// print('User: $name');
/// ```
///
/// Example of code that doesn't trigger this rule:
/// ```dart
/// final name = user.name ?? 'Unknown';  // Safe with default value
/// print('User: $name');
///
/// if (user.name != null) {
///   final checkedName = user.name;  // Safe after null check
///   print('User: $checkedName');
/// }
/// ```
class ForcedUnwrappingAnalyzer extends BaseAnalyzer {
  @override
  String get ruleName => 'forbid_forced_unwrapping';

  @override
  String get problemMessage =>
      'Forced unwrapping (!) is not allowed in production code.';

  @override
  String get correctionMessage =>
      'Use null-safe alternatives like null coalescing (??) or explicit null checks.';

  @override
  List<LintIssue> analyze(CompilationUnit unit) {
    final visitor = _ForcedUnwrappingVisitor(this);
    unit.accept(visitor);
    return visitor.issues;
  }
}

class _ForcedUnwrappingVisitor extends RecursiveAstVisitor<void> {
  final ForcedUnwrappingAnalyzer analyzer;
  final List<LintIssue> issues = [];

  _ForcedUnwrappingVisitor(this.analyzer);

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (node.operator.type == TokenType.BANG) {
      issues.add(analyzer.createIssue(node));
    }
    super.visitPostfixExpression(node);
  }
}
