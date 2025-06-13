import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';
import 'package:ripplearc_flutter_lint/rules/prefer_fake_over_mock_rule.dart';
import '../utils/test_error_reporter.dart';

/// Tests for the [PreferFakeOverMockRule] lint rule.
///
/// These tests verify that the rule correctly identifies and reports:
/// - Classes that extend [Mock] from mockito
/// - Classes that extend [Fake] (should not be reported)
/// - Regular class inheritance (should not be reported)
/// - Classes with no extends clause (should not be reported)
void main() {
  group('PreferFakeOverMockRule', () {
    late PreferFakeOverMockRule rule;
    late TestErrorReporter reporter;

    const mockClass = '''
import 'package:mockito/mockito.dart';

abstract class UserRepository {
  Future<String> getUser(String id);
}

class MockUserRepository extends Mock implements UserRepository {}
''';

    const fakeClass = '''
abstract class UserRepository {
  Future<String> getUser(String id);
}

class FakeUserRepository extends Fake implements UserRepository {
  @override
  Future<String> getUser(String id) async => 'fake-user';
}
''';

    const regularClass = '''
class BaseClass {
  void doSomething() {}
}

class ChildClass extends BaseClass {
  @override
  void doSomething() {
    super.doSomething();
  }
}
''';

    const noExtendsClass = '''
abstract class UserRepository {
  Future<String> getUser(String id);
}

class InMemoryUserRepository implements UserRepository {
  @override
  Future<String> getUser(String id) async => 'user';
}
''';

    setUp(() {
      rule = const PreferFakeOverMockRule();
      reporter = TestErrorReporter();
    });

    Future<void> analyzeCode(String sourceCode) async {
      final parseResult = parseString(content: sourceCode);
      final unit = parseResult.unit;
      
      for (final declaration in unit.declarations) {
        if (declaration is ClassDeclaration) {
          rule.checkForMockSuperclass(declaration, reporter);
        }
      }
    }

    test('should flag class extending Mock', () async {
      await analyzeCode(mockClass);

      expect(reporter.errors, hasLength(1));
      expect(reporter.errors.first.errorCode.name, equals('prefer_fake_over_mock'));
    });

    test('should not flag class extending Fake', () async {
      await analyzeCode(fakeClass);
      expect(reporter.errors, isEmpty);
    });

    test('should not flag regular class inheritance', () async {
      await analyzeCode(regularClass);
      expect(reporter.errors, isEmpty);
    });

    test('should not flag class with no extends clause', () async {
      await analyzeCode(noExtendsClass);
      expect(reporter.errors, isEmpty);
    });
  });
} 