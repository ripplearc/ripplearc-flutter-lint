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

  static bool _isLibraryUriAllowed(String libraryUri, LinterConfig config) {
    for (final prefix in config.allowedPackagePrefixes) {
      if (libraryUri.startsWith(prefix)) {
        return true;
      }
    }
    return false;
  }

  static bool _isSafeValueObject(
    String className,
    String libraryUri,
    LinterConfig config,
  ) {
    if (!config.safeValueObjects.contains(className)) {
      return false;
    }
    return _isLibraryUriAllowed(libraryUri, config);
  }

  static bool _checkPrefixedImportForExcludedPackage(
    String className,
    String prefix,
    CompilationUnit compilationUnit,
    LinterConfig config,
  ) {
    for (final directive in compilationUnit.directives) {
      if (directive is ImportDirective && directive.prefix?.name == prefix) {
        final uri = directive.uri.stringValue ?? '';
        if (_isLibraryUriAllowed(uri, config) ||
            _isSafeValueObject(className, uri, config)) {
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
    LinterConfig config,
  ) {
    final uri = directive.uri.stringValue ?? '';
    if (!_isLibraryUriAllowed(uri, config) &&
        !_isSafeValueObject(className, uri, config)) {
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

    return _isLibraryUriAllowed(uri, config) ||
        _isSafeValueObject(className, uri, config);
  }

  static bool isImportedFromAllowedPackage(
    String className,
    InstanceCreationExpression node,
    LinterConfig config,
  ) {
    final typeSource = node.constructorName.type.toSource();
    return isImportedFromAllowedPackageFromSource(
      className,
      typeSource,
      node,
      config,
    );
  }

  static bool isImportedFromAllowedPackageFromSource(
    String className,
    String typeSource,
    AstNode node,
    LinterConfig config,
  ) {
    return isNamedTypeFromAllowedPackageSource(
      className,
      typeSource,
      node,
      config,
    );
  }

  static bool isNamedTypeFromAllowedPackage(
    NamedType namedType,
    AstNode node,
    LinterConfig config,
  ) {
    return isNamedTypeFromAllowedPackageSource(
      namedType.name2.lexeme,
      namedType.toSource(),
      node,
      config,
    );
  }

  static bool isNamedTypeFromAllowedPackageSource(
    String className,
    String typeSource,
    AstNode node,
    LinterConfig config,
  ) {
    final compilationUnit = _getCompilationUnit(node);

    if (compilationUnit == null) return false;

    if (typeSource.contains('.')) {
      final parts = typeSource.split('.');
      if (parts.length == 2) {
        final prefix = parts[0];
        if (_checkPrefixedImportForExcludedPackage(
          className,
          prefix,
          compilationUnit,
          config,
        )) {
          return true;
        }
      }
    }

    for (final directive in compilationUnit.directives) {
      if (directive is ImportDirective && directive.prefix == null) {
        if (_checkNonPrefixedImportForExcludedPackage(
          className,
          directive,
          config,
        )) {
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
    LinterConfig config,
  ) {
    for (final directive in compilationUnit.directives) {
      if (directive is ImportDirective && directive.prefix?.name == prefix) {
        final uri = directive.uri.stringValue ?? '';
        return _isSafeValueObject(className, uri, config);
      }
    }
    return false;
  }

  static bool _checkNonPrefixedImportForSafeValueObject(
    String className,
    ImportDirective directive,
    LinterConfig config,
  ) {
    final uri = directive.uri.stringValue ?? '';
    if (!_isSafeValueObject(className, uri, config)) {
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
    LinterConfig config,
  ) {
    final typeSource = node.constructorName.type.toSource();
    return isWhitelistedThirdPartyClassFromSource(
      className,
      typeSource,
      node,
      config,
    );
  }

  static bool isWhitelistedThirdPartyClassFromSource(
    String className,
    String typeSource,
    AstNode node,
    LinterConfig config,
  ) {
    final compilationUnit = _getCompilationUnit(node);
    if (compilationUnit == null) return false;

    if (typeSource.contains('.')) {
      final parts = typeSource.split('.');
      if (parts.length == 2) {
        final prefix = parts[0];
        if (_checkPrefixedImportForSafeValueObject(
          className,
          prefix,
          compilationUnit,
          config,
        )) {
          return true;
        }
      }
    }

    for (final directive in compilationUnit.directives) {
      if (directive is ImportDirective && directive.prefix == null) {
        if (_checkNonPrefixedImportForSafeValueObject(
          className,
          directive,
          config,
        )) {
          return true;
        }
      }
    }

    return false;
  }
}
