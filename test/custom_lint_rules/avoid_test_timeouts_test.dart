import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:ripplearc_linter_test/custom_lint_rules/avoid_test_timeouts.dart';
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
  });
}
