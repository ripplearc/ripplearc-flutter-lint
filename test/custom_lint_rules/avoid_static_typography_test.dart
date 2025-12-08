import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:ripplearc_linter/custom_lint_rules/avoid_static_typography.dart';
import 'package:test/test.dart';
import '../utils/custom_lint_resolver.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('AvoidStaticTypography', () {
    late AvoidStaticTypography rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = AvoidStaticTypography();
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

    group('CoreTypography static method calls', () {
      test('should flag CoreTypography.headlineLargeSemiBold()', () async {
        const source = '''
        class CoreTypography {
          static TextStyle headlineLargeSemiBold() => TextStyle();
        }
        
        void main() {
          final style = CoreTypography.headlineLargeSemiBold();
        }
        ''';
        await analyzeCode(source, path: 'lib/example.dart');
        expect(reporter.errors, hasLength(2)); // TextStyle + CoreTypography
        expect(
          reporter.errors.any(
            (e) => e.errorCode.name == 'avoid_static_typography',
          ),
          isTrue,
        );
      });

      test('should flag CoreTypography.bodyLargeRegular()', () async {
        const source = '''
        class CoreTypography {
          static TextStyle bodyLargeRegular() => TextStyle();
        }
        
        Widget build(BuildContext context) {
          return Text(
            'Hello',
            style: CoreTypography.bodyLargeRegular(),
          );
        }
        ''';
        await analyzeCode(source, path: 'lib/widgets/my_widget.dart');
        expect(reporter.errors, isNotEmpty);
      });

      test('should flag CoreTypography.titleLargeMedium()', () async {
        const source = '''
        class CoreTypography {
          static TextStyle titleLargeMedium() => TextStyle();
        }
        
        void example() {
          final textStyle = CoreTypography.titleLargeMedium();
        }
        ''';
        await analyzeCode(source, path: 'lib/screens/home.dart');
        expect(reporter.errors, isNotEmpty);
      });
    });

    group('Raw TextStyle constructor', () {
      test('should flag TextStyle constructor', () async {
        const source = '''
        void main() {
          final style = TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          );
        }
        ''';
        await analyzeCode(source, path: 'lib/example.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag const TextStyle constructor', () async {
        const source = '''
        void main() {
          const style = const TextStyle(
            fontSize: 16,
          );
        }
        ''';
        await analyzeCode(source, path: 'lib/example.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag TextStyle in Text widget', () async {
        const source = '''
        Widget build(BuildContext context) {
          return Text(
            'Welcome back',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          );
        }
        ''';
        await analyzeCode(source, path: 'lib/widgets/welcome.dart');
        expect(reporter.errors, hasLength(1));
      });
    });

    group('GoogleFonts usage', () {
      test('should flag GoogleFonts.roboto()', () async {
        const source = '''
        class GoogleFonts {
          static TextStyle roboto({double? fontSize}) => TextStyle();
        }
        
        void main() {
          final style = GoogleFonts.roboto(fontSize: 16);
        }
        ''';
        await analyzeCode(source, path: 'lib/example.dart');
        expect(reporter.errors, isNotEmpty);
      });

      test('should flag GoogleFonts.lato()', () async {
        const source = '''
        class GoogleFonts {
          static TextStyle lato({double? fontSize}) => TextStyle();
        }
        
        Widget build(BuildContext context) {
          return Text(
            'Hello',
            style: GoogleFonts.lato(fontSize: 14),
          );
        }
        ''';
        await analyzeCode(source, path: 'lib/widgets/text.dart');
        expect(reporter.errors, isNotEmpty);
      });
    });

    group('CoreTypography static font weight constants', () {
      test('should flag CoreTypography.semiBold', () async {
        const source = '''
        class CoreTypography {
          static const semiBold = FontWeight.w600;
        }
        
        void main() {
          final weight = CoreTypography.semiBold;
        }
        ''';
        await analyzeCode(source, path: 'lib/example.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag CoreTypography.bold', () async {
        const source = '''
        class CoreTypography {
          static const bold = FontWeight.w700;
        }
        
        void main() {
          final weight = CoreTypography.bold;
        }
        ''';
        await analyzeCode(source, path: 'lib/example.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag CoreTypography.regular', () async {
        const source = '''
        class CoreTypography {
          static const regular = FontWeight.w400;
        }
        
        void main() {
          final weight = CoreTypography.regular;
        }
        ''';
        await analyzeCode(source, path: 'lib/example.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag CoreTypography.medium', () async {
        const source = '''
        class CoreTypography {
          static const medium = FontWeight.w500;
        }
        
        void main() {
          final weight = CoreTypography.medium;
        }
        ''';
        await analyzeCode(source, path: 'lib/example.dart');
        expect(reporter.errors, hasLength(1));
      });
    });

    group('Test files', () {
      test('should flag CoreTypography in test files', () async {
        const source = '''
        class CoreTypography {
          static TextStyle headlineLargeSemiBold() => TextStyle();
        }
        
        void main() {
          test('example', () {
            final style = CoreTypography.headlineLargeSemiBold();
            expect(style, isNotNull);
          });
        }
        ''';
        await analyzeCode(source, path: 'test/widgets/example_test.dart');
        expect(reporter.errors, hasLength(2));
      });

      test('should flag TextStyle in test files', () async {
        const source = '''
        void main() {
          test('text style test', () {
            final style = TextStyle(fontSize: 14);
            expect(style.fontSize, equals(14));
          });
        }
        ''';
        await analyzeCode(source, path: 'test/example_test.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag GoogleFonts in test files', () async {
        const source = '''
        class GoogleFonts {
          static TextStyle roboto({double? fontSize}) => TextStyle();
        }
        
        void main() {
          test('fonts test', () {
            final style = GoogleFonts.roboto(fontSize: 16);
            expect(style, isNotNull);
          });
        }
        ''';
        await analyzeCode(source, path: 'test/fonts_test.dart');
        expect(reporter.errors, hasLength(2));
      });
    });

    group('Valid patterns (should not flag)', () {
      test(
        'should NOT flag Theme.of(context).extension<TypographyExtension>()',
        () async {
          const source = '''
        Widget build(BuildContext context) {
          final typography = Theme.of(context).extension<TypographyExtension>();
          return Text(
            'Hello',
            style: typography?.bodyLargeRegular,
          );
        }
        ''';
          await analyzeCode(source, path: 'lib/widgets/example.dart');
          expect(reporter.errors, isEmpty);
        },
      );

      test('should NOT flag copyWith on theme typography', () async {
        const source = '''
        Widget build(BuildContext context) {
          final typography = Theme.of(context).extension<TypographyExtension>();
          final appColors = Theme.of(context).extension<AppColorsExtension>();
          return Text(
            'Hello',
            style: typography?.bodyLargeMedium?.copyWith(
              color: appColors?.textDark,
            ),
          );
        }
        ''';
        await analyzeCode(source, path: 'lib/widgets/example.dart');
        expect(reporter.errors, isEmpty);
      });

      test('should NOT flag inline Theme.of access', () async {
        const source = '''
        Widget build(BuildContext context) {
          return Text(
            'Hello',
            style: Theme.of(context)
                .extension<TypographyExtension>()
                ?.bodyMediumRegular,
          );
        }
        ''';
        await analyzeCode(source, path: 'lib/widgets/example.dart');
        expect(reporter.errors, isEmpty);
      });
    });

    group('Aliases, tear-offs, and wildcards', () {
      test('should flag CoreTypography usage through import alias', () async {
        const source = '''
        import 'package:ripplearc_coreui/ripplearc_coreui.dart' as design;
        
        void main() {
          final style = design.CoreTypography.headlineLargeSemiBold();
        }
        ''';
        await analyzeCode(source, path: 'lib/widgets/alias_example.dart');
        expect(reporter.errors, isNotEmpty);
      });

      test('should flag CoreTypography tear-offs', () async {
        const source = '''
        class CoreTypography {
          static TextStyle bodyLargeRegular() => TextStyle();
        }
        
        void main() {
          final builder = CoreTypography.bodyLargeRegular;
          builder();
        }
        ''';
        await analyzeCode(source, path: 'lib/widgets/tear_off_example.dart');
        expect(reporter.errors, isNotEmpty);
      });

      test('should flag GoogleFonts usage through alias', () async {
        const source = '''
        import 'package:google_fonts/google_fonts.dart' as gf;
        
        void render() {
          final style = gf.GoogleFonts.roboto(fontSize: 16);
        }
        ''';
        await analyzeCode(source, path: 'lib/widgets/google_fonts_alias.dart');
        expect(reporter.errors, isNotEmpty);
      });

      test('should flag GoogleFonts tear-offs', () async {
        const source = '''
        import 'package:google_fonts/google_fonts.dart' as gf;
        
        void render() {
          final builder = gf.GoogleFonts.roboto;
        }
        ''';
        await analyzeCode(
          source,
          path: 'lib/widgets/google_fonts_tear_off.dart',
        );
        expect(reporter.errors, isNotEmpty);
      });

      test('should flag aliased TextStyle constructors', () async {
        const source = '''
        import 'package:design_system/ui.dart' as ui;
        
        void main() {
          final style = ui.TextStyle(fontSize: 18);
        }
        ''';
        await analyzeCode(source, path: 'lib/widgets/ui_text_style.dart');
        expect(reporter.errors, isNotEmpty);
      });
    });

    group('Multiple violations', () {
      test('should flag multiple violations in same file', () async {
        const source = '''
        class CoreTypography {
          static TextStyle headlineLargeSemiBold() => TextStyle();
          static TextStyle bodyLargeRegular() => TextStyle();
          static const semiBold = FontWeight.w600;
        }
        
        class GoogleFonts {
          static TextStyle roboto({double? fontSize}) => TextStyle();
        }
        
        void main() {
          // Violation 1: CoreTypography method
          final style1 = CoreTypography.headlineLargeSemiBold();
          
          // Violation 2: Raw TextStyle
          final style2 = TextStyle(fontSize: 14);
          
          // Violation 3: GoogleFonts
          final style3 = GoogleFonts.roboto(fontSize: 16);
          
          // Violation 4: CoreTypography constant
          final weight = CoreTypography.semiBold;
        }
        ''';
        await analyzeCode(source, path: 'lib/example.dart');
        // Should have multiple violations
        expect(reporter.errors.length, greaterThanOrEqualTo(4));
      });
    });
  });
}
