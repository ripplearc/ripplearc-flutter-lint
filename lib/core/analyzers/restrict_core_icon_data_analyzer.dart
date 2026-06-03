import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';

/// Analyzer that restricts CoreIconData and CoreMaterialIcons usage to coreui package.
///
/// This rule enforces icon abstraction by requiring developers to use the `CoreIcons`
/// constants instead of directly instantiating `CoreIconData` or accessing
/// `CoreMaterialIcons`. This ensures consistent icon management and makes it easier
/// to modify icon implementations across the codebase.
///
/// Example of code that triggers this rule:
/// ```dart
/// final icon = CoreIconData.svg('assets/icon.svg');         // LINT
/// final icon = CoreIconData.material(Icons.home);           // LINT
/// final icon = CoreMaterialIcons.arrowRight;                // LINT
/// ```
///
/// Example of correct code:
/// ```dart
/// final icon = CoreIcons.arrowRight;  // OK
/// final icon = CoreIcons.microsoft;   // OK
/// ```
///
/// This rule is excluded for specific icon-defining files such as
/// `/lib/src/theme/icons/` and `/lib/src/components/core_icon.dart`.
class RestrictCoreIconDataAnalyzer extends BaseAnalyzer {
  static const _restrictedClasses = ['CoreIconData', 'CoreMaterialIcons'];

  static const _restrictedConstructors = ['svg', 'material'];

  @override
  String get ruleName => 'restrict_core_icon_data';

  @override
  String get problemMessage =>
      'CoreIconData and CoreMaterialIcons usage is restricted to coreui package only.';

  @override
  String get correctionMessage =>
      'Use CoreIcons constants instead of directly referencing CoreIconData or CoreMaterialIcons.';

  @override
  List<LintIssue> analyze(CompilationUnit unit) {
    return [];
  }

  @override
  List<LintIssue> analyzeWithResolver(CompilationUnit unit, dynamic resolver) {
    final path = resolver.path ?? '';
    if (shouldSkipFile(path)) {
      return [];
    }
    final visitor = _RestrictCoreIconDataVisitor(this, path);
    unit.accept(visitor);
    return visitor.issues;
  }

  @override
  bool shouldSkipFile(String path) {
    final normalized = path.replaceAll('\\', '/');
    return _isAllowedPath(normalized);
  }

  bool _isAllowedPath(String path) {
    return path.contains('/lib/src/theme/icons/') ||
        path.contains('/lib/src/components/core_icon.dart');
  }

  bool isRestrictedClass(String identifier) {
    return _restrictedClasses.contains(identifier);
  }

  bool isRestrictedConstructor(String identifier) {
    return _restrictedConstructors.contains(identifier);
  }
}

class _RestrictCoreIconDataVisitor extends RecursiveAstVisitor<void> {
  final RestrictCoreIconDataAnalyzer analyzer;
  final List<LintIssue> issues = [];
  final String filePath;

  _RestrictCoreIconDataVisitor(this.analyzer, this.filePath);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorName = node.constructorName;
    final typeName = constructorName.type.name2.lexeme;

    if (analyzer.isRestrictedClass(typeName)) {
      final constructor = constructorName.name?.name;
      if (constructor != null &&
          analyzer.isRestrictedConstructor(constructor)) {
        issues.add(
          analyzer.createIssue(
            node,
            customMessage:
                '$typeName.$constructor() usage is restricted. '
                'Use CoreIcons constants instead.',
          ),
        );
      }
    }

    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    if (target is SimpleIdentifier) {
      final targetName = target.name;
      final methodName = node.methodName.name;

      if (analyzer.isRestrictedClass(targetName) &&
          analyzer.isRestrictedConstructor(methodName)) {
        issues.add(
          analyzer.createIssue(
            node,
            customMessage:
                '$targetName.$methodName() usage is restricted. '
                'Use CoreIcons constants instead.',
          ),
        );
      }
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    final prefix = node.prefix.name;

    if (analyzer.isRestrictedClass(prefix)) {
      issues.add(
        analyzer.createIssue(
          node,
          customMessage:
              '$prefix usage is restricted outside coreui package. '
              'Use CoreIcons constants instead.',
        ),
      );
    }

    super.visitPrefixedIdentifier(node);
  }

}
