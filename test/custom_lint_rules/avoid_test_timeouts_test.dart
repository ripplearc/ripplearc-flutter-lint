import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:ripplearc_linter/custom_lint_rules/avoid_test_timeouts.dart';
import 'package:test/test.dart';
import '../utils/custom_lint_resolver.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('AvoidTestTimeouts', () {
    late AvoidTestTimeouts rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = AvoidTestTimeouts();
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

    test('should flag .timeout() in test block', () async {
      const source = '''
import 'dart:async';
final userCompleter = Completer<User>();
class User {}
void main() {
  test('example', () async {
    await userCompleter.future.timeout(Duration(seconds: 1));
  });
}
''';
      await analyzeCode(source, path: 'test/example_test.dart');
      expect(reporter.errors, isNotEmpty);
      expect(
        reporter.errors.first.errorCode.name,
        equals('avoid_test_timeouts'),
      );
    });

    test('should flag Future.delayed() in test block', () async {
      const source = '''
import 'dart:async';
void main() {
  test('example', () async {
    await Future.delayed(Duration(milliseconds: 10));
  });
}
''';
      await analyzeCode(source, path: 'test/example_test.dart');
      expect(reporter.errors, isNotEmpty);
      expect(
        reporter.errors.first.errorCode.name,
        equals('avoid_test_timeouts'),
      );
    });

    test('should allow expectLater in test block', () async {
      const source = '''
import 'dart:async';
final userStream = StreamController<User>();
final expectedUser = User();
class User {}
Future<void> expectLater(Stream<User> stream, dynamic matcher) async {}
dynamic emits(dynamic value) => value;
void main() {
  test('example', () async {
    await expectLater(userStream, emits(expectedUser));
  });
}
''';
      await analyzeCode(source, path: 'test/example_test.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should allow pumpAndSettle in test block', () async {
      const source = '''
final tester = _Tester();
class _Tester {
  Future<void> pumpAndSettle() async {}
}
void main() {
  test('example', () async {
    await tester.pumpAndSettle();
  });
}
''';
      await analyzeCode(source, path: 'test/example_test.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should not flag timeout in non-test file', () async {
      const source = '''
import 'dart:async';
final userCompleter = Completer<User>();
class User {}
void main() async {
  await userCompleter.future.timeout(Duration(seconds: 1));
}
''';
      await analyzeCode(source, path: 'lib/example.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should not flag Future.delayed in non-test file', () async {
      const source = '''
import 'dart:async';
void main() async {
  await Future.delayed(Duration(milliseconds: 10));
}
''';
      await analyzeCode(source, path: 'lib/example.dart');
      expect(reporter.errors, isEmpty);
    });

    test('should flag timeout in setUp block', () async {
      const source = '''
import 'dart:async';
final userCompleter = Completer<User>();
class User {}
void main() {
  setUp(() async {
    await userCompleter.future.timeout(Duration(seconds: 1));
  });
}
''';
      await analyzeCode(source, path: 'test/example_test.dart');
      expect(reporter.errors, isNotEmpty);
    });

    test('should flag timeout in tearDown block', () async {
      const source = '''
import 'dart:async';
final userCompleter = Completer<User>();
class User {}
void main() {
  tearDown(() async {
    await userCompleter.future.timeout(Duration(seconds: 1));
  });
}
''';
      await analyzeCode(source, path: 'test/example_test.dart');
      expect(reporter.errors, isNotEmpty);
    });

    test('should flag Future.delayed constructor in test block', () async {
      const source = '''
import 'dart:async';
void main() {
  test('example', () async {
    await Future.delayed(Duration(milliseconds: 10));
  });
}
''';
      await analyzeCode(source, path: 'test/example_test.dart');
      expect(reporter.errors, isNotEmpty);
    });

    test('should flag .timeout() in testWidgets block', () async {
      const source = '''
import 'dart:async';
final userCompleter = Completer<User>();
class User {}
void main() {
  testWidgets('example', (tester) async {
    await userCompleter.future.timeout(Duration(seconds: 1));
  });
}
''';
      await analyzeCode(source, path: 'test/example_test.dart');
      expect(reporter.errors, isNotEmpty);
      expect(
        reporter.errors.first.errorCode.name,
        equals('avoid_test_timeouts'),
      );
    });

    test('should flag Future.delayed() in testWidgets block', () async {
      const source = '''
import 'dart:async';
void main() {
  testWidgets('example', (tester) async {
    await Future.delayed(Duration(milliseconds: 10));
  });
}
''';
      await analyzeCode(source, path: 'test/example_test.dart');
      expect(reporter.errors, isNotEmpty);
      expect(
        reporter.errors.first.errorCode.name,
        equals('avoid_test_timeouts'),
      );
    });

    test('should flag timeout in setUpAll block', () async {
      const source = '''
import 'dart:async';
final userCompleter = Completer<User>();
class User {}
void main() {
  setUpAll(() async {
    await userCompleter.future.timeout(Duration(seconds: 1));
  });
}
''';
      await analyzeCode(source, path: 'test/example_test.dart');
      expect(reporter.errors, isNotEmpty);
    });

    test('should flag timeout in tearDownAll block', () async {
      const source = '''
import 'dart:async';
final userCompleter = Completer<User>();
class User {}
void main() {
  tearDownAll(() async {
    await userCompleter.future.timeout(Duration(seconds: 1));
  });
}
''';
      await analyzeCode(source, path: 'test/example_test.dart');
      expect(reporter.errors, isNotEmpty);
    });

    test('should flag timeout in nested test inside group', () async {
      const source = '''
import 'dart:async';
final completer1 = Completer<void>();
final completer2 = Completer<void>();
final completer3 = Completer<void>();
void main() {
  group('outer', () async {
    await completer1.future.timeout(Duration(seconds: 1)); // Should flag
    test('inner', () async {
      await completer2.future.timeout(Duration(seconds: 1)); // Should flag
    });
    await completer3.future.timeout(Duration(seconds: 1)); // Should flag
  });
}
''';
      await analyzeCode(source, path: 'test/example_test.dart');
      expect(reporter.errors.length, equals(3));
    });

    test('should flag timeout in deeply nested groups', () async {
      const source = '''
import 'dart:async';
final c1 = Completer<void>();
final c2 = Completer<void>();
final c3 = Completer<void>();
final c4 = Completer<void>();
void main() {
  group('level1', () async {
    await c1.future.timeout(Duration(seconds: 1)); // Should flag
    group('level2', () async {
      await c2.future.timeout(Duration(seconds: 1)); // Should flag
      test('test', () async {
        await c3.future.timeout(Duration(seconds: 1)); // Should flag
      });
      await c4.future.timeout(Duration(seconds: 1)); // Should flag
    });
  });
}
''';
      await analyzeCode(source, path: 'test/example_test.dart');
      expect(reporter.errors.length, equals(4));
    });

    test('should flag Future.delayed in nested blocks', () async {
      const source = '''
import 'dart:async';
void main() {
  group('outer', () async {
    await Future.delayed(Duration(milliseconds: 1)); // Should flag
    testWidgets('widget test', (tester) async {
      await Future.delayed(Duration(milliseconds: 2)); // Should flag
    });
    await Future.delayed(Duration(milliseconds: 3)); // Should flag
  });
}
''';
      await analyzeCode(source, path: 'test/example_test.dart');
      expect(reporter.errors.length, equals(3));
    });

    group('fixed waits', () {
      List<String> flaggedCode(String source) => reporter.errors
          .map((e) => source.substring(e.offset, e.offset + e.length))
          .toList();

      test('should flag wait: Duration in blocTest', () async {
        const source = '''
void main() {
  blocTest<SearchBloc, SearchState>(
    'debounces',
    build: () => SearchBloc(),
    wait: const Duration(milliseconds: 310),
    expect: () => [],
  );
}
''';
        await analyzeCode(source, path: 'test/search_bloc_test.dart');
        expect(
          flaggedCode(source),
          equals(['wait: const Duration(milliseconds: 310)']),
        );
        expect(
          reporter.errors.single.diagnosticCode.name,
          equals('avoid_test_timeouts'),
        );
      });

      test('should flag wait: in blocTest without type arguments', () async {
        const source = '''
void main() {
  group('bloc', () {
    blocTest('loads', build: () => Bloc(), wait: Duration.zero);
  });
}
''';
        await analyzeCode(source, path: 'test/bloc_test.dart');
        expect(flaggedCode(source), equals(['wait: Duration.zero']));
      });

      test('should not flag blocTest without wait:', () async {
        const source = '''
void main() {
  blocTest<SearchBloc, SearchState>(
    'loads',
    build: () => SearchBloc(),
    expect: () => [],
  );
}
''';
        await analyzeCode(source, path: 'test/search_bloc_test.dart');
        expect(reporter.errors, isEmpty);
      });

      test('should not flag wait: on a call that is not blocTest', () async {
        const source = '''
void main() {
  test('example', () async {
    await retry(wait: const Duration(seconds: 1));
  });
}
''';
        await analyzeCode(source, path: 'test/example_test.dart');
        expect(reporter.errors, isEmpty);
      });

      test('should flag every pumpEventQueue() in a unit test', () async {
        const source = '''
void main() {
  setUp(() async {
    await pumpEventQueue();
  });
  test('example', () async {
    await pumpEventQueue();
    await pumpEventQueue(times: 50);
  });
}
''';
        await analyzeCode(source, path: 'test/notifier_test.dart');
        expect(
          flaggedCode(source),
          equals([
            'pumpEventQueue()',
            'pumpEventQueue()',
            'pumpEventQueue(times: 50)',
          ]),
        );
      });

      test('should flag pumpEventQueue() in a helper outside test blocks',
          () async {
        const source = '''
Future<void> settle() => pumpEventQueue();
void main() {
  test('example', () async {
    await settle();
  });
}
''';
        await analyzeCode(source, path: 'test/notifier_test.dart');
        expect(flaggedCode(source), equals(['pumpEventQueue()']));
      });

      test('should not flag a pumpEventQueue() method on an object',
          () async {
        const source = '''
void main() {
  test('example', () async {
    await scheduler.pumpEventQueue();
  });
}
''';
        await analyzeCode(source, path: 'test/scheduler_test.dart');
        expect(reporter.errors, isEmpty);
      });

      test(
          'should flag pumpEventQueue() in a unit test of a file that also '
          'has testWidgets', () async {
        const source = '''
void main() {
  testWidgets('widget', (tester) async {
    await pumpEventQueue();
  });
  test('unit', () async {
    await pumpEventQueue(times: 3);
  });
}
''';
        await analyzeCode(source, path: 'test/mixed_test.dart');
        expect(flaggedCode(source), equals(['pumpEventQueue(times: 3)']));
      });

      test(
          'should not flag pump(Duration), pumpAndSettle() or '
          'pumpEventQueue() inside testWidgets', () async {
        const source = '''
void main() {
  group('widget', () {
    testWidgets('example', (tester) async {
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await pumpEventQueue();
    });
  });
}
''';
        await analyzeCode(source, path: 'test/widget_test.dart');
        expect(reporter.errors, isEmpty);
      });

      test('should not flag waits inside fakeAsync', () async {
        const source = '''
void main() {
  group('timeoutInForeground', () {
    test('completes in time', () {
      fakeAsync((async) {
        Future<String>.delayed(const Duration(seconds: 3), () => 'logs');
        Future.delayed(const Duration(seconds: 1));
        Future.microtask(() {});
        completer.future.timeout(const Duration(seconds: 15));
        pumpEventQueue();
        async.elapse(const Duration(seconds: 3));
      });
    });
  });
}
''';
        await analyzeCode(source, path: 'test/foreground_timeout_test.dart');
        expect(reporter.errors, isEmpty);
      });

      test('should flag the same waits after fakeAsync ends', () async {
        const source = '''
void main() {
  test('example', () async {
    fakeAsync((async) {
      Future.delayed(const Duration(seconds: 1));
    });
    await Future<String>.delayed(const Duration(seconds: 3), () => 'logs');
    await Future.microtask(() {});
    await completer.future.timeout(const Duration(seconds: 15));
    await pumpEventQueue();
  });
}
''';
        await analyzeCode(source, path: 'test/foreground_timeout_test.dart');
        expect(
          flaggedCode(source),
          equals([
            "Future<String>.delayed(const Duration(seconds: 3), () => 'logs')",
            'Future.microtask(() {})',
            'completer.future.timeout(const Duration(seconds: 15))',
            'pumpEventQueue()',
          ]),
        );
      });

      test('should not flag blocTest wait: or pumpEventQueue() outside test/',
          () async {
        const source = '''
void main() {
  blocTest('loads', wait: const Duration(milliseconds: 310));
  test('example', () async {
    await pumpEventQueue();
  });
}
''';
        await analyzeCode(source, path: 'lib/example.dart');
        expect(reporter.errors, isEmpty);
      });
    });
  });
}
