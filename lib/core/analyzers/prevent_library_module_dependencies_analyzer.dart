import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';

/// Analyzer that enforces library module independence from feature modules.
///
/// This rule prevents library modules from depending on feature modules,
/// ensuring libraries remain reusable and do not have feature-specific dependencies.
///
/// Rules:
/// - A library module (code in lib/libraries/*) CANNOT import from feature modules
/// - A library module CAN import from:
///   - Other library modules (lib/libraries/*)
///   - External packages (pub.dev packages)
///   - Flutter/Dart SDK packages
///
/// Example violations:
/// ```dart
/// // lib/libraries/auth/data/models/user.dart
/// import 'package:project/features/dashboard/data/models/dashboard.dart'; // ❌ Library importing a feature
/// ```
///
/// Example correct code:
/// ```dart
/// // lib/libraries/auth/data/models/user.dart
/// import 'package:project/libraries/time/interfaces/clock.dart'; // ✅ Library importing another library
/// import 'package:flutter/material.dart'; // ✅ Flutter SDK
/// ```
class LibraryModuleDependenciesAnalyzer extends BaseAnalyzer {
  @override
  String get ruleName => 'library_module_no_feature_dependencies';

  @override
  String get problemMessage =>
      'Library modules must not import feature modules.';

  @override
  String get correctionMessage =>
      'Libraries should only depend on other libraries, core packages, or external packages.';

  @override
  List<LintIssue> analyze(CompilationUnit unit) {
    return [];
  }

  @override
  List<LintIssue> analyzeWithResolver(CompilationUnit unit, dynamic resolver) {
    final filePath = resolver.path ?? '';

    if (!_isLibraryModuleFile(filePath)) return [];

    final visitor = _LibraryModuleImportVisitor(this);
    unit.accept(visitor);
    return visitor.issues;
  }

  bool _isLibraryModuleFile(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.contains('/libraries/');
  }
}

class _LibraryModuleImportVisitor extends RecursiveAstVisitor<void> {
  final LibraryModuleDependenciesAnalyzer analyzer;
  final List<LintIssue> issues = [];

  _LibraryModuleImportVisitor(this.analyzer);

  @override
  void visitImportDirective(ImportDirective node) {
    _validateNoFeatureImport(node);
    super.visitImportDirective(node);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _validateNoFeatureImport(node);
    super.visitExportDirective(node);
  }

  void _validateNoFeatureImport(UriBasedDirective node) {
    final uri = node.uri.stringValue;
    if (uri == null) return;

    if (_containsFeatureImport(uri)) {
      issues.add(
        analyzer.createIssue(
          node,
          customMessage:
              'Library modules cannot import from feature modules. '
              'Import URI "$uri" contains "/features/". '
              'Libraries should only depend on other libraries or external packages.',
        ),
      );
    }
  }

  bool _containsFeatureImport(String uri) {
    return uri.contains('/features/');
  }
}
