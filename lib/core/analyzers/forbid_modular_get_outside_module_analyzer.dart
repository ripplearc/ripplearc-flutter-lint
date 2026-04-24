import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';
import 'forbid_modular_get_outside_module_config.dart';
import 'forbid_modular_get_outside_module_config_parser.dart';

/// Analyzer that forbids `Modular.get<T>()` outside of module files.
class ForbidModularGetOutsideModuleAnalyzer extends BaseAnalyzer {
  ForbidModularGetOutsideModuleAnalyzer({
    ForbidModularGetOutsideModuleConfig? config,
  }) : _config = config;

  final ForbidModularGetOutsideModuleConfig? _config;
  final Map<String, ForbidModularGetOutsideModuleConfig> _configCache = {};

  @override
  String get ruleName => 'forbid_modular_get_outside_module';

  @override
  String get problemMessage =>
      'Modular.get<T>() is not allowed outside of module files. Inject dependencies through constructors; use Modular.get only in *_module.dart.';

  @override
  String get correctionMessage => 'Pass the dependency into the constructor.';

  @override
  bool shouldSkipFile(String path) {
    if (BaseAnalyzer.isTestFile(path)) return true;
    final normalized = path.replaceAll('\\', '/');
    final basename = normalized.split('/').last;
    if (basename.endsWith('.g.dart') || basename.endsWith('.freezed.dart')) {
      return true;
    }
    if (basename.endsWith('_module.dart')) return true;
    return false;
  }

  @override
  List<LintIssue> analyzeWithResolver(CompilationUnit unit, dynamic resolver) {
    final path = resolver.path as String?;
    if (path == null || shouldSkipFile(path)) {
      return [];
    }
    return _analyzeInternally(unit, _resolveConfig(path));
  }

  @override
  List<LintIssue> analyze(CompilationUnit unit) {
    // This method is intentionally overridden to return empty.
    // This rule requires a path context to correctly bypass test/generated/module files.
    // Tools (like StandaloneLintChecker and custom_lint) must use analyzeWithResolver.
    return [];
  }

  /// Internal implementation of the analysis logic.
  List<LintIssue> _analyzeInternally(
    CompilationUnit unit,
    ForbidModularGetOutsideModuleConfig config,
  ) {
    final visitor = _ModularGetVisitor(this, config);
    unit.accept(visitor);
    return visitor.issues;
  }

  ForbidModularGetOutsideModuleConfig _resolveConfig(String path) {
    if (_config != null) return _config;

    final normalizedPath = path.replaceAll('\\', '/');
    return _configCache.putIfAbsent(
      normalizedPath,
      () => ForbidModularGetOutsideModuleConfigParser.loadFromFile(path),
    );
  }
}

/// AST visitor that collects [LintIssue]s for every `Modular.get<T>()` call
/// found outside an allowed module file.
class _ModularGetVisitor extends RecursiveAstVisitor<void> {
  final BaseAnalyzer analyzer;
  final ForbidModularGetOutsideModuleConfig config;
  final List<LintIssue> issues = [];

  _ModularGetVisitor(this.analyzer, this.config);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isForbiddenModularGetCall(node)) {
      issues.add(analyzer.createIssue(node));
    }
    super.visitMethodInvocation(node);
  }

  bool _isForbiddenModularGetCall(MethodInvocation node) {
    if (!_isModularGetCall(node)) return false;
    if (_isAllowedType(node)) return false;
    if (_isInsideAllowedUiClass(node)) return false;
    return true;
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

  bool _isAllowedType(MethodInvocation node) {
    final typeArguments = node.typeArguments?.arguments;
    if (typeArguments == null || typeArguments.isEmpty) return false;

    final rawType = typeArguments.first.toSource();
    final normalizedType = rawType.split('<').first.split('.').last.trim();
    return config.allowsType(normalizedType);
  }

  bool _isInsideAllowedUiClass(AstNode node) {
    final enclosingClass = node.thisOrAncestorOfType<ClassDeclaration>();
    if (enclosingClass == null) return false;

    final className = enclosingClass.name.lexeme;
    if (className.endsWith('Page')) return true;

    final superclass =
        enclosingClass.extendsClause?.superclass.toSource() ?? '';
    final normalizedSuperclass =
        superclass.split('<').first.split('.').last.trim();

    return normalizedSuperclass == 'StatelessWidget' ||
        normalizedSuperclass == 'StatefulWidget' ||
        normalizedSuperclass.endsWith('Page');
  }
}
