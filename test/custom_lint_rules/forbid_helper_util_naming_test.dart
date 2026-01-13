import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:ripplearc_linter/custom_lint_rules/forbid_helper_util_naming.dart';
import 'package:test/test.dart';
import '../utils/custom_lint_resolver.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('ForbidHelperUtilNaming', () {
    late ForbidHelperUtilNaming rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = ForbidHelperUtilNaming();
      reporter = TestErrorReporter();
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

    group('production code (lib/)', () {
      test('should flag class with "Helper" suffix', () async {
        const source = '''
        class AssetHelper {}
        ''';
        await analyzeCode(source, path: 'lib/helpers/asset_helper.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag class with "Util" suffix', () async {
        const source = '''
        class StringUtil {}
        ''';
        await analyzeCode(source, path: 'lib/utils/string_util.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag class with "Helper" in the middle', () async {
        const source = '''
        class DateTimeHelperService {}
        ''';
        await analyzeCode(source, path: 'lib/services/datetime_helper.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag class with "Util" in the middle', () async {
        const source = '''
        class NetworkUtilsManager {}
        ''';
        await analyzeCode(source, path: 'lib/services/network_utils.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag multiple classes with forbidden names', () async {
        const source = '''
        class FileHelper {}
        class ValidationUtil {}
        class CacheHelper {}
        ''';
        await analyzeCode(source, path: 'lib/utils/utils.dart');
        expect(reporter.errors, hasLength(3));
      });

      test('should not flag class with descriptive name', () async {
        const source = '''
        class AssetLoader {}
        class StringParser {}
        class DateTimeFormatter {}
        ''';
        await analyzeCode(source, path: 'lib/services/services.dart');
        expect(reporter.errors, isEmpty);
      });

      test('should not flag class without forbidden substrings', () async {
        const source = '''
        class UserRepository {}
        class PaymentProcessor {}
        class ImageCompressor {}
        ''';
        await analyzeCode(source, path: 'lib/repositories/user.dart');
        expect(reporter.errors, isEmpty);
      });
    });

    group('test code (test/)', () {
      test('should flag class with "Helper" in test files', () async {
        const source = '''
        class TestHelper {}
        ''';
        await analyzeCode(source, path: 'test/helpers/test_helper.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag class with "Util" in test files', () async {
        const source = '''
        class MockUtil {}
        ''';
        await analyzeCode(source, path: 'test/utils/mock_util.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should not flag descriptive class names in test files', () async {
        const source = '''
        class FakeUserRepository {}
        class MockPaymentService {}
        ''';
        await analyzeCode(source, path: 'test/fakes/fake_user.dart');
        expect(reporter.errors, isEmpty);
      });
    });

    group('edge cases', () {
      test('should handle empty class', () async {
        const source = '''
        class Empty {}
        ''';
        await analyzeCode(source, path: 'lib/models/empty.dart');
        expect(reporter.errors, isEmpty);
      });

      test('should handle class with methods and fields', () async {
        const source = '''
        class DataHelper {
          final String data;
          DataHelper(this.data);
          void process() {}
        }
        ''';
        await analyzeCode(source, path: 'lib/helpers/data_helper.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should handle abstract class with forbidden name', () async {
        const source = '''
        abstract class BaseHelper {
          void help();
        }
        ''';
        await analyzeCode(source, path: 'lib/base/base_helper.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should handle class extending another with forbidden name', () async {
        const source = '''
        class ParentHelper {}
        class ChildHelper extends ParentHelper {}
        ''';
        await analyzeCode(source, path: 'lib/helpers/child_helper.dart');
        expect(reporter.errors, hasLength(2));
      });

      test('should be case-sensitive (no false positives)', () async {
        const source = '''
        class helper {}  // lowercase - should not flag
        class util {}    // lowercase - should not flag
        class HELPER {}  // uppercase - should not flag (not standard pattern)
        ''';
        await analyzeCode(source, path: 'lib/test/case_test.dart');
        expect(reporter.errors, isEmpty);
      });

      test('should flag "Utils" plural form', () async {
        const source = '''
        class FormattingUtils {}
        ''';
        await analyzeCode(source, path: 'lib/utils/formatting.dart');
        expect(reporter.errors, hasLength(1));
      });
    });
  });
}
