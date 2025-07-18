import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';

/// Analyzer that enforces the use of specific exception types instead of generic Exception.
///
/// This analyzer flags any code that throws a generic [Exception] or uses a private
/// exception factory (such as `_createException`). The goal is to encourage the use
/// of meaningful, specific exception classes (e.g., `AppException`, `ServerException`)
/// to improve error handling and debugging.
///
/// The rule triggers on:
///   - `throw Exception(...)`
///   - `throw _createException(...)` (by function, method, or identifier)
///
/// To fix a violation, define and throw a custom exception class that implements [Exception].
class SpecificExceptionTypesAnalyzer extends BaseAnalyzer {
  @override
  String get ruleName => 'specific_exception_types';
  @override
  String get problemMessage =>
      'Throwing generic Exception is not allowed. Use a specific exception type.';
  @override
  String get correctionMessage =>
      'Throw a class that implements Exception, e.g., AppException or ServerException.';

  @override
  List<LintIssue> analyze(CompilationUnit unit) {
    final visitor = _SpecificExceptionTypesVisitor(this);
    unit.accept(visitor);
    return visitor.issues;
  }
}

class _SpecificExceptionTypesVisitor extends RecursiveAstVisitor<void> {
  final SpecificExceptionTypesAnalyzer analyzer;
  final List<LintIssue> issues = [];
  _SpecificExceptionTypesVisitor(this.analyzer);

  @override
  void visitThrowExpression(ThrowExpression node) {
    final expression = node.expression;
    if (expression is InstanceCreationExpression) {
      final typeName = expression.constructorName.type.name2.lexeme;
      if (typeName == 'Exception') {
        issues.add(analyzer.createIssue(node));
      }
    }
    if (expression is FunctionExpressionInvocation) {
      final functionName = expression.function.toSource().trim();
      if (functionName == '_createException') {
        issues.add(analyzer.createIssue(node));
      }
    }
    if (expression is MethodInvocation) {
      final methodName = expression.methodName.name;
      if (methodName == '_createException') {
        issues.add(analyzer.createIssue(node));
      }
    }
    if (expression is SimpleIdentifier) {
      final identifierName = expression.name;
      if (identifierName == '_createException') {
        issues.add(analyzer.createIssue(node));
      }
    }
    super.visitThrowExpression(node);
  }
}
