import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';
import 'package:ripplearc_linter/custom_lint_rules/no_optional_operators_in_tests.dart';
import '../utils/custom_lint_resolver.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('NoOptionalOperatorsInTests', () {
    late NoOptionalOperatorsInTests rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = NoOptionalOperatorsInTests();
      reporter = TestErrorReporter();
    });

    Future<void> analyzeCode(String sourceCode) async {
      final parseResult = parseString(content: sourceCode);
      unit = parseResult.unit;
      rule.run(
        TestCustomLintResolver(unit),
        reporter,
        TestCustomLintContext(unit),
      );
    }

    test('should flag optional chaining operator (?.)', () async {
      const source = '''
void main() {
  test('example', () {
    final result = someObject?.someProperty;  // Should flag this
    expect(result, equals(expected));
  });
}
''';
      await analyzeCode(source);
      expect(reporter.errors, isNotEmpty);
    });

    test('should flag null-aware operator (??)', () async {
      const source = '''
void main() {
  test('example', () {
    final result = someValue ?? defaultValue;  // Should flag this
    expect(result, equals(expected));
  });
}
''';
      await analyzeCode(source);
      expect(reporter.errors, isNotEmpty);
    });

    test('should not flag null assertion operator (!)', () async {
      const source = '''
void main() {
  test('example', () {
    final result = someValue!;  // Should not flag this
    expect(result, equals(expected));
  });
}
''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('should not flag non-test files', () async {
      const source = '''
class MyClass {
  void someMethod() {
    final result = someObject?.someProperty;  // Should not flag this
    final value = someValue ?? defaultValue;  // Should not flag this
  }
}
''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('should not flag setup/teardown blocks', () async {
      const source = '''
void main() {
  setUp(() {
    final result = someObject?.someProperty;  // Should not flag this
    final value = someValue ?? defaultValue;  // Should not flag this
  });

  test('example', () {
    // Test implementation
  });
}
''';
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    group('Nested group/test state management', () {
      test(
        'should flag optional operators after nested test in group',
        () async {
          const source = '''
void main() {
  group('outer', () {
    test('test1', () {
      final x = obj?.prop;
    });
    final y = anotherObj?.prop;
  });
}
''';
          await analyzeCode(source);
          expect(reporter.errors.length, equals(2));
        },
      );

      test('should flag optional operators after nested group', () async {
        const source = '''
void main() {
  group('outer', () {
    group('inner', () {
      final x = obj?.prop;
    });
    final y = anotherObj?.prop;
  });
}
''';
        await analyzeCode(source);
        expect(reporter.errors.length, equals(2));
      });

      test(
        'should flag optional operators in deeply nested structure',
        () async {
          const source = '''
void main() {
  group('level1', () {
    final a = obj?.prop;
    group('level2', () {
      final b = obj?.prop;
      test('test', () {
        final c = obj?.prop;
      });
      final d = obj?.prop;
    });
    final e = obj?.prop;
  });
}
''';
          await analyzeCode(source);
          expect(reporter.errors.length, equals(5));
        },
      );
    });

    group('setUpAll/tearDownAll exclusion', () {
      test('should not flag setUpAll blocks', () async {
        const source = '''
void main() {
  setUpAll(() {
    final result = someObject?.someProperty;
    final value = someValue ?? defaultValue;
  });

  test('example', () {});
}
''';
        await analyzeCode(source);
        expect(reporter.errors, isEmpty);
      });

      test('should not flag tearDownAll blocks', () async {
        const source = '''
void main() {
  tearDownAll(() {
    final result = someObject?.someProperty;
    final value = someValue ?? defaultValue;
  });

  test('example', () {});
}
''';
        await analyzeCode(source);
        expect(reporter.errors, isEmpty);
      });

      test('should not flag setUpAll inside group', () async {
        const source = '''
void main() {
  group('tests', () {
    setUpAll(() {
      final result = someObject?.someProperty;
    });

    test('example', () {
      final x = obj?.prop;
    });
  });
}
''';
        await analyzeCode(source);
        expect(reporter.errors.length, equals(1));
      });
    });

    test('should flag null-aware assignment operator (??=)', () async {
      const source = '''
void main() {
  test('example', () {
    String? value;
    value ??= 'default';
  });
}
''';
      await analyzeCode(source);
      expect(reporter.errors, isNotEmpty);
    });

    test('should flag null-aware index operator (?[])', () async {
      const source = '''
void main() {
  test('example', () {
    final list = <int>[];
    final item = list?[0];
  });
}
''';
      await analyzeCode(source);
      expect(reporter.errors, isNotEmpty);
    });

    group('testWidgets support', () {
      test('should flag optional operators in testWidgets', () async {
        const source = '''
void main() {
  testWidgets('widget test', (tester) async {
    final result = someObject?.someProperty;
    final value = someValue ?? defaultValue;
  });
}
''';
        await analyzeCode(source);
        expect(reporter.errors, isNotEmpty);
      });
    });
  });
}
