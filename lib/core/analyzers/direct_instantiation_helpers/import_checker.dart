import 'package:analyzer/dart/ast/ast.dart';
import 'patterns.dart';

class ImportChecker {
  static bool isImportedFromDomainEntity(String className, AstNode node) {
    AstNode? current = node;
    while (current != null) {
      if (current is CompilationUnit) {
        for (final directive in current.directives) {
          if (directive is ImportDirective) {
            final uri = directive.uri.stringValue ?? '';
            if (DirectInstantiationPatterns.isDomainEntity(uri)) {
              final importPrefix = directive.prefix?.name;
              if (importPrefix == null) {
                final fileName = uri.split('/').last.replaceAll('.dart', '');
                final lowerClassName = className.toLowerCase();
                
                final potentialClassName = fileName
                    .replaceAll('_entity', '')
                    .replaceAll('_', '')
                    .toLowerCase();

                if (potentialClassName == lowerClassName) return true;
              } else {
                if (node is InstanceCreationExpression) {
                  final typeSource = node.constructorName.type.toSource();
                  if (typeSource.startsWith('$importPrefix.')) return true;
                }
              }
            }
          }
        }
        break;
      }
      current = current.parent;
    }
    return false;
  }

  static bool isImportedFromModelClass(String className, AstNode node) {
    AstNode? current = node;
    while (current != null) {
      if (current is CompilationUnit) {
        for (final directive in current.directives) {
          if (directive is ImportDirective) {
            final uri = directive.uri.stringValue ?? '';
            if (uri.contains('data/models/') || uri.contains('/models/')) {
              final importPrefix = directive.prefix?.name;
              if (importPrefix == null) {
                final fileName = uri.split('/').last.replaceAll('.dart', '');
                final lowerClassName = className.toLowerCase();
                final lowerFileName = fileName.toLowerCase();

                if (lowerFileName.contains(lowerClassName) ||
                    lowerClassName.contains(lowerFileName.replaceAll('_', ''))) {
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
        break;
      }
      current = current.parent;
    }
    return false;
  }

  static bool isImportedFromExcludedPackage(String className, InstanceCreationExpression node) {
    final constructorName = node.constructorName;
    final typeSource = constructorName.type.toSource();

    if (typeSource.contains('.')) {
      final parts = typeSource.split('.');
      if (parts.length == 2) {
        final prefix = parts[0];
        AstNode? current = node;
        while (current != null) {
          if (current is CompilationUnit) {
            for (final directive in current.directives) {
              if (directive is ImportDirective && directive.prefix?.name == prefix) {
                final uri = directive.uri.stringValue ?? '';
                if (DirectInstantiationPatterns.isExcludedByPackage(uri)) return true;
              }
            }
            break;
          }
          current = current.parent;
        }
      }
    }
    return false;
  }
}

