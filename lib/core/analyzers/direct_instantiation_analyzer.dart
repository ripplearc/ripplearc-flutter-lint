import 'package:analyzer/dart/ast/ast.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';
import 'direct_instantiation_helpers/patterns.dart';
import 'direct_instantiation_helpers/visitor.dart';

/// Analyzer that enforces dependency injection by flagging direct class instantiations.
///
/// This rule detects violations where classes are instantiated directly instead of using
/// dependency injection. Exclusions are configured centrally via LinterConfig and include:
/// - Classes from allowed packages (Flutter, Supabase, etc.)
/// - Classes extending ignored base classes (Equatable, Module, Event, etc.)
/// - Instantiations in specific contexts (const, factory, Module binds methods)
/// - Safe value objects from whitelisted packages
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
