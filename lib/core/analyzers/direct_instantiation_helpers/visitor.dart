import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import '../../models/lint_issue.dart';
import 'patterns.dart';
import 'context_checker.dart';
import 'type_checker.dart';
import 'import_checker.dart';
import 'linter_config.dart';

/// AST visitor that detects direct class instantiations and flags violations.
///
/// Traverses the AST to identify direct instantiations that should use dependency injection.
/// Delegates exclusion checks to TypeChecker, ImportChecker, ContextChecker, and Patterns.
/// Maintains a cache of class declarations per compilation unit for performance.
class DirectInstantiationVisitor extends RecursiveAstVisitor<void> {
  final dynamic resolver;
  final String filePath;
  final List<LintIssue> issues = [];
  final Function(AstNode) createIssue;

  Map<String, ClassDeclaration>? _classCache;
  bool? _unitHasModuleClass;

  DirectInstantiationVisitor(
    this.createIssue, [
    this.resolver,
    this.filePath = '',
  ]);

  Map<String, ClassDeclaration> _getClassCache(AstNode node) {
    if (_classCache != null) return _classCache!;
    final root = node.root;
    final cache = <String, ClassDeclaration>{};
    if (root is CompilationUnit) {
      for (final decl in root.declarations) {
        if (decl is ClassDeclaration) {
          cache[decl.name.lexeme] = decl;
        }
      }
    }
    _classCache = cache;
    return _classCache!;
  }

  bool _getUnitHasModuleClass(AstNode node) {
    if (_unitHasModuleClass != null) return _unitHasModuleClass!;
    final cache = _getClassCache(node);
    _unitHasModuleClass = cache.values.any((c) {
      final extendsClause = c.extendsClause;
      if (extendsClause == null) return false;
      final superclassName = extendsClause.superclass.name2.lexeme;
      return LinterConfig.ignoredBaseClasses.contains(superclassName);
    });
    return _unitHasModuleClass!;
  }

  bool _isInsideSameClass(AstNode node, String className) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is ClassDeclaration) {
        return current.name.lexeme == className;
      }
      current = current.parent;
    }
    return false;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _checkFactoryConstructorWithoutTarget(node);
    _checkNamedConstructorWithTarget(node);
    super.visitMethodInvocation(node);
  }

  void _checkFactoryConstructorWithoutTarget(MethodInvocation node) {
    if (node.target != null || node.argumentList.arguments.isNotEmpty) {
      return;
    }

    final methodName = node.methodName.name;
    final decl = _getClassCache(node)[methodName];
    if (decl == null) return;

    final hasFactoryConstructor = _hasFactoryConstructor(decl, methodName);
    if (!hasFactoryConstructor) {
      _checkInstantiation(methodName, node);
    }
  }

  void _checkNamedConstructorWithTarget(MethodInvocation node) {
    if (node.target is! SimpleIdentifier) return;

    final targetName = (node.target as SimpleIdentifier).name;
    final methodName = node.methodName.name;
    final decl = _getClassCache(node)[targetName];
    if (decl == null) return;

    final constructorInfo = _findNamedConstructor(decl, methodName);
    if (!constructorInfo.isNamedConstructor || constructorInfo.hasFactoryConstructor) {
      return;
    }

    if (methodName.startsWith('_') && _isInsideSameClass(node, targetName)) {
      return;
    }

    _checkInstantiation(targetName, node);
  }

  bool _hasFactoryConstructor(ClassDeclaration decl, String methodName) {
    for (final member in decl.members) {
      if (member is ConstructorDeclaration && member.factoryKeyword != null) {
        if (member.name == null || member.name!.lexeme == methodName) {
          return true;
        }
      }
    }
    return false;
  }

  ({bool isNamedConstructor, bool hasFactoryConstructor}) _findNamedConstructor(
    ClassDeclaration decl,
    String methodName,
  ) {
    for (final member in decl.members) {
      if (member is ConstructorDeclaration && member.name != null) {
        if (member.name!.lexeme == methodName) {
          return (
            isNamedConstructor: true,
            hasFactoryConstructor: member.factoryKeyword != null,
          );
        }
      }
    }
    return (isNamedConstructor: false, hasFactoryConstructor: false);
  }

  void _checkInstantiation(String className, AstNode node) {
    if (DirectInstantiationPatterns.shouldSkipFile(filePath)) {
      return;
    }

    if (ContextChecker.isInConstOrFactoryContext(node)) {
      return;
    }

    if (_isExcludedByContext(node, className)) {
      return;
    }

    if (node is MethodInvocation) {
      issues.add(createIssue(node));
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final className = node.constructorName.type.name2.lexeme;

    if (_shouldSkipInstanceCreation(node, className)) {
      super.visitInstanceCreationExpression(node);
      return;
    }

    if (_isExcludedByTypeOrImport(node, className)) {
      super.visitInstanceCreationExpression(node);
      return;
    }

    if (_isExcludedByContext(node, className)) {
      super.visitInstanceCreationExpression(node);
      return;
    }

    issues.add(createIssue(node));
    super.visitInstanceCreationExpression(node);
  }

  bool _shouldSkipInstanceCreation(InstanceCreationExpression node, String className) {
    if (DirectInstantiationPatterns.shouldSkipFile(filePath)) {
      return true;
    }

    final constructorName = node.constructorName.name;
    if (constructorName != null) {
      final constructorNameStr = constructorName.name;
      if (constructorNameStr.startsWith('_') && _isInsideSameClass(node, className)) {
        return true;
      }
    }

    return ContextChecker.isExcludedByContext(node);
  }

  bool _isExcludedByTypeOrImport(InstanceCreationExpression node, String className) {
    if (resolver == null) {
      return _checkImportBasedExclusions(className, node);
    }

    final element = node.constructorName.staticElement;
    final typeElement = element?.returnType.element;
    final hasFullTypeResolution = element != null &&
        typeElement != null &&
        typeElement is ClassElement;

    if (hasFullTypeResolution) {
      return _checkTypeBasedExclusions(node, typeElement, className);
    } else {
      return _checkImportBasedExclusions(className, node);
    }
  }

  bool _checkTypeBasedExclusions(
    InstanceCreationExpression node,
    ClassElement typeElement,
    String className,
  ) {
    if (TypeChecker.isFromAllowedLibrary(typeElement)) {
      return true;
    }

    if (TypeChecker.isExcludedBySubtype(node)) {
      return true;
    }

    if (TypeChecker.isSealedClass(node)) {
      return true;
    }

    return false;
  }

  bool _checkImportBasedExclusions(String className, InstanceCreationExpression node) {
    if (ImportChecker.isImportedFromAllowedPackage(className, node)) {
      return true;
    }

    return ImportChecker.isWhitelistedThirdPartyClass(className, node);
  }

  bool _isExcludedByContext(AstNode node, String className) {
    if (ContextChecker.isInsideModuleBindsMethodWithUnitHint(
      node,
      unitHasModuleClass: _getUnitHasModuleClass(node),
    )) {
      return true;
    }

    if (ContextChecker.isInsideModule(node)) {
      return true;
    }

    if (ContextChecker.isExcludedClass(
      className,
      node,
      classCache: _getClassCache(node),
    )) {
      return true;
    }

    return ContextChecker.extendsIgnoredBaseClass(
      className,
      node,
      classCache: _getClassCache(node),
    );
  }
}

