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
/// import 'package:project/core/constants/app_constants.dart'; // ✅ Core layer import
/// import 'package:project/shared/widgets/app_button.dart'; // ✅ Shared layer import
/// import 'package:flutter/material.dart'; // ✅ Flutter SDK
/// ```
class PreventFeatureModuleDependenciesAnalyzer extends BaseAnalyzer {
  @override
  String get ruleName => 'prevent_feature_module_dependencies';

  @override
  String get problemMessage =>
      'Avoid importing from other feature modules; extract shared code to core/shared layers or a common package.';

  @override
  String get correctionMessage =>
      'Move shared code to a core or shared layer that all features can depend on.';

  @override
  List<LintIssue> analyze(CompilationUnit unit) {
    // This analyzer requires file path context, which is provided via analyzeWithResolver
    return [];
  }

  @override
  List<LintIssue> analyzeWithResolver(CompilationUnit unit, dynamic resolver) {
    final path = resolver.path ?? '';

    // Only check files that are in the features directory
    if (!isFeatureModuleFile(path)) {
      return [];
    }

    // Extract the current feature name from the file path
    final currentFeature = extractFeatureNameFromPath(path);
    if (currentFeature == null) {
      return [];
    }

    final visitor = _FeatureDependencyVisitor(this, currentFeature);
    unit.accept(visitor);
    return visitor.issues;
  }

  // Helper methods moved to `lib/core/utils/feature_path_utils.dart` to
  // centralize logic and caching for feature path extraction and normalization.
}

class _FeatureDependencyVisitor extends RecursiveAstVisitor<void> {
  final PreventFeatureModuleDependenciesAnalyzer analyzer;
  final String currentFeature;
  final List<LintIssue> issues = [];

  _FeatureDependencyVisitor(this.analyzer, this.currentFeature);

  @override
  void visitImportDirective(ImportDirective node) {
    _checkDependency(node);
    super.visitImportDirective(node);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _checkDependency(node);
    super.visitExportDirective(node);
  }

  void _checkDependency(UriBasedDirective node) {
    final uri = node.uri.stringValue;

    // Only check package: imports (not relative imports)
    if (uri == null || !uri.startsWith('package:')) {
      return;
    }

    // Check if this import is from another feature module
    final importedFeature = extractFeatureNameFromImport(uri);

    if (importedFeature != null && importedFeature != currentFeature) {
      // This is an import from a different feature module - violation!
      issues.add(
        analyzer.createIssue(
          node,
          customMessage:
              'Feature module "$currentFeature" cannot depend on feature module "$importedFeature". '
              'Move shared code to a core or shared layer instead.',
        ),
      );
    }
  }
}
