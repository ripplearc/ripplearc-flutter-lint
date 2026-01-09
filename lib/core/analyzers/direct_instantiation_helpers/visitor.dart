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
  final Function(InstanceCreationExpression) createIssue;

  DirectInstantiationVisitor(
    this.createIssue, [
    this.resolver,
    this.filePath = '',
  ]);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorName = node.constructorName;
    final className = constructorName.type.name2.lexeme;
    
    if (DirectInstantiationPatterns.isExcludedByFilePath(filePath) || 
        BaseAnalyzer.isTestFile(filePath)) {
      super.visitInstanceCreationExpression(node);
      return;
    }

    if (ContextChecker.isExcludedByContext(node)) {
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

    if (constructorName.name != null) {
      bool shouldExclude = false;
      
      if (resolver != null && TypeChecker.isExcludedBySubtype(node)) shouldExclude = true;
      if (!shouldExclude && resolver != null && TypeChecker.isSealedClass(node)) shouldExclude = true;
      if (!shouldExclude && constructorName.name!.name.startsWith('_')) shouldExclude = true;
      if (!shouldExclude && ImportChecker.isImportedFromModelClass(className, node)) shouldExclude = true;

      if (shouldExclude) {
        super.visitInstanceCreationExpression(node);
        return;
      }
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

    if (ImportChecker.isImportedFromDomainEntity(className, node)) {
      super.visitInstanceCreationExpression(node);
      return;
    }
    if (ImportChecker.isImportedFromExcludedPackage(className, node)) {
      super.visitInstanceCreationExpression(node);
      return;
    }

    if (resolver != null && TypeChecker.isExcludedBySubtype(node)) {
      super.visitInstanceCreationExpression(node);
      return;
    }

    if (TypeChecker.isSealedClass(node)) {
      super.visitInstanceCreationExpression(node);
      return;
    }

    issues.add(createIssue(node));
    super.visitInstanceCreationExpression(node);
  }
}

