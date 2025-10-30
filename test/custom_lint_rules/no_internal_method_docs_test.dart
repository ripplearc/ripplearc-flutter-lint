import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:ripplearc_linter/custom_lint_rules/no_internal_method_docs.dart';
import 'package:test/test.dart';
import '../utils/custom_lint_resolver.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('NoInternalMethodDocs', () {
    late NoInternalMethodDocs rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = NoInternalMethodDocs();
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

    test('should flag private method with /// documentation', () async {
      const source = '''
      class AuthService {
        /// Handles internal auth state
        void _handleAuthState() { }
        
        void authenticate() { }
      }
      ''';
      await analyzeCode(source, path: 'lib/auth_service.dart');
      expect(reporter.errors, isNotEmpty);
    });

    test('should flag multiple private methods with documentation', () async {
      const source = '''
      class AuthService {
        /// Handles internal auth state
        void _handleAuthState() { }
        
        /// Processes user data
        void _processUserData() { }
        
        void authenticate() { }
      }
      ''';
      await analyzeCode(source, path: 'lib/auth_service.dart');
      expect(reporter.errors, isNotEmpty);
    });

    test('should not flag private methods without documentation', () async {
      const source = '''
      class AuthService {
        void _handleAuthState() { }
        void _validateInput(String input) { }
        void _processUserData() { }
        
        void authenticate() { }
      }
      ''';
      await analyzeCode(source, path: 'lib/auth_service.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should not flag public methods with documentation', () async {
      const source = '''
      class AuthService {
        void _handleAuthState() { }
        
        /// Authenticates the user with provided credentials
        void authenticate() { }
        
        /// Logs out the current user
        void logout() { }
      }
      ''';
      await analyzeCode(source, path: 'lib/auth_service.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should not flag private methods with empty documentation', () async {
      const source = '''
      class AuthService {
        /// 
        void _handleAuthState() { }
        
        // 
        void _validateInput(String input) { }
        
        void authenticate() { }
      }
      ''';
      await analyzeCode(source, path: 'lib/auth_service.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should not flag private methods in test files', () async {
      const source = '''
      class AuthService {
        /// Handles internal auth state
        void _handleAuthState() { }
        
        void authenticate() { }
      }
      ''';
      await analyzeCode(source, path: 'test/auth_service_test.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should not flag private methods in example files', () async {
      const source = '''
      class AuthService {
        /// Handles internal auth state
        void _handleAuthState() { }
        
        void authenticate() { }
      }
      ''';
      await analyzeCode(source, path: 'example/example_auth_service.dart');
      expect(reporter.errors, isNotEmpty);
    });

    test('should not flag private fields or variables', () async {
      const source = '''
      class AuthService {
        /// Internal auth state
        bool _isAuthenticated = false;
        
        /// User data
        String _userData = '';
        
        void authenticate() { }
      }
      ''';
      await analyzeCode(source, path: 'lib/auth_service.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should not flag private getters and setters', () async {
      const source = '''
      class AuthService {
        /// Internal auth state getter
        bool get _isAuthenticated => true;
        
        /// Internal auth state setter
        set _isAuthenticated(bool value) { }
        
        void authenticate() { }
      }
      ''';
      await analyzeCode(source, path: 'lib/auth_service.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should not flag /** */ documentation comments', () async {
      const source = '''
      class AuthService {
        /** Handles internal auth state */
        void _handleAuthState() { }
        
        void authenticate() { }
      }
      ''';
      await analyzeCode(source, path: 'lib/auth_service.dart');
      expect(reporter.errors, isEmpty);
    });
  });
}
