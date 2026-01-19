import 'package:analyzer/dart/ast/ast.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';
import 'direct_instantiation_helpers/patterns.dart';
import 'direct_instantiation_helpers/visitor.dart';

/// Analyzer that enforces dependency injection for better testability of auth/sync components.
///
/// This rule flags all direct instantiations of classes, except:
///   - Classes whose names end with 'Factory' (e.g., FileProcessorFactory)
///   - Classes that extend 'Module'
///   - Any instantiation that occurs inside a class that extends 'Module' (specifically in binds/exportedBinds methods)
///   - Flutter widgets, BLoC states, exceptions, and other legitimate patterns
class DirectInstantiationAnalyzer extends BaseAnalyzer {
  @override
  String get ruleName => 'no_direct_instantiation';

  @override
  String get problemMessage =>
      'Direct instantiation is not allowed. Use dependency injection instead.';

  @override
  String get correctionMessage =>
      'Replace direct instantiation with Modular.get<ClassName>().';

  @override
  List<LintIssue> analyze(CompilationUnit unit) {
    final visitor = DirectInstantiationVisitor(createIssue);
    unit.accept(visitor);
    return visitor.issues;
  }

  @override
  List<LintIssue> analyzeWithResolver(CompilationUnit unit, dynamic resolver) {
    final filePath = resolver.path ?? '';

    if (DirectInstantiationPatterns.shouldSkipFile(filePath)) {
      return [];
    }

    final visitor = DirectInstantiationVisitor(createIssue, resolver, filePath);
    unit.accept(visitor);
    return visitor.issues;
  }
}
