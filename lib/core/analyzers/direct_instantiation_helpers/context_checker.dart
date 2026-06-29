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
/// const/factory constructors, Module class contexts, binds methods, and ignored base class inheritance.
/// Uses LinterConfig for base classes, method names, and keywords.
class ContextChecker {
  static bool _extendsModule(ExtendsClause? extendsClause, LinterConfig config) {
    if (extendsClause == null) return false;
    final superclassName = extendsClause.superclass.name2.lexeme;
    return config.ignoredBaseClasses.contains(superclassName);
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

  static bool _isConstArgumentList(AstNode node, LinterConfig config) {
    if (node is! ArgumentList) return false;
    final parent = node.parent;
    if (parent is! InstanceCreationExpression) return false;
    final keyword = parent.keyword;
    return keyword != null &&
           config.astKeywords.contains(keyword.lexeme);
  }

  static bool _isFactoryConstructor(AstNode node) {
    return node is ConstructorDeclaration && node.factoryKeyword != null;
  }

  static bool _isConstructorInitializer(AstNode node) {
    return node is SuperConstructorInvocation || node is ConstructorInitializer;
  }

  static bool isInConstOrFactoryContext(AstNode node, LinterConfig config) {
    AstNode? current = node.parent;
    while (current != null) {
      if (_isConstLiteral(current)) return true;
      if (_isConstVariable(current)) return true;
      if (_isConstArgumentList(current, config)) return true;
      if (_isFactoryConstructor(current)) return true;
      if (_isConstructorInitializer(current)) return true;

      if (current is MethodDeclaration || current is FunctionDeclaration) break;
      current = current.parent;
    }

    return false;
  }

  static bool isExcludedByContext(InstanceCreationExpression node, LinterConfig config) {
    final keyword = node.keyword;
    if (keyword != null &&
        config.astKeywords.contains(keyword.lexeme)) {
      return true;
    }

    if (isInConstOrFactoryContext(node, config)) return true;

    final constructorElement = node.constructorName.element;
    if (constructorElement is ConstructorElement &&
        constructorElement.isConst) {
      return true;
    }

    return false;
  }

  static bool isInsideModuleBindsMethod(AstNode node, LinterConfig config) {
    return _isInsideModuleBindsMethodInternal(node, config);
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

  static bool _isModuleBindsMethod(MethodDeclaration methodDecl, ClassDeclaration classDecl, LinterConfig config) {
    final methodName = methodDecl.name.lexeme;
    return (config.astMethodNames.contains(methodName) ||
            methodName.startsWith('_')) &&
           _extendsModule(classDecl.extendsClause, config);
  }

  static bool _isModuleBindsFunction(
    FunctionDeclaration functionDecl,
    CompilationUnit compilationUnit,
    bool? unitHasModuleClass,
    LinterConfig config,
  ) {
    final functionName = functionDecl.name.lexeme;
    if (!functionName.startsWith('_')) return false;

    if (unitHasModuleClass != null) return unitHasModuleClass;

    for (final decl in compilationUnit.declarations) {
      if (decl is ClassDeclaration && _extendsModule(decl.extendsClause, config)) {
        return true;
      }
    }
    return false;
  }

  static bool _isInsideModuleBindsMethodInternal(
    AstNode node,
    LinterConfig config, {
    bool? unitHasModuleClass,
  }) {
    final context = _findModuleBindsContext(node);

    final methodDecl = context.methodDecl;
    final classDecl = context.classDecl;
    if (methodDecl != null && classDecl != null) {
      if (_isModuleBindsMethod(methodDecl, classDecl, config)) {
        return true;
      }
    }

    final functionDecl = context.functionDecl;
    final compilationUnit = context.compilationUnit;
    if (functionDecl != null &&
        compilationUnit != null &&
        context.classDecl == null) {
      if (_isModuleBindsFunction(
            functionDecl,
            compilationUnit,
            unitHasModuleClass,
            config,
          )) {
        return true;
      }
    }

    return false;
  }

  static bool isInsideModuleBindsMethodWithUnitHint(
    AstNode node,
    LinterConfig config, {
    required bool unitHasModuleClass,
  }) {
    return _isInsideModuleBindsMethodInternal(
      node,
      config,
      unitHasModuleClass: unitHasModuleClass,
    );
  }

  static bool isInsideModule(AstNode node, LinterConfig config) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is ClassDeclaration) {
        if (_extendsModule(current.extendsClause, config)) {
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
    AstNode node,
    LinterConfig config, {
    Map<String, ClassDeclaration>? classCache,
  }) {
    if (config.astTypePrefixes.any((prefix) => className.startsWith(prefix))) {
      return true;
    }
    if (config.astTypeSuffixes.any((suffix) => className.endsWith(suffix))) {
      return true;
    }
    final classDecl = findClassDeclaration(
      className,
      node,
      classCache: classCache,
    );
    if (classDecl != null && _extendsModule(classDecl.extendsClause, config)) {
      return true;
    }
    return false;
  }

  static bool hasIgnoredBaseClassInUnit(
    AstNode node,
    LinterConfig config, {
    Map<String, ClassDeclaration>? classCache,
  }) {
    final cache = classCache ?? _getClassCacheFromNode(node);
    return cache.values.any((c) {
      final extendsClause = c.extendsClause;
      if (extendsClause == null) return false;
      final superclassName = extendsClause.superclass.name2.lexeme;
      return _isIgnoredBaseClass(superclassName, config);
    });
  }

  static Map<String, ClassDeclaration> _getClassCacheFromNode(AstNode node) {
    final cache = <String, ClassDeclaration>{};
    AstNode? current = node;
    while (current != null) {
      if (current is CompilationUnit) {
        for (final decl in current.declarations) {
          if (decl is ClassDeclaration) {
            cache[decl.name.lexeme] = decl;
          }
        }
        break;
      }
      current = current.parent;
    }
    return cache;
  }

  static bool extendsIgnoredBaseClass(
    String className,
    AstNode node,
    LinterConfig config, {
    Map<String, ClassDeclaration>? classCache,
  }) {
    try {
      final classDecl = findClassDeclaration(
        className,
        node,
        classCache: classCache,
      );
      if (classDecl == null) return false;
      return _extendsIgnoredBaseClassRecursive(
        classDecl,
        node,
        <String>{},
        config,
        classCache: classCache,
      );
    } catch (e) {
      return false;
    }
  }

  static bool _isIgnoredBaseClass(String className, LinterConfig config) {
    return config.ignoredBaseClasses.contains(className);
  }

  static bool _checkSuperclass(
    String superclassName,
    AstNode node,
    Set<String> visited,
    LinterConfig config, {
    Map<String, ClassDeclaration>? classCache,
  }) {
    if (_isIgnoredBaseClass(superclassName, config)) return true;

    final superclassDecl = findClassDeclaration(
      superclassName,
      node,
      classCache: classCache,
    );
    if (superclassDecl != null &&
        !visited.contains(superclassDecl.name.lexeme)) {
      return _extendsIgnoredBaseClassRecursive(
        superclassDecl,
        node,
        visited,
        config,
        classCache: classCache,
      );
    }
    return false;
  }

  static bool _checkInterfaces(
    ImplementsClause implementsClause,
    AstNode node,
    Set<String> visited,
    LinterConfig config, {
    Map<String, ClassDeclaration>? classCache,
  }) {
    for (final interface in implementsClause.interfaces) {
      final interfaceName = interface.name2.lexeme;
      if (_isIgnoredBaseClass(interfaceName, config)) return true;

      final interfaceDecl = findClassDeclaration(
        interfaceName,
        node,
        classCache: classCache,
      );
      if (interfaceDecl != null &&
          !visited.contains(interfaceDecl.name.lexeme)) {
        if (_extendsIgnoredBaseClassRecursive(
              interfaceDecl,
              node,
              visited,
              config,
              classCache: classCache,
            )) {
          return true;
        }
      }
    }
    return false;
  }

  static bool _extendsIgnoredBaseClassRecursive(
    ClassDeclaration classDecl,
    AstNode node,
    Set<String> visited,
    LinterConfig config, {
    Map<String, ClassDeclaration>? classCache,
  }) {
    if (visited.contains(classDecl.name.lexeme)) return false;
    visited.add(classDecl.name.lexeme);

    final extendsClause = classDecl.extendsClause;
    if (extendsClause != null) {
      final superclassName = extendsClause.superclass.name2.lexeme;
      if (_checkSuperclass(superclassName, node, visited, config, classCache: classCache)) {
        return true;
      }
    }

    final implementsClause = classDecl.implementsClause;
    if (implementsClause != null) {
      if (_checkInterfaces(implementsClause, node, visited, config, classCache: classCache)) {
        return true;
      }
    }

    return false;
  }
}
