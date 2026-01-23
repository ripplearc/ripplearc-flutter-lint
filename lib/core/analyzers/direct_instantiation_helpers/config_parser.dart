import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart' as yaml;
import 'linter_config.dart';

/// Parser for reading LinterConfig from custom_lint configuration.
///
/// **Primary Usage (custom_lint plugin):**
/// Parses the `custom_lint.rules.no_direct_instantiation` section from
/// the configuration map provided by CustomLintConfigs and converts it
/// to a `LinterConfig` instance.
///
/// **Standalone Usage:**
/// For standalone tools (like standalone_checker), file-based loading
/// is available but should be used sparingly as it performs synchronous I/O.
class LinterConfigParser {
  static LinterConfig? parseFromRules(Map<String, Object?>? rules) {
    if (rules == null) return null;

    final ruleConfig = rules['no_direct_instantiation'];
    if (ruleConfig == null || ruleConfig is! Map) return null;

    try {
      final defaults = LinterConfig.defaults();

      return LinterConfig(
        allowedPackagePrefixes: _parseAndMergeSet(
          ruleConfig['allowed_package_prefixes'],
          defaults.allowedPackagePrefixes,
        ),
        ignoredBaseClasses: _parseAndMergeSet(
          ruleConfig['ignored_base_classes'],
          defaults.ignoredBaseClasses,
        ),
        safeValueObjects: _parseAndMergeSet(
          ruleConfig['safe_value_objects'],
          defaults.safeValueObjects,
        ),
        filePathPatterns: _parseAndMergeList(
          ruleConfig['file_path_patterns'],
          defaults.filePathPatterns,
        ),
        astTypeNames: _parseAndMergeSet(
          ruleConfig['ast_type_names'],
          defaults.astTypeNames,
        ),
        astTypeSuffixes: _parseAndMergeSet(
          ruleConfig['ast_type_suffixes'],
          defaults.astTypeSuffixes,
        ),
        astMethodNames: _parseAndMergeSet(
          ruleConfig['ast_method_names'],
          defaults.astMethodNames,
        ),
        astKeywords: _parseAndMergeSet(
          ruleConfig['ast_keywords'],
          defaults.astKeywords,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  static Set<String> _parseAndMergeSet(dynamic value, Set<String> defaults) {
    return _mergeSet(defaults, _parseStringSet(value));
  }

  static List<RegExp> _parseAndMergeList(dynamic value, List<RegExp> defaults) {
    return _mergeList(defaults, _parseRegexList(value));
  }

  static Set<String> _mergeSet(Set<String> defaults, Set<String> userValues) {
    return userValues.isEmpty ? defaults : {...defaults, ...userValues};
  }

  static List<RegExp> _mergeList(
    List<RegExp> defaults,
    List<RegExp> userValues,
  ) {
    return userValues.isEmpty ? defaults : [...defaults, ...userValues];
  }

  static Set<String> _parseStringSet(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toSet();
    }
    return const {};
  }

  static List<RegExp> _parseRegexList(dynamic value) {
    if (value is List) {
      return value
          .map((e) {
            try {
              return RegExp(e.toString(), caseSensitive: false);
            } catch (_) {
              return null;
            }
          })
          .whereType<RegExp>()
          .toList();
    }
    return [];
  }

  static LinterConfig? loadFromFile([String? filePath]) {
    try {
      if (filePath != null && filePath.isNotEmpty) {
        final config = _tryLoadFromProjectRoot(filePath);
        if (config != null) return config;
      }

      final config = _tryLoadFromCurrentDirectory();
      if (config != null) return config;

      return _tryLoadFromSearchPaths();
    } catch (e) {
      return null;
    }
  }

  static LinterConfig? _tryLoadFromProjectRoot(String filePath) {
    final projectRoot = _findProjectRoot(filePath);
    if (projectRoot == null) return null;

    return _tryLoadConfigFile(projectRoot);
  }

  static LinterConfig? _tryLoadFromCurrentDirectory() {
    try {
      final currentDir = Directory.current.path;
      final projectRoot = _findProjectRoot(currentDir);
      if (projectRoot == null) return null;

      return _tryLoadConfigFile(projectRoot);
    } catch (_) {
      return null;
    }
  }

  static LinterConfig? _tryLoadFromSearchPaths() {
    final searchPaths = ['.', '../', '../../', '../../../'];
    for (final searchPath in searchPaths) {
      try {
        final config = _tryLoadConfigFile(searchPath);
        if (config != null) return config;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  static LinterConfig? _tryLoadConfigFile(String directory) {
    final configFile = File(path.join(directory, 'analysis_options.yaml'));
    if (!configFile.existsSync()) return null;

    return _parseConfigFile(configFile);
  }

  static String? _findProjectRoot(String filePath) {
    try {
      final isDir = FileSystemEntity.isDirectorySync(filePath);
      final entity = isDir ? Directory(filePath) : File(filePath);

      final startDir =
          entity is File
              ? Directory(entity.parent.path)
              : Directory(entity.path);

      var current = startDir;
      for (var i = 0; i < 10; i++) {
        final configFile = File(
          path.join(current.path, 'analysis_options.yaml'),
        );
        if (configFile.existsSync()) {
          return current.path;
        }
        final parent = current.parent;
        if (parent.path == current.path) break;
        current = parent;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static LinterConfig? _parseConfigFile(File file) {
    try {
      final content = file.readAsStringSync();
      final yamlDoc = yaml.loadYaml(content);

      if (yamlDoc is! Map) return null;

      final configMap = Map<String, dynamic>.from(
        yamlDoc.map((k, v) => MapEntry(k.toString(), v)),
      );

      final ruleConfig = _extractRuleConfig(configMap);
      if (ruleConfig == null) return null;

      final rulesMap = <String, Object?>{'no_direct_instantiation': ruleConfig};
      return parseFromRules(rulesMap);
    } catch (e) {
      return null;
    }
  }

  static Map? _extractRuleConfig(Map<String, dynamic> configMap) {
    final customLint = configMap['custom_lint'];
    if (customLint is! Map) return null;

    var ruleConfig = customLint['no_direct_instantiation'];
    if (ruleConfig is Map) return ruleConfig;

    final rules = customLint['rules'];
    if (rules is Map) {
      ruleConfig = rules['no_direct_instantiation'];
      if (ruleConfig is Map) return ruleConfig;
    }

    return null;
  }
}
