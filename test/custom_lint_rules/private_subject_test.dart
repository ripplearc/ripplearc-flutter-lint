import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:ripplearc_flutter_lint/custom_lint_rules/private_subject.dart';
import 'package:test/test.dart';
import '../utils/custom_lint_resolver.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('PrivateSubject', () {
    late PrivateSubject rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = PrivateSubject();
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

    test('should flag public BehaviorSubject variables', () async {
      const source = '''
      import 'package:rxdart/rxdart.dart';
      
      class TestClass {
        final authController = BehaviorSubject<String>();
        final _privateController = BehaviorSubject<String>();
      }
      ''';
      await analyzeCode(source, path: 'lib/example.dart');
      expect(reporter.errors, isNotEmpty);
    });

    test('should flag public ReplaySubject variables', () async {
      const source = '''
      import 'package:rxdart/rxdart.dart';
      
      class TestClass {
        final userController = ReplaySubject<int>();
        final _privateController = ReplaySubject<int>();
      }
      ''';
      await analyzeCode(source, path: 'lib/example.dart');
      expect(reporter.errors, isNotEmpty);
    });

    test('should flag public PublishSubject variables', () async {
      const source = '''
      import 'package:rxdart/rxdart.dart';
      
      class TestClass {
        final eventController = PublishSubject<void>();
        final _privateController = PublishSubject<void>();
      }
      ''';
      await analyzeCode(source, path: 'lib/example.dart');
      expect(reporter.errors, isNotEmpty);
    });

    test('should flag public Subject variables', () async {
      const source = '''
      import 'package:rxdart/rxdart.dart';
      
      class TestClass {
        final genericController = Subject<String>();
        final _privateController = Subject<String>();
      }
      ''';
      await analyzeCode(source, path: 'lib/example.dart');
      expect(reporter.errors, isNotEmpty);
    });

    test('should not flag private Subject variables', () async {
      const source = '''
      import 'package:rxdart/rxdart.dart';
      
      class TestClass {
        final _authController = BehaviorSubject<String>();
        final _userController = ReplaySubject<int>();
        final _eventController = PublishSubject<void>();
      }
      ''';
      await analyzeCode(source, path: 'lib/example.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should not flag non-Subject variables', () async {
      const source = '''
      class TestClass {
        final publicVariable = 'test';
        final _privateVariable = 'test';
        final controller = StreamController<String>();
      }
      ''';
      await analyzeCode(source, path: 'lib/example.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should flag multiple public Subject variables', () async {
      const source = '''
      import 'package:rxdart/rxdart.dart';
      
      class TestClass {
        final authController = BehaviorSubject<String>();
        final userController = ReplaySubject<int>();
        final eventController = PublishSubject<void>();
        final _privateController = BehaviorSubject<String>();
      }
      ''';
      await analyzeCode(source, path: 'lib/example.dart');
      expect(reporter.errors, isNotEmpty);
    });

    test('debug: should detect any variable declaration', () async {
      const source = '''
      class TestClass {
        final testVar = 'test';
      }
      ''';
      await analyzeCode(source, path: 'lib/example.dart');
      // This test just ensures the rule runs without crashing
      expect(reporter.errors, isEmpty);
    });
  });
}
