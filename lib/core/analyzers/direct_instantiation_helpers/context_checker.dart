import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

/// Provides context-based exclusion checks for direct instantiation analysis.
///
/// This class checks if an instantiation should be excluded based on its surrounding
/// context in the code, such as:
/// - Const constructors and const contexts
/// - Factory constructors
/// - Module class contexts
/// - Module binds/exportedBinds methods
class ContextChecker {
  static bool _extendsModule(ExtendsClause? extendsClause) {
    return extendsClause != null &&
        extendsClause.superclass.name2.lexeme == 'Module';
  }


  static bool isInConstOrFactoryContext(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is ListLiteral && current.constKeyword != null) return true;
      if (current is SetOrMapLiteral && current.constKeyword != null)
        return true;
      if (current is VariableDeclaration) {
        final parent = current.parent;
        if (parent is VariableDeclarationList && parent.isConst) return true;
      }
      if (current is ArgumentList) {
        final parent = current.parent;
        if (parent is InstanceCreationExpression &&
            parent.keyword?.lexeme == 'const') {
          return true;
        }
      }

      if (current is ConstructorDeclaration) {
        if (current.factoryKeyword != null) return true;
        break;
      }

      if (current is SuperConstructorInvocation ||
          current is ConstructorInitializer) {
        return true;
      }

      if (current is MethodDeclaration || current is FunctionDeclaration) break;
      current = current.parent;
    }

    return false;
  }

  static bool isExcludedByContext(InstanceCreationExpression node) {
    if (node.keyword?.lexeme == 'const') return true;

    if (isInConstOrFactoryContext(node)) return true;

    final constructorElement = node.constructorName.staticElement;
    if (constructorElement is ConstructorElement &&
        constructorElement.isConst) {
      return true;
    }

    return false;
  }

  static bool isInsideModuleBindsMethod(AstNode node) {
    AstNode? current = node.parent;
    MethodDeclaration? methodDecl;
    FunctionDeclaration? functionDecl;
    ClassDeclaration? classDecl;
    CompilationUnit? compilationUnit;

    while (current != null) {
      if (current is MethodDeclaration && methodDecl == null)
        methodDecl = current;
      if (current is FunctionDeclaration && functionDecl == null)
        functionDecl = current;
      if (current is ClassDeclaration && classDecl == null) classDecl = current;
      if (current is CompilationUnit && compilationUnit == null)
        compilationUnit = current;
      if (methodDecl != null && classDecl != null && compilationUnit != null)
        break;
      current = current.parent;
    }

    if (methodDecl != null && classDecl != null) {
      final methodName = methodDecl.name.lexeme;
      if (methodName == 'binds' ||
          methodName == 'exportedBinds' ||
          methodName.startsWith('_')) {
        if (_extendsModule(classDecl.extendsClause)) {
          return true;
        }
      }
    }

    if (functionDecl != null && compilationUnit != null && classDecl == null) {
      final functionName = functionDecl.name.lexeme;
      if (functionName.startsWith('_')) {
        for (final decl in compilationUnit.declarations) {
          if (decl is ClassDeclaration) {
            if (_extendsModule(decl.extendsClause)) {
              return true;
            }
          }
        }
      }
    }

    return false;
  }

  static bool isInsideModule(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is ClassDeclaration) {
        if (_extendsModule(current.extendsClause)) {
          return true;
        }
        break;
      }
      current = current.parent;
    }
    return false;
  }

  static bool isExcludedClass(String className, AstNode node) {
    if (className.endsWith('Factory')) return true;

    final classDecl = findClassDeclaration(className, node);
    if (classDecl != null && _extendsModule(classDecl.extendsClause)) {
      return true;
    }
    return false;
  }

  static ClassDeclaration? findClassDeclaration(
    String className,
    AstNode node,
  ) {
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

  static bool extendsEquatable(String className, AstNode node) {
    try {
      final classDecl = findClassDeclaration(className, node);
      if (classDecl == null) return false;
      return _extendsEquatableRecursive(classDecl, node, <String>{});
    } catch (e) {
      return false;
    }
  }

  static bool _extendsEquatableRecursive(
    ClassDeclaration classDecl,
    AstNode node,
    Set<String> visited,
  ) {
    // Prevent infinite recursion in case of circular inheritance
    if (visited.contains(classDecl.name.lexeme)) return false;
    visited.add(classDecl.name.lexeme);

    // Check if this class directly extends Equatable
    final extendsClause = classDecl.extendsClause;
    if (extendsClause != null) {
      final superclassName = extendsClause.superclass.name2.lexeme;
      if (superclassName == 'Equatable') {
        return true;
      }
      final superclassDecl = findClassDeclaration(superclassName, node);
      if (superclassDecl != null &&
          _extendsEquatableRecursive(superclassDecl, node, visited)) {
        return true;
      }
    }

    final implementsClause = classDecl.implementsClause;
    if (implementsClause != null) {
      for (final interface in implementsClause.interfaces) {
        final interfaceName = interface.name2.lexeme;
        if (interfaceName == 'Equatable') {
          return true;
        }

        final interfaceDecl = findClassDeclaration(interfaceName, node);
        if (interfaceDecl != null &&
            _extendsEquatableRecursive(interfaceDecl, node, visited)) {
          return true;
        }
      }
    }

    return false;
  }
}
