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
  /// CoreUI color token class prefixes to detect
  static const _coreColorClasses = [
    'CoreTextColors',
    'CoreBackgroundColors',
    'CoreBorderColors',
    'CoreIconColors',
    'CoreButtonColors',
    'CoreStatusColors',
    'CoreChipColors',
    'CoreAlertColors',
    'CoreKeyboardColors',
    'CoreShadowColors',
    'CoreBrandColors',
  ];

  /// Flutter color classes to detect
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

  /// Checks if the identifier is a CoreUI color class
  bool isCoreColorClass(String identifier) {
    return _coreColorClasses.contains(identifier);
  }

  /// Checks if the identifier is a Flutter color class (Colors, CupertinoColors)
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

    // Skip if parent is IndexExpression (e.g., Colors.grey[700])
    // The IndexExpression visitor will handle this case with a more complete message
    if (node.parent is IndexExpression) {
      super.visitPrefixedIdentifier(node);
      return;
    }

    // Check for CoreUI color classes (CoreTextColors.headline, etc.)
    if (analyzer.isCoreColorClass(prefix)) {
      issues.add(analyzer.createIssue(
        node,
        customMessage:
            'Static color token "$prefix.${node.identifier.name}" detected. '
            'Use Theme.of(context).extension<AppColorsExtension>() instead.',
      ));
    }

    // Check for Flutter Colors/CupertinoColors class (Colors.white, CupertinoColors.systemRed, etc.)
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
    // Skip if parent is IndexExpression (e.g., m.Colors.grey[700])
    // The IndexExpression visitor will handle this case with a more complete message
    if (node.parent is IndexExpression) {
      super.visitPropertyAccess(node);
      return;
    }

    // Check for prefixed imports like MaterialUI.Colors.red or MaterialUI.CupertinoColors.systemRed
    // The AST structure is: PropertyAccess(target: PrefixedIdentifier(MaterialUI.Colors), property: red)
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
    // Check for Colors.grey[700] or CupertinoColors.systemGrey[700] pattern
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

    // Check for prefixed import index access: MaterialUI.Colors.grey[700]
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

    // Check for Color(...) - direct color definition
    if (typeName == 'Color') {
      final constructorNameElement = constructorName.name?.name;

      if (constructorNameElement == null) {
        // Color(...) - unnamed constructor with integer value (hex or decimal)
        final arguments = node.argumentList.arguments;
        if (arguments.isNotEmpty) {
          final firstArg = arguments.first;
          // Flag any integer literal (hex like 0xFF... or decimal like 4278190080)
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
        // Color.fromARGB(...) or Color.fromRGBO(...) as named constructor
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

    // Check for Color(...) when parsed as MethodInvocation with null target
    // This happens when using parseString without type resolution
    if (target == null && methodName == 'Color') {
      final arguments = node.argumentList.arguments;
      if (arguments.isNotEmpty) {
        final firstArg = arguments.first;
        // Flag any integer literal (hex like 0xFF... or decimal like 4278190080)
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

    // Check for prefixed import: MaterialUI.Color(0xFF...) or MaterialUI.Color(decimal)
    // AST: MethodInvocation(target: SimpleIdentifier(MaterialUI), methodName: Color)
    if (target is SimpleIdentifier && methodName == 'Color') {
      final arguments = node.argumentList.arguments;
      if (arguments.isNotEmpty) {
        final firstArg = arguments.first;
        // Flag any integer literal (hex like 0xFF... or decimal like 4278190080)
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

    // Check for Color.fromARGB(...) and Color.fromRGBO(...) as static method calls
    // These may be parsed as MethodInvocation when not resolved
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

    // Check for prefixed import: MaterialUI.Color.fromARGB(...) or MaterialUI.Color.fromRGBO(...)
    // AST: MethodInvocation(target: PrefixedIdentifier(MaterialUI.Color), methodName: fromARGB)
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

    // Check for Colors/CupertinoColors.black.withOpacity(...) etc.
    // The target would be a PrefixedIdentifier which is already caught,
    // but we want to flag the entire chain
    if (target is PrefixedIdentifier && analyzer.isFlutterColorClass(target.prefix.name)) {
      // Already flagged by visitPrefixedIdentifier, skip to avoid duplicate
      super.visitMethodInvocation(node);
      return;
    }

    // Check for method calls on Color like Color(0xFF...).withOpacity(...)
    if (target is InstanceCreationExpression) {
      final typeName = target.constructorName.type.name2.lexeme;
      if (typeName == 'Color') {
        // Already flagged by visitInstanceCreationExpression, skip to avoid duplicate
        super.visitMethodInvocation(node);
        return;
      }
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    // Handle Color(...) when parsed as function invocation
    final function = node.function;
    
    // Check for Color(...) with simple identifier
    if (function is SimpleIdentifier && function.name == 'Color') {
      final arguments = node.argumentList.arguments;
      if (arguments.isNotEmpty) {
        final firstArg = arguments.first;
        // Flag any integer literal (hex like 0xFF... or decimal like 4278190080)
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

    // Check for prefixed import: MaterialUI.Color(0xFF...) or MaterialUI.Color(decimal)
    // AST: FunctionExpressionInvocation(function: PrefixedIdentifier(MaterialUI.Color))
    if (function is PrefixedIdentifier && function.identifier.name == 'Color') {
      final arguments = node.argumentList.arguments;
      if (arguments.isNotEmpty) {
        final firstArg = arguments.first;
        // Flag any integer literal (hex like 0xFF... or decimal like 4278190080)
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

