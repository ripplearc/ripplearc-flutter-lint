import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';
import 'package:ripplearc_flutter_lint/rules/avoid_test_timeouts.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('AvoidTestTimeouts', () {
    late AvoidTestTimeouts rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = const AvoidTestTimeouts();
      reporter = TestErrorReporter();
    });

    Future<void> analyzeCode(String sourceCode) async {
      final parseResult = parseString(content: sourceCode);
      unit = parseResult.unit;
      rule.run(_TestResolver(unit), reporter, _TestContext(unit));
    }

    test('flags .timeout() in test block', () async {
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
      await analyzeCode(source);
      expect(reporter.errors, isNotEmpty);
      expect(
        reporter.errors.first.errorCode.name,
        equals('avoid_test_timeouts'),
      );
    });

    test('flags Future.delayed() in test block', () async {
      const source = '''
import 'dart:async';
void main() {
  test('example', () async {
    await Future.delayed(Duration(milliseconds: 10));
  });
}
''';
      await analyzeCode(source);
      expect(reporter.errors, isNotEmpty);
      expect(
        reporter.errors.first.errorCode.name,
        equals('avoid_test_timeouts'),
      );
    });

    test('allows expectLater in test block', () async {
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
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });

    test('allows pumpAndSettle in test block', () async {
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
      await analyzeCode(source);
      expect(reporter.errors, isEmpty);
    });
  });
}

class _TestResolver implements CustomLintResolver {
  _TestResolver(this.unit);
  final CompilationUnit unit;
  @override
  String get path => 'foo_test.dart';
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestContext implements CustomLintContext {
  _TestContext(this.unit);
  final CompilationUnit unit;
  @override
  LintRuleNodeRegistry get registry => _TestRegistry(unit);
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestRegistry implements LintRuleNodeRegistry {
  _TestRegistry(this.unit);
  final CompilationUnit unit;
  @override
  void addCompilationUnit(Function(CompilationUnit) callback) {
    callback(unit);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
