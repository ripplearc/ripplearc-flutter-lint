class DirectInstantiationPatterns {
  static final List<RegExp> classNamePatterns = [
    RegExp(r'^Left$'),
    RegExp(r'^Right$'),
    RegExp(r'.*State$'),
    RegExp(r'.*Event$'),
    RegExp(r'.*Initial$'),
    RegExp(r'.*Loading$'),
    RegExp(r'.*Success$'),
    RegExp(r'.*Failure$'),
    RegExp(r'.*Validated$'),
    RegExp(r'.*InProgress$'),
    RegExp(r'.*Exception$'),
    RegExp(r'.*Error$'),
    RegExp(r'.*Widget$'),
    RegExp(r'.*Dto$'),
    RegExp(r'.*DTO$'),
    RegExp(r'.*Entity$'),
    RegExp(r'.*Model$'),
    RegExp(r'.*Value$'),
    RegExp(r'.*Params$'),
    RegExp(r'.*Attributes$'),
    RegExp(r'.*Guard$'),
    RegExp(r'.*Result$'),
    RegExp(r'.*Provider$'),
    RegExp(r'^Uuid$'),
    RegExp(r'^Logger$'),
    RegExp(r'^Json.*'),
  ];

  static final List<RegExp> filePathPatterns = [
    RegExp(r'.*_dto\.dart$', caseSensitive: false),
    RegExp(r'.*_model\.dart$', caseSensitive: false),
    RegExp(r'.*testing/.*', caseSensitive: false),
    RegExp(r'.*test/.*', caseSensitive: false),
    RegExp(r'.*main\.dart$', caseSensitive: false),
    RegExp(r'.*data/models/.*', caseSensitive: false),
    RegExp(r'.*params/.*', caseSensitive: false),
    RegExp(r'.*usecases/params/.*', caseSensitive: false),
    RegExp(r'.*domain/entities/.*', caseSensitive: false),
  ];

  static bool isExcludedByFilePath(String path) {
    if (path.isEmpty) return false;
    final normalizedPath = path.replaceAll('\\', '/');
    if (filePathPatterns.any((pattern) => pattern.hasMatch(normalizedPath))) {
      return true;
    }
    if (normalizedPath.contains('/data/models/')) {
      return true;
    }
    return false;
  }

  static bool isExcludedByClassName(String className) {
    return classNamePatterns.any((pattern) => pattern.hasMatch(className));
  }

  static bool isWhitelistedClassName(String className) {
    return className.endsWith('Exception') ||
        className.endsWith('Error') ||
        className == 'Trace' ||
        className == 'DateTime' ||
        className == 'Uri' ||
        className == 'Uuid' ||
        className == 'Completer';
  }

  static bool matchesPackage(String libraryUri, String package) {
    if (package == 'dart:core') return libraryUri == 'dart:core';
    if (package == 'dart:async') return libraryUri == 'dart:async';
    return libraryUri.contains(package) || libraryUri.endsWith(package);
  }

  static bool isDomainEntity(String libraryUri) {
    if (libraryUri.contains('domain/entities/') ||
        libraryUri.contains('/entities/')) return true;
    if (libraryUri.endsWith('_entity.dart')) return true;
    if (libraryUri.contains('project_entity.dart') ||
        libraryUri.contains('project/domain/entities/')) return true;
    return false;
  }

  static bool isExcludedByPackage(String libraryUri) {
    if (libraryUri.startsWith('package:flutter/')) return true;
    if (libraryUri.startsWith('package:flutter_bloc/')) return true;
    if (libraryUri.startsWith('package:supabase/')) return true;
    if (libraryUri.startsWith('package:supabase_flutter/')) return true;
    if (libraryUri.startsWith('package:intl/')) return true;
    if (libraryUri.startsWith('package:uuid/')) return true;
    return false;
  }
}

