import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';
import '../utils/feature_path_utils.dart';

/// Analyzer that forbids importing a feature's internals from outside the
/// feature except through that feature's own provider file.
///
/// A feature's provider file is `{feature_name}_feature_module.dart` inside
/// `lib/features/{feature_name}/` — the single file that implements the
/// `FeatureModule`/`TabEntry` contract and is meant to be the feature's only
/// public door (see the "Per-Flavor Feature Module Exclusion" HLD, CA-923).
///
/// Rules:
/// - Code inside `lib/features/{feature_name}/*` CAN import anything within
///   the same feature freely (already covered by `feature_module_isolation`).
/// - Code outside `lib/features/{feature_name}/*` CAN only import
///   `package:.../features/{feature_name}/{feature_name}_feature_module.dart`.
///   Any deeper import (e.g. a domain entity, a screen, a bloc) is forbidden.
///
/// Example violation:
/// ```dart
/// // lib/app/enabled_features.dart
/// import 'package:project/features/estimation/domain/entities/estimate.dart'; // ❌ deep import
/// ```
///
/// Example correct code:
/// ```dart
/// // lib/app/enabled_features.dart
/// import 'package:project/features/estimation/estimation_feature_module.dart'; // ✅ provider file
/// ```
class ForbidFeatureImportOutsideProviderAnalyzer extends BaseAnalyzer {
  @override
  String get ruleName => 'forbid_feature_import_outside_provider';

  @override
  String get problemMessage =>
      'A feature can only be imported from outside through its own provider file.';

  @override
  String get correctionMessage =>
      'Import that feature\'s own "*_feature_module.dart" file instead, or move this code inside the feature.';

  @override
  List<LintIssue> analyze(CompilationUnit unit) {
    // Requires file path context; use analyzeWithResolver.
    return [];
  }

  @override
  List<LintIssue> analyzeWithResolver(CompilationUnit unit, dynamic resolver) {
    final filePath = resolver.path ?? '';

    // Code inside a feature is already covered by feature_module_isolation.
    if (isFeatureModuleFile(filePath)) return [];

    final visitor = _ProviderImportVisitor(this);
    unit.accept(visitor);
    return visitor.issues;
  }
}

class _ProviderImportVisitor extends RecursiveAstVisitor<void> {
  final ForbidFeatureImportOutsideProviderAnalyzer analyzer;
  final List<LintIssue> issues = [];

  _ProviderImportVisitor(this.analyzer);

  @override
  void visitImportDirective(ImportDirective node) {
    _validateProviderOnlyImport(node);
    super.visitImportDirective(node);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _validateProviderOnlyImport(node);
    super.visitExportDirective(node);
  }

  void _validateProviderOnlyImport(UriBasedDirective node) {
    final uri = node.uri.stringValue;
    if (uri == null || !uri.startsWith('package:')) return;

    final featureName = extractFeatureNameFromImport(uri);
    if (featureName == null) return;
    if (_isProviderFileImport(uri, featureName)) return;

    issues.add(
      analyzer.createIssue(
        node,
        customMessage:
            'Feature "$featureName" must only be imported through its provider file '
            '"${featureName}_feature_module.dart". Move this code behind that file '
            'or import it instead.',
      ),
    );
  }

  bool _isProviderFileImport(String uri, String featureName) {
    final normalized = uri.replaceAll('\\', '/');
    return normalized.endsWith('/features/$featureName/${featureName}_feature_module.dart');
  }
}
