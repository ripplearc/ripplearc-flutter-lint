import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import '../base_analyzer.dart';
import '../../models/lint_issue.dart';
import 'patterns.dart';
import 'context_checker.dart';
import 'type_checker.dart';
import 'import_checker.dart';

class DirectInstantiationVisitor extends RecursiveAstVisitor<void> {
  final dynamic resolver;
  final String filePath;
  final List<LintIssue> issues = [];
  final Function(AstNode) createIssue;

  DirectInstantiationVisitor(
    this.createIssue, [
    this.resolver,
    this.filePath = '',
  ]);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target == null && node.argumentList.arguments.isEmpty) {
      final methodName = node.methodName.name;
      final unit = node.root;
      if (unit is CompilationUnit) {
        for (final decl in unit.declarations) {
          if (decl is ClassDeclaration && decl.name.lexeme == methodName) {
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
            break;
          }
        }
      }
    }
    super.visitMethodInvocation(node);
  }

  void _checkInstantiation(String className, AstNode node) {
    if (DirectInstantiationPatterns.isExcludedByFilePath(filePath) ||
        BaseAnalyzer.isTestFile(filePath)) {
      return;
    }

    if (_isInConstContext(node)) {
      return;
    }

    if (_isInFactoryConstructor(node)) {
      return;
    }

    if (DirectInstantiationPatterns.isExcludedByClassName(className)) {
      return;
    }

    if (DirectInstantiationPatterns.isWhitelistedClassName(className)) {
      return;
    }

    if (ContextChecker.isInsideModuleBindsMethod(node)) {
      return;
    }

    if (ContextChecker.isInsideModule(node)) {
      return;
    }

    if (ContextChecker.isExcludedClass(className, node)) {
      return;
    }

    if (ContextChecker.extendsEquatable(className, node)) {
      return;
    }

    if (node is MethodInvocation) {
      issues.add(createIssue(node));
    }
  }

  bool _isInConstContext(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is ListLiteral && current.constKeyword != null) return true;
      if (current is SetOrMapLiteral && current.constKeyword != null)
        return true;
      if (current is VariableDeclaration) {
        final parent = current.parent;
        if (parent is VariableDeclarationList && parent.isConst) return true;
      }
      if (current is ConstructorDeclaration) break;
      if (current is MethodDeclaration || current is FunctionDeclaration) break;
      current = current.parent;
    }
    return false;
  }

  bool _isInFactoryConstructor(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is ConstructorDeclaration) {
        return current.factoryKeyword != null;
      }
      if (current is MethodDeclaration || current is FunctionDeclaration) break;
      current = current.parent;
    }
    return false;
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorName = node.constructorName;
    final name2 = constructorName.type.name2;
    final className = name2.lexeme;

    if (DirectInstantiationPatterns.isExcludedByFilePath(filePath) ||
        BaseAnalyzer.isTestFile(filePath)) {
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

    if (ContextChecker.isInsideModuleBindsMethod(node)) {
      super.visitInstanceCreationExpression(node);
      return;
    }

    if (ContextChecker.isInsideModule(node)) {
      super.visitInstanceCreationExpression(node);
      return;
    }

    if (ContextChecker.isExcludedClass(className, node)) {
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
    } else {

      if (ContextChecker.extendsEquatable(className, node)) {
        super.visitInstanceCreationExpression(node);
        return;
      }
    }

    if (TypeChecker.isSealedClass(node)) {
      super.visitInstanceCreationExpression(node);
      return;
    }

    issues.add(createIssue(node));
    super.visitInstanceCreationExpression(node);
  }
}

