import 'package:analyzer/dart/ast/ast.dart';
import 'linter_config.dart';

/// Provides import-based exclusion checks for direct instantiation analysis.
///
/// Checks if a class instantiation should be excluded by analyzing import directives
/// to determine package origins. Handles both prefixed and non-prefixed imports,
/// including show/hide combinators. Uses LinterConfig for allowed packages and safe value objects.
class ImportChecker {

  static CompilationUnit? _getCompilationUnit(AstNode node) {
    AstNode? current = node;
    while (current != null) {
      if (current is CompilationUnit) {
        return current;
      }
      current = current.parent;
    }
    return null;
  }

  static bool _isLibraryUriAllowed(String libraryUri) {
    for (final prefix in LinterConfig.allowedPackagePrefixes) {
      if (libraryUri.startsWith(prefix)) {
        return true;
      }
    }
    return false;
  }

  static bool _isSafeValueObject(String className, String libraryUri) {
    if (!LinterConfig.safeValueObjects.contains(className)) {
      return false;
    }
    return _isLibraryUriAllowed(libraryUri);
  }

  static bool _checkPrefixedImportForExcludedPackage(
    String className,
    String prefix,
    CompilationUnit compilationUnit,
  ) {
    for (final directive in compilationUnit.directives) {
      if (directive is ImportDirective && directive.prefix?.name == prefix) {
        final uri = directive.uri.stringValue ?? '';
        if (_isLibraryUriAllowed(uri) || _isSafeValueObject(className, uri)) {
          return true;
        }
      }
    }
    return false;
  }

  static bool _isClassNameShown(ShowCombinator combinator, String className) {
    return combinator.shownNames.any((name) => name.name == className);
  }

  static bool _isClassNameHidden(HideCombinator combinator, String className) {
    return combinator.hiddenNames.any((name) => name.name == className);
  }

  static bool _checkNonPrefixedImportForExcludedPackage(
    String className,
    ImportDirective directive,
  ) {
    final uri = directive.uri.stringValue ?? '';
    if (!_isLibraryUriAllowed(uri) && !_isSafeValueObject(className, uri)) {
      return false;
    }

    final showCombinators =
        directive.combinators.whereType<ShowCombinator>().toList();
    if (showCombinators.isNotEmpty) {
      if (showCombinators.any((c) => _isClassNameShown(c, className))) {
        return true;
      }
      return false;
    }

    final hideCombinators =
        directive.combinators.whereType<HideCombinator>().toList();
    if (hideCombinators.isNotEmpty) {
      if (hideCombinators.any((c) => _isClassNameHidden(c, className))) {
        return false;
      }
    }

    return _isLibraryUriAllowed(uri) || _isSafeValueObject(className, uri);
  }

  static bool isImportedFromExcludedPackage(
    String className,
    InstanceCreationExpression node,
  ) {
    final constructorName = node.constructorName;
    final typeSource = constructorName.type.toSource();
    final compilationUnit = _getCompilationUnit(node);

    if (compilationUnit == null) return false;

    if (typeSource.contains('.')) {
      final parts = typeSource.split('.');
      if (parts.length == 2) {
        final prefix = parts[0];
        if (_checkPrefixedImportForExcludedPackage(
            className, prefix, compilationUnit)) {
          return true;
        }
      }
    }

    for (final directive in compilationUnit.directives) {
      if (directive is ImportDirective && directive.prefix == null) {
        if (_checkNonPrefixedImportForExcludedPackage(className, directive)) {
          return true;
        }
      }
    }

    return false;
  }

  static bool _checkPrefixedImportForSafeValueObject(
    String className,
    String prefix,
    CompilationUnit compilationUnit,
  ) {
    for (final directive in compilationUnit.directives) {
      if (directive is ImportDirective && directive.prefix?.name == prefix) {
        final uri = directive.uri.stringValue ?? '';
        return _isSafeValueObject(className, uri);
      }
    }
    return false;
  }

  static bool _checkNonPrefixedImportForSafeValueObject(
    String className,
    ImportDirective directive,
  ) {
    final uri = directive.uri.stringValue ?? '';
    if (!_isSafeValueObject(className, uri)) {
      return false;
    }

    final showCombinators =
        directive.combinators.whereType<ShowCombinator>().toList();
    if (showCombinators.isEmpty) return true;

    return showCombinators.any((c) => _isClassNameShown(c, className));
  }

  static bool isWhitelistedThirdPartyClass(
    String className,
    InstanceCreationExpression node,
  ) {
    final compilationUnit = _getCompilationUnit(node);
    if (compilationUnit == null) return false;

    final constructorName = node.constructorName;
    final typeSource = constructorName.type.toSource();

    if (typeSource.contains('.')) {
      final parts = typeSource.split('.');
      if (parts.length == 2) {
        final prefix = parts[0];
        if (_checkPrefixedImportForSafeValueObject(
            className, prefix, compilationUnit)) {
          return true;
        }
      }
    }

    for (final directive in compilationUnit.directives) {
      if (directive is ImportDirective && directive.prefix == null) {
        if (_checkNonPrefixedImportForSafeValueObject(className, directive)) {
          return true;
        }
      }
    }

    return false;
  }

  static bool _hasAllowedSuffix(String className) {
    return LinterConfig.astTypeSuffixes.any(
      (suffix) => className.endsWith(suffix),
    );
  }

  static bool _checkPrefixedImportForAllowedPackage(
    String prefix,
    CompilationUnit compilationUnit,
  ) {
    for (final directive in compilationUnit.directives) {
      if (directive is ImportDirective && directive.prefix?.name == prefix) {
        final uri = directive.uri.stringValue ?? '';
        return _isLibraryUriAllowed(uri);
      }
    }
    return false;
  }

  static bool _checkNonPrefixedImportForAllowedPackage(
    String className,
    ImportDirective directive,
  ) {
    final uri = directive.uri.stringValue ?? '';
    if (!_isLibraryUriAllowed(uri)) {
      return false;
    }

    final showCombinators =
        directive.combinators.whereType<ShowCombinator>().toList();
    if (showCombinators.isEmpty) return true;

    return showCombinators.any((c) => _isClassNameShown(c, className));
  }

  static bool isFromSupabasePackage(
    String className,
    InstanceCreationExpression node,
  ) {
    if (!_hasAllowedSuffix(className)) return false;

    final compilationUnit = _getCompilationUnit(node);
    if (compilationUnit == null) return false;

    final constructorName = node.constructorName;
    final typeSource = constructorName.type.toSource();

    if (typeSource.contains('.')) {
      final parts = typeSource.split('.');
      if (parts.length == 2) {
        final prefix = parts[0];
        if (_checkPrefixedImportForAllowedPackage(prefix, compilationUnit)) {
          return true;
        }
      }
    }

    for (final directive in compilationUnit.directives) {
      if (directive is ImportDirective && directive.prefix == null) {
        if (_checkNonPrefixedImportForAllowedPackage(className, directive)) {
          return true;
        }
      }
    }

    return false;
  }
}
