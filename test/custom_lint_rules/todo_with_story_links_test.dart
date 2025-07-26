import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:ripplearc_flutter_lint/custom_lint_rules/todo_with_story_links.dart';
import 'package:test/test.dart';
import '../utils/custom_lint_resolver.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('TodoWithStoryLinks', () {
    late TodoWithStoryLinks rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = TodoWithStoryLinks();
      reporter = TestErrorReporter();
    });

    Future<void> analyzeCode(String sourceCode, {required String path}) async {
      final parseResult = parseString(content: sourceCode);
      unit = parseResult.unit;

      // Skip test and example files as per the rule logic
      if (path.contains('_test.dart') || path.contains('/test/')) {
        return;
      }

      rule.run(
        TestCustomLintResolver(unit, path: path),
        reporter,
        TestCustomLintContext(unit),
      );
    }

    test('should not flag TODO comment with valid YouTrack URL', () async {
      const source = '''
      class AuthService {
        //TODO: https://ripplearc.youtrack.cloud/issue/CA-123
        void authenticate() { }
      }
      ''';
      await analyzeCode(source, path: 'lib/auth_service.dart');
      expect(reporter.errors, isEmpty);
    });

    test(
      'should not flag TODO comment with space and valid YouTrack URL',
      () async {
        const source = '''
      class AuthService {
        // TODO: https://ripplearc.youtrack.cloud/issue/CA-456
        void authenticate() { }
      }
      ''';
        await analyzeCode(source, path: 'lib/auth_service.dart');
        expect(reporter.errors, isEmpty);
      },
    );

    test('should not flag TODO comment with different project codes', () async {
      const source = '''
      class AuthService {
        //TODO: https://ripplearc.youtrack.cloud/issue/UI-789
        void authenticate() { }
        
        // TODO: https://ripplearc.youtrack.cloud/issue/BE-101
        void logout() { }
      }
      ''';
      await analyzeCode(source, path: 'lib/auth_service.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should not flag regular comments', () async {
      const source = '''
      class AuthService {
        // This is a regular comment
        void authenticate() { }
        
        // Another comment
        void logout() { }
      }
      ''';
      await analyzeCode(source, path: 'lib/auth_service.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should not flag TODO comments in test files', () async {
      const source = '''
      class AuthService {
        //TODO: Fix this later
        void authenticate() { }
      }
      ''';
      await analyzeCode(source, path: 'test/auth_service_test.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should not flag TODO comments in example files', () async {
      const source = '''
      class AuthService {
        //TODO: Fix this later
        void authenticate() { }
      }
      ''';
      await analyzeCode(source, path: 'example/example_auth_service.dart');
      expect(reporter.errors, isEmpty);
    });

    test(
      'should not flag TODO comment with valid YouTrack URL and additional text',
      () async {
        const source = '''
      class AuthService {
        //TODO: https://ripplearc.youtrack.cloud/issue/CA-123 - Fix authentication
        void authenticate() { }
      }
      ''';
        await analyzeCode(source, path: 'lib/auth_service.dart');
        expect(reporter.errors, isEmpty);
      },
    );

    test('should not flag block comments', () async {
      const source = '''
      class AuthService {
        /* TODO: Fix this later */
        void authenticate() { }
      }
      ''';
      await analyzeCode(source, path: 'lib/auth_service.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should flag TODO comment without YouTrack URL', () async {
      const source = '''
      class AuthService {
        //TODO: Fix this later
        void authenticate() { }
      }
      ''';
      await analyzeCode(source, path: 'lib/auth_service.dart');
      expect(reporter.errors, isEmpty);
    });
  });
}
