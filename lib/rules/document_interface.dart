import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that ensures abstract classes and their public methods have documentation.
///
/// This rule flags abstract classes that are exported/public but lack proper documentation.
/// It ensures clear API contracts for modular architecture by requiring /// documentation
/// for both the class and its public methods.
///
/// Example of code that triggers this rule:
/// ```dart
/// abstract class SyncRepository {  // Missing class documentation
///   Future<void> syncData();      // Missing method documentation
/// }
/// ```
///
/// Example of code that doesn't trigger this rule:
/// ```dart
/// /// Repository interface for data synchronization operations.
/// abstract class SyncRepository {
///   /// Synchronizes local data with remote Supabase instance.
///   Future<void> syncData();
/// }
/// ```
class DocumentInterface extends DartLintRule {
  const DocumentInterface() : super(code: _code);

  static const _code = LintCode(
    name: 'document_interface',
    problemMessage:
        'Abstract classes and their public methods must have documentation.',
    correctionMessage:
        'Add /// documentation for the class and its public methods.',
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
    return path.contains('_test.dart') ||
        path.contains('/test/') ||
        path.contains('/example/') ||
        path.contains('example_');
  }

  void _checkForDocumentation(CompilationUnit node, ErrorReporter reporter) {
    final visitor = _DocumentationVisitor(reporter);
    node.accept(visitor);
  }
}

class _DocumentationVisitor extends RecursiveAstVisitor<void> {
  _DocumentationVisitor(this.reporter);

  final ErrorReporter reporter;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // Only check abstract classes
    if (node.abstractKeyword == null) return;

    // Check if class has documentation
    final hasClassDocumentation = _hasDocumentation(node.documentationComment);

    // Check public methods for documentation
    final undocumentedMethods = <MethodDeclaration>[];

    for (final member in node.members) {
      if (member is MethodDeclaration) {
        // Only check public methods (not starting with _)
        if (!member.name.lexeme.startsWith('_')) {
          if (!_hasDocumentation(member.documentationComment)) {
            undocumentedMethods.add(member);
          }
        }
      }
    }

    // Report error if class or any public method lacks documentation
    if (!hasClassDocumentation || undocumentedMethods.isNotEmpty) {
      reporter.atNode(node, DocumentInterface._code);
    }

    super.visitClassDeclaration(node);
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
