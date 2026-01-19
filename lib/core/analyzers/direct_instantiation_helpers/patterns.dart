class DirectInstantiationPatterns {
  static final List<RegExp> classNamePatterns = [
    RegExp(r'^Left$'),
    RegExp(r'^Right$'),
    RegExp(r'.*Error$'),
    RegExp(r'.*Widget$'),
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
    RegExp(r'.*testing/.*', caseSensitive: false),
    RegExp(r'.*main\.dart$', caseSensitive: false),
  ];

  static bool isExcludedByFilePath(String path) {
    if (path.isEmpty) return false;
    final normalizedPath = path.replaceAll('\\', '/');
    if (filePathPatterns.any((pattern) => pattern.hasMatch(normalizedPath))) {
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
    // For package: URLs, check if it starts with the package name
    // e.g., package:equatable/equatable.dart matches package:equatable/src/equatable.dart
    if (package.startsWith('package:')) {
      final packageName = package.split('/')[0]; // e.g., "package:equatable"
      return libraryUri.startsWith(packageName + '/');
    }
    return libraryUri.contains(package) || libraryUri.endsWith(package);
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

