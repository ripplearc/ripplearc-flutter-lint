import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';

/// Flags manual dual-theme patterns (`ThemeData?` params, `_dark.png`
/// golden suffixes) in `*_screenshot_test.dart` files.
class ForbidManualScreenshotThemeAnalyzer extends BaseAnalyzer {
  @override
  String get ruleName => 'forbid_manual_screenshot_theme';

  @override
  String get problemMessage =>
      'Manual dual-theme pattern detected. Use screenshotThemeGroups instead.';

  @override
  String get correctionMessage =>
      'Replace manual ThemeData? parameters and _dark.png suffixes with screenshotThemeGroups.';

  @override
  List<LintIssue> analyze(CompilationUnit unit) {
    // Intentionally returns [] — path context is required.
    // Any caller that bypasses analyzeWithResolver gets no violations
    // rather than false positives on non-screenshot files.
    return [];
  }

  @override
  List<LintIssue> analyzeWithResolver(CompilationUnit unit, dynamic resolver) {
    final path = resolver.path as String? ?? '';
    if (shouldSkipFile(path)) return [];
    final visitor = _ForbidManualScreenshotThemeVisitor(this);
    unit.accept(visitor);
    return visitor.issues;
  }

  @override
  bool shouldSkipFile(String path) {
    final basename = path.replaceAll('\\', '/').split('/').last;
    return !basename.endsWith('_screenshot_test.dart');
  }
}

class _ForbidManualScreenshotThemeVisitor extends RecursiveAstVisitor<void> {
  final ForbidManualScreenshotThemeAnalyzer analyzer;
  final List<LintIssue> issues = [];

  _ForbidManualScreenshotThemeVisitor(this.analyzer);

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    final type = node.type;
    if (type is NamedType &&
        type.name2.lexeme == 'ThemeData' &&
        type.question != null) {
      issues.add(
        analyzer.createIssue(
          node,
          customMessage:
              'ThemeData? parameter found in screenshot test. Use screenshotThemeGroups to handle theme variants automatically.',
        ),
      );
    }
    super.visitSimpleFormalParameter(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'matchesGoldenFile') {
      final args = node.argumentList.arguments;
      if (args.isNotEmpty && args.first is SimpleStringLiteral) {
        final literal = args.first as SimpleStringLiteral;
        if (literal.value.endsWith('_dark.png')) {
          issues.add(
            analyzer.createIssue(
              literal,
              customMessage:
                  "Hard-coded '_dark.png' suffix in matchesGoldenFile. Use screenshotThemeGroups to generate golden suffixes automatically.",
            ),
          );
        }
      }
    }
    super.visitMethodInvocation(node);
  }
}
