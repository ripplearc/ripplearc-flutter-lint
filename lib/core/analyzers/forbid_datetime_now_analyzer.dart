import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
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
    if (node.methodName.name != 'now') return false;

    final element = node.methodName.staticElement;
    if (element != null) {
      if (element is ConstructorElement) {
        final enclosingElement = element.enclosingElement3;
        return enclosingElement is ClassElement &&
            enclosingElement.name == 'DateTime' &&
            enclosingElement.library.isDartCore;
      }
      if (element is MethodElement && element.isStatic) {
        final enclosingElement = element.enclosingElement3;
        return enclosingElement is ClassElement &&
            enclosingElement.name == 'DateTime' &&
            enclosingElement.library.isDartCore;
      }
      return false;
    }

    final target = node.target;
    if (target == null) return false;

    String? targetName;
    if (target is SimpleIdentifier) {
      targetName = target.name;
    } else if (target is PrefixedIdentifier) {
      targetName = target.identifier.name;
    } else if (target is PropertyAccess) {
      targetName = target.propertyName.name;
    }

    return targetName == 'DateTime';
  }
}
