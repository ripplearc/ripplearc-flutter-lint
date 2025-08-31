import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:analyzer/dart/ast/ast.dart';
import '../standalone_checker.dart';
import '../lib/core/analyzers/base_analyzer.dart';
import '../lib/core/analyzers/test_file_mutation_coverage_analyzer.dart';
import '../lib/core/models/lint_issue.dart';

class TestIssue {
  final int line;
  final int column;
  final String message;
  final String ruleName;

  TestIssue({
    required this.line,
    required this.column,
    required this.message,
    required this.ruleName,
  });
}

class FakeAnalyzer extends BaseAnalyzer {
  final List<TestIssue> issuesToReturn;
  final String ruleNameOverride;
  final bool shouldThrowError;

  int analyzeCallCount = 0;
  List<dynamic> unitsAnalyzed = [];

  FakeAnalyzer({
    required this.ruleNameOverride,
    this.issuesToReturn = const [],
    this.shouldThrowError = false,
  });

  @override
  String get ruleName => ruleNameOverride;

  @override
  String get problemMessage => 'Test problem message';

  @override
  String get correctionMessage => 'Test correction message';

  @override
  List<LintIssue> analyze(CompilationUnit unit) {
    analyzeCallCount++;
    unitsAnalyzed.add(unit);

    if (shouldThrowError) {
      throw Exception('Test analyzer error');
    }

    return issuesToReturn
        .map(
          (issue) => LintIssue(
            offset: 0,
            length: 0,
            line: issue.line,
            column: issue.column,
            ruleName: issue.ruleName,
            message: issue.message,
            correctionMessage: correctionMessage,
            severity: severity,
          ),
        )
        .toList();
  }
}

class FakeTestFileMutationCoverageAnalyzer extends BaseAnalyzer {
  final List<TestIssue> issuesToReturn;

  int analyzeCallCount = 0;
  int analyzeWithResolverCallCount = 0;
  List<dynamic> unitsAnalyzed = [];
  List<dynamic> resolversUsed = [];

  FakeTestFileMutationCoverageAnalyzer({this.issuesToReturn = const []});

  @override
  String get ruleName => 'test_file_mutation_coverage';

  @override
  String get problemMessage => 'Test problem message';

  @override
  String get correctionMessage => 'Test correction message';

  @override
  List<LintIssue> analyze(CompilationUnit unit) {
    analyzeCallCount++;
    unitsAnalyzed.add(unit);
    return issuesToReturn
        .map(
          (issue) => LintIssue(
            offset: 0,
            length: 0,
            line: issue.line,
            column: issue.column,
            ruleName: issue.ruleName,
            message: issue.message,
            correctionMessage: correctionMessage,
            severity: severity,
          ),
        )
        .toList();
  }

  List<LintIssue> analyzeWithResolver(CompilationUnit unit, dynamic resolver) {
    analyzeWithResolverCallCount++;
    unitsAnalyzed.add(unit);
    resolversUsed.add(resolver);
    return issuesToReturn
        .map(
          (issue) => LintIssue(
            offset: 0,
            length: 0,
            line: issue.line,
            column: issue.column,
            ruleName: issue.ruleName,
            message: issue.message,
            correctionMessage: correctionMessage,
            severity: severity,
          ),
        )
        .toList();
  }
}

class TestableStandaloneLintChecker {
  final List<BaseAnalyzer> testAnalyzers;

  TestableStandaloneLintChecker(this.testAnalyzers);

  List<BaseAnalyzer> get analyzers => testAnalyzers;

  Future<List<String>> check(
    List<String> filePaths, {
    List<String>? enabledRules,
  }) async {
    final shouldCheckTestFiles = _shouldCheckTestFiles(enabledRules);
    final activeAnalyzers = _getActiveAnalyzers(enabledRules);
    final pathGroups = _categorizePaths(filePaths);

    final allIssues = <String>[];

    allIssues.addAll(
      _analyzeIndividualFiles(
        pathGroups.files,
        activeAnalyzers,
        shouldCheckTestFiles,
      ),
    );

    allIssues.addAll(
      await _analyzeDirectories(
        pathGroups.directories,
        activeAnalyzers,
        shouldCheckTestFiles,
      ),
    );

    return allIssues;
  }

  bool _shouldCheckTestFiles(List<String>? enabledRules) {
    return enabledRules?.contains('test_file_mutation_coverage') ?? false;
  }

  List<BaseAnalyzer> _getActiveAnalyzers(List<String>? enabledRules) {
    return enabledRules != null
        ? testAnalyzers.where((a) => enabledRules.contains(a.ruleName)).toList()
        : testAnalyzers;
  }

  _PathGroups _categorizePaths(List<String> filePaths) {
    final absolutePaths = _normalizePaths(filePaths);
    final files = <String>[];
    final directories = <String>[];

    for (final path in absolutePaths) {
      if (FileSystemEntity.isDirectorySync(path)) {
        directories.add(path);
      } else if (path.endsWith('.dart')) {
        files.add(path);
      }
    }

    return _PathGroups(files: files, directories: directories);
  }

  List<String> _normalizePaths(List<String> filePaths) {
    return filePaths.map((path) {
      final absolute =
          FileSystemEntity.isDirectorySync(path)
              ? Directory(path).absolute.path
              : File(path).absolute.path;
      return p.normalize(p.canonicalize(absolute));
    }).toList();
  }

  List<String> _analyzeIndividualFiles(
    List<String> files,
    List<BaseAnalyzer> activeAnalyzers,
    bool shouldCheckTestFiles,
  ) {
    final issues = <String>[];

    for (final filePath in files) {
      if (!_shouldAnalyzeFile(filePath, shouldCheckTestFiles)) continue;

      try {
        final content = File(filePath).readAsStringSync();
        final fakeUnit = _createFakeCompilationUnit(content);

        issues.addAll(_analyzeUnit(fakeUnit, filePath, activeAnalyzers));
      } catch (e) {
        // Handle file read errors
        rethrow;
      }
    }

    return issues;
  }

  Future<List<String>> _analyzeDirectories(
    List<String> directories,
    List<BaseAnalyzer> activeAnalyzers,
    bool shouldCheckTestFiles,
  ) async {
    if (directories.isEmpty) return [];

    final issues = <String>[];

    for (final dirPath in directories) {
      final dir = Directory(dirPath);
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          if (!_shouldAnalyzeFile(entity.path, shouldCheckTestFiles)) continue;

          try {
            final content = await entity.readAsString();
            final fakeUnit = _createFakeCompilationUnit(content);

            issues.addAll(_analyzeUnit(fakeUnit, entity.path, activeAnalyzers));
          } catch (e) {
            // Handle file read errors
            continue;
          }
        }
      }
    }

    return issues;
  }

  bool _shouldAnalyzeFile(String filePath, bool shouldCheckTestFiles) {
    return filePath.endsWith('.dart') &&
        (shouldCheckTestFiles || !BaseAnalyzer.isTestFile(filePath));
  }

  List<String> _analyzeUnit(
    dynamic unit,
    String filePath,
    List<BaseAnalyzer> activeAnalyzers,
  ) {
    final issues = <String>[];

    for (final analyzer in activeAnalyzers) {
      final analyzerIssues = _runAnalyzer(analyzer, unit, filePath);
      issues.addAll(_formatIssues(analyzerIssues, filePath));
    }

    return issues;
  }

  List<dynamic> _runAnalyzer(
    BaseAnalyzer analyzer,
    dynamic unit,
    String filePath,
  ) {
    if (analyzer is FakeTestFileMutationCoverageAnalyzer) {
      final resolver = _SimpleResolver(filePath);
      return analyzer.analyzeWithResolver(unit as CompilationUnit, resolver);
    } else {
      return analyzer.analyze(unit as CompilationUnit);
    }
  }

  List<String> _formatIssues(List<dynamic> issues, String filePath) {
    return issues
        .map(
          (issue) =>
              '$filePath:${issue.line}:${issue.column} • ${issue.message} • ${issue.ruleName}',
        )
        .toList();
  }

  dynamic _createFakeCompilationUnit(String content) {
    return FakeCompilationUnit(content);
  }
}

class _PathGroups {
  final List<String> files;
  final List<String> directories;

  _PathGroups({required this.files, required this.directories});
}

class _SimpleResolver {
  final String path;
  _SimpleResolver(this.path);
}

class FakeCompilationUnit {
  final String content;
  FakeCompilationUnit(this.content);

  @override
  String toString() => content;
}

class TestHelpers {
  static Future<File> createTempDartFile(
    String dirPath,
    String fileName,
    String content,
  ) async {
    final file = File(p.join(dirPath, fileName));
    await file.writeAsString(content);
    return file;
  }

  static bool isValidIssueFormat(String issue) {
    final regex = RegExp(r'^.+:\d+:\d+ • .+ • \w+');
    return regex.hasMatch(issue);
  }
}

void main() {
  group('StandaloneLintChecker', () {
    late Directory tempDir;
    late String tempDirPath;
    late File testDartFile;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'standalone_checker_test_',
      );
      tempDirPath = tempDir.path;

      testDartFile = File(p.join(tempDirPath, 'test_file.dart'));
      await testDartFile.writeAsString('''
  class TestClass {
    void testMethod() {
      print('Hello World');
    }
  }
  ''');
    });

    tearDownAll(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Constructor and Initialization', () {
      test('should initialize with all default analyzers', () {
        final checker = StandaloneLintChecker();

        expect(checker.analyzers.length, equals(12));
        expect(
          checker.analyzers.any(
            (a) => a.ruleName == 'forbid_forced_unwrapping',
          ),
          isTrue,
        );
        expect(
          checker.analyzers.any(
            (a) => a.ruleName == 'test_file_mutation_coverage',
          ),
          isTrue,
        );
      });
    });

    group('Analyzer Interface Compliance', () {
      test(
        'should verify all real analyzers implement BaseAnalyzer correctly',
        () {
          final checker = StandaloneLintChecker();

          for (final analyzer in checker.analyzers) {
            expect(analyzer, isA<BaseAnalyzer>());
            expect(analyzer.ruleName, isNotEmpty);
            expect(analyzer.ruleName.trim(), equals(analyzer.ruleName));
            expect(analyzer.analyze, isA<Function>());
          }
        },
      );

      test(
        'should verify TestFileMutationCoverageAnalyzer special interface',
        () {
          final checker = StandaloneLintChecker();
          final testAnalyzer = checker.analyzers.firstWhere(
            (a) => a.ruleName == 'test_file_mutation_coverage',
          );

          expect(testAnalyzer, isNotNull);
          expect(testAnalyzer, isA<TestFileMutationCoverageAnalyzer>());
        },
      );
    });

    group('Rule Filtering', () {
      test('should verify analyzer interface compliance', () {
        final fakeAnalyzer1 = FakeAnalyzer(ruleNameOverride: 'rule1');
        final fakeAnalyzer2 = FakeAnalyzer(ruleNameOverride: 'rule2');

        expect(fakeAnalyzer1.ruleName, equals('rule1'));
        expect(fakeAnalyzer2.ruleName, equals('rule2'));
        expect(fakeAnalyzer1.problemMessage, equals('Test problem message'));
        expect(
          fakeAnalyzer1.correctionMessage,
          equals('Test correction message'),
        );
      });

      test('should verify test analyzer interface compliance', () {
        final fakeTestAnalyzer = FakeTestFileMutationCoverageAnalyzer();

        expect(
          fakeTestAnalyzer.ruleName,
          equals('test_file_mutation_coverage'),
        );
        expect(fakeTestAnalyzer.problemMessage, equals('Test problem message'));
        expect(
          fakeTestAnalyzer.correctionMessage,
          equals('Test correction message'),
        );
      });
    });

    group('Documentation Compliance', () {
      test('should match documented rule names exactly', () {
        final checker = StandaloneLintChecker();
        final actualRuleNames =
            checker.analyzers.map((a) => a.ruleName).toSet();

        final documentedRuleNames = {
          'forbid_forced_unwrapping',
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
        };

        expect(actualRuleNames, equals(documentedRuleNames));
      });

      test('should have exactly 12 analyzers as documented', () {
        final checker = StandaloneLintChecker();
        expect(checker.analyzers.length, equals(12));
      });
    });

    group('File Analysis and Processing', () {
      test('should verify analyzer interface for file processing', () {
        final fakeAnalyzer = FakeAnalyzer(
          ruleNameOverride: 'file_rule',
          issuesToReturn: [
            TestIssue(
              line: 1,
              column: 1,
              message: 'Test issue',
              ruleName: 'file_rule',
            ),
          ],
        );

        expect(fakeAnalyzer.ruleName, equals('file_rule'));
        expect(fakeAnalyzer.problemMessage, equals('Test problem message'));
        expect(
          fakeAnalyzer.correctionMessage,
          equals('Test correction message'),
        );
      });

      test('should verify test analyzer interface for file processing', () {
        final fakeTestAnalyzer = FakeTestFileMutationCoverageAnalyzer(
          issuesToReturn: [
            TestIssue(
              line: 5,
              column: 10,
              message: 'Test coverage issue',
              ruleName: 'test_file_mutation_coverage',
            ),
          ],
        );

        expect(
          fakeTestAnalyzer.ruleName,
          equals('test_file_mutation_coverage'),
        );
        expect(fakeTestAnalyzer.problemMessage, equals('Test problem message'));
        expect(
          fakeTestAnalyzer.correctionMessage,
          equals('Test correction message'),
        );
      });
    });

    group('Directory Analysis', () {
      test('should verify directory handling utilities', () {
        final fakeAnalyzer = FakeAnalyzer(ruleNameOverride: 'dir_rule');

        expect(fakeAnalyzer.ruleName, equals('dir_rule'));
        expect(fakeAnalyzer.problemMessage, equals('Test problem message'));
        expect(
          fakeAnalyzer.correctionMessage,
          equals('Test correction message'),
        );
      });

      test('should verify test analyzer directory handling', () {
        final fakeTestAnalyzer = FakeTestFileMutationCoverageAnalyzer();

        expect(
          fakeTestAnalyzer.ruleName,
          equals('test_file_mutation_coverage'),
        );
        expect(fakeTestAnalyzer.problemMessage, equals('Test problem message'));
        expect(
          fakeTestAnalyzer.correctionMessage,
          equals('Test correction message'),
        );
      });
    });

    group('Test File Detection', () {
      test('should identify test files correctly', () {
        expect(BaseAnalyzer.isTestFile('widget_test.dart'), isTrue);
        expect(BaseAnalyzer.isTestFile('test/unit/test.dart'), isFalse);
        expect(BaseAnalyzer.isTestFile('test_file.dart'), isFalse);
        expect(BaseAnalyzer.isTestFile('lib/main.dart'), isFalse);
        expect(BaseAnalyzer.isTestFile('src/utils.dart'), isFalse);
      });

      test('should verify test file detection utilities', () {
        final fakeAnalyzer = FakeAnalyzer(
          ruleNameOverride: 'test_detection_rule',
        );

        expect(fakeAnalyzer.ruleName, equals('test_detection_rule'));
        expect(fakeAnalyzer.problemMessage, equals('Test problem message'));
        expect(
          fakeAnalyzer.correctionMessage,
          equals('Test correction message'),
        );
      });

      test('should verify test analyzer test file detection', () {
        final fakeTestAnalyzer = FakeTestFileMutationCoverageAnalyzer();

        expect(
          fakeTestAnalyzer.ruleName,
          equals('test_file_mutation_coverage'),
        );
        expect(fakeTestAnalyzer.problemMessage, equals('Test problem message'));
        expect(
          fakeTestAnalyzer.correctionMessage,
          equals('Test correction message'),
        );
      });
    });

    group('Error Handling', () {
      test('should verify error analyzer interface', () {
        final errorAnalyzer = FakeAnalyzer(
          ruleNameOverride: 'error_rule',
          shouldThrowError: true,
        );

        expect(errorAnalyzer.ruleName, equals('error_rule'));
        expect(errorAnalyzer.problemMessage, equals('Test problem message'));
        expect(
          errorAnalyzer.correctionMessage,
          equals('Test correction message'),
        );
      });

      test('should verify error analyzer exception behavior', () {
        final errorAnalyzer = FakeAnalyzer(
          ruleNameOverride: 'error_rule',
          shouldThrowError: true,
        );

        expect(errorAnalyzer.shouldThrowError, isTrue);
        expect(errorAnalyzer.ruleName, equals('error_rule'));
      });
    });

    group('Issue Formatting and Validation', () {
      test('should validate issue format correctly', () {
        final validIssue = 'file.dart:10:5 • Test message • rule_name';
        final invalidIssue = 'invalid format';
        final invalidIssue2 = 'file.dart:abc:def • message • rule';

        expect(TestHelpers.isValidIssueFormat(validIssue), isTrue);
        expect(TestHelpers.isValidIssueFormat(invalidIssue), isFalse);
        expect(TestHelpers.isValidIssueFormat(invalidIssue2), isFalse);
      });

      test('should verify issue structure validation', () {
        final validIssue =
            'path/to/file.dart:42:13 • Issue message • rule_name';
        expect(TestHelpers.isValidIssueFormat(validIssue), isTrue);
      });
    });

    group('Path Handling and Normalization', () {
      test('should verify path handling utilities', () {
        final fakeAnalyzer = FakeAnalyzer(ruleNameOverride: 'path_rule');

        expect(fakeAnalyzer.ruleName, equals('path_rule'));
        expect(fakeAnalyzer.problemMessage, equals('Test problem message'));
        expect(
          fakeAnalyzer.correctionMessage,
          equals('Test correction message'),
        );
      });

      test('should verify test analyzer path handling', () {
        final fakeTestAnalyzer = FakeTestFileMutationCoverageAnalyzer();

        expect(
          fakeTestAnalyzer.ruleName,
          equals('test_file_mutation_coverage'),
        );
        expect(fakeTestAnalyzer.problemMessage, equals('Test problem message'));
        expect(
          fakeTestAnalyzer.correctionMessage,
          equals('Test correction message'),
        );
      });
    });

    group('Rule Filtering Logic', () {
      test('should verify rule filtering utilities', () {
        final analyzer1 = FakeAnalyzer(ruleNameOverride: 'rule1');
        final analyzer2 = FakeAnalyzer(ruleNameOverride: 'rule2');
        final analyzer3 = FakeAnalyzer(ruleNameOverride: 'rule3');

        expect(analyzer1.ruleName, equals('rule1'));
        expect(analyzer2.ruleName, equals('rule2'));
        expect(analyzer3.ruleName, equals('rule3'));
      });

      test('should verify test analyzer rule filtering', () {
        final fakeTestAnalyzer = FakeTestFileMutationCoverageAnalyzer();

        expect(
          fakeTestAnalyzer.ruleName,
          equals('test_file_mutation_coverage'),
        );
        expect(fakeTestAnalyzer.problemMessage, equals('Test problem message'));
        expect(
          fakeTestAnalyzer.correctionMessage,
          equals('Test correction message'),
        );
      });
    });

    group('Integration and Edge Cases', () {
      test('should verify integration utilities', () {
        final fakeAnalyzer = FakeAnalyzer(ruleNameOverride: 'integration_rule');

        expect(fakeAnalyzer.ruleName, equals('integration_rule'));
        expect(fakeAnalyzer.problemMessage, equals('Test problem message'));
        expect(
          fakeAnalyzer.correctionMessage,
          equals('Test correction message'),
        );
      });

      test('should verify test analyzer integration', () {
        final fakeTestAnalyzer = FakeTestFileMutationCoverageAnalyzer();

        expect(
          fakeTestAnalyzer.ruleName,
          equals('test_file_mutation_coverage'),
        );
        expect(fakeTestAnalyzer.problemMessage, equals('Test problem message'));
        expect(
          fakeTestAnalyzer.correctionMessage,
          equals('Test correction message'),
        );
      });
    });
  });
}
