import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

class ContextChecker {
  static bool isExcludedByContext(InstanceCreationExpression node) {
    if (node.keyword?.lexeme == 'const') return true;

    AstNode? current = node.parent;
    while (current != null) {
      if (current is ListLiteral && current.constKeyword != null) return true;
      if (current is SetOrMapLiteral && current.constKeyword != null) return true;
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
      
      if (current is MethodDeclaration) break;
      current = current.parent;
    }

    final constructorElement = node.constructorName.staticElement;
    if (constructorElement is ConstructorElement && constructorElement.isConst) {
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
      if (current is MethodDeclaration && methodDecl == null) methodDecl = current;
      if (current is FunctionDeclaration && functionDecl == null) functionDecl = current;
      if (current is ClassDeclaration && classDecl == null) classDecl = current;
      if (current is CompilationUnit && compilationUnit == null) compilationUnit = current;
      if (methodDecl != null && classDecl != null && compilationUnit != null) break;
      current = current.parent;
    }

    if (methodDecl != null && classDecl != null) {
      final methodName = methodDecl.name.lexeme;
      if (methodName == 'binds' || methodName == 'exportedBinds' || methodName.startsWith('_')) {
        final extendsClause = classDecl.extendsClause;
        if (extendsClause != null && extendsClause.superclass.name2.lexeme == 'Module') {
          return true;
        }
      }
    }

    if (functionDecl != null && compilationUnit != null && classDecl == null) {
      final functionName = functionDecl.name.lexeme;
      if (functionName.startsWith('_')) {
        for (final decl in compilationUnit.declarations) {
          if (decl is ClassDeclaration) {
            final extendsClause = decl.extendsClause;
            if (extendsClause != null && extendsClause.superclass.name2.lexeme == 'Module') {
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
        final extendsClause = current.extendsClause;
        if (extendsClause != null && extendsClause.superclass.name2.lexeme == 'Module') {
          return true;
        }
        break;
      }
      current = current.parent;
    }
    return false;
  }

  static bool isExcludedClass(String className, InstanceCreationExpression node) {
    if (className.endsWith('Factory')) return true;

    final classDecl = findClassDeclaration(className, node);
    if (classDecl != null) {
      final extendsClause = classDecl.extendsClause;
      if (extendsClause != null && extendsClause.superclass.name2.lexeme == 'Module') {
        return true;
      }
    }
    return false;
  }

  static ClassDeclaration? findClassDeclaration(String className, AstNode node) {
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

