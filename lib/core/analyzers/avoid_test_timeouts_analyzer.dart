import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';

/// Analyzer that forbids using .timeout() and Future.delayed() in test files.
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
class AvoidTestTimeoutsAnalyzer extends BaseAnalyzer {
  @override
  String get ruleName => 'avoid_test_timeouts';
  @override
  String get problemMessage =>
      'Using .timeout() or Future.delayed() in tests can cause flaky tests. Use expectLater or proper async/await patterns instead.';
  @override
  String get correctionMessage =>
      'Replace with expectLater for streams or proper async/await patterns.';

  @override
  List<LintIssue> analyze(CompilationUnit unit) {
    final visitor = _AvoidTestTimeoutsVisitor(this);
    unit.accept(visitor);
    return visitor.issues;
  }
}

class _AvoidTestTimeoutsVisitor extends RecursiveAstVisitor<void> {
  final AvoidTestTimeoutsAnalyzer analyzer;
  final List<LintIssue> issues = [];
  bool _isInTestBlock = false;
  bool _isInSetupOrTeardown = false;

  _AvoidTestTimeoutsVisitor(this.analyzer);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    if (name == 'test' || name == 'group') {
      _isInTestBlock = true;
      super.visitMethodInvocation(node);
      _isInTestBlock = false;
    } else if (name == 'setUp' || name == 'tearDown') {
      _isInTestBlock = true;
      _isInSetupOrTeardown = true;
      super.visitMethodInvocation(node);
      _isInSetupOrTeardown = false;
      _isInTestBlock = false;
    } else {
      if (_isInTestBlock && name == 'timeout') {
        issues.add(analyzer.createIssue(node));
      }
      if (_isInTestBlock && name == 'delayed') {
        final target = node.target;
        if ((target is Identifier && target.name == 'Future') ||
            (target is PrefixedIdentifier &&
                target.identifier.name == 'Future')) {
          issues.add(analyzer.createIssue(node));
        }
      }
      super.visitMethodInvocation(node);
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final parent = node.parent;
    if (parent is ClassDeclaration &&
        parent.extendsClause?.superclass.toString() == 'Module') {
      _isInTestBlock = true;
      super.visitMethodDeclaration(node);
      _isInTestBlock = false;
    } else {
      super.visitMethodDeclaration(node);
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorName = node.constructorName;
    final typeName = constructorName.type.toString();
    final name = constructorName.name?.name;
    if (_isInTestBlock && typeName == 'Future' && name == 'delayed') {
      issues.add(analyzer.createIssue(node));
    }
    super.visitInstanceCreationExpression(node);
  }
}
