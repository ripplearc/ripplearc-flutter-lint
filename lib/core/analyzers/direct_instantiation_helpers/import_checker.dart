import 'package:analyzer/dart/ast/ast.dart';
import 'patterns.dart';

/// Provides import-based exclusion checks for direct instantiation analysis.
///
/// This class checks if a class instantiation should be excluded based on:
/// - Import URI patterns (domain entities, model classes)
/// - Package exclusions (Flutter, BLoC, Supabase, etc.)
class ImportChecker {
  static bool isImportedFromDomainEntity(String className, AstNode node) {
    final compilationUnit = _getCompilationUnit(node);
    if (compilationUnit == null) return false;

    for (final directive in compilationUnit.directives) {
      if (directive is ImportDirective) {
        final uri = directive.uri.stringValue ?? '';
        if (DirectInstantiationPatterns.isDomainEntity(uri)) {
          final importPrefix = directive.prefix?.name;
          if (importPrefix == null) {
            if (_matchesClassName(className, uri)) {
              return true;
            }
          } else {
            if (node is InstanceCreationExpression) {
              final typeSource = node.constructorName.type.toSource();
              if (typeSource.startsWith('$importPrefix.')) return true;
            }
          }
        }
      }
    }
    return false;
  }

  static bool isImportedFromModelClass(String className, AstNode node) {
    final compilationUnit = _getCompilationUnit(node);
    if (compilationUnit == null) return false;

    for (final directive in compilationUnit.directives) {
      if (directive is ImportDirective) {
        final uri = directive.uri.stringValue ?? '';
        if (uri.contains('data/models/') || uri.contains('/models/')) {
          final importPrefix = directive.prefix?.name;
          if (importPrefix == null) {
            if (_matchesClassName(className, uri)) {
              return true;
            }
          } else {
            if (node is InstanceCreationExpression) {
              final typeSource = node.constructorName.type.toSource();
              if (typeSource.startsWith('$importPrefix.')) return true;
            }
          }
        }
      }
    }
    return false;
  }

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

  static bool _matchesClassName(String className, String uri) {
    final fileName = uri.split('/').last.replaceAll('.dart', '');
    final normalizedClassName = _normalizeName(className);
    final normalizedFileName = _normalizeName(fileName);

    return normalizedFileName == normalizedClassName ||
        normalizedFileName.contains(normalizedClassName) ||
        normalizedClassName.contains(normalizedFileName);
  }

  static String _normalizeName(String name) {
    return name
        .replaceAll(
          RegExp(
            r'_model$|_dto$|_entity$|_model\.dart$|_dto\.dart$|_entity\.dart$',
          ),
          '',
        )
        .replaceAll('_', '')
        .toLowerCase();
  }

  static bool isImportedFromExcludedPackage(
    String className,
    InstanceCreationExpression node,
  ) {
    final constructorName = node.constructorName;
    final typeSource = constructorName.type.toSource();

    if (typeSource.contains('.')) {
      final parts = typeSource.split('.');
      if (parts.length == 2) {
        final prefix = parts[0];
        final compilationUnit = _getCompilationUnit(node);
        if (compilationUnit != null) {
          for (final directive in compilationUnit.directives) {
            if (directive is ImportDirective &&
                directive.prefix?.name == prefix) {
              final uri = directive.uri.stringValue ?? '';
              if (DirectInstantiationPatterns.isExcludedByPackage(uri))
                return true;
            }
          }
        }
      }
    }
    return false;
  }
}
