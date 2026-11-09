import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';

/// Analyzer that forbids using .timeout(), Future.delayed(),
/// Future.microtask(), `blocTest(wait: ...)` and pumpEventQueue() in test
/// files.
///
/// This rule flags timeout and delay patterns in test blocks to prevent flaky tests
/// and encourage the use of proper async/await patterns and expectLater.
///
/// Example of code that triggers this rule:
/// ```dart
/// test('example', () async {
///   await userCompleter.future.timeout(Duration(seconds: 1));  // LINT
///   await Future.delayed(Duration(milliseconds: 10));  // LINT
///   await pumpEventQueue();  // LINT
/// });
/// blocTest<SearchBloc, SearchState>(
///   'example',
///   wait: const Duration(milliseconds: 310),  // LINT
/// );
/// ```
///
/// Example of code that doesn't trigger this rule:
/// ```dart
/// test('example', () async {
///   await expectLater(userStream, emits(expectedUser));
///   await tester.pumpAndSettle();
/// });
/// testWidgets('example', (tester) async {
///   await tester.pump(const Duration(milliseconds: 400));  // fake clock
/// });
/// test('example', () {
///   fakeAsync((async) {
///     Future.delayed(const Duration(seconds: 3), onDone);  // fake clock
///     async.elapse(const Duration(seconds: 3));
///   });
/// });
/// ```
class AvoidTestTimeoutsAnalyzer extends BaseAnalyzer {
  @override
  String get ruleName => 'avoid_test_timeouts';
  @override
  String get problemMessage =>
      'Using .timeout(), Future.delayed(), Future.microtask(), blocTest wait: or pumpEventQueue() in tests waits a fixed time and can cause flaky tests.';
  @override
  String get correctionMessage =>
      'Wait on the real event instead: expectLater(bloc.stream, emitsInOrder([...])) or stream.firstWhere(...). For a debounce, make the debounce time a parameter so the test can pass Duration.zero. To check that nothing happened yet, run the test in fakeAsync and call async.elapse(Duration.zero) first.';

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
  static const _blocTestMethodName = 'blocTest';
  static const _waitArgumentName = 'wait';
  static const _pumpEventQueueMethodName = 'pumpEventQueue';
  static const _testWidgetsMethodName = 'testWidgets';
  static const _fakeAsyncMethodName = 'fakeAsync';

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
  int _testWidgetsDepth = 0;
  int _fakeAsyncDepth = 0;

  bool get _isInTestBlock => _testBlockDepth > 0;
  bool get _isOnFakeAsyncClock => _fakeAsyncDepth > 0;
  bool get _checksTimers => _isInTestBlock && !_isOnFakeAsyncClock;

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
      final isTestWidgets = name == _testWidgetsMethodName;
      _testBlockDepth++;
      if (isTestWidgets) _testWidgetsDepth++;
      super.visitMethodInvocation(node);
      if (isTestWidgets) _testWidgetsDepth--;
      _testBlockDepth--;
    } else if (name == _fakeAsyncMethodName) {
      // Timers and microtasks inside fakeAsync only run when the test calls
      // async.elapse or a flush, so nothing in there waits in real time.
      _fakeAsyncDepth++;
      super.visitMethodInvocation(node);
      _fakeAsyncDepth--;
    } else {
      if (name == _blocTestMethodName) {
        _reportWaitArgument(node.argumentList);
      }
      // A bare pumpEventQueue() in testWidgets never finishes, so it fails by
      // timeout. Inside tester.runAsync it is a real wait, not caught yet.
      if (name == _pumpEventQueueMethodName &&
          node.target == null &&
          _testWidgetsDepth == 0 &&
          !_isOnFakeAsyncClock) {
        issues.add(analyzer.createIssue(node));
      }
      if (_checksTimers && name == _timeoutMethodName) {
        issues.add(analyzer.createIssue(node));
      }
      if (_checksTimers &&
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

  void _reportWaitArgument(ArgumentList arguments) {
    for (final argument in arguments.arguments) {
      if (argument is NamedExpression &&
          argument.name.label.name == _waitArgumentName) {
        issues.add(analyzer.createIssue(argument));
      }
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
    if (_checksTimers &&
        isFutureType &&
        _isGenericStaticCallParsedAsConstructor(name)) {
      issues.add(analyzer.createIssue(node));
    }
    super.visitInstanceCreationExpression(node);
  }
}
