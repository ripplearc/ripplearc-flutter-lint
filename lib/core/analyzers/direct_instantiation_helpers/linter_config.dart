/// Centralized configuration registry for the no_direct_instantiation rule.
///
/// Single source of truth for all exclusion rules: allowed packages, ignored base classes,
/// safe value objects, file path patterns, and AST analysis constants.
/// All helper classes reference this configuration to avoid hardcoded values.
class LinterConfig {
  static const Set<String> allowedPackagePrefixes = {
    'dart:',
    'package:flutter/',
    'package:intl/',
    'package:uuid/',
    'package:supabase/',
    'package:supabase_flutter/',
    'package:rxdart/',
    'package:dartz/',
    'package:faker/',
  };

  static const Set<String> ignoredBaseClasses = {
    'Equatable',
    'Module',
    'Event',
    'Exception',
    'Error',
    'RouteGuard',
  };

  static const Set<String> safeValueObjects = {
    'Uuid',
    'DateFormat',
    'NumberFormat',
    'Unit',
    'Faker',
  };

  static final List<RegExp> filePathPatterns = [
    RegExp(r'.*testing/.*', caseSensitive: false),
    RegExp(r'.*main\.dart$', caseSensitive: false),
  ];

  static const Set<String> astTypeNames = {
    'Object',
  };

  static const Set<String> astTypeSuffixes = {
    'Factory',
    'Attributes',
  };

  static const Set<String> astMethodNames = {
    'binds',
    'exportedBinds',
  };

  static const Set<String> astKeywords = {
    'const',
  };
}
