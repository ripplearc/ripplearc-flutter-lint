import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';

class DocumentInterfaceAnalyzer extends BaseAnalyzer {
  @override
  String get ruleName => 'document_interface';
  @override
  String get problemMessage =>
      'Abstract classes and their public methods must have documentation.';
  @override
  String get correctionMessage =>
      'Add /// documentation for the class and its public methods.';

  @override
  List<LintIssue> analyze(CompilationUnit unit) {
    final visitor = _DocumentationVisitor(this);
    unit.accept(visitor);
    return visitor.issues;
  }
}

class _DocumentationVisitor extends RecursiveAstVisitor<void> {
  final DocumentInterfaceAnalyzer analyzer;
  final List<LintIssue> issues = [];
  _DocumentationVisitor(this.analyzer);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (node.abstractKeyword == null) return;
    final hasClassDocumentation = _hasDocumentation(node.documentationComment);
    final undocumentedMethods = <MethodDeclaration>[];
    for (final member in node.members) {
      if (member is MethodDeclaration) {
        if (!member.name.lexeme.startsWith('_')) {
          if (!_hasDocumentation(member.documentationComment)) {
            undocumentedMethods.add(member);
          }
        }
      }
    }
    if (!hasClassDocumentation || undocumentedMethods.isNotEmpty) {
      issues.add(analyzer.createIssue(node));
    }
    super.visitClassDeclaration(node);
  }

  bool _hasDocumentation(Comment? comment) {
    if (comment == null) return false;
    for (final token in comment.tokens) {
      if (token.lexeme.startsWith('///')) {
        final content = token.lexeme.substring(3).trim();
        if (content.isNotEmpty) {
          return true;
        }
      }
    }
    return false;
  }
}
