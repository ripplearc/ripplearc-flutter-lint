import 'dart:io';
import 'dart:io' as io;
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:ripplearc_flutter_lint/custom_lint_rules/test_file_mutation_coverage.dart';
import 'package:test/test.dart';
import '../utils/custom_lint_resolver.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('TestFileMutationCoverage', () {
    late TestFileMutationCoverage rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;
    late Directory tempDir;

    setUp(() {
      rule = TestFileMutationCoverage();
      reporter = TestErrorReporter();

      // Create temporary directory structure for testing
      tempDir = Directory.systemTemp.createTempSync('test_mutation_coverage_');
      final testUnitsDir = Directory('${tempDir.path}/test/units');
      final testMutationsDir = Directory('${tempDir.path}/test/mutations');
      testUnitsDir.createSync(recursive: true);
      testMutationsDir.createSync(recursive: true);
    });

    tearDown(() {
      // Clean up temporary directory
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    Future<void> analyzeCode(String sourceCode, {required String path}) async {
      final parseResult = parseString(content: sourceCode);
      unit = parseResult.unit;
      rule.run(
        TestCustomLintResolver(unit, path: path),
        reporter,
        TestCustomLintContext(unit),
      );
    }

    void createTestFile(String relativePath, String content) {
      final file = File('${tempDir.path}/$relativePath');
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    void createMutationFile(String relativePath, String content) {
      final file = File('${tempDir.path}/$relativePath');
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    test('should flag test file without corresponding mutation file', () async {
      const source = '''
import 'package:test/test.dart';

void main() {
  test('example test', () {
    expect(1 + 1, equals(2));
  });
}
''';

      // Create test file without mutation file
      createTestFile('test/units/user_test.dart', source);

      await analyzeCode(
        source,
        path: '${tempDir.path}/test/units/user_test.dart',
      );
      expect(reporter.errors, isNotEmpty);
      expect(
        reporter.errors.first.errorCode.name,
        equals('test_file_mutation_coverage'),
      );
      expect(
        reporter.errors.first.errorCode.name,
        equals('test_file_mutation_coverage'),
      );
    });

    test(
      'should not flag test file with corresponding mutation file',
      () async {
        const source = '''
import 'package:test/test.dart';

void main() {
  test('example test', () {
    expect(1 + 1, equals(2));
  });
}
''';

        // Create test file with mutation file
        createTestFile('test/units/user_test.dart', source);
        createMutationFile(
          'test/mutations/user_test.xml',
          '<mutation></mutation>',
        );

        await analyzeCode(
          source,
          path: '${tempDir.path}/test/units/user_test.dart',
        );
        expect(reporter.errors, isEmpty);
      },
    );

    test('should handle nested directories correctly', () async {
      const source = '''
import 'package:test/test.dart';

void main() {
  test('auth test', () {
    expect(true, isTrue);
  });
}
''';

      // Create test file in nested directory without mutation file
      createTestFile('test/units/auth/login_test.dart', source);

      await analyzeCode(
        source,
        path: '${tempDir.path}/test/units/auth/login_test.dart',
      );
      expect(reporter.errors, isNotEmpty);
      expect(
        reporter.errors.first.errorCode.name,
        equals('test_file_mutation_coverage'),
      );
    });

    test(
      'should not flag test file with corresponding mutation file in nested directory',
      () async {
        const source = '''
import 'package:test/test.dart';

void main() {
  test('auth test', () {
    expect(true, isTrue);
  });
}
''';

        // Create test file with mutation file in nested directory
        createTestFile('test/units/auth/login_test.dart', source);
        createMutationFile(
          'test/mutations/auth/login_test.xml',
          '<mutation></mutation>',
        );

        await analyzeCode(
          source,
          path: '${tempDir.path}/test/units/auth/login_test.dart',
        );
        expect(reporter.errors, isEmpty);
      },
    );

    test('should not flag non-test files', () async {
      const source = '''
class User {
  String name;
  User(this.name);
}
''';

      await analyzeCode(source, path: '${tempDir.path}/lib/user.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should not flag test files outside units directory', () async {
      const source = '''
import 'package:test/test.dart';

void main() {
  test('integration test', () {
    expect(true, isTrue);
  });
}
''';

      await analyzeCode(
        source,
        path: '${tempDir.path}/test/integration_test.dart',
      );
      expect(reporter.errors, isEmpty);
    });

    test('should handle files with different extensions correctly', () async {
      const source = '''
import 'package:test/test.dart';

void main() {
  test('widget test', () {
    expect(true, isTrue);
  });
}
''';

      // Create test file without mutation file
      createTestFile('test/units/widget_test.dart', source);

      await analyzeCode(
        source,
        path: '${tempDir.path}/test/units/widget_test.dart',
      );
      expect(reporter.errors, isNotEmpty);
      expect(
        reporter.errors.first.errorCode.name,
        equals('test_file_mutation_coverage'),
      );
    });
  });
}
