import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';

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
      'Feature modules cannot depend on other feature modules.';

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
    if (!_isFeatureModuleFile(path)) {
      return [];
    }

    // Extract the current feature name from the file path
    final currentFeature = _extractFeatureNameFromPath(path);
    if (currentFeature == null) {
      return [];
    }

    final visitor = _FeatureDependencyVisitor(this, currentFeature);
    unit.accept(visitor);
    return visitor.issues;
  }

  /// Checks if a file is part of a feature module.
  /// A file is considered part of a feature module if its path contains
  /// 'lib/features/{feature_name}' directory structure.
  bool _isFeatureModuleFile(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.contains('/lib/features/');
  }

  /// Extracts the feature name from a file path.
  /// For example: '/project/lib/features/auth/presentation/screens/login.dart' -> 'auth'
  String? _extractFeatureNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');

    // Look for the pattern: /lib/features/{feature_name}/
    final match = RegExp(r'/lib/features/([^/]+)/').firstMatch(normalized);

    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }

    return null;
  }

  /// Checks if an import is from a feature module.
  /// Returns the feature name if it is (e.g., 'product'), or null if it's not.
  String? _extractFeatureNameFromImport(String importUri) {
    // We're looking for patterns like:
    // 'package:project/features/product/data/models/product.dart'
    // The package name could be any project name, so we just look for /features/{feature_name}/

    final match = RegExp(r'/features/([^/]+)/').firstMatch(importUri);

    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }

    return null;
  }
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
    final importedFeature = analyzer._extractFeatureNameFromImport(uri);

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
