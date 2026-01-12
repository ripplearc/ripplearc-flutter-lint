import 'package:analyzer/dart/ast/ast.dart';
import 'patterns.dart';

/// Provides import-based exclusion checks for direct instantiation analysis.
///
/// This class checks if a class instantiation should be excluded based on:
/// - Package exclusions (Flutter, BLoC, Supabase, etc.)
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
