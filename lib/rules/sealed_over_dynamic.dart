import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces the use of sealed classes over dynamic for sync results.
///
/// This rule flags any use of `dynamic` for sync results and suggests using a sealed class instead.
///
/// Example:
/// ```dart
/// // ❌ Not allowed:
/// dynamic syncResult = await powersync.execute(query);
///
/// // ✅ Allowed:
/// sealed class SyncResult {}
/// SyncResult result = await powersync.execute(query);
/// ```
class SealedOverDynamic extends DartLintRule {
  const SealedOverDynamic() : super(code: _code);

  static const _code = LintCode(
    name: 'sealed_over_dynamic',
    problemMessage:
        'Do not use dynamic for sync results. Use a sealed class instead.',
    correctionMessage: 'Declare a sealed class and use it for sync results.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((node) {
      _checkForDynamicSyncResult(node, reporter);
    });
  }

  void _checkForDynamicSyncResult(
    CompilationUnit node,
    ErrorReporter reporter,
  ) {
    node.visitChildren(_SealedOverDynamicVisitor(reporter));
  }
}

class _SealedOverDynamicVisitor extends RecursiveAstVisitor<void> {
  final ErrorReporter reporter;
  _SealedOverDynamicVisitor(this.reporter);

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final parent = node.parent;
    if (parent is VariableDeclarationList) {
      final type = parent.type;
      if (type != null && type.toString() == 'dynamic') {
        reporter.atNode(node, SealedOverDynamic._code);
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
      reporter.atNode(node, SealedOverDynamic._code);
    }
    super.visitAssignmentExpression(node);
  }
}
