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
/// - `CoreTypography.semiBold` and similar static font weight constants
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

  static const _typographyUsageMessageSuffix =
      ' static members bypass the theme system. '
      'Use Theme.of(context).extension<TypographyExtension>() instead.';
  static const _fontPackageMessageSuffix =
      ' bypasses the centralized theme definition. '
      'Font families should be defined in app_theme.dart.';

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _handleStaticMemberUsage(
      node: node,
      target: node.target,
      memberName: node.methodName.name,
    );

    if (_isTextStyleInvocation(node)) {
      issues.add(
        analyzer.createIssue(
          node,
          customMessage:
              'Raw TextStyle constructor bypasses the design system tokens. '
              'Use Theme.of(context).extension<TypographyExtension>() and .copyWith() for modifications.',
        ),
      );
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final typeName = node.constructorName.type.name2.lexeme;
    if (typeName == 'TextStyle') {
      issues.add(
        analyzer.createIssue(
          node,
          customMessage:
              'Raw TextStyle constructor bypasses the design system tokens. '
              'Use Theme.of(context).extension<TypographyExtension>() and .copyWith() for modifications.',
        ),
      );
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (_isPartOfLargerAccess(node)) {
      super.visitPropertyAccess(node);
      return;
    }

    _handleStaticMemberUsage(
      node: node,
      target: node.target,
      memberName: node.propertyName.name,
    );

    super.visitPropertyAccess(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (_isPartOfLargerAccess(node)) {
      super.visitPrefixedIdentifier(node);
      return;
    }

    _handleStaticMemberUsage(
      node: node,
      target: node.prefix,
      memberName: node.identifier.name,
    );

    super.visitPrefixedIdentifier(node);
  }

  void _handleStaticMemberUsage({
    required AstNode node,
    required Expression? target,
    required String memberName,
  }) {
    final classIdentifier = _extractIdentifier(target);
    if (classIdentifier == null) return;

    if (_isTypographyClassName(classIdentifier)) {
      issues.add(
        analyzer.createIssue(
          node,
          customMessage: _typographyMessage(classIdentifier),
        ),
      );
    }

    if (_isGoogleFontsClassName(classIdentifier)) {
      issues.add(
        analyzer.createIssue(
          node,
          customMessage: _fontPackageMessage(classIdentifier),
        ),
      );
    }
  }

  bool _isTextStyleInvocation(MethodInvocation node) {
    if (node.methodName.name != 'TextStyle') return false;
    // If the analyzer does not resolve constructors, TextStyle(...) appears as a method call.
    return true;
  }

  bool _isPartOfLargerAccess(AstNode node) {
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

  String? _extractIdentifier(Expression? expression) {
    if (expression == null) return null;
    if (expression is SimpleIdentifier) return expression.name;
    if (expression is PrefixedIdentifier) return expression.identifier.name;
    if (expression is PropertyAccess) return expression.propertyName.name;
    return null;
  }

  bool _isTypographyClassName(String? identifier) {
    if (identifier == null) return false;
    return identifier == 'CoreTypography';
  }

  bool _isGoogleFontsClassName(String? identifier) {
    if (identifier == null || !_startsWithUpperCase(identifier)) return false;
    return identifier == 'GoogleFonts' || identifier.endsWith('Fonts');
  }

  bool _startsWithUpperCase(String value) {
    if (value.isEmpty) return false;
    final code = value.codeUnitAt(0);
    return code >= 0x41 && code <= 0x5A;
  }

  String _typographyMessage(String classIdentifier) =>
      '$classIdentifier$_typographyUsageMessageSuffix';

  String _fontPackageMessage(String classIdentifier) =>
      '$classIdentifier$_fontPackageMessageSuffix';
}
