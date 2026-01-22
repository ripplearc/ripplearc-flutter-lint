import 'package:analyzer/dart/ast/ast.dart';

/// Utility functions for checking documentation comments.
///
/// This class provides shared documentation validation logic used by multiple
/// analyzers (e.g., document_enum, document_interface) to reduce code duplication.
class DocumentationUtils {
  /// Returns true if the comment contains valid `///` documentation.
  ///
  /// This method checks for triple-slash documentation comments and ensures
  /// they contain actual content (not just empty `///` lines).
  ///
  /// Example of valid documentation:
  /// ```dart
  /// /// This is valid documentation.
  /// ```
  ///
  /// Example of invalid documentation:
  /// ```dart
  /// ///
  /// ```
  static bool hasDocumentation(Comment? comment) {
    if (comment == null) return false;

    for (final token in comment.tokens) {
      if (token.lexeme.startsWith('///')) {
        final content = token.lexeme.substring(3).trim();
        if (content.isNotEmpty) {
          return true;
        }
      }
    }

    return false;
  }
}
