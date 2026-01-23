import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'linter_config.dart';

class _ModuleBindsContext {
  final MethodDeclaration? methodDecl;
  final FunctionDeclaration? functionDecl;
  final ClassDeclaration? classDecl;
  final CompilationUnit? compilationUnit;

  _ModuleBindsContext({
    this.methodDecl,
    this.functionDecl,
    this.classDecl,
    this.compilationUnit,
  });
}

/// Provides context-based exclusion checks for direct instantiation analysis.
///
/// Checks if an instantiation should be excluded based on its AST context, including
/// const/factory constructors, Module class contexts, binds methods, and Equatable inheritance.
/// Uses LinterConfig for base classes, method names, and keywords.
class ContextChecker {
  static bool _extendsModule(ExtendsClause? extendsClause) {
    if (extendsClause == null) return false;
    final superclassName = extendsClause.superclass.name2.lexeme;
    return LinterConfig.ignoredBaseClasses.contains(superclassName);
  }

  static ClassDeclaration? findClassDeclaration(
    String className,
    AstNode node, {
    Map<String, ClassDeclaration>? classCache,
  }) {
    if (classCache != null) return classCache[className];

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

  static bool _isConstLiteral(AstNode node) {
    return (node is ListLiteral && node.constKeyword != null) ||
           (node is SetOrMapLiteral && node.constKeyword != null);
  }

  static bool _isConstVariable(AstNode node) {
    if (node is! VariableDeclaration) return false;
    final parent = node.parent;
    return parent is VariableDeclarationList && parent.isConst;
  }

  static bool _isConstArgumentList(AstNode node) {
    if (node is! ArgumentList) return false;
    final parent = node.parent;
    return parent is InstanceCreationExpression &&
           parent.keyword != null &&
           LinterConfig.astKeywords.contains(parent.keyword!.lexeme);
  }

  static bool _isFactoryConstructor(AstNode node) {
    return node is ConstructorDeclaration && node.factoryKeyword != null;
  }

  static bool _isConstructorInitializer(AstNode node) {
    return node is SuperConstructorInvocation || node is ConstructorInitializer;
  }

  static bool isInConstOrFactoryContext(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (_isConstLiteral(current)) return true;
      if (_isConstVariable(current)) return true;
      if (_isConstArgumentList(current)) return true;
      if (_isFactoryConstructor(current)) return true;
      if (_isConstructorInitializer(current)) return true;

      if (current is MethodDeclaration || current is FunctionDeclaration) break;
      current = current.parent;
    }

    return false;
  }

  static bool isExcludedByContext(InstanceCreationExpression node) {
    if (node.keyword != null &&
        LinterConfig.astKeywords.contains(node.keyword!.lexeme)) {
      return true;
    }

    if (isInConstOrFactoryContext(node)) return true;

    final constructorElement = node.constructorName.staticElement;
    if (constructorElement is ConstructorElement &&
        constructorElement.isConst) {
      return true;
    }

    return false;
  }

  static bool isInsideModuleBindsMethod(AstNode node) {
    return _isInsideModuleBindsMethodInternal(node);
  }

  static _ModuleBindsContext _findModuleBindsContext(AstNode node) {
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

    return _ModuleBindsContext(
      methodDecl: methodDecl,
      functionDecl: functionDecl,
      classDecl: classDecl,
      compilationUnit: compilationUnit,
    );
  }

  static bool _isModuleBindsMethod(MethodDeclaration methodDecl, ClassDeclaration classDecl) {
    final methodName = methodDecl.name.lexeme;
    return (LinterConfig.astMethodNames.contains(methodName) ||
            methodName.startsWith('_')) &&
           _extendsModule(classDecl.extendsClause);
  }

  static bool _isModuleBindsFunction(
    FunctionDeclaration functionDecl,
    CompilationUnit compilationUnit,
    bool? unitHasModuleClass,
  ) {
    final functionName = functionDecl.name.lexeme;
    if (!functionName.startsWith('_')) return false;

    if (unitHasModuleClass != null) return unitHasModuleClass;

    for (final decl in compilationUnit.declarations) {
      if (decl is ClassDeclaration && _extendsModule(decl.extendsClause)) {
        return true;
      }
    }
    return false;
  }

  static bool _isInsideModuleBindsMethodInternal(
    AstNode node, {
    bool? unitHasModuleClass,
  }) {
    final context = _findModuleBindsContext(node);

    if (context.methodDecl != null && context.classDecl != null) {
      if (_isModuleBindsMethod(context.methodDecl!, context.classDecl!)) {
        return true;
      }
    }

    if (context.functionDecl != null &&
        context.compilationUnit != null &&
        context.classDecl == null) {
      if (_isModuleBindsFunction(
            context.functionDecl!,
            context.compilationUnit!,
            unitHasModuleClass,
          )) {
        return true;
      }
    }

    return false;
  }

  static bool isInsideModuleBindsMethodWithUnitHint(
    AstNode node, {
    required bool unitHasModuleClass,
  }) {
    return _isInsideModuleBindsMethodInternal(
      node,
      unitHasModuleClass: unitHasModuleClass,
    );
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

  static bool isExcludedClass(
    String className,
    AstNode node, {
    Map<String, ClassDeclaration>? classCache,
  }) {
    if (LinterConfig.astTypeSuffixes.any((suffix) => className.endsWith(suffix))) {
      return true;
    }
    final classDecl = findClassDeclaration(
      className,
      node,
      classCache: classCache,
    );
    if (classDecl != null && _extendsModule(classDecl.extendsClause)) {
      return true;
    }
    return false;
  }

  static bool extendsEquatable(
    String className,
    AstNode node, {
    Map<String, ClassDeclaration>? classCache,
  }) {
    try {
      final classDecl = findClassDeclaration(
        className,
        node,
        classCache: classCache,
      );
      if (classDecl == null) return false;
      return _extendsEquatableRecursive(
        classDecl,
        node,
        <String>{},
        classCache: classCache,
      );
    } catch (e) {
      return false;
    }
  }

  static bool _isIgnoredBaseClass(String className) {
    return LinterConfig.ignoredBaseClasses.contains(className);
  }

  static bool _checkSuperclass(
    String superclassName,
    AstNode node,
    Set<String> visited, {
    Map<String, ClassDeclaration>? classCache,
  }) {
    if (_isIgnoredBaseClass(superclassName)) return true;

    final superclassDecl = findClassDeclaration(
      superclassName,
      node,
      classCache: classCache,
    );
    if (superclassDecl != null &&
        !visited.contains(superclassDecl.name.lexeme)) {
      return _extendsEquatableRecursive(
        superclassDecl,
        node,
        visited,
        classCache: classCache,
      );
    }
    return false;
  }

  static bool _checkInterfaces(
    ImplementsClause implementsClause,
    AstNode node,
    Set<String> visited, {
    Map<String, ClassDeclaration>? classCache,
  }) {
    for (final interface in implementsClause.interfaces) {
      final interfaceName = interface.name2.lexeme;
      if (_isIgnoredBaseClass(interfaceName)) return true;

      final interfaceDecl = findClassDeclaration(
        interfaceName,
        node,
        classCache: classCache,
      );
      if (interfaceDecl != null &&
          !visited.contains(interfaceDecl.name.lexeme)) {
        if (_extendsEquatableRecursive(
              interfaceDecl,
              node,
              visited,
              classCache: classCache,
            )) {
          return true;
        }
      }
    }
    return false;
  }

  static bool _extendsEquatableRecursive(
    ClassDeclaration classDecl,
    AstNode node,
    Set<String> visited, {
    Map<String, ClassDeclaration>? classCache,
  }) {
    if (visited.contains(classDecl.name.lexeme)) return false;
    visited.add(classDecl.name.lexeme);

    final extendsClause = classDecl.extendsClause;
    if (extendsClause != null) {
      final superclassName = extendsClause.superclass.name2.lexeme;
      if (_checkSuperclass(superclassName, node, visited, classCache: classCache)) {
        return true;
      }
    }

    final implementsClause = classDecl.implementsClause;
    if (implementsClause != null) {
      if (_checkInterfaces(implementsClause, node, visited, classCache: classCache)) {
        return true;
      }
    }

    return false;
  }
}
