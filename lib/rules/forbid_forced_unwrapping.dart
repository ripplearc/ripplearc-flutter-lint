import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that forbids using forced unwrapping (`!`) in production code.
///
/// This rule flags forced unwrapping operators to ensure null values are handled
/// explicitly using null-safe alternatives like null coalescing (`??`) or explicit
/// null checks. This helps prevent runtime crashes and makes the code more robust.
///
/// Example of code that triggers this rule:
/// ```dart
/// final name = user.name!;  // Will crash if name is null
/// print('User: $name');
/// ```
///
/// Example of code that doesn't trigger this rule:
/// ```dart
/// final name = user.name ?? 'Unknown';  // Safe with default value
/// print('User: $name');
///
/// if (user.name != null) {
///   final checkedName = user.name;  // Safe after null check
///   print('User: $checkedName');
/// }
/// ```
class ForbidForcedUnwrapping extends DartLintRule {
  const ForbidForcedUnwrapping() : super(code: _code);

  static const _code = LintCode(
    name: 'forbid_forced_unwrapping',
    problemMessage: 'Forced unwrapping (!) is not allowed in production code.',
    correctionMessage: 'Use null-safe alternatives like null coalescing (??) or explicit null checks.',
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
      _checkForForcedUnwrapping(node, reporter);
    });
  }

  bool _isTestFile(String path) {
    return path.contains('_test.dart') || path.contains('/test/');
  }

  void _checkForForcedUnwrapping(CompilationUnit node, ErrorReporter reporter) {
    final visitor = _ForcedUnwrappingVisitor(reporter);
    node.accept(visitor);
  }
}

class _ForcedUnwrappingVisitor extends RecursiveAstVisitor<void> {
  _ForcedUnwrappingVisitor(this.reporter);

  final ErrorReporter reporter;

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (node.operator.type == TokenType.BANG) {
      reporter.atNode(node, ForbidForcedUnwrapping._code);
    }
    super.visitPostfixExpression(node);
  }
} 