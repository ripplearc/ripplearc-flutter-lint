import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as path;

import '../models/lint_issue.dart';
import 'base_analyzer.dart';
import 'forbid_direct_storage_access_config.dart';
import 'forbid_direct_storage_access_config_parser.dart';

/// Analyzer that forbids using `shared_preferences`, `path_provider` and
/// `flutter_secure_storage` outside the storage library.
///
/// Everything an app keeps on the device goes through one storage library, so
/// sign-out can find and delete it. A file outside the library folder may use
/// these packages only when `analysis_options.yaml` lists its exact path.
///
/// Example violation:
/// ```dart
/// // lib/features/estimation/data/last_unit.dart
/// import 'package:shared_preferences/shared_preferences.dart'; // ❌
/// ```
class ForbidDirectStorageAccessAnalyzer extends BaseAnalyzer {
  /// Creates the analyzer. [config] replaces the one read from disk and is
  /// meant for tests.
  ForbidDirectStorageAccessAnalyzer({ForbidDirectStorageAccessConfig? config})
    : _config = config;

  final ForbidDirectStorageAccessConfig? _config;
  final Map<String, ForbidDirectStorageAccessConfig> _configCache = {};

  static const _forbiddenPackages = {
    'shared_preferences',
    'path_provider',
    'flutter_secure_storage',
  };

  @override
  String get ruleName => 'forbid_direct_storage_access';

  @override
  String get problemMessage =>
      'Do not use shared_preferences, path_provider or flutter_secure_storage '
      'directly. Use the storage library.';

  @override
  String get correctionMessage =>
      'Call the storage library in lib/libraries/storage/ instead, or add this '
      'exact file to allowed_files in analysis_options.yaml.';

  @override
  bool shouldSkipFile(String path) =>
      path.endsWith('.g.dart') || path.endsWith('.freezed.dart');

  @override
  List<LintIssue> analyze(CompilationUnit unit) => [];

  @override
  List<LintIssue> analyzeWithResolver(CompilationUnit unit, dynamic resolver) {
    final filePath = resolver.path as String?;
    if (filePath == null || shouldSkipFile(filePath)) return [];

    final config = _configFor(filePath);
    if (config.allows(_relativePathOf(filePath))) return [];

    final visitor = _StorageImportVisitor(this);
    unit.accept(visitor);
    return visitor.issues;
  }

  ForbidDirectStorageAccessConfig _configFor(String filePath) {
    final injected = _config;
    if (injected != null) return injected;

    final root =
        ForbidDirectStorageAccessConfigParser.projectRootOf(filePath) ??
        filePath;
    return _configCache.putIfAbsent(
      root,
      () => ForbidDirectStorageAccessConfigParser.loadFromFile(filePath),
    );
  }

  String _relativePathOf(String filePath) {
    final root = ForbidDirectStorageAccessConfigParser.projectRootOf(filePath);
    final relative =
        root == null ? filePath : path.relative(filePath, from: root);
    final normalized = ForbidDirectStorageAccessConfigParser.normalize(
      relative,
    );
    return normalized.startsWith('/') ? normalized.substring(1) : normalized;
  }
}

class _StorageImportVisitor extends RecursiveAstVisitor<void> {
  final ForbidDirectStorageAccessAnalyzer analyzer;
  final List<LintIssue> issues = [];

  _StorageImportVisitor(this.analyzer);

  @override
  void visitImportDirective(ImportDirective node) {
    _check(node);
    super.visitImportDirective(node);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _check(node);
    super.visitExportDirective(node);
  }

  void _check(NamespaceDirective node) {
    final uris = [
      node.uri.stringValue,
      for (final configuration in node.configurations)
        configuration.uri.stringValue,
    ];
    for (final uri in uris) {
      final package = uri == null ? null : _forbiddenPackageOf(uri);
      if (package == null) continue;
      issues.add(
        analyzer.createIssue(
          node,
          customMessage:
              'Do not use $package directly. Use the storage library in '
              'lib/libraries/storage/.',
        ),
      );
      return;
    }
  }

  String? _forbiddenPackageOf(String uri) {
    const scheme = 'package:';
    if (!uri.startsWith(scheme)) return null;
    final package = uri.substring(scheme.length).split('/').first;
    return ForbidDirectStorageAccessAnalyzer._forbiddenPackages.contains(
          package,
        )
        ? package
        : null;
  }
}
