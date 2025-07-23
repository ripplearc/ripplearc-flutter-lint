import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';

/// Analyzer that forbids using optional operators (?., ??) in test files.
///
/// This rule flags optional operators in test blocks to ensure tests fail explicitly
/// at the point of failure rather than silently handling nulls.
///
/// Example of code that triggers this rule:
/// ```dart
/// test('example', () {
///   final result = someObject?.someProperty;  // LINT
///   final value = someValue ?? defaultValue;  // LINT
/// });
/// ```
///
/// Example of code that doesn't trigger this rule:
/// ```dart
/// test('example', () {
///   expect(someObject, isNotNull);
///   final result = someObject.someProperty;
///   expect(someValue, isNotNull);
///   final value = someValue;
///   final assertion = someValue!;  // This is fine
/// });
/// ```
class NoOptionalOperatorsInTestsAnalyzer extends BaseAnalyzer {
  @override
  String get ruleName => 'no_optional_operators_in_tests';
  @override
  String get problemMessage =>
      'Optional operators (?., ??) are not allowed in test blocks. Tests should fail explicitly at the point of failure.';
  @override
  String get correctionMessage =>
      'Remove the optional operator and add an explicit null check if needed.';

  @override
  List<LintIssue> analyze(CompilationUnit unit) {
    final visitor = _OptionalOperatorVisitor(this);
    unit.accept(visitor);
    return visitor.issues;
  }
}

class _OptionalOperatorVisitor extends RecursiveAstVisitor<void> {
  final NoOptionalOperatorsInTestsAnalyzer analyzer;
  final List<LintIssue> issues = [];
  bool _isInTestBlock = false;
  bool _isInSetupOrTeardown = false;
  _OptionalOperatorVisitor(this.analyzer);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    if (name == 'test' || name == 'group') {
      _isInTestBlock = true;
      super.visitMethodInvocation(node);
      _isInTestBlock = false;
    } else if (name == 'setUp' || name == 'tearDown') {
      _isInSetupOrTeardown = true;
      super.visitMethodInvocation(node);
      _isInSetupOrTeardown = false;
    } else {
      if (_isInTestBlock &&
          !_isInSetupOrTeardown &&
          node.operator?.type == TokenType.QUESTION_PERIOD) {
        issues.add(analyzer.createIssue(node));
      }
      super.visitMethodInvocation(node);
    }
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (_isInTestBlock &&
        !_isInSetupOrTeardown &&
        node.operator.type == TokenType.QUESTION_PERIOD) {
      issues.add(analyzer.createIssue(node));
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (_isInTestBlock &&
        !_isInSetupOrTeardown &&
        node.operator.type == TokenType.QUESTION_QUESTION) {
      issues.add(analyzer.createIssue(node));
    }
    super.visitBinaryExpression(node);
  }
}
