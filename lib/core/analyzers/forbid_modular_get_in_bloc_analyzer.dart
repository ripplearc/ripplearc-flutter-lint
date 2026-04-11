import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';

/// Analyzer that forbids `Modular.get<T>()` in BLoC files.
class ForbidModularGetInBlocAnalyzer extends BaseAnalyzer {
  @override
  String get ruleName => 'forbid_modular_get_in_bloc';

  @override
  String get problemMessage =>
      'Modular.get<T>() is not allowed in BLoC files. Inject dependencies through the BLoC constructor; use Modular.get only in *_module.dart.';

  @override
  String get correctionMessage =>
      'Pass the dependency into the BLoC constructor and register the BLoC in a *_module.dart factory using Modular.get there if needed.';

  @override
  bool shouldSkipFile(String path) {
    final normalized = path.replaceAll('\\', '/');
    final basename = normalized.split('/').last;
    if (basename.endsWith('_module.dart')) return true;
    if (!basename.endsWith('_bloc.dart')) return true;
    return false;
  }

  @override
  List<LintIssue> analyzeWithResolver(CompilationUnit unit, dynamic resolver) {
    final path = resolver.path as String?;
    if (path == null || shouldSkipFile(path)) {
      return [];
    }
    return analyze(unit);
  }

  @override
  List<LintIssue> analyze(CompilationUnit unit) {
    final visitor = _ModularGetVisitor(this);
    unit.accept(visitor);
    return visitor.issues;
  }
}

class _ModularGetVisitor extends RecursiveAstVisitor<void> {
  final ForbidModularGetInBlocAnalyzer analyzer;
  final List<LintIssue> issues = [];

  _ModularGetVisitor(this.analyzer);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isModularGetCall(node)) {
      issues.add(analyzer.createIssue(node));
    }
    super.visitMethodInvocation(node);
  }

  /// Detects `Modular.get<...>()` and `prefix.Modular.get<...>()`.
  bool _isModularGetCall(MethodInvocation node) {
    if (node.methodName.name != 'get') return false;
    final target = node.target;
    if (target is SimpleIdentifier && target.name == 'Modular') {
      return true;
    }
    if (target is PrefixedIdentifier && target.identifier.name == 'Modular') {
      return true;
    }
    return false;
  }
}
