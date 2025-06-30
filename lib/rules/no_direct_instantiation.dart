import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that enforces dependency injection by forbidding direct class instantiation.
///
/// This rule flags direct instantiations of classes to ensure proper dependency injection
/// is used, improving testability and maintainability of auth/sync components.
///
/// Example of code that triggers this rule:
/// ```dart
/// fakeSupabaseWrapper = FakeSupabaseWrapper();  // LINT: Direct instantiation not allowed
/// final service = AuthService();                // LINT: Direct instantiation not allowed
/// ```
///
/// Example of code that doesn't trigger this rule:
/// ```dart
/// fakeSupabaseWrapper = Modular.get<FakeSupabaseWrapper>();  // Good: DI pattern
/// final service = Modular.get<AuthService>();                // Good: DI pattern
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
      if (_isTestFile(resolver.path)) return;
      _checkForDirectInstantiation(node, reporter);
    });
  }

  bool _isTestFile(String path) {
    return path.contains('_test.dart') || path.contains('/test/');
  }

  void _checkForDirectInstantiation(
    CompilationUnit node,
    ErrorReporter reporter,
  ) {
    final visitor = _DirectInstantiationVisitor(reporter);
    node.visitChildren(visitor);
  }
}

class _DirectInstantiationVisitor extends RecursiveAstVisitor<void> {
  _DirectInstantiationVisitor(this.reporter);

  final ErrorReporter reporter;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // Check if this is a direct instantiation (not Modular.get)
    if (!_isModularGetCall(node)) {
      // Check if the class being instantiated is excluded (Module or factory)
      final className = node.constructorName.type.name2.lexeme;
      if (!_isExcludedClass(className, node)) {
        reporter.atNode(node, NoDirectInstantiation._code);
      }
    }

    super.visitInstanceCreationExpression(node);
  }

  bool _isModularGetCall(InstanceCreationExpression node) {
    // Check if this is a Modular.get<ClassName>() call
    final parent = node.parent;
    if (parent is MethodInvocation) {
      final methodName = parent.methodName.name;
      final target = parent.target;
      if (methodName == 'get' && target is PrefixedIdentifier) {
        final prefix = target.prefix.name;
        final identifier = target.identifier.name;
        return prefix == 'Modular' && identifier == 'get';
      }
    }
    return false;
  }

  bool _isExcludedClass(String className, InstanceCreationExpression node) {
    // Check if the class name ends with "Factory"
    if (className.endsWith('Factory')) {
      return true;
    }

    // Check if the class extends Module
    final classDeclaration = _findClassDeclaration(className, node);
    if (classDeclaration != null) {
      // Check if it extends Module
      final extendsClause = classDeclaration.extendsClause;
      if (extendsClause != null) {
        final superclass = extendsClause.superclass;
        if (superclass.name2.lexeme == 'Module') {
          return true;
        }
      }
    }

    return false;
  }

  ClassDeclaration? _findClassDeclaration(String className, AstNode node) {
    // Find the class declaration by traversing up the AST
    AstNode? current = node;
    while (current != null) {
      if (current is CompilationUnit) {
        for (final declaration in current.declarations) {
          if (declaration is ClassDeclaration &&
              declaration.name.lexeme == className) {
            return declaration;
          }
        }
        break;
      }
      current = current.parent;
    }
    return null;
  }
}
