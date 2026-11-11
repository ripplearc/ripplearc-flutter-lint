import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart' as yaml;

import 'forbid_direct_storage_access_config.dart';
import 'forbid_modular_get_outside_module_config_parser.dart';

/// Parses `forbid_direct_storage_access` options from `analysis_options.yaml`.
///
/// The only option is `allowed_files`, a list of exact file paths. The options
/// sit next to `rules:` under `custom_lint:`, or inside a `rules:` map.
class ForbidDirectStorageAccessConfigParser {
  static const _ruleName = 'forbid_direct_storage_access';
  static const _allowedFilesKey = 'allowed_files';

  /// Loads the config of the project that contains [filePath].
  ///
  /// Returns the defaults when no project root or config can be found. An
  /// unreadable config is not hidden: the error is rethrown. An
  /// `allowed_files` that is neither a list nor a single path throws a
  /// [FormatException].
  static ForbidDirectStorageAccessConfig loadFromFile(String filePath) {
    final root = projectRootOf(filePath);
    if (root == null) return ForbidDirectStorageAccessConfig.defaults();

    final configFile = File(path.join(root, 'analysis_options.yaml'));
    final options = _optionsOf(yaml.loadYaml(configFile.readAsStringSync()));
    if (options == null) return ForbidDirectStorageAccessConfig.defaults();

    return ForbidDirectStorageAccessConfig(
      allowedFiles: _pathsOf(options[_allowedFilesKey]),
    );
  }

  /// The nearest ancestor folder of [filePath] that holds an
  /// `analysis_options.yaml`, or null when there is none.
  static String? projectRootOf(String filePath) =>
      ForbidModularGetOutsideModuleConfigParser.findProjectRoot(filePath);

  static Map? _optionsOf(Object? document) {
    if (document is! Map) return null;
    final customLint = document['custom_lint'];
    if (customLint is! Map) return null;

    final direct = customLint[_ruleName];
    if (direct is Map) return direct;

    final rules = customLint['rules'];
    if (rules is! Map) return null;
    final listed = rules[_ruleName];
    return listed is Map ? listed : null;
  }

  static Set<String> _pathsOf(Object? value) {
    if (value == null) return const {};
    if (value is String) return _pathsOf([value]);
    if (value is! List) {
      throw FormatException(
        '$_ruleName: $_allowedFilesKey must be a list of file paths, '
        'but it is ${value.runtimeType}',
      );
    }
    return value
        .map((entry) => normalize(entry.toString()))
        .where((entry) => entry.isNotEmpty)
        .toSet();
  }

  /// Turns [value] into a `/`-separated path with no leading `./`.
  static String normalize(String value) {
    var normalized = value.trim().replaceAll('\\', '/');
    while (normalized.startsWith('./')) {
      normalized = normalized.substring(2);
    }
    return normalized;
  }
}
