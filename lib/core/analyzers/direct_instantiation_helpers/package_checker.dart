import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'linter_config.dart';
import 'import_checker.dart';

/// Unified package checker that combines type-based and import-based exclusion checks.
///
/// Provides a single entry point for checking if a class instantiation should be excluded
/// based on package origins. Tries type-based checks first (when Element available),
/// then falls back to import-based checks. This eliminates the redundancy where both
/// TypeChecker and ImportChecker check the same conceptual whitelist.
class PackageChecker {
  static bool isFromAllowedPackage(
    InstanceCreationExpression node,
    String className, {
    ClassElement? typeElement,
  }) {
    if (typeElement != null) {
      if (isFromAllowedLibrary(typeElement)) {
        return true;
      }
    }

    if (ImportChecker.isImportedFromAllowedPackage(className, node)) {
      return true;
    }

    if (ImportChecker.isWhitelistedThirdPartyClass(className, node)) {
      return true;
    }

    return false;
  }

  static bool isFromAllowedLibrary(ClassElement classElement) {
    final library = classElement.library;
    final uri = library.source.uri;

    if (library.isInSdk) return true;

    final libraryUri = uri.toString();

    for (final prefix in LinterConfig.allowedPackagePrefixes) {
      if (libraryUri.startsWith(prefix)) {
        return true;
      }
    }

    final className = classElement.name;
    if (LinterConfig.safeValueObjects.contains(className)) {
      for (final prefix in LinterConfig.allowedPackagePrefixes) {
        if (libraryUri.startsWith(prefix)) {
          return true;
        }
      }
    }

    return false;
  }
}
