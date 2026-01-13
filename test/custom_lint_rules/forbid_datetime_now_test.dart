import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:ripplearc_linter/custom_lint_rules/forbid_datetime_now.dart';
import 'package:test/test.dart';
import '../utils/custom_lint_resolver.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('ForbidDateTimeNow', () {
    late ForbidDateTimeNow rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = ForbidDateTimeNow();
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

    group('DateTime.now() detection', () {
      test('should flag simple DateTime.now() call', () async {
        const source = '''
        void main() {
          final now = DateTime.now();
        }
        ''';
        await analyzeCode(source, path: 'lib/my_service.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag DateTime.now() in variable initialization', () async {
        const source = '''
        class MyService {
          final DateTime createdAt = DateTime.now();
        }
        ''';
        await analyzeCode(source, path: 'lib/my_service.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag DateTime.now() chained with property access', () async {
        const source = '''
        void main() {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
        }
        ''';
        await analyzeCode(source, path: 'lib/my_service.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag DateTime.now() chained with method call', () async {
        const source = '''
        void main() {
          final formatted = DateTime.now().toIso8601String();
        }
        ''';
        await analyzeCode(source, path: 'lib/my_service.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag DateTime.now() in conditional expression', () async {
        const source = '''
        void main() {
          final isAfternoon = DateTime.now().hour >= 12;
        }
        ''';
        await analyzeCode(source, path: 'lib/my_service.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag DateTime.now() in method argument', () async {
        const source = '''
        void printTime(DateTime time) {}
        
        void main() {
          printTime(DateTime.now());
        }
        ''';
        await analyzeCode(source, path: 'lib/my_service.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag DateTime.now() in return statement', () async {
        const source = '''
        DateTime getCurrentTime() {
          return DateTime.now();
        }
        ''';
        await analyzeCode(source, path: 'lib/my_service.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag multiple DateTime.now() calls', () async {
        const source = '''
        void main() {
          final start = DateTime.now();
          final end = DateTime.now();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
        }
        ''';
        await analyzeCode(source, path: 'lib/my_service.dart');
        expect(reporter.errors, hasLength(3));
      });

      test(
        'should flag DateTime.now() in isAfter/isBefore comparison',
        () async {
          const source = '''
        bool isExpired(DateTime expiration) {
          return DateTime.now().isAfter(expiration);
        }
        ''';
          await analyzeCode(source, path: 'lib/my_service.dart');
          expect(reporter.errors, hasLength(1));
        },
      );
    });

    group('Valid code - no DateTime.now()', () {
      test('should not flag clock.now() usage', () async {
        const source = '''
        abstract class Clock {
          DateTime now();
        }
        
        class MyService {
          final Clock clock;
          MyService(this.clock);
          
          DateTime getCurrentTime() {
            return clock.now();
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/my_service.dart');
        expect(reporter.errors, isEmpty);
      });

      test('should not flag DateTime constructor calls', () async {
        const source = '''
        void main() {
          final date = DateTime(2024, 1, 15);
          final utc = DateTime.utc(2024, 1, 15);
          final parsed = DateTime.parse('2024-01-15');
        }
        ''';
        await analyzeCode(source, path: 'lib/my_service.dart');
        expect(reporter.errors, isEmpty);
      });

      test('should not flag DateTime.fromMillisecondsSinceEpoch', () async {
        const source = '''
        void main() {
          final date = DateTime.fromMillisecondsSinceEpoch(1705320000000);
        }
        ''';
        await analyzeCode(source, path: 'lib/my_service.dart');
        expect(reporter.errors, isEmpty);
      });

      test('should not flag DateTime.tryParse', () async {
        const source = '''
        void main() {
          final date = DateTime.tryParse('2024-01-15');
        }
        ''';
        await analyzeCode(source, path: 'lib/my_service.dart');
        expect(reporter.errors, isEmpty);
      });

      test(
        'should not flag other now() methods on different classes',
        () async {
          const source = '''
        class MyCustomClock {
          DateTime now() => DateTime(2024, 1, 1);
        }
        
        void main() {
          final clock = MyCustomClock();
          final time = clock.now();
        }
        ''';
          await analyzeCode(source, path: 'lib/my_service.dart');
          expect(reporter.errors, isEmpty);
        },
      );

      test('should not flag variables named DateTime', () async {
        const source = '''
        void main() {
          // This is contrived but tests that we only flag actual DateTime.now() calls
          final DateTime = SomeClass();
          // This should not be flagged as it's not the real DateTime class
        }
        
        class SomeClass {}
        ''';
        await analyzeCode(source, path: 'lib/my_service.dart');
        expect(reporter.errors, isEmpty);
      });
    });

    group('Edge cases', () {
      test('should flag DateTime.now() in nested expressions', () async {
        const source = '''
        void main() {
          final result = someCondition 
            ? DateTime.now() 
            : DateTime(2024, 1, 1);
        }
        
        final someCondition = true;
        ''';
        await analyzeCode(source, path: 'lib/my_service.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag DateTime.now() in lambda expressions', () async {
        const source = '''
        void main() {
          final getTime = () => DateTime.now();
        }
        ''';
        await analyzeCode(source, path: 'lib/my_service.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag DateTime.now() in constructor initializer', () async {
        const source = '''
        class MyEntity {
          final DateTime createdAt;
          MyEntity() : createdAt = DateTime.now();
        }
        ''';
        await analyzeCode(source, path: 'lib/my_service.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag DateTime.now() in cascade notation', () async {
        const source = '''
        void main() {
          DateTime.now()
            ..toIso8601String()
            ..toString();
        }
        ''';
        await analyzeCode(source, path: 'lib/my_service.dart');
        expect(reporter.errors, hasLength(1));
      });
    });

    group('Rule metadata', () {
      test('should have correct rule name', () {
        expect(rule.code.name, equals('forbid_datetime_now'));
      });

      test('should have problem message mentioning clock package', () {
        expect(rule.code.problemMessage, contains('clock.now()'));
        expect(rule.code.problemMessage, contains('package:clock/clock.dart'));
      });

      test('should have correction message with guidance', () {
        expect(rule.code.correctionMessage, contains('clock.now()'));
      });
    });
  });
}
