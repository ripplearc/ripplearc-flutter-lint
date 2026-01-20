import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';
import '../utils/documentation_utils.dart';

/// Ensures enums and their values have documentation.
///
/// Flags enums and values missing documentation comments.
class DocumentEnumAnalyzer extends BaseAnalyzer {
  @override
  String get ruleName => 'document_enum';
  @override
  String get problemMessage =>
      'Enums and their values must have documentation.';
  @override
  String get correctionMessage =>
      'Add /// documentation for the enum and its values.';

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
}
