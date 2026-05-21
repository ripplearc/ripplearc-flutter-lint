import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';

/// Analyzer that prevents direct usage of raw Flutter icons and Image.asset.
///
/// This rule enforces icon abstraction by requiring developers to use the `CoreIcons`
/// constants instead of directly instantiating `Icon` with `Icons.xxx` or using `Image.asset`.
///
/// Example of code that triggers this rule:
/// ```dart
/// final icon = Icon(Icons.import_contacts); // LINT
/// final image = Image.asset('assets/image.png'); // LINT
/// ```
class ForbidRawIconAndImageUsageAnalyzer extends BaseAnalyzer {
  @override
  String get ruleName => 'forbid_raw_icon_and_image_usage';

  @override
  String get problemMessage =>
      'Raw Flutter icons and direct Image.asset usages are restricted. Use CoreIcons and coreui components instead.';

  @override
  String get correctionMessage =>
      'Use CoreIcons constants or properly abstracted coreui components.';

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
    final visitor = _ForbidRawIconAndImageUsageVisitor(this);
    unit.accept(visitor);
    return visitor.issues;
  }

  @override
  bool shouldSkipFile(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.contains('/coreui/lib/') ||
        normalized.contains('/coreui/test/');
  }
}

class _ForbidRawIconAndImageUsageVisitor extends RecursiveAstVisitor<void> {
  final ForbidRawIconAndImageUsageAnalyzer analyzer;
  final List<LintIssue> issues = [];

  _ForbidRawIconAndImageUsageVisitor(this.analyzer);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorName = node.constructorName;
    final typeName = constructorName.type.name2.lexeme;

    if (typeName == 'Icon') {
      issues.add(
        analyzer.createIssue(
          node,
          customMessage:
              'Direct usage of Icon() is restricted. Use CoreIcons and coreui components instead.',
        ),
      );
    }

    final importPrefix = constructorName.type.importPrefix?.name.lexeme;
    if (importPrefix == 'Image' && typeName == 'asset') {
      issues.add(
        analyzer.createIssue(
          node,
          customMessage:
              'Direct usage of Image.asset() is restricted. Use coreui components instead.',
        ),
      );
    }

    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    if (target is SimpleIdentifier &&
        target.name == 'Image' &&
        node.methodName.name == 'asset') {
      issues.add(
        analyzer.createIssue(
          node,
          customMessage:
              'Direct usage of Image.asset() is restricted. Use coreui components instead.',
        ),
      );
    }

    super.visitMethodInvocation(node);
  }
}
