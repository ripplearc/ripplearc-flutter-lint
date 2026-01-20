import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';
import '../utils/documentation_utils.dart';

/// Ensures enums, their values, and extensions on enums have documentation.
///
/// Flags enums, values, and extension members missing documentation comments.
class DocumentEnumAnalyzer extends BaseAnalyzer {
  @override
  String get ruleName => 'document_enum';
  @override
  String get problemMessage =>
      'Enums, their values and extensions must have documentation.';
  @override
  String get correctionMessage =>
      'Add /// documentation for the enum, its values and extensions.';

  @override
  List<LintIssue> analyze(CompilationUnit unit) {
    final visitor = _EnumDocumentationVisitor(this);
    unit.accept(visitor);
    return visitor.issues;
  }
}

class _EnumDocumentationVisitor extends RecursiveAstVisitor<void> {
  final DocumentEnumAnalyzer analyzer;
  final List<LintIssue> issues = [];
  _EnumDocumentationVisitor(this.analyzer);

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    final hasEnumDocumentation = DocumentationUtils.hasDocumentation(
      node.documentationComment,
    );

    if (!hasEnumDocumentation) {
      issues.add(analyzer.createIssue(node));
    }

    for (final constant in node.constants) {
      if (!DocumentationUtils.hasDocumentation(constant.documentationComment)) {
        issues.add(analyzer.createIssue(constant));
      }
    }

    super.visitEnumDeclaration(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    final hasExtensionDocumentation = DocumentationUtils.hasDocumentation(
      node.documentationComment,
    );

    if (!hasExtensionDocumentation) {
      issues.add(analyzer.createIssue(node));
    }

    for (final member in node.members) {
      if (member is MethodDeclaration) {
        if (!member.name.lexeme.startsWith('_')) {
          if (!DocumentationUtils.hasDocumentation(
            member.documentationComment,
          )) {
            issues.add(analyzer.createIssue(member));
          }
        }
      } else if (member is FieldDeclaration) {
        for (final variable in member.fields.variables) {
          if (!variable.name.lexeme.startsWith('_')) {
            if (!DocumentationUtils.hasDocumentation(
              member.documentationComment,
            )) {
              issues.add(analyzer.createIssue(member));
            }
          }
        }
      }
    }

    super.visitExtensionDeclaration(node);
  }
}
