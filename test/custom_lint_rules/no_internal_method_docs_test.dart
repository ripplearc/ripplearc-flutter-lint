import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:ripplearc_flutter_lint/rules/no_internal_method_docs.dart';
import 'package:test/test.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('NoInternalMethodDocs', () {
    late NoInternalMethodDocs rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = const NoInternalMethodDocs();
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

    test('should flag private method with /// documentation', () async {
      const source = '''
      class AuthService {
        /// Handles internal auth state
        void _handleAuthState() { }
        
        void authenticate() { }
      }
      ''';
      await analyzeCode(source, path: 'lib/auth_service.dart');
      expect(reporter.errors, hasLength(1));
      expect(
        reporter.errors.first.errorCode.name,
        equals('no_internal_method_docs'),
      );
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
      expect(reporter.errors, hasLength(2));
      expect(
        reporter.errors.first.errorCode.name,
        equals('no_internal_method_docs'),
      );
      expect(
        reporter.errors.last.errorCode.name,
        equals('no_internal_method_docs'),
      );
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
      expect(reporter.errors, hasLength(1));
      expect(
        reporter.errors.first.errorCode.name,
        equals('no_internal_method_docs'),
      );
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
