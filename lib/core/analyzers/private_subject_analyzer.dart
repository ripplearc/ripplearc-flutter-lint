import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';

class PrivateSubjectAnalyzer extends BaseAnalyzer {
  @override
  String get ruleName => 'private_subject';
  @override
  String get problemMessage =>
      'Subject variables must be private to prevent external manipulation.';
  @override
  String get correctionMessage =>
      'Add underscore prefix to make the variable private.';

  @override
  List<LintIssue> analyze(CompilationUnit unit) {
    final visitor = _PrivateSubjectVisitor(this);
    unit.accept(visitor);
    return visitor.issues;
  }
}

class _PrivateSubjectVisitor extends RecursiveAstVisitor<void> {
  final PrivateSubjectAnalyzer analyzer;
  final List<LintIssue> issues = [];
  _PrivateSubjectVisitor(this.analyzer);

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final initializer = node.initializer;
    if (initializer != null) {
      final source = initializer.toSource();
      if (_isSubjectType(source)) {
        final name = node.name.lexeme;
        if (!name.startsWith('_')) {
          issues.add(analyzer.createIssue(node));
        }
      }
    }
    super.visitVariableDeclaration(node);
  }

  bool _isSubjectType(String typeName) {
    final lower = typeName.toLowerCase();
    return lower.contains('behaviorsubject') ||
        lower.contains('replaysubject') ||
        lower.contains('publishsubject') ||
        lower.contains('subject');
  }
}
