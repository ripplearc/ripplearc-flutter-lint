import 'dart:convert';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';

/// Analyzer that forbids documentation comments on private methods.
///
/// This analyzer flags any private method (name starts with `_`) that has a documentation
/// comment (///) or a line comment immediately above it. The intent is to reduce noise
/// in the codebase and encourage documentation only for public APIs.
///
/// The rule triggers on:
///   - Any private method with a documentation comment or a line comment above it.
///
/// To fix a violation, remove the documentation comment from the private method.
class NoInternalMethodDocsAnalyzer extends BaseAnalyzer {
  @override
  String get ruleName => 'no_internal_method_docs';
  @override
  String get problemMessage =>
      'Private methods should not have documentation comments.';
  @override
  String get correctionMessage =>
      'Remove the documentation comment from the private method.';
  @override
  String get severity => 'WARNING';

  @override
  List<LintIssue> analyze(CompilationUnit unit) {
    final visitor = _PrivateMethodDocsVisitor(this, unit);
    unit.accept(visitor);
    return visitor.issues;
  }
}

class _PrivateMethodDocsVisitor extends RecursiveAstVisitor<void> {
  final NoInternalMethodDocsAnalyzer analyzer;
  final CompilationUnit unit;
  final List<LintIssue> issues = [];
  _PrivateMethodDocsVisitor(this.analyzer, this.unit);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!node.name.lexeme.startsWith('_')) return;
    if (node.isGetter || node.isSetter) return;
    if (_hasDocumentation(node.documentationComment)) {
      issues.add(analyzer.createIssue(node));
      super.visitMethodDeclaration(node);
      return;
    }
    // Best-effort: Check for // comments immediately above the method in the source
    final methodOffset = node.offset;
    final lineInfo = unit.lineInfo;
    final methodLine = lineInfo.getLocation(methodOffset).lineNumber;
    final source = unit.toSource();
    final lines = const LineSplitter().convert(source);
    if (methodLine > 1 && methodLine <= lines.length) {
      int checkLine = methodLine - 2;
      bool found = false;
      while (checkLine >= 0 && checkLine < lines.length) {
        final line = lines[checkLine].trimLeft();
        if (line.startsWith('//')) {
          found = true;
          checkLine--;
        } else if (line.isEmpty) {
          break;
        } else {
          break;
        }
      }
      if (found) {
        issues.add(analyzer.createIssue(node));
      }
    }
    super.visitMethodDeclaration(node);
  }

  bool _hasDocumentation(Comment? comment) {
    if (comment == null) return false;
    for (final token in comment.tokens) {
      final lexeme = token.lexeme;
      if (lexeme.startsWith('///')) {
        final content = lexeme.substring(3).trim();
        if (content.isNotEmpty) {
          return true;
        }
      }
    }
    return false;
  }
}
