import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';
import '../utils/feature_path_utils.dart';

/// Analyzer that enforces feature module independence.
///
/// This rule prevents feature modules from depending on other feature modules,
/// ensuring each feature can be developed and tested independently.
///
/// Rules:
/// - A feature module (code in lib/features/{feature_name}/*) CANNOT import from other feature modules
/// - A feature module CAN import from:
///   - The same feature module (lib/features/{same_feature_name}/*)
///   - Core, shared, or utility packages
///   - External packages (pub.dev packages)
///   - Flutter/Dart SDK packages
///
/// Example violations:
/// ```dart
/// // lib/features/auth/presentation/screens/login_screen.dart
/// import 'package:project/features/product/data/models/product.dart'; // ❌ Feature importing another feature
/// ```
///
/// Example correct code:
/// ```dart
/// // lib/features/auth/presentation/screens/login_screen.dart
/// import 'package:project/features/auth/data/models/user.dart'; // ✅ Same feature import
/// import 'package:flutter/material.dart'; // ✅ Flutter SDK
class FeatureModuleIsolationAnalyzer extends BaseAnalyzer {
  @override
  String get ruleName => 'feature_module_isolation';

  @override
  String get problemMessage =>
      'Feature modules must not import other feature modules.';

  @override
  String get correctionMessage =>
      'Extract shared code into a shared layer that all features can depend on.';

  @override
  List<LintIssue> analyze(CompilationUnit unit) {
    // Requires file path context; use analyzeWithResolver.
    return [];
  }

  @override
  List<LintIssue> analyzeWithResolver(CompilationUnit unit, dynamic resolver) {
    final filePath = resolver.path ?? '';

    if (!isFeatureModuleFile(filePath)) return [];

    final sourceFeatureName = extractFeatureNameFromPath(filePath);
    if (sourceFeatureName == null) return [];

    final visitor = _FeatureModuleImportVisitor(this, sourceFeatureName);
    unit.accept(visitor);
    return visitor.issues;
  }
}

class _FeatureModuleImportVisitor extends RecursiveAstVisitor<void> {
  final FeatureModuleIsolationAnalyzer analyzer;
  final String sourceFeatureName;
  final List<LintIssue> issues = [];

  _FeatureModuleImportVisitor(this.analyzer, this.sourceFeatureName);

  @override
  void visitImportDirective(ImportDirective node) {
    _validateNoCrossFeatureImport(node);
    super.visitImportDirective(node);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _validateNoCrossFeatureImport(node);
    super.visitExportDirective(node);
  }

  void _validateNoCrossFeatureImport(UriBasedDirective node) {
    final uri = node.uri.stringValue;
    if (uri == null || !uri.startsWith('package:')) return;

    final importedFeatureName = extractFeatureNameFromImport(uri);
    if (importedFeatureName != null &&
        importedFeatureName != sourceFeatureName) {
      issues.add(
        analyzer.createIssue(
          node,
          customMessage:
              'Feature "$sourceFeatureName" must not depend on feature "$importedFeatureName". '
              'Move shared code to a shared layer.',
        ),
      );
    }
  }
}
