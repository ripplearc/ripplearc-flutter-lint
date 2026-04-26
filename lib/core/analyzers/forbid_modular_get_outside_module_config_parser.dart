import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart' as yaml;

import 'forbid_modular_get_outside_module_config.dart';

class ForbidModularGetOutsideModuleConfigParser {
  static const _ruleName = 'forbid_modular_get_outside_module';

  static ForbidModularGetOutsideModuleConfig loadFromFile([String? filePath]) {
    final defaults = ForbidModularGetOutsideModuleConfig.defaults();

    try {
      final projectRoot = findProjectRoot(filePath);
      if (projectRoot == null) return defaults;

      final configFile = File(path.join(projectRoot, 'analysis_options.yaml'));
      if (!configFile.existsSync()) return defaults;

      final parsed = _parseConfigFile(configFile);
      if (parsed == null) return defaults;

      return ForbidModularGetOutsideModuleConfig(
        allowList: {...defaults.allowList, ...parsed.allowList},
      );
    } catch (_) {
      return defaults;
    }
  }

  static ForbidModularGetOutsideModuleConfig? _parseConfigFile(File file) {
    final content = file.readAsStringSync();
    final yamlDoc = yaml.loadYaml(content);

    if (yamlDoc is! Map) return null;

    final configMap = Map<String, dynamic>.from(
      yamlDoc.map((k, v) => MapEntry(k.toString(), v)),
    );

    final ruleConfig = _extractRuleConfig(configMap);
    if (ruleConfig == null) return null;

    return ForbidModularGetOutsideModuleConfig(
      allowList: _parseStringSet(ruleConfig['allow_list']),
    );
  }

  static Map? _extractRuleConfig(Map<String, dynamic> configMap) {
    final customLint = configMap['custom_lint'];
    if (customLint is! Map) return null;

    var ruleConfig = customLint[_ruleName];
    if (ruleConfig is Map) return ruleConfig;

    final rules = customLint['rules'];
    if (rules is Map) {
      ruleConfig = rules[_ruleName];
      if (ruleConfig is Map) return ruleConfig;
    }

    return null;
  }

  static Set<String> _parseStringSet(dynamic value) {
    if (value is! List) return const {};

    return value
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toSet();
  }

  static String? findProjectRoot(String? filePath) {
    if (filePath == null || filePath.isEmpty) return null;

    try {
      final entity =
          FileSystemEntity.isDirectorySync(filePath)
              ? Directory(filePath)
              : File(filePath).parent;

      var current = entity.absolute;
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
    } catch (_) {
      return null;
    }

    return null;
  }
}
