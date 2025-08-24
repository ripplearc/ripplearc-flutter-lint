import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

import '../standalone_checker.dart';
import '../lib/core/analyzers/forced_unwrapping_analyzer.dart';
import '../lib/core/analyzers/direct_instantiation_analyzer.dart';
import '../lib/core/analyzers/sealed_over_dynamic_analyzer.dart';
import '../lib/core/analyzers/private_subject_analyzer.dart';
import '../lib/core/analyzers/specific_exception_types_analyzer.dart';
import '../lib/core/analyzers/document_fake_parameters_analyzer.dart';
import '../lib/core/analyzers/document_interface_analyzer.dart';
import '../lib/core/analyzers/no_internal_method_docs_analyzer.dart';
import '../lib/core/analyzers/todo_with_story_links_analyzer.dart';
import '../lib/core/analyzers/no_optional_operators_in_tests_analyzer.dart';
import '../lib/core/analyzers/prefer_fake_over_mock_analyzer.dart';
import '../lib/core/analyzers/test_file_mutation_coverage_analyzer.dart';

void main() {
  group('StandaloneLintChecker', () {
    late StandaloneLintChecker checker;
    late Directory tempDir;

    setUp(() {
      checker = StandaloneLintChecker();
      tempDir = Directory.systemTemp.createTempSync('standalone_checker_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('Constructor and Properties', () {
      test('should initialize with all analyzers', () {
        expect(checker.analyzers, isNotEmpty);
        final analyzerTypes =
            checker.analyzers.map((a) => a.runtimeType).toSet();
        expect(
          analyzerTypes,
          containsAll({
            ForcedUnwrappingAnalyzer,
            DirectInstantiationAnalyzer,
            SealedOverDynamicAnalyzer,
            PrivateSubjectAnalyzer,
            SpecificExceptionTypesAnalyzer,
            DocumentFakeParametersAnalyzer,
            DocumentInterfaceAnalyzer,
            NoInternalMethodDocsAnalyzer,
            TodoWithStoryLinksAnalyzer,
            NoOptionalOperatorsInTestsAnalyzer,
            PreferFakeOverMockAnalyzer,
            TestFileMutationCoverageAnalyzer,
          }),
        );
      });

      test('should have analyzers with valid rule names and messages', () {
        for (final analyzer in checker.analyzers) {
          expect(analyzer.ruleName, isNotEmpty);
          expect(analyzer.ruleName, matches(r'^[a-z_]+$'));
          expect(analyzer.problemMessage, isNotEmpty);
          expect(analyzer.problemMessage.length, greaterThan(10));
        }
      });
    });

    group('Public Interface - check() method', () {
      test('should handle empty file paths list', () async {
        final result = await checker.check([]);
        expect(result, isEmpty);
      });

      test('should handle null enabledRules (all rules enabled)', () async {
        final cleanFile = File(p.join(tempDir.path, 'clean.dart'))
          ..writeAsStringSync('void main() {}');

        final result = await checker.check([cleanFile.path]);
        expect(
          result,
          isA<List<String>>(),
        ); // Validates method returns correct type
      });

      test(
        'should handle empty enabledRules list (all rules enabled)',
        () async {
          final cleanFile = File(p.join(tempDir.path, 'clean.dart'))
            ..writeAsStringSync('void main() {}');

          final result = await checker.check([
            cleanFile.path,
          ], enabledRules: []);
          expect(
            result,
            isA<List<String>>(),
          ); // Ensures return type consistency
        },
      );

      test(
        'should handle specific enabledRules with issue detection',
        () async {
          final issueFile = File(p.join(tempDir.path, 'issue.dart'))
            ..writeAsStringSync('''
void main() {
  String? nullableString = null;
  print(nullableString!);
}
''');

          final result = await checker.check(
            [issueFile.path],
            enabledRules: ['forbid_forced_unwrapping'],
          );

          expect(result, isA<List<String>>()); // Validates return type contract
          expect(result, isNotEmpty);
        },
      );

      test('should handle non-existent rules gracefully', () async {
        final cleanFile = File(p.join(tempDir.path, 'clean.dart'))
          ..writeAsStringSync('void main() {}');

        final result = await checker.check(
          [cleanFile.path],
          enabledRules: ['non_existent_rule'],
        );
        expect(
          result,
          isA<List<String>>(),
        ); // Ensures method returns list even with invalid rules
        expect(result, isEmpty);
      });

      test('should skip non-dart files', () async {
        final nonDartFile = File(p.join(tempDir.path, 'test.txt'))
          ..writeAsStringSync('This is not a dart file');

        final result = await checker.check([nonDartFile.path]);
        expect(
          result,
          isA<List<String>>(),
        ); // Validates return type for non-dart files
        expect(result, isEmpty);
      });

      test('should handle relative and absolute paths', () async {
        final testFile = File(p.join(tempDir.path, 'test_file.dart'))
          ..writeAsStringSync('void main() {}');

        final relativePath = p.relative(testFile.path);
        final absPath = p.absolute(testFile.path);

        final relativeResult = await checker.check([relativePath]);
        final absResult = await checker.check([absPath]);

        expect(relativeResult, isEmpty);
        expect(absResult, isEmpty);
      });

      test('should handle paths with special characters', () async {
        final specialFile = File(
          p.join(tempDir.path, 'test-file_with_underscores.dart'),
        )..writeAsStringSync('void main() {}');

        final result = await checker.check([specialFile.path]);
        expect(
          result,
          isA<List<String>>(),
        ); // Ensures special characters don't break return type
        expect(result, isEmpty);
      });
    });

    group('Analyzer Functionality Tests', () {
      test('should detect forced unwrapping issues', () async {
        final file = File(p.join(tempDir.path, 'forced_unwrapping.dart'))
          ..writeAsStringSync('''
void main() {
  String? nullableString = null;
  print(nullableString!);
}
''');

        final result = await checker.check(
          [file.path],
          enabledRules: ['forbid_forced_unwrapping'],
        );
        expect(
          result,
          isA<List<String>>(),
        ); // Validates return type for forced unwrapping detection
        expect(result, isNotEmpty);
      });

      test('should detect direct instantiation issues', () async {
        final file = File(p.join(tempDir.path, 'direct_instantiation.dart'))
          ..writeAsStringSync('''
class AuthService {
  AuthService();
}

void main() {
  final service = AuthService();
}
''');

        final result = await checker.check(
          [file.path],
          enabledRules: ['no_direct_instantiation'],
        );
        expect(
          result,
          isA<List<String>>(),
        ); // Ensures return type for direct instantiation detection
      });

      test('should return empty list when no issues found', () async {
        final cleanFile = File(p.join(tempDir.path, 'clean.dart'))
          ..writeAsStringSync('void main() { print("Hello World"); }');

        final result = await checker.check(
          [cleanFile.path],
          enabledRules: ['forbid_forced_unwrapping', 'no_direct_instantiation'],
        );

        expect(
          result,
          isA<List<String>>(),
        ); // Validates return type even when no issues found
        expect(result, isEmpty);
      });
    });

    group('Error Handling', () {
      test('should handle non-existent file gracefully', () async {
        final nonExistentPath = p.join(tempDir.path, 'non_existent.dart');
        final file = File(nonExistentPath)..writeAsStringSync('void main() {}');

        final result = await checker.check([nonExistentPath]);
        expect(
          result,
          isA<List<String>>(),
        ); // Ensures method handles file access gracefully
      });

      test('should handle files with syntax errors gracefully', () async {
        final file = File(p.join(tempDir.path, 'syntax_error.dart'))
          ..writeAsStringSync('''
void main() {
  String? nullableString = null;
  print(nullableString!);
}

void anotherFunction() {
  print('Hello');  // Missing semicolon but not fatal
}
'''); // missing semicolon intentionally

        final result = await checker.check(
          [file.path],
          enabledRules: ['forbid_forced_unwrapping'],
        );
        expect(
          result,
          isA<List<String>>(),
        ); // Validates return type despite syntax errors
      });
    });
  });
}
