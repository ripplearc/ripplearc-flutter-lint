// Utilities for normalizing paths and extracting feature names from paths/imports.
// These helpers are used by multiple analyzers and are cached to reduce work.

final RegExp _featuresPathRegExp = RegExp(r'/features/([^/]+)/');

final Map<String, String?> _importFeatureCache = {};
final Map<String, String?> _pathFeatureCache = {};

/// Simple project-level index to register/lookup feature names for paths.
/// This can be seeded once per analysis run if a project-wide scan is needed.
class ProjectFeatureIndex {
  static final Map<String, String> _index = {};

  /// Register a path -> feature mapping explicitly.
  static void register(String path, String feature) {
    _index[_normalizePath(path)] = feature;
  }

  /// Bulk register a list of paths (will extract features lazily).
  static void seedPaths(Iterable<String> paths) {
    for (final p in paths) {
      final feature = extractFeatureNameFromPath(p);
      if (feature != null) _index[_normalizePath(p)] = feature;
    }
  }

  /// Get feature for a path if present in the index, otherwise null.
  static String? getFeature(String path) => _index[_normalizePath(path)];

  /// Clear the index.
  static void clear() => _index.clear();
}

String _normalizePath(String path) => path.replaceAll('\\', '/');

bool isFeatureModuleFile(String path) {
  final normalized = _normalizePath(path);
  return normalized.contains('/lib/features/');
}

String? extractFeatureNameFromPath(String path) {
  final normalized = _normalizePath(path);
  return _pathFeatureCache.putIfAbsent(normalized, () {
    final match = _featuresPathRegExp.firstMatch(normalized);
    return match != null && match.groupCount >= 1 ? match.group(1) : null;
  });
}

String? extractFeatureNameFromImport(String importUri) {
  // importUri is typically like: 'package:project/features/product/data/...'
  return _importFeatureCache.putIfAbsent(importUri, () {
    final match = _featuresPathRegExp.firstMatch(importUri);
    return match != null && match.groupCount >= 1 ? match.group(1) : null;
  });
}
