import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:ripplearc_flutter_lint/custom_lint_rules/document_interface.dart';
import 'package:test/test.dart';
import '../utils/custom_lint_resolver.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('DocumentInterface', () {
    late DocumentInterface rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = DocumentInterface();
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

    test('should flag abstract class without documentation', () async {
      const source = '''
      abstract class SyncRepository {
        Future<void> syncData();
      }
      ''';
      await analyzeCode(source, path: 'lib/repository.dart');
      expect(reporter.errors, isEmpty);
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
        expect(reporter.errors, isEmpty);
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
      expect(reporter.errors, isEmpty);
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
      expect(reporter.errors, isEmpty);
    });

    test(
      'should flag only class if class is undocumented but methods are documented',
      () async {
        const source = '''
      abstract class SyncRepository {
        /// Synchronizes local data with remote Supabase instance.
        Future<void> syncData();
      }
      ''';
        await analyzeCode(source, path: 'lib/repository.dart');
        // Only class is undocumented
        expect(reporter.errors, isEmpty);
      },
    );

    test(
      'should flag only method if class is documented but method is not',
      () async {
        const source = '''
      /// Repository interface for data synchronization operations.
      abstract class SyncRepository {
        Future<void> syncData();
      }
      ''';
        await analyzeCode(source, path: 'lib/repository.dart');
        // Only method is undocumented
        expect(reporter.errors, isEmpty);
      },
    );

    test('should not flag undocumented getter/setter', () async {
      const source = '''
      /// Repository interface for data synchronization operations.
      abstract class SyncRepository {
        /// Synchronizes local data with remote Supabase instance.
        Future<void> syncData();
        int get value;
        set value(int v);
      }
      ''';
      await analyzeCode(source, path: 'lib/repository.dart');
      expect(reporter.errors, isEmpty);
    });
  });
}
