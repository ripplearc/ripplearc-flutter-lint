import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that forbids using optional operators (?., ??) in test files.
///
/// This rule flags optional operators in test blocks to ensure tests fail explicitly
/// at the point of failure rather than silently handling nulls.
///
/// Example of code that triggers this rule:
/// ```dart
/// test('example', () {
///   final result = someObject?.someProperty;  // LINT
///   final value = someValue ?? defaultValue;  // LINT
/// });
/// ```
///
/// Example of code that doesn't trigger this rule:
/// ```dart
/// test('example', () {
///   expect(someObject, isNotNull);
///   final result = someObject.someProperty;
///   expect(someValue, isNotNull);
///   final value = someValue;
///   final assertion = someValue!;  // This is fine
/// });
/// ```
class NoOptionalOperatorsInTests extends DartLintRule {
  const NoOptionalOperatorsInTests() : super(code: _code);

  static const _code = LintCode(
    name: 'no_optional_operators_in_tests',
    problemMessage: 'Optional operators (?., ??) are not allowed in test blocks. Tests should fail explicitly at the point of failure.',
    correctionMessage: 'Remove the optional operator and add an explicit null check if needed.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((node) {
      if (!_isTestFile(resolver.path)) return;
      _checkForOptionalOperators(node, reporter);
    });
  }

  bool _isTestFile(String path) {
    return path.contains('_test.dart') || 
           path.contains('/test/') || 
           path.contains('/example/') ||
           path.contains('example_');
  }

  void _checkForOptionalOperators(CompilationUnit node, ErrorReporter reporter) {
    final visitor = _OptionalOperatorVisitor(reporter);
    node.accept(visitor);
  }
}

class _OptionalOperatorVisitor extends RecursiveAstVisitor<void> {
  _OptionalOperatorVisitor(this._reporter);

  final ErrorReporter _reporter;
  bool _isInTestBlock = false;
  bool _isInSetupOrTeardown = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    if (name == 'test' || name == 'group') {
      _isInTestBlock = true;
      super.visitMethodInvocation(node);
      _isInTestBlock = false;
    } else if (name == 'setUp' || name == 'tearDown') {
      _isInSetupOrTeardown = true;
      super.visitMethodInvocation(node);
      _isInSetupOrTeardown = false;
    } else {
      // Check for ?. operator in method calls
      if (_isInTestBlock && !_isInSetupOrTeardown && node.operator?.type == TokenType.QUESTION_PERIOD) {
        _reporter.atNode(node, NoOptionalOperatorsInTests._code);
      }
      super.visitMethodInvocation(node);
    }
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (_isInTestBlock && !_isInSetupOrTeardown && node.operator.type == TokenType.QUESTION_PERIOD) {
      _reporter.atNode(node, NoOptionalOperatorsInTests._code);
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (_isInTestBlock && !_isInSetupOrTeardown && node.operator.type == TokenType.QUESTION_QUESTION) {
      _reporter.atNode(node, NoOptionalOperatorsInTests._code);
    }
    super.visitBinaryExpression(node);
  }
} 