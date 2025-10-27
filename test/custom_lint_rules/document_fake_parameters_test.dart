import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:ripplearc_lint_rules/custom_lint_rules/document_fake_parameters.dart';
import 'package:test/test.dart';
import '../utils/custom_lint_resolver.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('DocumentFakeParameters', () {
    late DocumentFakeParameters rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = DocumentFakeParameters();
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

    test('should flag Fake class without documentation', () async {
      const source = '''
      abstract class AuthService {
        Future<void> authenticate();
      }
      
      class FakeAuthService extends Fake implements AuthService {
        void setAuthDelay(Duration delay) { }
        void triggerAuthFailure() { }
        
        @override
        Future<void> authenticate() async { }
      }
      ''';
      await analyzeCode(source, path: 'lib/auth_service.dart');
      expect(reporter.errors, isNotEmpty);
    });

    test('should flag Fake class with undocumented methods', () async {
      const source = '''
      abstract class AuthService {
        Future<void> authenticate();
      }
      
      /// Fake implementation of AuthService for testing.
      class FakeAuthService extends Fake implements AuthService {
        void setAuthDelay(Duration delay) { }  // Missing documentation
        void triggerAuthFailure() { }          // Missing documentation
        
        @override
        Future<void> authenticate() async { }
      }
      ''';
      await analyzeCode(source, path: 'lib/auth_service.dart');
      expect(reporter.errors, isNotEmpty);
    });

    test('should not flag Fake class with proper documentation', () async {
      const source = '''
      abstract class AuthService {
        Future<void> authenticate();
      }
      
      /// Fake implementation of AuthService for testing.
      class FakeAuthService extends Fake implements AuthService {
        /// Sets authentication delay for testing timing scenarios.
        void setAuthDelay(Duration delay) { }
        
        /// Simulates authentication failure for error handling tests.
        void triggerAuthFailure() { }
        
        @override
        Future<void> authenticate() async { }
      }
      ''';
      await analyzeCode(source, path: 'lib/auth_service.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should not flag private methods', () async {
      const source = '''
      abstract class AuthService {
        Future<void> authenticate();
      }
      
      /// Fake implementation of AuthService for testing.
      class FakeAuthService extends Fake implements AuthService {
        /// Sets authentication delay for testing timing scenarios.
        void setAuthDelay(Duration delay) { }
        
        void _privateHelper() { }  // Should not flag private methods
        
        @override
        Future<void> authenticate() async { }
      }
      ''';
      await analyzeCode(source, path: 'lib/auth_service.dart');
      expect(reporter.errors, isEmpty);
    });

    test(
      'should not flag classes that extend Fake but do not implement interfaces',
      () async {
        const source = '''
      class FakeAuthService extends Fake {
        void setAuthDelay(Duration delay) { }
        void triggerAuthFailure() { }
      }
      ''';
        await analyzeCode(source, path: 'lib/auth_service.dart');
        expect(reporter.errors, isEmpty);
      },
    );

    test(
      'should not flag classes that implement interfaces but do not extend Fake',
      () async {
        const source = '''
      abstract class AuthService {
        Future<void> authenticate();
      }
      
      class MockAuthService implements AuthService {
        void setAuthDelay(Duration delay) { }
        void triggerAuthFailure() { }
        
        @override
        Future<void> authenticate() async { }
      }
      ''';
        await analyzeCode(source, path: 'lib/auth_service.dart');
        expect(reporter.errors, isEmpty);
      },
    );

    test('should not flag Fake classes in test files', () async {
      const source = '''
      abstract class AuthService {
        Future<void> authenticate();
      }
      
      class FakeAuthService extends Fake implements AuthService {
        void setAuthDelay(Duration delay) { }
        void triggerAuthFailure() { }
        
        @override
        Future<void> authenticate() async { }
      }
      ''';
      await analyzeCode(source, path: 'test/auth_service_test.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should not flag Fake classes in example files', () async {
      const source = '''
      abstract class AuthService {
        Future<void> authenticate();
      }
      
      class FakeAuthService extends Fake implements AuthService {
        void setAuthDelay(Duration delay) { }
        void triggerAuthFailure() { }
        
        @override
        Future<void> authenticate() async { }
      }
      ''';
      await analyzeCode(source, path: 'example/example_auth_service.dart');
      expect(reporter.errors, isNotEmpty);
    });

    test('should not flag getters and setters', () async {
      const source = '''
      abstract class AuthService {
        Future<void> authenticate();
      }
      
      /// Fake implementation of AuthService for testing.
      class FakeAuthService extends Fake implements AuthService {
        /// Sets authentication delay for testing timing scenarios.
        void setAuthDelay(Duration delay) { }
        
        bool get isAuthenticated => true;  // Should not flag getters
        set isAuthenticated(bool value) { }  // Should not flag setters
        
        @override
        Future<void> authenticate() async { }
      }
      ''';
      await analyzeCode(source, path: 'lib/auth_service.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should not flag methods with @override annotation', () async {
      const source = '''
      abstract class AuthService {
        Future<void> authenticate();
        Future<void> logout();
      }
      
      /// Fake implementation of AuthService for testing.
      class FakeAuthService extends Fake implements AuthService {
        /// Sets authentication delay for testing timing scenarios.
        void setAuthDelay(Duration delay) { }
        
        @override
        Future<void> authenticate() async { }  // Should not flag overrides
        
        @override
        Future<void> logout() async { }  // Should not flag overrides
      }
      ''';
      await analyzeCode(source, path: 'lib/auth_service.dart');
      expect(reporter.errors, isEmpty);
    });

    test(
      'should flag classes with Fake in name that implement interfaces but do not extend Fake',
      () async {
        const source = '''
      abstract class UserRepository {
        Future<List<User>> getUsers();
      }
      
      class FakeUserRepository implements UserRepository {
        void setMockData(List<User> users) { }
        void triggerNetworkError() { }
        
        @override
        Future<List<User>> getUsers() async { return []; }
      }
      ''';
        await analyzeCode(source, path: 'lib/user_repository.dart');
        expect(reporter.errors, isNotEmpty);
      },
    );

    test(
      'should not flag classes with Fake in name that do not implement interfaces',
      () async {
        const source = '''
      class FakeUserRepository {
        void setMockData(List<User> users) { }
        void triggerNetworkError() { }
      }
      ''';
        await analyzeCode(source, path: 'lib/user_repository.dart');
        expect(reporter.errors, isEmpty);
      },
    );

    test(
      'should flag Fake class and constructor without documentation',
      () async {
        const source = '''
      abstract class AuthService {
        Future<void> authenticate();
      }

      class FakeAuthService extends Fake implements AuthService {
        FakeAuthService();
        void setAuthDelay(Duration delay) { }
        void triggerAuthFailure() { }
        @override
        Future<void> authenticate() async { }
      }
      ''';
        await analyzeCode(source, path: 'lib/auth_service.dart');
        // Class, constructor, and both methods are undocumented, so expect 4 errors
        expect(reporter.errors, isNotEmpty);
      },
    );

    test(
      'should flag only constructor if class is documented but constructor is not',
      () async {
        const source = '''
      abstract class AuthService {
        Future<void> authenticate();
      }

      /// Fake implementation of AuthService for testing.
      class FakeAuthService extends Fake implements AuthService {
        FakeAuthService();
        /// Sets authentication delay for testing timing scenarios.
        void setAuthDelay(Duration delay) { }
        /// Simulates authentication failure for error handling tests.
        void triggerAuthFailure() { }
        @override
        Future<void> authenticate() async { }
      }
      ''';
        await analyzeCode(source, path: 'lib/auth_service.dart');
        // Only constructor is undocumented
        expect(reporter.errors, isNotEmpty);
      },
    );

    test('should not flag documented constructor', () async {
      const source = '''
      abstract class AuthService {
        Future<void> authenticate();
      }

      /// Fake implementation of AuthService for testing.
      class FakeAuthService extends Fake implements AuthService {
        /// Creates a new FakeAuthService.
        FakeAuthService();
        /// Sets authentication delay for testing timing scenarios.
        void setAuthDelay(Duration delay) { }
        /// Simulates authentication failure for error handling tests.
        void triggerAuthFailure() { }
        @override
        Future<void> authenticate() async { }
      }
      ''';
      await analyzeCode(source, path: 'lib/auth_service.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should flag undocumented private constructor', () async {
      const source = '''
      abstract class AuthService {
        Future<void> authenticate();
      }

      /// Fake implementation of AuthService for testing.
      class FakeAuthService extends Fake implements AuthService {
        FakeAuthService._();
        /// Sets authentication delay for testing timing scenarios.
        void setAuthDelay(Duration delay) { }
        /// Simulates authentication failure for error handling tests.
        void triggerAuthFailure() { }
        @override
        Future<void> authenticate() async { }
      }
      ''';
      await analyzeCode(source, path: 'lib/auth_service.dart');
      // Private constructor should not be flagged
      expect(reporter.errors, isEmpty);
    });

    test('should not flag undocumented getter/setter', () async {
      const source = '''
      abstract class AuthService {
        Future<void> authenticate();
      }

      /// Fake implementation of AuthService for testing.
      class FakeAuthService extends Fake implements AuthService {
        /// Sets authentication delay for testing timing scenarios.
        void setAuthDelay(Duration delay) { }
        bool get isAuthenticated => true;
        set isAuthenticated(bool value) { }
        @override
        Future<void> authenticate() async { }
      }
      ''';
      await analyzeCode(source, path: 'lib/auth_service.dart');
      expect(reporter.errors, isEmpty);
    });
  });
}
