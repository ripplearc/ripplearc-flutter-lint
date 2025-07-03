import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces dependency injection for better testability of auth/sync components.
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
class NoDirectInstantiation extends DartLintRule {
  const NoDirectInstantiation() : super(code: _code);

  static const _code = LintCode(
    name: 'no_direct_instantiation',
    problemMessage:
        'Direct instantiation is not allowed. Use dependency injection instead.',
    correctionMessage:
        'Replace direct instantiation with Modular.get<ClassName>().',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((node) {
      _checkForDirectInstantiation(node, reporter);
    });
  }

  void _checkForDirectInstantiation(
    CompilationUnit node,
    ErrorReporter reporter,
  ) {
    node.visitChildren(_DirectInstantiationVisitor(reporter));
  }
}

class _DirectInstantiationVisitor extends RecursiveAstVisitor<void> {
  final ErrorReporter reporter;
  _DirectInstantiationVisitor(this.reporter);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final className = node.constructorName.type.name2.lexeme;
    if (!_isExcludedClass(className, node) && !_isInsideModule(node)) {
      reporter.atNode(node, NoDirectInstantiation._code);
    }
    super.visitInstanceCreationExpression(node);
  }

  bool _isExcludedClass(String className, InstanceCreationExpression node) {
    // Allow classes whose names end with 'Factory'
    if (className.endsWith('Factory')) {
      return true;
    }
    // Allow classes that extend 'Module'
    final classDecl = _findClassDeclaration(className, node);
    if (classDecl != null) {
      final extendsClause = classDecl.extendsClause;
      if (extendsClause != null &&
          extendsClause.superclass.name2.lexeme == 'Module') {
        return true;
      }
    }
    return false;
  }

  bool _isInsideModule(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is ClassDeclaration) {
        final extendsClause = current.extendsClause;
        if (extendsClause != null &&
            extendsClause.superclass.name2.lexeme == 'Module') {
          return true;
        }
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
