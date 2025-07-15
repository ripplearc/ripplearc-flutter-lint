import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';

class SealedOverDynamicAnalyzer extends BaseAnalyzer {
  @override
  String get ruleName => 'sealed_over_dynamic';

  @override
  String get problemMessage =>
      'Do not use dynamic for sync results. Use a sealed class instead.';

  @override
  String get correctionMessage =>
      'Declare a sealed class and use it for sync results.';

  @override
  List<LintIssue> analyze(CompilationUnit unit) {
    final visitor = _SealedOverDynamicVisitor(this);
    unit.accept(visitor);
    return visitor.issues;
  }
}

class _SealedOverDynamicVisitor extends RecursiveAstVisitor<void> {
  final SealedOverDynamicAnalyzer analyzer;
  final List<LintIssue> issues = [];

  _SealedOverDynamicVisitor(this.analyzer);

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final parent = node.parent;
    if (parent is VariableDeclarationList) {
      final type = parent.type;
      if (type != null && type.toString() == 'dynamic') {
        issues.add(analyzer.createIssue(node));
      }
    }
    super.visitVariableDeclaration(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final left = node.leftHandSide;
    if (left is SimpleIdentifier &&
        left.staticType != null &&
        left.staticType.toString() == 'dynamic') {
      issues.add(analyzer.createIssue(node));
    }
    super.visitAssignmentExpression(node);
  }
}
