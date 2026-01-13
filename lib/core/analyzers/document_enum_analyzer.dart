import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';

/// Analyzer that ensures enums and their values have documentation.
///
/// This rule flags enums that are missing proper documentation comments.
/// It ensures clear documentation for all enum types and their values.
///
/// Example of code that triggers this rule:
/// ```dart
/// enum Status {  // Missing enum documentation
///   active,      // Missing value documentation
///   inactive,    // Missing value documentation
/// }
/// ```
///
/// Example of code that doesn't trigger this rule:
/// ```dart
/// /// Represents the current status of an item.
/// enum Status {
///   /// The item is currently active.
///   active,
///   /// The item is inactive.
///   inactive,
/// }
/// ```
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
    // Check if enum has documentation
    final hasEnumDocumentation = _hasDocumentation(node.documentationComment);

    // Report error if enum lacks documentation
    if (!hasEnumDocumentation) {
      issues.add(analyzer.createIssue(node));
    }

    // Check each enum constant for documentation
    for (final constant in node.constants) {
      if (!_hasDocumentation(constant.documentationComment)) {
        issues.add(analyzer.createIssue(constant));
      }
    }

    super.visitEnumDeclaration(node);
  }

  bool _hasDocumentation(Comment? comment) {
    if (comment == null) return false;

    // Check for /// documentation (not /** */ or //)
    for (final token in comment.tokens) {
      if (token.lexeme.startsWith('///')) {
        // Check if there's actual content (not just ///)
        final content = token.lexeme.substring(3).trim();
        if (content.isNotEmpty) {
          return true;
        }
      }
    }

    return false;
  }
}
