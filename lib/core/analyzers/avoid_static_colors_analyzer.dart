import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';

/// Analyzer that enforces theme-context-based color access.
///
/// This rule flags static color tokens and direct color definitions that break
/// theme switching (light/dark mode). Colors should be accessed via
/// `Theme.of(context).extension<AppColorsExtension>()` instead.
///
/// Violations detected:
/// - CoreUI static color token classes (CoreTextColors, CoreBackgroundColors, etc.)
/// - Flutter's Colors and CupertinoColors classes
/// - Direct Color definitions (hex, decimal, fromARGB, fromRGBO)
/// - Prefixed imports (e.g., MaterialUI.Colors.red)
///
/// Example of code that triggers this rule:
/// ```dart
/// // Using static CoreUI tokens
/// color: CoreTextColors.headline,
/// backgroundColor: CoreBackgroundColors.pageBackground,
///
/// // Using Flutter Colors class
/// color: Colors.white,
/// color: Colors.grey[700],
/// color: CupertinoColors.systemRed,
///
/// // Using direct colors (hex or decimal)
/// color: Color(0xFF015B7C),
/// color: Color(4278190080),
/// color: Color.fromARGB(255, 0, 0, 0),
///
/// // Using prefixed imports
/// color: MaterialUI.Colors.red,
/// ```
///
/// Example of correct code:
/// ```dart
/// final colors = Theme.of(context).extension<AppColorsExtension>()!;
/// color: colors.textHeadline,
/// backgroundColor: colors.pageBackground,
/// ```
class AvoidStaticColorsAnalyzer extends BaseAnalyzer {
  
  static final _coreColorPattern = RegExp(r'^Core\w+Colors$');

  static const _flutterColorClasses = [
    'Colors',
    'CupertinoColors',
  ];

  @override
  String get ruleName => 'avoid_static_colors';

  @override
  String get problemMessage =>
      'Static color usage detected. Use Theme.of(context).extension<AppColorsExtension>() instead.';

  @override
  String get correctionMessage =>
      'Access colors via Theme.of(context).extension<AppColorsExtension>()! for proper light/dark mode support.';

  @override
  List<LintIssue> analyze(CompilationUnit unit) {
    final visitor = _StaticColorVisitor(this);
    unit.accept(visitor);
    return visitor.issues;
  }

  bool isCoreColorClass(String identifier) {
    return _coreColorPattern.hasMatch(identifier);
  }

  bool isFlutterColorClass(String identifier) {
    return _flutterColorClasses.contains(identifier);
  }
}

class _StaticColorVisitor extends RecursiveAstVisitor<void> {
  final AvoidStaticColorsAnalyzer analyzer;
  final List<LintIssue> issues = [];

  _StaticColorVisitor(this.analyzer);

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    final prefix = node.prefix.name;

    if (node.parent is IndexExpression) {
      super.visitPrefixedIdentifier(node);
      return;
    }

    if (analyzer.isCoreColorClass(prefix)) {
      issues.add(analyzer.createIssue(
        node,
        customMessage:
            'Static color token "$prefix.${node.identifier.name}" detected. '
            'Use Theme.of(context).extension<AppColorsExtension>() instead.',
      ));
    }

    if (analyzer.isFlutterColorClass(prefix)) {
      issues.add(analyzer.createIssue(
        node,
        customMessage:
            'Flutter $prefix class usage "$prefix.${node.identifier.name}" detected. '
            'Use Theme.of(context).extension<AppColorsExtension>() instead.',
      ));
    }

    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.parent is IndexExpression) {
      super.visitPropertyAccess(node);
      return;
    }

    final target = node.target;
    if (target is PrefixedIdentifier) {
      final colorClass = target.identifier.name;
      if (analyzer.isFlutterColorClass(colorClass)) {
        issues.add(analyzer.createIssue(
          node,
          customMessage:
              'Flutter $colorClass class usage (via prefixed import) "${node.toSource()}" detected. '
              'Use Theme.of(context).extension<AppColorsExtension>() instead.',
        ));
      }
    }

    super.visitPropertyAccess(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    final target = node.target;
    if (target is PrefixedIdentifier && analyzer.isFlutterColorClass(target.prefix.name)) {
      final colorClass = target.prefix.name;
      issues.add(analyzer.createIssue(
        node,
        customMessage:
            'Flutter $colorClass class index access "$colorClass.${target.identifier.name}[...]" detected. '
            'Use Theme.of(context).extension<AppColorsExtension>() instead.',
      ));
    }

    if (target is PropertyAccess) {
      final propertyTarget = target.target;
      if (propertyTarget is PrefixedIdentifier) {
        final colorClass = propertyTarget.identifier.name;
        if (analyzer.isFlutterColorClass(colorClass)) {
          issues.add(analyzer.createIssue(
            node,
            customMessage:
                'Flutter $colorClass class index access (via prefixed import) "${node.toSource()}" detected. '
                'Use Theme.of(context).extension<AppColorsExtension>() instead.',
          ));
        }
      }
    }

    super.visitIndexExpression(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorName = node.constructorName;
    final typeName = constructorName.type.name2.lexeme;

    if (typeName == 'Color') {
      final constructorNameElement = constructorName.name?.name;

      if (constructorNameElement == null) {
        final arguments = node.argumentList.arguments;
        if (arguments.isNotEmpty) {
          final firstArg = arguments.first;
          if (firstArg is IntegerLiteral) {
            final argString = firstArg.toSource();
            issues.add(analyzer.createIssue(
              node,
              customMessage:
                  'Direct color definition "Color($argString)" detected. '
                  'Use Theme.of(context).extension<AppColorsExtension>() instead.',
            ));
          }
        }
      } else if (constructorNameElement == 'fromARGB' ||
          constructorNameElement == 'fromRGBO') {
        issues.add(analyzer.createIssue(
          node,
          customMessage:
              'Direct color definition "Color.$constructorNameElement(...)" detected. '
              'Use Theme.of(context).extension<AppColorsExtension>() instead.',
        ));
      }
    }

    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    final methodName = node.methodName.name;

    if (target == null && methodName == 'Color') {
      final arguments = node.argumentList.arguments;
      if (arguments.isNotEmpty) {
        final firstArg = arguments.first;
        if (firstArg is IntegerLiteral) {
          final argString = firstArg.toSource();
          issues.add(analyzer.createIssue(
            node,
            customMessage:
                'Direct color definition "Color($argString)" detected. '
                'Use Theme.of(context).extension<AppColorsExtension>() instead.',
          ));
        }
      }
    }

    if (target is SimpleIdentifier && methodName == 'Color') {
      final arguments = node.argumentList.arguments;
      if (arguments.isNotEmpty) {
        final firstArg = arguments.first;
        if (firstArg is IntegerLiteral) {
          issues.add(analyzer.createIssue(
            node,
            customMessage:
                'Direct color definition (via prefixed import) "${node.toSource()}" detected. '
                'Use Theme.of(context).extension<AppColorsExtension>() instead.',
          ));
        }
      }
    }

    if (target is SimpleIdentifier && target.name == 'Color') {
      if (methodName == 'fromARGB' || methodName == 'fromRGBO') {
        issues.add(analyzer.createIssue(
          node,
          customMessage:
              'Direct color definition "Color.$methodName(...)" detected. '
              'Use Theme.of(context).extension<AppColorsExtension>() instead.',
        ));
      }
    }

    if (target is PrefixedIdentifier && target.identifier.name == 'Color') {
      if (methodName == 'fromARGB' || methodName == 'fromRGBO') {
        issues.add(analyzer.createIssue(
          node,
          customMessage:
              'Direct color definition (via prefixed import) "${node.toSource()}" detected. '
              'Use Theme.of(context).extension<AppColorsExtension>() instead.',
        ));
      }
    }

    if (target is PrefixedIdentifier &&
        analyzer.isFlutterColorClass(target.prefix.name)) {
      super.visitMethodInvocation(node);
      return;
    }

    if (target is InstanceCreationExpression) {
      final typeName = target.constructorName.type.name2.lexeme;
      if (typeName == 'Color') {
        super.visitMethodInvocation(node);
        return;
      }
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    final function = node.function;

    if (function is SimpleIdentifier && function.name == 'Color') {
      final arguments = node.argumentList.arguments;
      if (arguments.isNotEmpty) {
        final firstArg = arguments.first;
        if (firstArg is IntegerLiteral) {
          final argString = firstArg.toSource();
          issues.add(analyzer.createIssue(
            node,
            customMessage:
                'Direct color definition "Color($argString)" detected. '
                'Use Theme.of(context).extension<AppColorsExtension>() instead.',
          ));
        }
      }
    }

    if (function is PrefixedIdentifier && function.identifier.name == 'Color') {
      final arguments = node.argumentList.arguments;
      if (arguments.isNotEmpty) {
        final firstArg = arguments.first;
        if (firstArg is IntegerLiteral) {
          issues.add(analyzer.createIssue(
            node,
            customMessage:
                'Direct color definition (via prefixed import) "${node.toSource()}" detected. '
                'Use Theme.of(context).extension<AppColorsExtension>() instead.',
          ));
        }
      }
    }

    super.visitFunctionExpressionInvocation(node);
  }
}

