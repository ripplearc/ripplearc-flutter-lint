import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces throwing specific exception types instead of generic Exception.
///
/// This rule flags any `throw Exception(...)` and suggests using a specific exception type
/// that implements [Exception], such as [AppException] or [ServerException].
///
/// Example:
/// ```dart
/// // ❌ Not allowed:
/// throw Exception('SUPABASE_URL required');
///
/// // ✅ Allowed:
/// throw ConfigurationException('SUPABASE_URL required');
/// throw AppException(...);
/// throw ServerException(...);
/// ```
class SpecificExceptionTypes extends DartLintRule {
  const SpecificExceptionTypes() : super(code: _code);

  static const _code = LintCode(
    name: 'specific_exception_types',
    problemMessage:
        'Throwing generic Exception is not allowed. Use a specific exception type.',
    correctionMessage:
        'Throw a class that implements Exception, e.g., AppException or ServerException.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((node) {
      _checkForGenericException(node, reporter);
    });
  }

  void _checkForGenericException(CompilationUnit node, ErrorReporter reporter) {
    node.visitChildren(_SpecificExceptionTypesVisitor(reporter));
  }
}

class _SpecificExceptionTypesVisitor extends RecursiveAstVisitor<void> {
  final ErrorReporter reporter;
  _SpecificExceptionTypesVisitor(this.reporter);

  @override
  void visitThrowExpression(ThrowExpression node) {
    final expression = node.expression;
    if (expression is InstanceCreationExpression) {
      final typeName = expression.constructorName.type.name2.lexeme;
      if (typeName == 'Exception') {
        reporter.atNode(node, SpecificExceptionTypes._code);
      }
    }
    super.visitThrowExpression(node);
  }
}
