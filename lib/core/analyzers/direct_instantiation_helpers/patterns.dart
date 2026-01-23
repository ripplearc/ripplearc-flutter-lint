import '../base_analyzer.dart';
import 'linter_config.dart';

/// Utility class for pattern matching operations using LinterConfig.
///
/// Provides static methods to check if classes or files should be excluded from analysis
/// based on name patterns and file paths. All patterns are configured in LinterConfig.
class DirectInstantiationPatterns {
  static bool isExcludedByFilePath(String path) {
    if (path.isEmpty) return false;
    final normalizedPath = path.replaceAll('\\', '/');
    if (LinterConfig.filePathPatterns.any((pattern) => pattern.hasMatch(normalizedPath))) {
      return true;
    }
    return false;
  }

  static bool shouldSkipFile(String filePath) {
    return isExcludedByFilePath(filePath);
  }

}
