import 'dart:io';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as path;
import 'base_analyzer.dart';
import '../models/lint_issue.dart';

/// Analyzer that ensures test files in test/units have corresponding mutation files.
///
/// This rule checks that every test file under test/units directory has a corresponding
/// mutation file under test/mutations directory with the same name but .xml extension.
///
/// Example:
/// ```dart
/// // ❌ Not allowed - missing mutation file:
/// // test/units/user_test.dart exists but test/mutations/user_test.xml is missing
///
/// // ✅ Allowed - mutation file exists:
/// // test/units/user_test.dart -> test/mutations/user_test.xml
/// // test/units/auth/login_test.dart -> test/mutations/auth/login_test.xml
/// ```
class TestFileMutationCoverageAnalyzer extends BaseAnalyzer {
  @override
  String get ruleName => 'test_file_mutation_coverage';

  @override
  String get problemMessage =>
      'Test file is missing corresponding mutation file.';

  @override
  String get correctionMessage =>
      'Create a mutation file with .xml extension in test/mutations directory with the same name as the test file.';

  @override
  List<LintIssue> analyze(CompilationUnit unit) {
    return [];
  }

  @override
  List<LintIssue> analyzeWithResolver(CompilationUnit unit, dynamic resolver) {
    final issues = <LintIssue>[];

    final filePath = resolver.path;
    if (filePath == null || filePath.isEmpty) return issues;

    if (!_isTestUnitsFile(filePath)) return issues;

    if (!_hasMutationFile(filePath)) {
      issues.add(createIssue(unit));
    }

    return issues;
  }

  bool _isTestUnitsFile(String filePath) {
    final normalizedPath = path.normalize(filePath);
    return normalizedPath.contains('test${path.separator}units') &&
        normalizedPath.endsWith('.dart');
  }

  bool _hasMutationFile(String testFilePath) {
    final mutationFilePath = _getMutationFilePath(testFilePath);

    final testUnitsDir = path.dirname(testFilePath);
    final unitsIndex = testUnitsDir.indexOf('test${path.separator}units');
    if (unitsIndex == -1) {
      // Fallback: assume we're in the project root
      return File(mutationFilePath).existsSync();
    }

    final projectRoot = testUnitsDir.substring(0, unitsIndex);
    final absoluteMutationPath = path.join(projectRoot, mutationFilePath);

    return File(absoluteMutationPath).existsSync();
  }

  String _getMutationFilePath(String testFilePath) {
    final normalizedPath = path.normalize(testFilePath);

    final unitsIndex = normalizedPath.indexOf('test${path.separator}units');
    if (unitsIndex == -1) {
      final relativePath = path.relative(normalizedPath, from: 'test/units');
      final withoutExtension = path.withoutExtension(relativePath);
      final mutationFileName = '$withoutExtension.xml';
      return path.join('test', 'mutations', mutationFileName);
    }

    final afterUnits = normalizedPath.substring(
      unitsIndex + 'test${path.separator}units'.length,
    );
    final withoutExtension = path.withoutExtension(
      afterUnits.startsWith(path.separator)
          ? afterUnits.substring(1)
          : afterUnits,
    );
    final mutationFileName = '$withoutExtension.xml';

    return path.join('test', 'mutations', mutationFileName);
  }

  String _getMissingMutationMessage(String testFilePath) {
    final expectedMutationPath = _getMutationFilePath(testFilePath);
    return 'Missing mutation file: $expectedMutationPath. Each test file should have a corresponding mutation file.';
  }
}
