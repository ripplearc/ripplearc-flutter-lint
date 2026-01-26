/// Centralized configuration registry for the no_direct_instantiation rule.
///
/// Single source of truth for all exclusion rules: allowed packages, ignored base classes,
/// safe value objects, file path patterns, and AST analysis constants.
/// All helper classes reference this configuration to avoid hardcoded values.
class LinterConfig {
  final Set<String> allowedPackagePrefixes;
  final Set<String> ignoredBaseClasses;
  final Set<String> safeValueObjects;
  final List<RegExp> filePathPatterns;
  final Set<String> astTypeNames;
  final Set<String> astTypePrefixes;
  final Set<String> astTypeSuffixes;
  final Set<String> astMethodNames;
  final Set<String> astKeywords;

  const LinterConfig({
    required this.allowedPackagePrefixes,
    required this.ignoredBaseClasses,
    required this.safeValueObjects,
    required this.filePathPatterns,
    required this.astTypeNames,
    required this.astTypePrefixes,
    required this.astTypeSuffixes,
    required this.astMethodNames,
    required this.astKeywords,
  });

  factory LinterConfig.defaults() {
    return LinterConfig(
      allowedPackagePrefixes: const {
        'dart:',
        'package:flutter/',
        'package:intl/',
        'package:uuid/',
        'package:supabase/',
        'package:supabase_flutter/',
        'package:rxdart/',
        'package:dartz/',
        'package:faker/',
        'package:gotrue/',
      },
      ignoredBaseClasses: const {
        'Equatable',
        'Module',
        'Event',
        'Exception',
        'Error',
        'RouteGuard',
      },
      safeValueObjects: const {
        'Uuid',
        'DateFormat',
        'NumberFormat',
        'Unit',
        'Faker',
      },
      filePathPatterns: [RegExp(r'.*main\.dart$', caseSensitive: false)],
      astTypeNames: const {'Object'},
      astTypePrefixes: const {},
      astTypeSuffixes: const {'Factory'},
      astMethodNames: const {'binds', 'exportedBinds'},
      astKeywords: const {'const'},
    );
  }

  bool shouldSkipFile(String filePath) {
    if (filePath.isEmpty) return false;
    final normalizedPath = filePath.replaceAll('\\', '/');
    return filePathPatterns.any((pattern) => pattern.hasMatch(normalizedPath));
  }
}
