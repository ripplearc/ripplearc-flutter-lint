import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:ripplearc_flutter_lint/rules/private_subject.dart';
import 'package:test/test.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('PrivateSubject', () {
    late PrivateSubject rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = const PrivateSubject();
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

    test('should flag public BehaviorSubject variables', () async {
      const source = '''
      import 'package:rxdart/rxdart.dart';
      
      class TestClass {
        final authController = BehaviorSubject<String>();
        final _privateController = BehaviorSubject<String>();
      }
      ''';
      await analyzeCode(source, path: 'lib/example.dart');
      expect(reporter.errors, hasLength(1));
      expect(reporter.errors.first.errorCode.name, equals('private_subject'));
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
      expect(reporter.errors, hasLength(1));
      expect(reporter.errors.first.errorCode.name, equals('private_subject'));
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
      expect(reporter.errors, hasLength(1));
      expect(reporter.errors.first.errorCode.name, equals('private_subject'));
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
      expect(reporter.errors, hasLength(1));
      expect(reporter.errors.first.errorCode.name, equals('private_subject'));
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
      expect(reporter.errors, hasLength(3));
      expect(
        reporter.errors.every(
          (error) => error.errorCode.name == 'private_subject',
        ),
        isTrue,
      );
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
