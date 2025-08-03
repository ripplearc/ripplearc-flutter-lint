import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';

/// Analyzer that enforces dependency injection for better testability of auth/sync components.
///
/// This rule flags all direct instantiations of classes, except:
///   - Classes whose names end with 'Factory' (e.g., FileProcessorFactory)
///   - Classes that extend 'Module'
///   - Any instantiation that occurs inside a class that extends 'Module'
///
/// Example:
/// ```dart
/// // ❌ Not allowed:
/// fakeSupabaseWrapper = FakeSupabaseWrapper();
/// final service = AuthService();
///
/// // ✅ Allowed:
/// fakeSupabaseWrapper = Modular.get<FakeSupabaseWrapper>();
/// final service = Modular.get<AuthService>();
/// final factory = FileProcessorFactory();
/// final module = AppModule();
///
/// // ✅ Allowed: Instantiation inside a Module
/// class AppModule extends Module {
///   AppModule() {
///     final service = AuthService(); // Allowed here
///   }
/// }
/// ```
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
    final visitor = _DirectInstantiationVisitor(this);
    unit.accept(visitor);
    return visitor.issues;
  }

  /// Returns true if the class should be excluded from the rule (e.g., Factory or Module classes).
  bool isExcludedClass(String className, InstanceCreationExpression node) {
    if (className.endsWith('Factory')) return true;
    final classDecl = _findClassDeclaration(className, node);
    if (classDecl != null) {
      final extendsClause = classDecl.extendsClause;
      if (extendsClause?.superclass.name2.lexeme == 'Module') return true;
    }
    return false;
  }

  /// Returns true if the given [node] is inside a class that extends 'Module'.
  bool isInsideModule(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is ClassDeclaration) {
        final extendsClause = current.extendsClause;
        if (extendsClause?.superclass.name2.lexeme == 'Module') return true;
        break;
      }
      current = current.parent;
    }
    return false;
  }

  ClassDeclaration? _findClassDeclaration(String className, AstNode node) {
    AstNode? current = node;
    while (current != null) {
      if (current is CompilationUnit) {
        for (final decl in current.declarations) {
          if (decl is ClassDeclaration && decl.name.lexeme == className) {
            return decl;
          }
        }
        break;
      }
      current = current.parent;
    }
    return null;
  }
}

class _DirectInstantiationVisitor extends RecursiveAstVisitor<void> {
  final DirectInstantiationAnalyzer analyzer;

  final List<LintIssue> issues = [];

  _DirectInstantiationVisitor(this.analyzer);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final className = node.constructorName.type.name2.lexeme;
    if (!analyzer.isExcludedClass(className, node) &&
        !analyzer.isInsideModule(node)) {
      issues.add(analyzer.createIssue(node));
    }
    super.visitInstanceCreationExpression(node);
  }
}
