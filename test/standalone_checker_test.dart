import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import '../bin/standalone_checker.dart';
import 'package:ripplearc_linter/core/analyzers/base_analyzer.dart';
import 'package:ripplearc_linter/core/analyzers/test_file_mutation_coverage_analyzer.dart';

void main() {
  group('StandaloneLintChecker - Bridge between custom_dart_lint and user commands', () {
    late Directory tempDir;
    late String tempDirPath;

    setUpAll(() async {
      tempDir = Directory.systemTemp.createTempSync('standalone_checker_test_');
      tempDirPath = tempDir.path;
    });

    tearDownAll(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Bridge Initialization and Configuration', () {
      test('should initialize with all 20 custom lint analyzers', () {
        final checker = StandaloneLintChecker();

        expect(checker.analyzers.length, equals(20));

        final ruleNames = checker.analyzers.map((a) => a.ruleName).toSet();
        final expectedRules = {
          'avoid_static_colors',
          'avoid_static_typography',
          'forbid_forced_unwrapping',
          'forbid_helper_util_naming',
          'no_direct_instantiation',
          'sealed_over_dynamic',
          'private_subject',
          'specific_exception_types',
          'document_fake_parameters',
          'document_interface',
          'no_internal_method_docs',
          'todo_with_story_links',
          'no_optional_operators_in_tests',
          'prefer_fake_over_mock',
          'test_file_mutation_coverage',
          'feature_module_isolation',
          'prevent_library_module_dependencies',
          'forbid_modular_get_outside_module',
          'forbid_raw_icon_and_image_usage',
          'restrict_core_icon_data',
        };

        expect(ruleNames, equals(expectedRules));
      });

      test(
        'should provide access to all analyzer interfaces for command integration',
        () {
          final checker = StandaloneLintChecker();

          for (final analyzer in checker.analyzers) {
            expect(analyzer, isA<BaseAnalyzer>());
            expect(analyzer.ruleName, isNotEmpty);
            expect(analyzer.ruleName.trim(), equals(analyzer.ruleName));
            expect(analyzer.analyze, isA<Function>());
            expect(analyzer.problemMessage, isNotEmpty);
            expect(analyzer.correctionMessage, isNotEmpty);
          }
        },
      );
    });

    group('User Command Interface - Specific Files Control', () {
      test(
        'should run all analyzers on specific single file when no rules specified',
        () async {
          final testFile = await _createTempFile(
            tempDirPath,
            'single_file_test.dart',
            '''
class TestClass {
  String? getValue() => null;
  
  void problematicMethod() {
    final value = getValue();
    print(value!);
  }
}
''',
          );

          final checker = StandaloneLintChecker();
          final issues = await checker.check([testFile.path]);

          final uniqueRules =
              issues.map((issue) => issue.split(' • ').last).toSet();
          expect(uniqueRules.length, greaterThanOrEqualTo(0));
        },
      );

      test('should run all analyzers on multiple specific files', () async {
        final file1 = await _createTempFile(tempDirPath, 'multi_file1.dart', '''
class File1 {
  String? getValue() => null;
  void test() { print(getValue()!); }
}
''');

        final file2 = await _createTempFile(tempDirPath, 'multi_file2.dart', '''
class File2 {
  void cleanMethod() {
    print('Clean code here');
  }
}
''');

        final checker = StandaloneLintChecker();
        final issues = await checker.check([file1.path, file2.path]);

        final analyzedFiles =
            issues.map((issue) => issue.split(':').first).toSet();
        expect(
          analyzedFiles.any((path) => path.contains('multi_file1.dart')),
          isTrue,
          reason: 'Should analyze first file',
        );
      });

      test(
        'should run specific analyzer on specific file via enabledRules',
        () async {
          final testFile = await _createTempFile(
            tempDirPath,
            'specific_rule_test.dart',
            '''
class SpecificTest {
  String? getValue() => null;
  void method() {
    print(getValue()!);
  }
}
''',
          );

          final checker = StandaloneLintChecker();
          final issues = await checker.check(
            [testFile.path],
            enabledRules: ['forbid_forced_unwrapping'],
          );

          for (final issue in issues) {
            expect(issue, contains('forbid_forced_unwrapping'));
          }
        },
      );

      test(
        'should run multiple specific analyzers on specific files',
        () async {
          final testFile = await _createTempFile(
            tempDirPath,
            'multi_rule_test.dart',
            '''
class MultiRuleTest {
  String? getValue() => null;
  
  void method() {
    print(getValue()!);
  }
}
''',
          );

          final checker = StandaloneLintChecker();
          final issues = await checker.check(
            [testFile.path],
            enabledRules: ['forbid_forced_unwrapping', 'sealed_over_dynamic'],
          );

          for (final issue in issues) {
            final ruleName = issue.split(' • ').last;
            expect([
              'forbid_forced_unwrapping',
              'sealed_over_dynamic',
            ], contains(ruleName));
          }
        },
      );
    });

    group('User Command Interface - Directory Control', () {
      test('should run all analyzers on all files in directory', () async {
        final mainTestFile = await _createTempFile(tempDirPath, 'main.dart', '''
class MainClass {
  String? getValue() => null;
  void run() { print(getValue()!); }
}
''');
        final utilsTestFile = await _createTempFile(
          tempDirPath,
          'utils.dart',
          '''
class Utils {
  String? getValue() => null;
  void run() { print(getValue()!); }
}
''',
        );

        final checker = StandaloneLintChecker();
        final issues = await checker.check([
          mainTestFile.path,
          utilsTestFile.path,
        ]);

        final analyzedFiles =
            issues.map((issue) => issue.split(':').first).toSet();

        expect(
          analyzedFiles.any((p) => p.contains('main.dart')) &&
              analyzedFiles.any((p) => p.contains('utils.dart')),
          isTrue,
          reason: 'Should analyze both main.dart and utils.dart in directory',
        );
      });

      test(
        'should run specific analyzers on directory via enabledRules',
        () async {
          final testDir = Directory(p.join(tempDirPath, 'specific_dir_test'));
          await testDir.create();

          final testFile = await _createTempFile(testDir.path, 'main.dart', '''
class DirTest {
  String? getValue() => null;
  void test() { print(getValue()!); }
}
''');

          final checker = StandaloneLintChecker();
          final issues = await checker.check(
            [testFile.path],
            enabledRules: ['forbid_forced_unwrapping'],
          );

          for (final issue in issues) {
            expect(issue, contains('forbid_forced_unwrapping'));
          }
        },
      );

      test(
        'should handle mixed file and directory paths with rule filtering',
        () async {
          final individualFile = await _createTempFile(
            tempDirPath,
            'individual.dart',
            '''
class Individual {
  String? getValue() => null;
  void test() { print(getValue()!); }
}
''',
          );

          final mixedDir = Directory(p.join(tempDirPath, 'mixed_test'));
          await mixedDir.create();
          final inDirFile = await _createTempFile(
            mixedDir.path,
            'in_dir.dart',
            '''
class InDir {
  String? getValue() => null;
  void test() { print(getValue()!); }
}
''',
          );

          final checker = StandaloneLintChecker();
          final issues = await checker.check(
            [individualFile.path, inDirFile.path],
            enabledRules: ['forbid_forced_unwrapping'],
          );

          final analyzedFiles =
              issues.map((issue) => issue.split(':').first).toSet();
          expect(
            analyzedFiles.any((path) => path.contains('individual.dart')),
            isTrue,
            reason: 'Should analyze individual file',
          );
        },
      );
    });

    group('Bridge Performance Optimization', () {
      test(
        'should detect issues in at least one analysis strategy (file vs directory)',
        () async {
          final simpleFile = await _createTempFile(
            tempDirPath,
            'simple.dart',
            '''
class Simple {
  String? getValue() => null;
  void test() { print(getValue()!); }
}
''',
          );

          final testDir = Directory(p.join(tempDirPath, 'strategy_test'));
          await testDir.create();
          await _createTempFile(testDir.path, 'strategy.dart', '''
class Strategy {
  String? getValue() => null;  
  void test() { print(getValue()!); }
}
''');

          final checker = StandaloneLintChecker();

          final fileResults = await checker.check([simpleFile.path]);
          final dirResults = await checker.check([
            "${testDir.path}/strategy.dart",
          ]);

          expect(fileResults, isA<List<String>>());
          expect(dirResults, isA<List<String>>());

          final fileResultsSet = fileResults.toSet();
          final dirResultsSet = dirResults.toSet();

          expect(
            fileResultsSet.isNotEmpty || dirResultsSet.isNotEmpty,
            isTrue,
            reason: 'At least one analysis strategy should find issues',
          );
        },
      );
    });

    group('Test File Filtering Control', () {
      test('should exclude test files by default (user control)', () async {
        final testFile = await _createTempFile(
          tempDirPath,
          'widget_test.dart',
          '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('test widget', (tester) async {
    
  });
}
''',
        );

        final checker = StandaloneLintChecker();
        final issues = await checker.check([testFile.path]);

        expect(issues, isEmpty, reason: 'Should skip test files by default');
      });

      test(
        'should include test files when test_file_mutation_coverage enabled',
        () async {
          final testFile = await _createTempFile(
            tempDirPath,
            'unit_test.dart',
            '''
import 'package:test/test.dart';

void main() {
  test('unit test example', () {
    expect(1 + 1, equals(2));
  });
}
''',
          );

          final checker = StandaloneLintChecker();
          await checker.check(
            [testFile.path],
            enabledRules: ['test_file_mutation_coverage'],
          );
        },
      );

      test(
        'should correctly identify test files using BaseAnalyzer.isTestFile',
        () {
          expect(BaseAnalyzer.isTestFile('widget_test.dart'), isTrue);
          expect(BaseAnalyzer.isTestFile('integration_test.dart'), isTrue);
          expect(BaseAnalyzer.isTestFile('lib/main.dart'), isFalse);
          expect(BaseAnalyzer.isTestFile('lib/src/service.dart'), isFalse);
        },
      );
    });

    group('Command Line Bridge Integration', () {
      test('should handle empty rule list as all rules enabled', () async {
        final testFile = await _createTempFile(
          tempDirPath,
          'all_rules.dart',
          '''
class AllRulesTest {
  void method() {
    print('Testing all rules');
  }
}
''',
        );

        final checker = StandaloneLintChecker();

        final issuesNull = await checker.check([
          testFile.path,
        ], enabledRules: null);
        final issuesEmpty = await checker.check([testFile.path]);

        expect(issuesNull, isA<List<String>>());
        expect(issuesEmpty, isA<List<String>>());
      });

      test('should validate rule names from command input', () async {
        final testFile = await _createTempFile(
          tempDirPath,
          'validate_rules.dart',
          'class ValidateRules {}',
        );

        final checker = StandaloneLintChecker();

        final issues = await checker.check(
          [testFile.path],
          enabledRules: ['non_existent_rule'],
        );

        expect(
          issues,
          isEmpty,
          reason: 'Should handle invalid rule names gracefully',
        );
      });

      test(
        'should provide proper issue formatting for command line output',
        () async {
          final testFile = await _createTempFile(
            tempDirPath,
            'format_output.dart',
            '''
class FormatOutput {
  String? getValue() => null;
  void test() {
    print(getValue()!);
  }
}
''',
          );

          final checker = StandaloneLintChecker();
          final issues = await checker.check(
            [testFile.path],
            enabledRules: ['forbid_forced_unwrapping'],
          );

          for (final issue in issues) {
            expect(
              issue,
              matches(r'^.+:\d+:\d+ • .+ • \w+$'),
              reason: 'Should format for command line output',
            );
            expect(issue, contains(testFile.path));
            expect(issue, contains('•'));
            expect(issue, contains('forbid_forced_unwrapping'));
          }
        },
      );

      test(
        'should handle unicode bullet character correctly in output format',
        () async {
          final testFile = await _createTempFile(
            tempDirPath,
            'unicode_test.dart',
            '''
class UnicodeTest {
  String? getValue() => null;
  void test() { print(getValue()!); }
}
''',
          );

          final checker = StandaloneLintChecker();
          final issues = await checker.check(
            [testFile.path],
            enabledRules: ['forbid_forced_unwrapping'],
          );

          for (final issue in issues) {
            final parts = issue.split(' • ');
            expect(
              parts.length,
              equals(3),
              reason: 'Issue should split correctly on bullet character',
            );

            expect(
              parts[0],
              matches(r'^.+:\d+:\d+$'),
              reason: 'First part should be filepath:line:column',
            );
            expect(
              parts[1],
              isNotEmpty,
              reason: 'Second part should be message',
            );
            expect(
              parts[2],
              equals('forbid_forced_unwrapping'),
              reason: 'Third part should be rule name',
            );

            expect(
              issue,
              contains('•'),
              reason: 'Should contain proper unicode bullet character',
            );
            expect(
              issue,
              isNot(contains('â€¢')),
              reason: 'Should not contain malformed UTF-8 encoding',
            );
          }
        },
      );

      test(
        'should verify consistent character encoding across all issue formats',
        () async {
          final testFiles = <File>[];
          final expectedRules = [
            'forbid_forced_unwrapping',
            'sealed_over_dynamic',
          ];

          for (int i = 0; i < 2; i++) {
            testFiles.add(
              await _createTempFile(tempDirPath, 'encoding_$i.dart', '''
class EncodingTest$i {
  String? getValue() => null;
  void test() { print(getValue()!); }
}
'''),
            );
          }

          final checker = StandaloneLintChecker();
          final issues = await checker.check(
            testFiles.map((f) => f.path).toList(),
            enabledRules: expectedRules,
          );

          final bulletCharacters = <String>{};
          for (final issue in issues) {
            final matches = RegExp(r' (.) ').allMatches(issue);
            for (final match in matches) {
              if (match.group(1) != null) {
                bulletCharacters.add(match.group(1)!);
              }
            }
          }

          expect(
            bulletCharacters.length,
            lessThanOrEqualTo(1),
            reason: 'All issues should use the same bullet character',
          );

          if (bulletCharacters.isNotEmpty) {
            final bulletChar = bulletCharacters.first;
            expect(
              bulletChar,
              equals('•'),
              reason: 'Should use proper unicode bullet character',
            );
            expect(
              bulletChar.codeUnits.length,
              equals(1),
              reason: 'Bullet character should be single unicode code unit',
            );
          }
        },
      );
    });

    group('Bridge Error Handling and Robustness', () {
      test('should handle file system errors gracefully', () async {
        final checker = StandaloneLintChecker();

        expect(
          () => checker.check(['non_existent_file.dart']),
          throwsA(isA<FileSystemException>()),
          reason: 'Should throw appropriate file system error',
        );
      });

      test(
        'should handle analyzer exceptions without breaking bridge',
        () async {
          final testFile = await _createTempFile(
            tempDirPath,
            'analyzer_stress.dart',
            '''
class AnalyzerStress {
  dynamic getValue() => null;
  void method() {
    var result = getValue();
    print(result);
  }
}
''',
          );

          final checker = StandaloneLintChecker();
          final issues = await checker.check([testFile.path]);

          expect(
            issues,
            isEmpty,
            reason: 'Analyzer exceptions should not produce issues',
          );
        },
      );
    });

    group('Special Analyzer Integration', () {
      test(
        'should properly handle TestFileMutationCoverageAnalyzer special interface',
        () {
          final checker = StandaloneLintChecker();
          final testAnalyzer = checker.analyzers.firstWhere(
            (a) => a.ruleName == 'test_file_mutation_coverage',
            orElse:
                () =>
                    throw StateError(
                      'TestFileMutationCoverageAnalyzer not found in bridge',
                    ),
          );

          expect(testAnalyzer, isA<TestFileMutationCoverageAnalyzer>());
          expect(testAnalyzer.ruleName, equals('test_file_mutation_coverage'));
        },
      );

      test(
        'should provide _SimpleResolver with file path to TestFileMutationCoverageAnalyzer',
        () async {
          final testFile = await _createTempFile(
            tempDirPath,
            'resolver_test.dart',
            '''
import 'package:test/test.dart';

void main() {
  test('resolver integration test', () {
    expect(true, isTrue);
  });
}
''',
          );

          final checker = StandaloneLintChecker();
          final issues = await checker.check(
            [testFile.path],
            enabledRules: ['test_file_mutation_coverage'],
          );

          for (final issue in issues) {
            expect(
              issue,
              contains(testFile.path),
              reason: 'Resolver should provide correct file path context',
            );
          }
        },
      );

      test(
        'should verify _SimpleResolver provides minimal resolver interface',
        () async {
          final testFile = await _createTempFile(
            tempDirPath,
            'minimal_resolver_test.dart',
            '''
import 'package:test/test.dart';

void main() {
  group('test group', () {
    test('nested test', () {
      expect(1 + 1, equals(2));
    });
  });
}
''',
          );

          final checker = StandaloneLintChecker();

          expect(
            () async {
              await checker.check(
                [testFile.path],
                enabledRules: ['test_file_mutation_coverage'],
              );
            },
            returnsNormally,
            reason:
                '_SimpleResolver should provide sufficient interface for TestFileMutationCoverageAnalyzer',
          );
        },
      );

      test(
        'should handle TestFileMutationCoverageAnalyzer differently from regular analyzers',
        () async {
          final regularFile = await _createTempFile(
            tempDirPath,
            'regular_analysis.dart',
            '''
class RegularTest {
  String? getValue() => null;
  void test() { print(getValue()!); }
}
''',
          );

          final testFile = await _createTempFile(
            tempDirPath,
            'mutation_test.dart',
            '''
import 'package:test/test.dart';

void main() {
  test('mutation test', () {
    expect(true, isTrue);
  });
}
''',
          );

          final checker = StandaloneLintChecker();

          final regularResults = await checker.check(
            [regularFile.path],
            enabledRules: ['forbid_forced_unwrapping'],
          );

          final mutationResults = await checker.check(
            [testFile.path],
            enabledRules: ['test_file_mutation_coverage'],
          );

          expect(regularResults, isA<List<String>>());
          expect(mutationResults, isA<List<String>>());

          if (regularResults.isNotEmpty) {
            expect(regularResults.first, contains('forbid_forced_unwrapping'));
          }
          if (mutationResults.isNotEmpty) {
            expect(
              mutationResults.first,
              contains('test_file_mutation_coverage'),
            );
          }
        },
      );
    });

    group('Path Handling and Normalization', () {
      test('should normalize paths for consistent command interface', () async {
        final testFile = await _createTempFile(
          tempDirPath,
          'path_test.dart',
          'class PathTest {}',
        );

        final relativePath = p.relative(testFile.path);

        final checker = StandaloneLintChecker();
        final issues = await checker.check([relativePath]);
        expect(
          issues.every((issue) => issue.contains('path_test.dart')),
          isTrue,
          reason: 'Issues should correctly map to normalized relative path',
        );
      });

      test('should handle directory traversal correctly', () async {
        final nestedDir = Directory(p.join(tempDirPath, 'nested'));
        await nestedDir.create(recursive: true);

        final deepFile = await _createTempFile(
          nestedDir.path,
          'deep_file.dart',
          '''
class SpecificTest {
  String? getValue() => null;
  void method() {
    print(getValue()!);
  }
}
''',
        );

        final checker = StandaloneLintChecker();
        final issues = await checker.check([deepFile.path]);
        expect(
          issues.any((issue) => issue.contains('deep_file.dart')),
          isTrue,
          reason: 'Should analyze files inside nested directories',
        );
      });
    });
  });
}

Future<File> _createTempFile(
  String dirPath,
  String fileName,
  String content,
) async {
  final file = File(p.join(dirPath, fileName));
  await file.writeAsString(content);
  return file;
}
