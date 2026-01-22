import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:ripplearc_linter/custom_lint_rules/document_enum.dart';
import 'package:test/test.dart';
import '../utils/custom_lint_resolver.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('DocumentEnum', () {
    late DocumentEnum rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = DocumentEnum();
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

    group('Enum declaration documentation', () {
      test('should flag enum without documentation', () async {
        const source = '''
        enum Status {
          active,
          inactive,
        }
        ''';
        await analyzeCode(source, path: 'lib/enums.dart');
        expect(reporter.errors, hasLength(3));
      });

      test('should flag enum with only class documentation', () async {
        const source = '''
        /// Represents the status.
        enum Status {
          active,
          inactive,
        }
        ''';
        await analyzeCode(source, path: 'lib/enums.dart');
        expect(reporter.errors, hasLength(2));
      });

      test('should flag enum with only value documentation', () async {
        const source = '''
        enum Status {
          /// The item is active.
          active,
          /// The item is inactive.
          inactive,
        }
        ''';
        await analyzeCode(source, path: 'lib/enums.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should not flag properly documented enum', () async {
        const source = '''
        /// Represents the status of an item.
        enum Status {
          /// The item is active.
          active,
          /// The item is inactive.
          inactive,
        }
        ''';
        await analyzeCode(source, path: 'lib/enums.dart');
        expect(reporter.errors, isEmpty);
      });

      test('should not flag enum with multi-line documentation', () async {
        const source = '''
        /// Represents the status of an item.
        ///
        /// This enum is used throughout the application.
        enum Status {
          /// The item is active and visible.
          ///
          /// Active items appear in the main list.
          active,
          /// The item is inactive and hidden.
          inactive,
        }
        ''';
        await analyzeCode(source, path: 'lib/enums.dart');
        expect(reporter.errors, isEmpty);
      });
    });

    group('Enum constant documentation', () {
      test('should flag single undocumented enum constant', () async {
        const source = '''
        /// Represents the status.
        enum Status {
          /// The item is active.
          active,
          inactive,
        }
        ''';
        await analyzeCode(source, path: 'lib/enums.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag multiple undocumented enum constants', () async {
        const source = '''
        /// Represents the status.
        enum Status {
          active,
          inactive,
          pending,
        }
        ''';
        await analyzeCode(source, path: 'lib/enums.dart');
        expect(reporter.errors, hasLength(3));
      });
    });

    group('Empty documentation comments', () {
      test('should flag enum with empty documentation comment', () async {
        const source = '''
        ///
        enum Status {
          /// The item is active.
          active,
        }
        ''';
        await analyzeCode(source, path: 'lib/enums.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag enum value with empty documentation comment', () async {
        const source = '''
        /// Represents the status.
        enum Status {
          ///
          active,
        }
        ''';
        await analyzeCode(source, path: 'lib/enums.dart');
        expect(reporter.errors, hasLength(1));
      });
    });

    group('Enhanced enums (Dart 2.17+)', () {
      test('should flag undocumented enhanced enum', () async {
        const source = '''
        enum Vehicle {
          car('Car'),
          bike('Bike');
          
          final String label;
          const Vehicle(this.label);
        }
        ''';
        await analyzeCode(source, path: 'lib/enums.dart');
        expect(reporter.errors, hasLength(3));
      });

      test('should not flag documented enhanced enum', () async {
        const source = '''
        /// Represents a vehicle type.
        enum Vehicle {
          /// A car vehicle.
          car('Car'),
          /// A bike vehicle.
          bike('Bike');
          
          /// The display label for this vehicle type.
          final String label;
          
          /// Creates a vehicle with the given label.
          const Vehicle(this.label);
        }
        ''';
        await analyzeCode(source, path: 'lib/enums.dart');
        expect(reporter.errors, isEmpty);
      });
    });

    group('Private enums', () {
      test('should flag undocumented private enum', () async {
        const source = '''
        enum _InternalState {
          initial,
          loading,
        }
        ''';
        await analyzeCode(source, path: 'lib/enums.dart');
        expect(reporter.errors, hasLength(3));
      });

      test('should not flag documented private enum', () async {
        const source = '''
        /// Internal state management.
        enum _InternalState {
          /// Initial state.
          initial,
          /// Loading state.
          loading,
        }
        ''';
        await analyzeCode(source, path: 'lib/enums.dart');
        expect(reporter.errors, isEmpty);
      });
    });

    group('Multiple enums', () {
      test('should flag all undocumented enums', () async {
        const source = '''
        enum First {
          a,
          b,
        }
        
        enum Second {
          x,
          y,
        }
        ''';
        await analyzeCode(source, path: 'lib/enums.dart');
        expect(reporter.errors, hasLength(6));
      });

      test('should only flag undocumented parts', () async {
        const source = '''
        /// First enum.
        enum First {
          /// Value a.
          a,
          /// Value b.
          b,
        }
        
        enum Second {
          x,
          y,
        }
        ''';
        await analyzeCode(source, path: 'lib/enums.dart');
        expect(reporter.errors, hasLength(3));
      });
    });

    group('Real-world patterns', () {
      test('should flag auth error type pattern from construculator', () async {
        const source = '''
        enum AuthErrorType {
          userNotFound,
          invalidCredentials,
          unknownError,
        }
        ''';
        await analyzeCode(source, path: 'lib/auth_types.dart');
        expect(reporter.errors, hasLength(4));
      });

      test('should not flag properly documented auth pattern', () async {
        const source = '''
        /// Error type for authentication operations.
        ///
        /// [userNotFound] is used when the user is not found
        /// [invalidCredentials] is used when credentials are invalid
        /// [unknownError] is used for unknown errors
        enum AuthErrorType {
          /// Used when the user is not found.
          userNotFound,
          /// Used when credentials are invalid.
          invalidCredentials,
          /// Used for unknown errors.
          unknownError,
        }
        ''';
        await analyzeCode(source, path: 'lib/auth_types.dart');
        expect(reporter.errors, isEmpty);
      });

      test('should flag toast type pattern from coreui', () async {
        const source = '''
        enum ToastType { error, warning, info, success }
        ''';
        await analyzeCode(source, path: 'lib/toast.dart');
        expect(reporter.errors, hasLength(5));
      });

      test('should not flag properly documented toast pattern', () async {
        const source = '''
        /// Defines the type of toast notification and its visual styling.
        enum ToastType {
          /// Error toast with red background.
          error,
          /// Warning toast with orange background.
          warning,
          /// Info toast with blue background.
          info,
          /// Success toast with green background.
          success,
        }
        ''';
        await analyzeCode(source, path: 'lib/toast.dart');
        expect(reporter.errors, isEmpty);
      });
    });

    group('Test files', () {
      test('should flag undocumented enums in test files', () async {
        const source = '''
        enum TestState {
          pending,
          passed,
        }
        ''';
        await analyzeCode(source, path: 'test/my_test.dart');
        // 1 for enum + 2 for values
        expect(reporter.errors, hasLength(3));
      });
    });

    group('Block comment documentation', () {
      test('should flag enum with block comment documentation', () async {
        const source = '''
        /** This is a block comment */
        enum Status {
          /** Active state */
          active,
        }
        ''';
        await analyzeCode(source, path: 'lib/enums.dart');
        expect(reporter.errors, hasLength(2));
      });

      test('should flag enum with JavaDoc style block comment', () async {
        const source = '''
        /**
         * This is a JavaDoc style comment.
         */
        enum Status {
          /**
           * Active state.
           */
          active,
        }
        ''';
        await analyzeCode(source, path: 'lib/enums.dart');
        expect(reporter.errors, hasLength(2));
      });
    });

    group('Whitespace-only documentation', () {
      test('should flag enum with whitespace-only documentation', () async {
        const source = '''
        ///     
        enum Status {
          ///     
          active,
        }
        ''';
        await analyzeCode(source, path: 'lib/enums.dart');
        expect(reporter.errors, hasLength(2));
      });

      test('should flag enum with multiple empty doc lines', () async {
        const source = '''
        ///
        ///
        ///
        enum Status {
          ///
          active,
        }
        ''';
        await analyzeCode(source, path: 'lib/enums.dart');
        expect(reporter.errors, hasLength(2));
      });
    });

    group('Mixed documented/undocumented values', () {
      test(
        'should correctly count errors for partially documented values',
        () async {
          const source = '''
        /// Status enum.
        enum Status {
          /// Documented.
          active,
          inactive,
          /// Documented.
          pending,
          archived,
        }
        ''';
          await analyzeCode(source, path: 'lib/enums.dart');
          expect(reporter.errors, hasLength(2));
        },
      );

      test('should flag alternating documented/undocumented values', () async {
        const source = '''
        /// Status enum.
        enum Status {
          /// First value.
          first,
          second,
          /// Third value.
          third,
          fourth,
          /// Fifth value.
          fifth,
        }
        ''';
        await analyzeCode(source, path: 'lib/enums.dart');
        expect(reporter.errors, hasLength(2));
      });
    });
    group('Extensions', () {
      test('should flag extension without documentation', () async {
        const source = '''
        extension DigitTypeExtension on DigitType {
          /// Returns the display string.
          String get display => '0';
        }
        ''';
        await analyzeCode(source, path: 'lib/extensions.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag extension with undocumented public method', () async {
        const source = '''
        /// Extension on DigitType.
        extension DigitTypeExtension on DigitType {
          String get display => '0';
        }
        ''';
        await analyzeCode(source, path: 'lib/extensions.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should not flag extension with documented public method', () async {
        const source = '''
        /// Extension on DigitType.
        extension DigitTypeExtension on DigitType {
          /// Returns the display string.
          String get display => '0';
        }
        ''';
        await analyzeCode(source, path: 'lib/extensions.dart');
        expect(reporter.errors, isEmpty);
      });

      test('should not flag extension with private method', () async {
        const source = '''
        /// Extension on DigitType.
        extension DigitTypeExtension on DigitType {
          String _internal() => '0';
        }
        ''';
        await analyzeCode(source, path: 'lib/extensions.dart');
        expect(reporter.errors, isEmpty);
      });

      test('should not flag switch cases inside extension methods', () async {
        const source = '''
        /// Extension on DigitType.
        extension DigitTypeExtension on DigitType {
          /// Returns the display string.
          String get display {
            switch (this) {
              case DigitType.zero:
                return '0';
              case DigitType.one:
                return '1';
            }
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/extensions.dart');
        expect(reporter.errors, isEmpty);
      });
    });
  });
}
