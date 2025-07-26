import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';

/// Analyzer that ensures Fake classes and their non-private members have documentation.
///
/// This rule flags Fake classes (classes that extend Fake or have "Fake" in their name)
/// that implement interfaces but lack proper documentation for their test helper methods
/// and variables. It improves test maintainability and ensures test helpers are documented
/// for team collaboration.
///
/// Example of code that triggers this rule:
/// ```dart
/// class FakeAuthService extends Fake implements AuthService {
///   void setAuthDelay(Duration delay) { ... }  // Missing documentation
///   void triggerAuthFailure() { ... }          // Missing documentation
/// }
///
/// class FakeUserRepository implements UserRepository {
///   void setMockData(List<User> users) { ... }  // Missing documentation
/// }
/// ```
///
/// Example of code that doesn't trigger this rule:
/// ```dart
/// /// Fake implementation of AuthService for testing.
/// class FakeAuthService extends Fake implements AuthService {
///   /// Sets authentication delay for testing timing scenarios.
///   void setAuthDelay(Duration delay) { ... }
///
///   /// Simulates authentication failure for error handling tests.
///   void triggerAuthFailure() { ... }
///
///   @override
///   Future<void> authenticate() async { ... }  // Override - no documentation needed
/// }
/// ```
class DocumentFakeParametersAnalyzer extends BaseAnalyzer {
  @override
  String get ruleName => 'document_fake_parameters';
  @override
  String get problemMessage =>
      'Fake classes and their non-private members must have documentation.';
  @override
  String get correctionMessage =>
      'Add /// documentation for the class and its non-private members.';

  @override
  List<LintIssue> analyze(CompilationUnit unit) {
    final visitor = _FakeDocumentationVisitor(this);
    unit.accept(visitor);
    return visitor.issues;
  }
}

class _FakeDocumentationVisitor extends RecursiveAstVisitor<void> {
  final DocumentFakeParametersAnalyzer analyzer;
  final List<LintIssue> issues = [];
  _FakeDocumentationVisitor(this.analyzer);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!_isFakeClass(node) || !_implementsInterface(node)) return;
    final hasClassDocumentation = _hasDocumentation(node.documentationComment);
    final undocumentedMembers = <AstNode>[];
    for (final member in node.members) {
      if (_shouldCheckMember(member)) {
        if (!_hasDocumentation(member.documentationComment)) {
          undocumentedMembers.add(member);
        }
      }
    }
    if (!hasClassDocumentation || undocumentedMembers.isNotEmpty) {
      issues.add(analyzer.createIssue(node));
    }
    super.visitClassDeclaration(node);
  }

  bool _isFakeClass(ClassDeclaration node) {
    return node.name.lexeme.startsWith('Fake');
  }

  bool _implementsInterface(ClassDeclaration node) {
    final implementsClause = node.implementsClause;
    return implementsClause != null && implementsClause.interfaces.isNotEmpty;
  }

  bool _shouldCheckMember(ClassMember member) {
    if (member is MethodDeclaration && member.name.lexeme.startsWith('_')) {
      return false;
    }
    if (member is FieldDeclaration) {
      for (final field in member.fields.variables) {
        if (field.name.lexeme.startsWith('_')) {
          return false;
        }
      }
    }
    if (member is MethodDeclaration &&
        member.metadata.any((m) => m.name.name == 'override')) {
      return false;
    }
    if (member is MethodDeclaration && (member.isGetter || member.isSetter)) {
      return false;
    }
    return true;
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
