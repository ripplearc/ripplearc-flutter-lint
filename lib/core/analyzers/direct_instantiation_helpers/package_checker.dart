import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'linter_config.dart';
import 'import_checker.dart';
import 'context_checker.dart';

/// Unified package checker that combines type-based and import-based exclusion checks.
///
/// Provides a single entry point for checking if a class instantiation should be excluded
/// based on package origins. Tries type-based checks first (when Element available),
/// then falls back to import-based checks. This eliminates the redundancy where both
/// TypeChecker and ImportChecker check the same conceptual whitelist.
class PackageChecker {
  static bool isFromAllowedPackage(
    InstanceCreationExpression node,
    String className,
    LinterConfig config, {
    ClassElement? typeElement,
    Map<String, ClassDeclaration>? classCache,
  }) {
    final typeSource = node.constructorName.type.toSource();
    return isFromAllowedPackageForNode(
      node,
      className,
      typeSource,
      config,
      typeElement: typeElement,
      classCache: classCache,
    );
  }

  static bool isFromAllowedPackageForNode(
    AstNode node,
    String className,
    String typeSource,
    LinterConfig config, {
    ClassElement? typeElement,
    Map<String, ClassDeclaration>? classCache,
  }) {
    if (typeElement != null) {
      if (isFromAllowedLibrary(typeElement, config)) {
        return true;
      }
    }

    if (ImportChecker.isImportedFromAllowedPackageFromSource(
      className,
      typeSource,
      node,
      config,
    )) {
      return true;
    }

    if (isLocalClassDerivedFromAllowedType(
      node,
      className,
      config,
      classCache: classCache,
    )) {
      return true;
    }

    if (ImportChecker.isWhitelistedThirdPartyClassFromSource(
      className,
      typeSource,
      node,
      config,
    )) {
      return true;
    }

    return false;
  }

  static bool isFromAllowedLibrary(
    ClassElement classElement,
    LinterConfig config,
  ) {
    final library = classElement.library;
    final uri = library.uri;

    if (library.isInSdk) return true;

    final libraryUri = uri.toString();

    for (final prefix in config.allowedPackagePrefixes) {
      if (libraryUri.startsWith(prefix)) {
        return true;
      }
    }

    final className = classElement.name;
    if (config.safeValueObjects.contains(className)) {
      for (final prefix in config.allowedPackagePrefixes) {
        if (libraryUri.startsWith(prefix)) {
          return true;
        }
      }
    }

    return false;
  }

  static bool isLocalClassDerivedFromAllowedType(
    AstNode node,
    String className,
    LinterConfig config, {
    Map<String, ClassDeclaration>? classCache,
    Set<String>? visited,
  }) {
    visited ??= {};
    if (!visited.add(className)) return false;

    final classDecl = ContextChecker.findClassDeclaration(
      className,
      node,
      classCache: classCache,
    );
    if (classDecl == null) return false;

    final superType = classDecl.extendsClause?.superclass;
    if (superType != null) {
      final superName = superType.name2.lexeme;
      if (ImportChecker.isNamedTypeFromAllowedPackage(
        superType,
        node,
        config,
      )) {
        return true;
      }
      if (_isLocalAndRecurse(superName, classCache)) {
        if (isLocalClassDerivedFromAllowedType(
          node,
          superName,
          config,
          classCache: classCache,
          visited: visited,
        )) {
          return true;
        }
      }
    }

    final withClause = classDecl.withClause;
    if (withClause != null) {
      for (final mixinType in withClause.mixinTypes) {
        final mixinName = mixinType.name2.lexeme;
        if (ImportChecker.isNamedTypeFromAllowedPackage(
          mixinType,
          node,
          config,
        )) {
          return true;
        }
        if (_isLocalAndRecurse(mixinName, classCache)) {
          if (isLocalClassDerivedFromAllowedType(
            node,
            mixinName,
            config,
            classCache: classCache,
            visited: visited,
          )) {
            return true;
          }
        }
      }
    }

    final implementsClause = classDecl.implementsClause;
    if (implementsClause != null) {
      for (final interfaceType in implementsClause.interfaces) {
        final interfaceName = interfaceType.name2.lexeme;
        if (ImportChecker.isNamedTypeFromAllowedPackage(
          interfaceType,
          node,
          config,
        )) {
          return true;
        }
        if (_isLocalAndRecurse(interfaceName, classCache)) {
          if (isLocalClassDerivedFromAllowedType(
            node,
            interfaceName,
            config,
            classCache: classCache,
            visited: visited,
          )) {
            return true;
          }
        }
      }
    }

    return false;
  }

  static bool _isLocalAndRecurse(
    String typeName,
    Map<String, ClassDeclaration>? classCache,
  ) {
    return classCache?.containsKey(typeName) == true;
  }
}
