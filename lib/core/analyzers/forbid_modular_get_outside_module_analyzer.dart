import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';

/// Analyzer that forbids `Modular.get<T>()` outside of module files.
class ForbidModularGetOutsideModuleAnalyzer extends BaseAnalyzer {
  @override
  String get ruleName => 'forbid_modular_get_outside_module';

  @override
  String get problemMessage =>
      'Modular.get<T>() is not allowed outside of module files. Inject dependencies through constructors; use Modular.get only in *_module.dart.';

  @override
  String get correctionMessage =>
      'Pass the dependency into the constructor and register the instance in a *_module.dart factory using Modular.get there if needed.';

  @override
  bool shouldSkipFile(String path) {
    final normalized = path.replaceAll('\\', '/');
    
    // Skip test files inside the top-level test/ folder
    if (normalized.contains('/test/')) return true;
    
    final basename = normalized.split('/').last;

    // Skip generated files
    if (basename.endsWith('.g.dart') || basename.endsWith('.freezed.dart')) {
      return true;
    }
    
    // Allow Modular.get in _module.dart files
    if (basename.endsWith('_module.dart')) return true;
    
    return false;
  }

  @override
  List<LintIssue> analyzeWithResolver(CompilationUnit unit, dynamic resolver) {
    final path = resolver.path as String?;
    if (path == null || shouldSkipFile(path)) {
      return [];
    }
    return _analyzeInternally(unit);
  }

  @override
  List<LintIssue> analyze(CompilationUnit unit) {
    // This method is called directly by some test runners or parent classes.
    // However, without a file path, we cannot determine if the file should be analyzed.
    // We only rely on path-aware [analyzeWithResolver]
    return [];
  }

  /// Internal implementation of the analysis logic.
  List<LintIssue> _analyzeInternally(CompilationUnit unit) {
    final visitor = _ModularGetVisitor(this);
    unit.accept(visitor);
    return visitor.issues;
  }
}

class _ModularGetVisitor extends RecursiveAstVisitor<void> {
  final ForbidModularGetOutsideModuleAnalyzer analyzer;
  final List<LintIssue> issues = [];

  _ModularGetVisitor(this.analyzer);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isModularGetCall(node)) {
      issues.add(analyzer.createIssue(node));
    }
    super.visitMethodInvocation(node);
  }

  /// Detects `Modular.get<...>()` and `alias.Modular.get<...>()` where Modular is the class name.
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
