import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that ensures Fake classes and their non-private members have documentation.
///
/// This rule flags Fake classes that implement interfaces but lack proper documentation
/// for their test helper methods and variables. It improves test maintainability and
/// ensures test helpers are documented for team collaboration.
///
/// Example of code that triggers this rule:
/// ```dart
/// class FakeAuthService extends Fake implements AuthService {
///   void setAuthDelay(Duration delay) { ... }  // Missing documentation
///   void triggerAuthFailure() { ... }          // Missing documentation
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
class DocumentFakeParameters extends DartLintRule {
  const DocumentFakeParameters() : super(code: _code);

  static const _code = LintCode(
    name: 'document_fake_parameters',
    problemMessage:
        'Fake classes and their non-private members must have documentation.',
    correctionMessage:
        'Add /// documentation for the class and its non-private members.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((node) {
      if (_isTestFile(resolver.path)) return;
      _checkForDocumentation(node, reporter);
    });
  }

  bool _isTestFile(String path) {
    return path.contains('_test.dart') || path.contains('/test/');
  }

  void _checkForDocumentation(CompilationUnit node, ErrorReporter reporter) {
    final visitor = _FakeDocumentationVisitor(reporter);
    node.accept(visitor);
  }
}

class _FakeDocumentationVisitor extends RecursiveAstVisitor<void> {
  _FakeDocumentationVisitor(this.reporter);

  final ErrorReporter reporter;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // Only check classes that extend Fake and implement interfaces
    if (!_extendsFake(node) || !_implementsInterface(node)) return;

    // Check if class has documentation
    final hasClassDocumentation = _hasDocumentation(node.documentationComment);

    // Check non-private members for documentation
    final undocumentedMembers = <AstNode>[];

    for (final member in node.members) {
      if (_shouldCheckMember(member)) {
        if (!_hasDocumentation(member.documentationComment)) {
          undocumentedMembers.add(member);
        }
      }
    }

    // Report error if class or any non-private member lacks documentation
    if (!hasClassDocumentation || undocumentedMembers.isNotEmpty) {
      reporter.atNode(node, DocumentFakeParameters._code);
    }

    super.visitClassDeclaration(node);
  }

  bool _extendsFake(ClassDeclaration node) {
    final extendsClause = node.extendsClause;
    if (extendsClause == null) return false;

    final superclass = extendsClause.superclass;
    return superclass.name2.lexeme == 'Fake';
  }

  bool _implementsInterface(ClassDeclaration node) {
    final implementsClause = node.implementsClause;
    return implementsClause != null && implementsClause.interfaces.isNotEmpty;
  }

  bool _shouldCheckMember(ClassMember member) {
    // Skip private members
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

    // Skip methods with @override annotation (interface method overrides)
    if (member is MethodDeclaration &&
        member.metadata.any((m) => m.name.name == 'override')) {
      return false;
    }

    // Skip getters and setters
    if (member is MethodDeclaration && (member.isGetter || member.isSetter)) {
      return false;
    }

    return true;
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
