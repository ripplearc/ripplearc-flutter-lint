import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';

/// Analyzer that forbids using static typography definitions in production code.
///
/// This rule flags:
/// - `CoreTypography.*()` static method calls
/// - Raw `TextStyle(...)` constructor usage
/// - `GoogleFonts.*()` method calls
///
/// Typography should be accessed through `Theme.of(context).extension<TypographyExtension>()`
/// to ensure consistency and proper light/dark mode support.
///
/// Example of code that triggers this rule:
/// ```dart
/// Text(
///   'Hello',
///   style: CoreTypography.headlineLargeSemiBold(),  // LINT
/// );
///
/// Text(
///   'Welcome',
///   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),  // LINT
/// );
///
/// Text(
///   'Hello',
///   style: GoogleFonts.roboto(fontSize: 16),  // LINT
/// );
/// ```
///
/// Example of code that doesn't trigger this rule:
/// ```dart
/// final typography = Theme.of(context).extension<TypographyExtension>();
/// Text(
///   'Hello',
///   style: typography?.bodyLargeRegular,
/// );
/// ```
class AvoidStaticTypographyAnalyzer extends BaseAnalyzer {
  @override
  String get ruleName => 'avoid_static_typography';

  @override
  String get problemMessage =>
      'Static typography bypasses the theme system and will not adapt to light/dark mode changes.';

  @override
  String get correctionMessage =>
      'Use Theme.of(context).extension<TypographyExtension>() to access typography.';

  @override
  List<LintIssue> analyze(CompilationUnit unit) {
    final visitor = _StaticTypographyVisitor(this);
    unit.accept(visitor);
    return visitor.issues;
  }
}

class _StaticTypographyVisitor extends RecursiveAstVisitor<void> {
  _StaticTypographyVisitor(this.analyzer);

  final AvoidStaticTypographyAnalyzer analyzer;
  final List<LintIssue> issues = [];

  static const _coreTypographyClassName = 'CoreTypography';
  static const _googleFontsClassName = 'GoogleFonts';
  static const _textStyleTypeName = 'TextStyle';

  static const _coreTypographyMessage =
      'CoreTypography static members bypass the theme system. '
      'Use Theme.of(context).extension<TypographyExtension>() instead.';

  static const _googleFontsMessage =
      'GoogleFonts bypasses the centralized theme definition. '
      'Font families should be defined in app_theme.dart.';

  static const _textStyleMessage =
      'Raw TextStyle constructor bypasses the design system tokens. '
      'Use Theme.of(context).extension<TypographyExtension>().';

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final classMessage = _buildBannedClassMessage(node.target);
    if (classMessage != null) {
      issues.add(analyzer.createIssue(node, customMessage: classMessage));
    }

    if (node.methodName.name == _textStyleTypeName) {
      issues.add(analyzer.createIssue(node, customMessage: _textStyleMessage));
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final typeName = node.constructorName.type.name2.lexeme;
    if (typeName == _textStyleTypeName) {
      issues.add(analyzer.createIssue(node, customMessage: _textStyleMessage));
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (_isChainedAccess(node)) {
      super.visitPropertyAccess(node);
      return;
    }

    final message = _buildBannedClassMessage(node.target);
    if (message != null) {
      issues.add(analyzer.createIssue(node, customMessage: message));
    }

    super.visitPropertyAccess(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (_isChainedAccess(node)) {
      super.visitPrefixedIdentifier(node);
      return;
    }

    final message = _buildBannedClassMessage(node);
    if (message != null) {
      issues.add(analyzer.createIssue(node, customMessage: message));
    }

    super.visitPrefixedIdentifier(node);
  }

  String? _buildBannedClassMessage(Expression? expression) {
    final className = _bannedClassNameIn(expression);
    if (className == _coreTypographyClassName) return _coreTypographyMessage;
    if (className == _googleFontsClassName) return _googleFontsMessage;
    return null;
  }

  bool _isChainedAccess(AstNode node) {
    final parent = node.parent;
    if (parent is MethodInvocation && identical(parent.target, node)) {
      return true;
    }
    if (parent is PropertyAccess && identical(parent.target, node)) {
      return true;
    }
    if (parent is PrefixedIdentifier && identical(parent.prefix, node)) {
      return true;
    }
    return false;
  }

  String? _bannedClassNameIn(Expression? expression) {
    if (expression == null) return null;
    if (expression is SimpleIdentifier) {
      return expression.name;
    } else if (expression is PrefixedIdentifier) {
      if (expression.identifier.name == _coreTypographyClassName ||
          expression.identifier.name == _googleFontsClassName) {
        return expression.identifier.name;
      }
      return _bannedClassNameIn(expression.prefix);
    } else if (expression is PropertyAccess) {
      if (expression.propertyName.name == _coreTypographyClassName ||
          expression.propertyName.name == _googleFontsClassName) {
        return expression.propertyName.name;
      }
      return _bannedClassNameIn(expression.target);
    }
    return null;
  }
}
