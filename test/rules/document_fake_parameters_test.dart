import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:ripplearc_flutter_lint/rules/document_fake_parameters.dart';
import 'package:test/test.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('DocumentFakeParameters', () {
    late DocumentFakeParameters rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = const DocumentFakeParameters();
      reporter = TestErrorReporter();
    });

    Future<void> analyzeCode(String sourceCode, {required String path}) async {
      final parseResult = parseString(content: sourceCode);
      unit = parseResult.unit;
      rule.run(
        TestCustomLintResolver(unit, path),
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
      expect(reporter.errors, hasLength(1));
      expect(
        reporter.errors.first.errorCode.name,
        equals('document_fake_parameters'),
      );
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
      expect(reporter.errors, hasLength(1));
      expect(
        reporter.errors.first.errorCode.name,
        equals('document_fake_parameters'),
      );
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
      expect(reporter.errors, hasLength(1));
      expect(
        reporter.errors.first.errorCode.name,
        equals('document_fake_parameters'),
      );
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
  });
}

class TestCustomLintResolver implements CustomLintResolver {
  TestCustomLintResolver(this.unit, this.path);
  final CompilationUnit unit;
  @override
  final String path;

  @override
  Future<ResolvedUnitResult> getResolvedUnitResult() async {
    throw UnimplementedError();
  }

  @override
  LineInfo get lineInfo => throw UnimplementedError();

  @override
  Source get source => throw UnimplementedError();
}

class _MockLintRuleNodeRegistry implements LintRuleNodeRegistry {
  final CompilationUnit unit;

  _MockLintRuleNodeRegistry(this.unit);

  @override
  void addCompilationUnit(Function(CompilationUnit) callback) {
    callback(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class TestCustomLintContext implements CustomLintContext {
  TestCustomLintContext(this.unit);
  final CompilationUnit unit;

  void addCompilationUnit(Function(CompilationUnit) callback) {
    callback(unit);
  }

  @override
  void addPostRunCallback(Function() callback) {}

  @override
  Pubspec get pubspec => throw UnimplementedError();

  @override
  Map<String, dynamic> get sharedState => {};

  @override
  LintRuleNodeRegistry get registry => _MockLintRuleNodeRegistry(unit);
}
