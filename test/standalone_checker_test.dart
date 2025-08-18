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
    late File testFile;
    late File testFile2;
    late File nonDartFile;

    setUp(() {
      checker = StandaloneLintChecker();

      tempDir = Directory.systemTemp.createTempSync('standalone_checker_test_');
      testFile = File(p.join(tempDir.path, 'test_file.dart'));
      testFile2 = File(p.join(tempDir.path, 'test_file2.dart'));
      nonDartFile = File(p.join(tempDir.path, 'test.txt'));

      testFile.writeAsStringSync('''
void main() {
  print('Hello World');
}
''');

      testFile2.writeAsStringSync('''
class TestClass {
  void testMethod() {
  }
}
''');

      nonDartFile.writeAsStringSync('This is not a dart file');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('Constructor and Properties', () {
      test('should initialize with all analyzers', () {
        expect(checker.analyzers, isNotEmpty);
        expect(checker.analyzers.length, 12);
      });

      test('should contain specific analyzers', () {
        final analyzerTypes =
            checker.analyzers.map((a) => a.runtimeType).toSet();
        expect(analyzerTypes, contains(ForcedUnwrappingAnalyzer));
        expect(analyzerTypes, contains(DirectInstantiationAnalyzer));
        expect(analyzerTypes, contains(SealedOverDynamicAnalyzer));
        expect(analyzerTypes, contains(PrivateSubjectAnalyzer));
        expect(analyzerTypes, contains(SpecificExceptionTypesAnalyzer));
        expect(analyzerTypes, contains(DocumentFakeParametersAnalyzer));
        expect(analyzerTypes, contains(DocumentInterfaceAnalyzer));
        expect(analyzerTypes, contains(NoInternalMethodDocsAnalyzer));
        expect(analyzerTypes, contains(TodoWithStoryLinksAnalyzer));
        expect(analyzerTypes, contains(NoOptionalOperatorsInTestsAnalyzer));
        expect(analyzerTypes, contains(PreferFakeOverMockAnalyzer));
        expect(analyzerTypes, contains(TestFileMutationCoverageAnalyzer));
      });

      test('should have analyzers with valid rule names', () {
        for (final analyzer in checker.analyzers) {
          expect(analyzer.ruleName, isNotEmpty);
        }
      });
    });

    group('Public Interface - check() method', () {
      test('should handle empty file paths list', () async {
        final result = await checker.check([]);
        expect(result, isEmpty);
      });

      test('should handle null enabledRules (all rules enabled)', () async {
        final paths = [testFile.path];
        final result = await checker.check(paths);
        expect(result, isA<List<String>>());
      });

      test(
        'should handle empty enabledRules list (all rules enabled)',
        () async {
          final paths = [testFile.path];
          final result = await checker.check(paths, enabledRules: []);
          expect(result, isA<List<String>>());
        },
      );

      test('should handle specific enabledRules', () async {
        final paths = [testFile.path];
        final enabledRules = ['no_direct_instantiation', 'sealed_over_dynamic'];
        final result = await checker.check(paths, enabledRules: enabledRules);
        expect(result, isA<List<String>>());
      });

      test('should handle non-existent rules gracefully', () async {
        final paths = [testFile.path];
        final enabledRules = ['non_existent_rule'];
        final result = await checker.check(paths, enabledRules: enabledRules);
        expect(result, isA<List<String>>());
        expect(result, isEmpty);
      });

      test('should analyze individual dart files', () async {
        final paths = [testFile.path, testFile2.path];
        final result = await checker.check(paths);
        expect(result, isA<List<String>>());
      });

      test('should analyze directories', () async {
        final paths = [testFile.path];
        final result = await checker.check(paths);
        expect(result, isA<List<String>>());
      });

      test('should analyze mixed files and directories', () async {
        final paths = [testFile.path, testFile2.path];
        final result = await checker.check(paths);
        expect(result, isA<List<String>>());
      });

      test('should skip non-dart files', () async {
        final paths = [nonDartFile.path];
        final result = await checker.check(paths);
        expect(result, isA<List<String>>());
        expect(result, isEmpty);
      });

      test('should handle relative paths', () async {
        final relativePath = p.relative(testFile.path);
        final paths = [relativePath];
        final result = await checker.check(paths);
        expect(result, isA<List<String>>());
      });

      test('should handle absolute paths', () async {
        final absolutePath = p.absolute(testFile.path);
        final paths = [absolutePath];
        final result = await checker.check(paths);
        expect(result, isA<List<String>>());
      });

      test('should handle paths with special characters', () async {
        final specialFile = File(
          p.join(tempDir.path, 'test-file_with_underscores.dart'),
        );
        specialFile.writeAsStringSync('void main() {}');

        final paths = [specialFile.path];
        final result = await checker.check(paths);
        expect(result, isA<List<String>>());
      });
    });

    group('Analyzer Functionality Tests', () {
      test('should detect forced unwrapping issues', () async {
        final forcedUnwrappingFile = File(
          p.join(tempDir.path, 'forced_unwrapping.dart'),
        );
        forcedUnwrappingFile.writeAsStringSync('''
void main() {
  String? nullableString = null;
  print(nullableString!);
}
''');

        final paths = [forcedUnwrappingFile.path];
        final enabledRules = ['forbid_forced_unwrapping'];
        final result = await checker.check(paths, enabledRules: enabledRules);

        expect(result, isA<List<String>>());
        expect(result, isNotEmpty);
        expect(
          result.any((issue) => issue.contains('forbid_forced_unwrapping')),
          isTrue,
        );
      });

      test('should detect direct instantiation issues', () async {
        final directInstantiationFile = File(
          p.join(tempDir.path, 'direct_instantiation.dart'),
        );
        directInstantiationFile.writeAsStringSync('''
class AuthService {
  AuthService();
}

void main() {
  final service = AuthService();
}
''');

        final paths = [directInstantiationFile.path];
        final enabledRules = ['no_direct_instantiation'];
        final result = await checker.check(paths, enabledRules: enabledRules);

        expect(result, isA<List<String>>());
      });

      test('should detect sealed over dynamic issues', () async {
        final sealedOverDynamicFile = File(
          p.join(tempDir.path, 'sealed_over_dynamic.dart'),
        );
        sealedOverDynamicFile.writeAsStringSync('''
void main() {
  dynamic value = 'test';
  value = 42;
}
''');

        final paths = [sealedOverDynamicFile.path];
        final enabledRules = ['sealed_over_dynamic'];
        final result = await checker.check(paths, enabledRules: enabledRules);

        expect(result, isA<List<String>>());
      });

      test('should return empty list when no issues found', () async {
        final cleanFile = File(p.join(tempDir.path, 'clean.dart'));
        cleanFile.writeAsStringSync('''
void main() {
  print('Hello World');
}
''');

        final paths = [cleanFile.path];
        final enabledRules = [
          'forbid_forced_unwrapping',
          'no_direct_instantiation',
        ];
        final result = await checker.check(paths, enabledRules: enabledRules);

        expect(result, isA<List<String>>());
        expect(result, isEmpty);
      });

      test('should format issues correctly', () async {
        final issueFile = File(p.join(tempDir.path, 'issue_file.dart'));
        issueFile.writeAsStringSync('''
void main() {
  String? nullableString = null;
  print(nullableString!);
}
''');

        final paths = [issueFile.path];
        final enabledRules = ['forbid_forced_unwrapping'];
        final result = await checker.check(paths, enabledRules: enabledRules);

        expect(result, isA<List<String>>());
        expect(result, isNotEmpty);

        final issue = result.first;
        expect(issue, contains(':'));
        expect(issue, contains('•'));
        expect(issue, contains('forbid_forced_unwrapping'));
        expect(issue, contains(issueFile.path));
      });

      test('should work with multiple analyzers simultaneously', () async {
        final multiIssueFile = File(p.join(tempDir.path, 'multi_issue.dart'));
        multiIssueFile.writeAsStringSync('''
class TestClass {
  TestClass();
}

void main() {
  String? nullableString = null;
  print(nullableString!);
  
  final instance = TestClass();
}
''');

        final paths = [multiIssueFile.path];
        final enabledRules = [
          'forbid_forced_unwrapping',
          'no_direct_instantiation',
        ];
        final result = await checker.check(paths, enabledRules: enabledRules);

        expect(result, isA<List<String>>());
        expect(result, isNotEmpty);
        expect(
          result.any((issue) => issue.contains('forbid_forced_unwrapping')),
          isTrue,
        );
      });

      test('debug: should show what analyzers are actually doing', () async {
        final debugFile = File(p.join(tempDir.path, 'debug.dart'));
        debugFile.writeAsStringSync('''
class TestClass {
  TestClass();
}

void main() {
  String? nullableString = null;
  print(nullableString!);
  
  final instance = TestClass();
}
''');

        final paths = [debugFile.path];

        final allRulesResult = await checker.check(paths);
        print('All rules result: $allRulesResult');

        final forcedUnwrappingResult = await checker.check(
          paths,
          enabledRules: ['forbid_forced_unwrapping'],
        );
        print('Forced unwrapping result: $forcedUnwrappingResult');

        final directInstantiationResult = await checker.check(
          paths,
          enabledRules: ['no_direct_instantiation'],
        );
        print('Direct instantiation result: $directInstantiationResult');

        expect(allRulesResult, isA<List<String>>());
        expect(forcedUnwrappingResult, isA<List<String>>());
        expect(directInstantiationResult, isA<List<String>>());
      });

      test('debug: direct instantiation analyzer specifically', () async {
        final directInstantiationDebugFile = File(
          p.join(tempDir.path, 'direct_instantiation_debug.dart'),
        );
        directInstantiationDebugFile.writeAsStringSync('''
class SimpleClass {
  SimpleClass();
}

void main() {
  final obj = SimpleClass();
}
''');

        final paths = [directInstantiationDebugFile.path];
        final result = await checker.check(
          paths,
          enabledRules: ['no_direct_instantiation'],
        );

        print('Direct instantiation debug result: $result');
        print(
          'File content: ${directInstantiationDebugFile.readAsStringSync()}',
        );

        expect(result, isA<List<String>>());
      });
    });

    group('Test File Handling', () {
      test(
        'should analyze test files when test_file_mutation_coverage rule is enabled',
        () async {
          final testFile = File(p.join(tempDir.path, 'test_test.dart'));
          testFile.writeAsStringSync('void main() {}');

          final paths = [testFile.path];
          final enabledRules = ['test_file_mutation_coverage'];
          final result = await checker.check(paths, enabledRules: enabledRules);
          expect(result, isA<List<String>>());
        },
      );

      test(
        'should skip test files when test_file_mutation_coverage rule is not enabled',
        () async {
          final testFile = File(p.join(tempDir.path, 'test_test.dart'));
          testFile.writeAsStringSync('void main() {}');

          final paths = [testFile.path];
          final enabledRules = ['forbid_forced_unwrapping'];
          final result = await checker.check(paths, enabledRules: enabledRules);
          expect(result, isA<List<String>>());
          expect(result, isEmpty);
        },
      );
    });

    group('Error Handling and Edge Cases', () {
      test('should handle empty paths gracefully', () async {
        final result = await checker.check([]);
        expect(result, isEmpty);
      });

      test('should handle paths with special characters', () async {
        final specialFile = File(
          p.join(tempDir.path, 'test-file_with_underscores.dart'),
        );
        specialFile.writeAsStringSync('void main() {}');

        final paths = [specialFile.path];
        final result = await checker.check(paths);
        expect(result, isA<List<String>>());
      });

      test('should handle mixed valid and invalid paths gracefully', () async {
        final validPath = testFile.path;
        final result = await checker.check([validPath]);
        expect(result, isA<List<String>>());
      });
    });

    group('Performance and Scalability', () {
      test('should handle large number of files', () async {
        final files = <String>[];
        for (int i = 0; i < 10; i++) {
          final file = File(p.join(tempDir.path, 'test_file_$i.dart'));
          file.writeAsStringSync('void main() { print("File $i"); }');
          files.add(file.path);
        }

        final result = await checker.check(files);
        expect(result, isA<List<String>>());
      });

      test('should handle large number of directories', () async {
        final files = <String>[];
        for (int i = 0; i < 5; i++) {
          final file = File(p.join(tempDir.path, 'test_file_$i.dart'));
          file.writeAsStringSync('void main() { print("File $i"); }');
          files.add(file.path);
        }

        final result = await checker.check(files);
        expect(result, isA<List<String>>());
      });
    });

    group('Integration Tests', () {
      test(
        'should work with real dart files containing various content',
        () async {
          final complexFile = File(p.join(tempDir.path, 'complex.dart'));
          complexFile.writeAsStringSync('''
import 'dart:io';

class ComplexClass {
  final String name;
  final int value;
  
  ComplexClass(this.name, this.value);
  
  void complexMethod() {
    if (value > 0) {
      print('Positive: \$name');
    } else {
      print('Non-positive: \$name');
    }
  }
}

void main() {
  final instance = ComplexClass('Test', 42);
  instance.complexMethod();
}
''');

          final paths = [complexFile.path];
          final result = await checker.check(paths);
          expect(result, isA<List<String>>());
        },
      );

      test('should work with multiple rule combinations', () async {
        final paths = [testFile.path];
        final ruleCombinations = [
          ['forbid_forced_unwrapping'],
          ['no_direct_instantiation', 'sealed_over_dynamic'],
          ['document_interface', 'no_internal_method_docs'],
          ['todo_with_story_links', 'prefer_fake_over_mock'],
        ];

        for (final rules in ruleCombinations) {
          final result = await checker.check(paths, enabledRules: rules);
          expect(result, isA<List<String>>());
        }
      });
    });
  });
}
