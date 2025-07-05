import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that forbids using .timeout() and Future.delayed() in test files.
///
/// This rule flags timeout and delay patterns in test blocks to prevent flaky tests
/// and encourage the use of proper async/await patterns and expectLater.
///
/// Example of code that triggers this rule:
/// ```dart
/// test('example', () async {
///   await userCompleter.future.timeout(Duration(seconds: 1));  // LINT
///   await Future.delayed(Duration(milliseconds: 10));  // LINT
/// });
/// ```
///
/// Example of code that doesn't trigger this rule:
/// ```dart
/// test('example', () async {
///   await expectLater(userStream, emits(expectedUser));
///   await tester.pumpAndSettle();
/// });
/// ```
class AvoidTestTimeouts extends DartLintRule {
  const AvoidTestTimeouts() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_test_timeouts',
    problemMessage:
        'Using .timeout() or Future.delayed() in tests can cause flaky tests. Use expectLater or proper async/await patterns instead.',
    correctionMessage:
        'Replace with expectLater for streams or proper async/await patterns.',
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
      _checkForTestTimeouts(node, reporter);
    });
  }

  bool _isTestFile(String path) {
    return path.contains('_test.dart') ||
        path.contains('/test/') ||
        path.contains('/example/') ||
        path.contains('example_');
  }

  void _checkForTestTimeouts(CompilationUnit node, ErrorReporter reporter) {
    final visitor = _TestTimeoutVisitor(reporter);
    node.accept(visitor);
  }
}

class _TestTimeoutVisitor extends RecursiveAstVisitor<void> {
  _TestTimeoutVisitor(this._reporter);

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
      // Check for .timeout() method calls
      if (_isInTestBlock && !_isInSetupOrTeardown && name == 'timeout') {
        _reporter.atNode(node, AvoidTestTimeouts._code);
      }
      // Check for Future.delayed() method calls
      if (_isInTestBlock && !_isInSetupOrTeardown && name == 'delayed') {
        final target = node.target;
        if (target is Identifier && target.name == 'Future') {
          _reporter.atNode(node, AvoidTestTimeouts._code);
        }
      }
      super.visitMethodInvocation(node);
    }
  }
}
