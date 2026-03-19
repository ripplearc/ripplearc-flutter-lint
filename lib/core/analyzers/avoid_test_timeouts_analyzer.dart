import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';

/// Analyzer that forbids using .timeout(), Future.delayed(), and
/// Future.microtask() in test files.
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
      'Using .timeout(), Future.delayed(), or Future.microtask() in tests can cause flaky tests. Use expectLater or proper async/await patterns instead.';
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
  static const _timeoutMethodName = 'timeout';
  static const _delayedMethodName = 'delayed';
  static const _microtaskMethodName = 'microtask';
  static const _futureTypeName = 'Future';

  static const _testBlockMethods = {
    'test',
    'group',
    'testWidgets',
    'setUp',
    'tearDown',
    'setUpAll',
    'tearDownAll',
  };

  final AvoidTestTimeoutsAnalyzer analyzer;
  final List<LintIssue> issues = [];
  int _testBlockDepth = 0;

  bool get _isInTestBlock => _testBlockDepth > 0;

  _AvoidTestTimeoutsVisitor(this.analyzer);

  bool _isFutureTypeName(String typeName) {
    return typeName == _futureTypeName ||
        RegExp('^$_futureTypeName<.+>\$').hasMatch(typeName) ||
        typeName.endsWith('.$_futureTypeName') ||
        RegExp('\\.$_futureTypeName<.+>\$').hasMatch(typeName);
  }

  bool _isGenericStaticCallParsedAsConstructor(String? methodName) {
    return methodName == _delayedMethodName ||
        methodName == _microtaskMethodName;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    if (_testBlockMethods.contains(name)) {
      _testBlockDepth++;
      super.visitMethodInvocation(node);
      _testBlockDepth--;
    } else {
      if (_isInTestBlock && name == _timeoutMethodName) {
        issues.add(analyzer.createIssue(node));
      }
      if (_isInTestBlock &&
          (name == _delayedMethodName || name == _microtaskMethodName)) {
        final target = node.target;
        final targetString = target?.toString();
        if (targetString != null && _isFutureTypeName(targetString)) {
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
      _testBlockDepth++;
      super.visitMethodDeclaration(node);
      _testBlockDepth--;
    } else {
      super.visitMethodDeclaration(node);
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorName = node.constructorName;
    final typeName = constructorName.type.toString();
    final name = constructorName.name?.name;
    final isFutureType = _isFutureTypeName(typeName);
    if (_isInTestBlock &&
        isFutureType &&
        _isGenericStaticCallParsedAsConstructor(name)) {
      issues.add(analyzer.createIssue(node));
    }
    super.visitInstanceCreationExpression(node);
  }
}
