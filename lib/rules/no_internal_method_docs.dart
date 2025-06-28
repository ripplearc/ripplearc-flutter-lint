import 'dart:convert';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:analyzer/source/line_info.dart';

/// A lint rule that forbids documentation on private methods to reduce documentation noise.
///
/// This rule flags private methods that have documentation comments, as these are
/// internal implementation details that don't need to be documented for external
/// consumers. This reduces documentation noise and focuses on public API documentation.
///
/// Example of code that triggers this rule:
/// ```dart
/// /// Handles internal auth state
/// void _handleAuthState() { ... }  // LINT: Private method should not be documented
///
/// // Validates user input
/// void _validateInput(String input) { ... }  // LINT: Private method should not be documented
/// ```
///
/// Example of code that doesn't trigger this rule:
/// ```dart
/// void _handleAuthState() { ... }  // No documentation - good
///
/// /// Public method that should be documented
/// void authenticate() { ... }  // Public method - documentation required
/// ```
class NoInternalMethodDocs extends DartLintRule {
  const NoInternalMethodDocs() : super(code: _code);

  static const _code = LintCode(
    name: 'no_internal_method_docs',
    problemMessage: 'Private methods should not have documentation comments.',
    correctionMessage:
        'Remove the documentation comment from the private method.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((node) {
      if (_isTestFile(resolver.path)) return;
      _checkForPrivateMethodDocs(node, reporter, resolver);
    });
  }

  bool _isTestFile(String path) {
    return path.contains('_test.dart') ||
        path.contains('/test/') ||
        path.contains('/example/') ||
        path.contains('example_');
  }

  void _checkForPrivateMethodDocs(
    CompilationUnit node,
    ErrorReporter reporter,
    CustomLintResolver resolver,
  ) {
    final visitor = _PrivateMethodDocsVisitor(
      reporter,
      node.lineInfo,
      resolver,
      node,
    );
    node.accept(visitor);
  }
}

class _PrivateMethodDocsVisitor extends RecursiveAstVisitor<void> {
  _PrivateMethodDocsVisitor(
    this.reporter,
    this.lineInfo,
    this.resolver,
    this.unit,
  );

  final ErrorReporter reporter;
  final LineInfo lineInfo;
  final CustomLintResolver resolver;
  final CompilationUnit unit;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // Only check private methods (starting with _)
    if (!node.name.lexeme.startsWith('_')) return;
    // Skip getters and setters
    if (node.isGetter || node.isSetter) return;

    // Check for /// documentation
    if (_hasDocumentation(node.documentationComment)) {
      reporter.atNode(node, NoInternalMethodDocs._code);
      super.visitMethodDeclaration(node);
      return;
    }

    // Best-effort: Check for // comments immediately above the method in the source
    final methodOffset = node.offset;
    final methodLine = lineInfo.getLocation(methodOffset).lineNumber;
    final source = unit.toSource();
    final lines = const LineSplitter().convert(source);
    if (methodLine > 1 && methodLine <= lines.length) {
      int checkLine = methodLine - 2; // Dart lines are 1-based
      bool found = false;
      while (checkLine >= 0 && checkLine < lines.length) {
        final line = lines[checkLine].trimLeft();
        if (line.startsWith('//')) {
          // Only flag if the comment is directly above (no blank lines)
          found = true;
          checkLine--;
        } else if (line.isEmpty) {
          // Stop if there's a blank line
          break;
        } else {
          break;
        }
      }
      if (found) {
        reporter.atNode(node, NoInternalMethodDocs._code);
      }
    }

    super.visitMethodDeclaration(node);
  }

  bool _hasDocumentation(Comment? comment) {
    if (comment == null) return false;
    for (final token in comment.tokens) {
      final lexeme = token.lexeme;
      if (lexeme.startsWith('///')) {
        final content = lexeme.substring(3).trim();
        if (content.isNotEmpty) {
          return true;
        }
      }
    }
    return false;
  }
}
