import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import '../../models/lint_issue.dart';
import 'patterns.dart';
import 'context_checker.dart';
import 'type_checker.dart';
import 'import_checker.dart';
import 'type_names.dart';

/// AST visitor that detects direct class instantiations and flags violations.
///
/// This visitor traverses the AST and identifies direct instantiations of classes
/// that should use dependency injection instead. It maintains a cache of class
/// declarations per compilation unit to optimize performance.
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
      return extendsClause != null &&
          extendsClause.superclass.name2.lexeme == TypeNames.module;
    });
    return _unitHasModuleClass!;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target == null && node.argumentList.arguments.isEmpty) {
      final methodName = node.methodName.name;
      final decl = _getClassCache(node)[methodName];
      if (decl != null) {
        bool hasFactoryConstructor = false;
        for (final member in decl.members) {
          if (member is ConstructorDeclaration &&
              member.factoryKeyword != null) {
            if (member.name == null || member.name!.lexeme == methodName) {
              hasFactoryConstructor = true;
              break;
            }
          }
        }

        if (!hasFactoryConstructor) {
          _checkInstantiation(methodName, node);
        }
      }
    }
    super.visitMethodInvocation(node);
  }

  void _checkInstantiation(String className, AstNode node) {
    if (DirectInstantiationPatterns.shouldSkipFile(filePath)) {
      return;
    }

    if (ContextChecker.isInConstOrFactoryContext(node)) {
      return;
    }

    if (DirectInstantiationPatterns.isExcludedByClassName(className)) {
      return;
    }

    if (DirectInstantiationPatterns.isWhitelistedClassName(className)) {
      return;
    }

    if (ContextChecker.isInsideModuleBindsMethodWithUnitHint(
      node,
      unitHasModuleClass: _getUnitHasModuleClass(node),
    )) {
      return;
    }

    if (ContextChecker.isInsideModule(node)) {
      return;
    }

    if (ContextChecker.isExcludedClass(
      className,
      node,
      classCache: _getClassCache(node),
    )) {
      return;
    }

    if (ContextChecker.extendsEquatable(
      className,
      node,
      classCache: _getClassCache(node),
    )) {
      return;
    }

    if (node is MethodInvocation) {
      issues.add(createIssue(node));
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorName = node.constructorName;
    final name2 = constructorName.type.name2;
    final className = name2.lexeme;

    if (DirectInstantiationPatterns.shouldSkipFile(filePath)) {
      super.visitInstanceCreationExpression(node);
      return;
    }

    if (constructorName.name != null) {
      final constructorNameStr = constructorName.name!.name;
      if (constructorNameStr.startsWith('_')) {
        super.visitInstanceCreationExpression(node);
        return;
      }
    }

    final isExcludedByContext = ContextChecker.isExcludedByContext(node);
    if (isExcludedByContext) {
      super.visitInstanceCreationExpression(node);
      return;
    }

    if (DirectInstantiationPatterns.isExcludedByClassName(className)) {
      super.visitInstanceCreationExpression(node);
      return;
    }

    if (DirectInstantiationPatterns.isWhitelistedClassName(className)) {
      super.visitInstanceCreationExpression(node);
      return;
    }

    if (ContextChecker.isInsideModuleBindsMethodWithUnitHint(
      node,
      unitHasModuleClass: _getUnitHasModuleClass(node),
    )) {
      super.visitInstanceCreationExpression(node);
      return;
    }

    if (ContextChecker.isInsideModule(node)) {
      super.visitInstanceCreationExpression(node);
      return;
    }

    if (ContextChecker.isExcludedClass(
      className,
      node,
      classCache: _getClassCache(node),
    )) {
      super.visitInstanceCreationExpression(node);
      return;
    }

    if (ImportChecker.isImportedFromExcludedPackage(className, node)) {
      super.visitInstanceCreationExpression(node);
      return;
    }

    if (resolver != null) {
      if (TypeChecker.isExcludedBySubtype(node)) {
        super.visitInstanceCreationExpression(node);
        return;
      }
      if (TypeChecker.isSealedClass(node, classCache: _getClassCache(node))) {
        super.visitInstanceCreationExpression(node);
        return;
      }
    } else {
      if (ContextChecker.extendsEquatable(
        className,
        node,
        classCache: _getClassCache(node),
      )) {
        super.visitInstanceCreationExpression(node);
        return;
      }
      if (TypeChecker.isSealedClass(node, classCache: _getClassCache(node))) {
        super.visitInstanceCreationExpression(node);
        return;
      }
    }

    issues.add(createIssue(node));
    super.visitInstanceCreationExpression(node);
  }
}

