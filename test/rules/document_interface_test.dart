import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:ripplearc_flutter_lint/rules/document_interface.dart';
import 'package:test/test.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('DocumentInterface', () {
    late DocumentInterface rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = const DocumentInterface();
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

    test('should flag abstract class without documentation', () async {
      const source = '''
      abstract class SyncRepository {
        Future<void> syncData();
      }
      ''';
      await analyzeCode(source, path: 'lib/repository.dart');
      expect(reporter.errors, hasLength(1));
      expect(
        reporter.errors.first.errorCode.name,
        equals('document_interface'),
      );
    });

    test(
      'should flag abstract class with undocumented public methods',
      () async {
        const source = '''
      /// Repository interface for data synchronization operations.
      abstract class SyncRepository {
        Future<void> syncData();  // Missing documentation
        Future<void> clearData(); // Missing documentation
      }
      ''';
        await analyzeCode(source, path: 'lib/repository.dart');
        expect(reporter.errors, hasLength(1));
        expect(
          reporter.errors.first.errorCode.name,
          equals('document_interface'),
        );
      },
    );

    test('should not flag abstract class with proper documentation', () async {
      const source = '''
      /// Repository interface for data synchronization operations.
      abstract class SyncRepository {
        /// Synchronizes local data with remote Supabase instance.
        Future<void> syncData();
        
        /// Clears all local data.
        Future<void> clearData();
      }
      ''';
      await analyzeCode(source, path: 'lib/repository.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should not flag private methods', () async {
      const source = '''
      /// Repository interface for data synchronization operations.
      abstract class SyncRepository {
        /// Synchronizes local data with remote Supabase instance.
        Future<void> syncData();
        
        Future<void> _privateMethod();  // Should not flag private methods
      }
      ''';
      await analyzeCode(source, path: 'lib/repository.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should not flag concrete classes', () async {
      const source = '''
      class SyncRepository {
        Future<void> syncData() async {
          // Implementation
        }
      }
      ''';
      await analyzeCode(source, path: 'lib/repository.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should not flag abstract classes in test files', () async {
      const source = '''
      abstract class TestRepository {
        Future<void> syncData();
      }
      ''';
      await analyzeCode(source, path: 'test/repository_test.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should flag abstract classes in example files', () async {
      const source = '''
      abstract class ExampleRepository {
        Future<void> syncData();
      }
      ''';
      await analyzeCode(source, path: 'example/example_repository.dart');
      expect(reporter.errors, hasLength(1));
      expect(
        reporter.errors.first.errorCode.name,
        equals('document_interface'),
      );
    });

    test('should not flag empty documentation comments', () async {
      const source = '''
      /// 
      abstract class SyncRepository {
        /// 
        Future<void> syncData();
      }
      ''';
      await analyzeCode(source, path: 'lib/repository.dart');
      expect(reporter.errors, hasLength(1));
      expect(
        reporter.errors.first.errorCode.name,
        equals('document_interface'),
      );
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
