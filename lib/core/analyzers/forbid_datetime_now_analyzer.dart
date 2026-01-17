import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';

/// Analyzer that forbids using `DateTime.now()` in production code.
///
/// This rule flags direct usage of `DateTime.now()` to encourage the use of the
/// custom `Clock` interface from `libraries/time/interfaces/clock.dart` instead.
/// Using a `Clock` instance enables deterministic testing and time mocking in widget and unit tests.
///
/// Exception: `DateTime.now()` is allowed in `system_clock_impl.dart` where the
/// Clock implementation is defined.
///
/// Example of code that triggers this rule:
/// ```dart
/// final currentTime = DateTime.now();  // LINT
/// final timestamp = DateTime.now().millisecondsSinceEpoch;  // LINT
/// ```
///
/// Example of code that doesn't trigger this rule:
/// ```dart
/// import 'libraries/time/interfaces/clock.dart';
///
/// final clock = Clock();  // or inject via dependency injection
/// final currentTime = clock.now();  // OK - testable
/// final timestamp = clock.now().millisecondsSinceEpoch;  // OK - testable
/// ```
class ForbidDateTimeNowAnalyzer extends BaseAnalyzer {
  @override
  String get ruleName => 'forbid_datetime_now';

  @override
  String get problemMessage =>
      'DateTime.now() is not allowed. Use clock.now() from libraries/time/interfaces/clock.dart instead for testable code.';

  @override
  String get correctionMessage =>
      'Replace DateTime.now() with clock.now() from libraries/time/interfaces/clock.dart. Inject Clock via dependency injection for testing.';

  @override
  List<LintIssue> analyzeWithResolver(CompilationUnit unit, dynamic resolver) {
    // Allow DateTime.now() in system_clock_impl.dart where Clock implementation is defined
    final path = resolver.path ?? '';
    if (path.endsWith('system_clock_impl.dart')) {
      return [];
    }

    final visitor = _DateTimeNowVisitor(this);
    unit.accept(visitor);
    return visitor.issues;
  }

  @override
  List<LintIssue> analyze(CompilationUnit unit) {
    final visitor = _DateTimeNowVisitor(this);
    unit.accept(visitor);
    return visitor.issues;
  }
}

class _DateTimeNowVisitor extends RecursiveAstVisitor<void> {
  final ForbidDateTimeNowAnalyzer analyzer;
  final List<LintIssue> issues = [];

  _DateTimeNowVisitor(this.analyzer);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Check if this is a call to DateTime.now()
    // The target should be a SimpleIdentifier with name 'DateTime'
    // and the method name should be 'now'
    final target = node.target;
    final methodName = node.methodName.name;

    if (target is SimpleIdentifier &&
        target.name == 'DateTime' &&
        methodName == 'now') {
      issues.add(analyzer.createIssue(node));
    }

    super.visitMethodInvocation(node);
  }
}
