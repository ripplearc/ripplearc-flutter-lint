import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'linter_config.dart';
import 'package_checker.dart';

/// Provides type-based exclusion checks for direct instantiation analysis.
///
/// Checks if a class instantiation should be excluded by analyzing class elements,
/// inheritance hierarchies, and sealed classes. Uses LinterConfig for ignored base classes
/// and PackageChecker for package-based exclusion checks. Requires full type resolution.
class TypeChecker {
  static bool isExcludedBySubtype(InstanceCreationExpression node) {
    try {
      final element = node.constructorName.staticElement;
      if (element == null) return false;
      final typeElement = element.returnType.element;
      if (typeElement is! ClassElement) return false;

      final classElement = typeElement;

      if (PackageChecker.isFromAllowedLibrary(classElement)) return true;

      for (final interface in classElement.interfaces) {
        final interfaceElement = interface.element;
        if (interfaceElement is! ClassElement) continue;

        if (PackageChecker.isFromAllowedLibrary(interfaceElement)) return true;

        if (LinterConfig.ignoredBaseClasses.contains(interfaceElement.name)) {
          return true;
        }
      }

      for (final supertype in classElement.allSupertypes) {
        final supertypeElement = supertype.element;
        if (supertypeElement is! ClassElement) continue;
        if (LinterConfig.astTypeNames.contains(supertypeElement.name)) continue;

        if (PackageChecker.isFromAllowedLibrary(supertypeElement)) return true;

        if (LinterConfig.ignoredBaseClasses.contains(supertypeElement.name)) {
          return true;
        }
      }

      return false;
    } catch (e, stackTrace) {
      assert(() {
        print('TypeChecker.isExcludedBySubtype error: $e\n$stackTrace');
        return true;
      }());
      return false;
    }
  }

  static bool isSealedClass(InstanceCreationExpression node) {
    try {
      final element = node.constructorName.staticElement;
      if (element == null) return false;
      final typeElement = element.returnType.element;
      if (typeElement is! ClassElement) return false;

      final classElement = typeElement;

      if (classElement.isSealed) return true;

      if (classElement.allSupertypes.any((t) {
        final supertypeElement = t.element;
        if (supertypeElement is! ClassElement) return false;
        if (LinterConfig.astTypeNames.contains(supertypeElement.name))
          return false;
        return supertypeElement.isSealed;
      })) {
        return true;
      }

      return false;
    } catch (e, stackTrace) {
      assert(() {
        print('TypeChecker.isSealedClass error: $e\n$stackTrace');
        return true;
      }());
      return false;
    }
  }
}
