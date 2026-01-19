import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';

/// Analyzer that forbids using `DateTime.now()` in production code.
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
    if (_isSystemClockImplFile(resolver.path)) {
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

  bool _isSystemClockImplFile(String? path) {
    return path?.endsWith('system_clock_impl.dart') ?? false;
  }
}

class _DateTimeNowVisitor extends RecursiveAstVisitor<void> {
  final ForbidDateTimeNowAnalyzer analyzer;
  final List<LintIssue> issues = [];

  _DateTimeNowVisitor(this.analyzer);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isDateTimeNowCall(node)) {
      issues.add(analyzer.createIssue(node));
    }

    super.visitMethodInvocation(node);
  }

  bool _isDateTimeNowCall(MethodInvocation node) {
    final target = node.target;
    return target is SimpleIdentifier &&
        target.name == 'DateTime' &&
        node.methodName.name == 'now';
  }
}
