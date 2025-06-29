import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:ripplearc_flutter_lint/rules/no_direct_instantiation.dart';
import 'package:test/test.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('NoDirectInstantiation', () {
    late NoDirectInstantiation rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = const NoDirectInstantiation();
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

    test('should not flag Modular.get calls', () async {
      const source = '''
      class AuthService {
        void authenticate() { }
      }
      
      void main() {
        final service = Modular.get<AuthService>();  // Should not flag this
      }
      ''';
      await analyzeCode(source, path: 'lib/auth_service.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should not flag Module class instantiation', () async {
      const source = '''
      class AppModule extends Module {
        @override
        List<Bind> get binds => [];
      }
      
      void main() {
        final module = AppModule();  // Should not flag this
      }
      ''';
      await analyzeCode(source, path: 'lib/app_module.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should not flag factory class instantiation', () async {
      const source = '''
      class AuthService {
        factory AuthService() {
          return AuthService._internal();
        }
        
        AuthService._internal();
      }
      
      void main() {
        final service = AuthService();  // Should not flag this
      }
      ''';
      await analyzeCode(source, path: 'lib/auth_service.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should not flag direct instantiations in test files', () async {
      const source = '''
      class AuthService {
        void authenticate() { }
      }
      
      void main() {
        final service = AuthService();  // Should not flag this in test files
      }
      ''';
      await analyzeCode(source, path: 'test/auth_service_test.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should not flag direct instantiations in example files', () async {
      const source = '''
      class AuthService {
        void authenticate() { }
      }
      
      void main() {
        final service = AuthService();  // Should not flag this in example files
      }
      ''';
      await analyzeCode(source, path: 'example/example_auth_service.dart');
    });

    test('should not flag Modular.get with constructor parameters', () async {
      const source = '''
      class AuthService {
        AuthService(String apiKey);
        void authenticate() { }
      }
      
      void main() {
        final service = Modular.get<AuthService>();  // Should not flag this
      }
      ''';
      await analyzeCode(source, path: 'lib/auth_service.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should not flag static factory methods', () async {
      const source = '''
      class AuthService {
        static AuthService create() {
          return AuthService._internal();
        }
        
        AuthService._internal();
      }
      
      void main() {
        final service = AuthService.create();  // Should not flag this
      }
      ''';
      await analyzeCode(source, path: 'lib/auth_service.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should not flag factory class with parameters', () async {
      const source = '''
      class UserService {
        factory UserService(String apiKey) {
          return UserService._internal(apiKey);
        }
        
        UserService._internal(this.apiKey);
        
        final String apiKey;
      }
      
      void main() {
        final service = UserService('api-key');  // Should not flag this
      }
      ''';
      await analyzeCode(source, path: 'lib/user_service.dart');
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
