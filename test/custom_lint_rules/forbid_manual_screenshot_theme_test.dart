import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:ripplearc_linter/custom_lint_rules/forbid_manual_screenshot_theme.dart';
import 'package:ripplearc_linter/core/analyzers/forbid_manual_screenshot_theme_analyzer.dart';
import 'package:test/test.dart';
import '../utils/custom_lint_resolver.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('ForbidManualScreenshotTheme', () {
    late ForbidManualScreenshotTheme rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = ForbidManualScreenshotTheme();
    });

    Future<void> analyzeCode(String sourceCode, {required String path}) async {
      reporter = TestErrorReporter();
      final parseResult = parseString(content: sourceCode);
      unit = parseResult.unit;
      rule.run(
        TestCustomLintResolver(unit, path: path),
        reporter,
        TestCustomLintContext(unit),
      );
    }

    group('ThemeData? parameter detection', () {
      test('flags ThemeData? parameter in screenshot test file', () async {
        const source = '''
        void pumpWidget(WidgetTester tester, ThemeData? theme) async {}
        ''';
        await analyzeCode(source,
            path: '/test/my_widget_screenshot_test.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('flags ThemeData? parameter on a method in screenshot test', () async {
        const source = '''
        class ScreenshotHelper {
          Future<void> pump(ThemeData? theme) async {}
        }
        ''';
        await analyzeCode(source,
            path: '/test/home_screenshot_test.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('does not flag non-nullable ThemeData parameter', () async {
        const source = '''
        void pumpWidget(WidgetTester tester, ThemeData theme) async {}
        ''';
        await analyzeCode(source,
            path: '/test/my_widget_screenshot_test.dart');
        expect(reporter.errors, isEmpty);
      });

      test('does not flag other nullable parameters', () async {
        const source = '''
        void pumpWidget(WidgetTester tester, String? label) async {}
        ''';
        await analyzeCode(source,
            path: '/test/my_widget_screenshot_test.dart');
        expect(reporter.errors, isEmpty);
      });

      test('does not flag a type that merely contains "ThemeData" as a substring',
          () async {
        const source = '''
        void pumpWidget(WidgetTester tester, AppThemeData? theme) async {}
        ''';
        await analyzeCode(source,
            path: '/test/my_widget_screenshot_test.dart');
        expect(reporter.errors, isEmpty);
      });
    });

    group('_dark.png suffix detection in matchesGoldenFile', () {
      test('flags _dark.png suffix in matchesGoldenFile', () async {
        const source = '''
        void main() {
          expect(finder, matchesGoldenFile('golden/my_widget_dark.png'));
        }
        ''';
        await analyzeCode(source,
            path: '/test/my_widget_screenshot_test.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('does not flag non-dark golden suffix', () async {
        const source = '''
        void main() {
          expect(finder, matchesGoldenFile('golden/my_widget_light.png'));
        }
        ''';
        await analyzeCode(source,
            path: '/test/my_widget_screenshot_test.dart');
        expect(reporter.errors, isEmpty);
      });

      test('does not flag matchesGoldenFile without string literal argument',
          () async {
        const source = '''
        void main() {
          final path = getPath();
          expect(finder, matchesGoldenFile(path));
        }
        ''';
        await analyzeCode(source,
            path: '/test/my_widget_screenshot_test.dart');
        expect(reporter.errors, isEmpty);
      });

      test('does not flag string ending in _dark.png outside matchesGoldenFile',
          () async {
        const source = '''
        void main() {
          final label = 'golden_dark.png';
        }
        ''';
        await analyzeCode(source,
            path: '/test/my_widget_screenshot_test.dart');
        expect(reporter.errors, isEmpty);
      });
    });

    group('combined violations', () {
      test('flags both ThemeData? and _dark.png in same file', () async {
        const source = '''
        Future<void> pump(WidgetTester tester, ThemeData? theme) async {}
        void main() {
          expect(finder, matchesGoldenFile('golden/widget_dark.png'));
        }
        ''';
        await analyzeCode(source,
            path: '/test/my_widget_screenshot_test.dart');
        expect(reporter.errors, hasLength(2));
      });

      test('flags multiple ThemeData? parameters', () async {
        const source = '''
        void pumpLight(ThemeData? theme) async {}
        void pumpDark(ThemeData? theme) async {}
        ''';
        await analyzeCode(source,
            path: '/test/my_widget_screenshot_test.dart');
        expect(reporter.errors, hasLength(2));
      });
    });

    group('path filtering (shouldSkipFile)', () {
      test('does not flag violations in non-screenshot test files', () async {
        const source = '''
        Future<void> pump(WidgetTester tester, ThemeData? theme) async {}
        void main() {
          expect(finder, matchesGoldenFile('golden/widget_dark.png'));
        }
        ''';
        await analyzeCode(source, path: '/test/my_widget_test.dart');
        expect(reporter.errors, isEmpty);
      });

      test('does not flag violations in production files', () async {
        const source = '''
        void doSomething(ThemeData? theme) {}
        ''';
        await analyzeCode(source, path: '/lib/my_widget.dart');
        expect(reporter.errors, isEmpty);
      });

      test('does not flag violations in generated files', () async {
        const source = '''
        void doSomething(ThemeData? theme) {}
        ''';
        await analyzeCode(source, path: '/lib/my_widget.g.dart');
        expect(reporter.errors, isEmpty);
      });

      test('flags violations when filename ends with _screenshot_test.dart',
          () async {
        const source = '''
        void pump(ThemeData? theme) async {}
        ''';
        await analyzeCode(source,
            path: '/test/deep/nested/feature_screenshot_test.dart');
        expect(reporter.errors, hasLength(1));
      });
    });

    group('shouldSkipFile', () {
      late ForbidManualScreenshotThemeAnalyzer analyzer;

      setUp(() {
        analyzer = ForbidManualScreenshotThemeAnalyzer();
      });

      test('skips non-screenshot test files', () {
        expect(analyzer.shouldSkipFile('/test/my_widget_test.dart'), isTrue);
      });

      test('skips production lib files', () {
        expect(analyzer.shouldSkipFile('/lib/my_widget.dart'), isTrue);
      });

      test('skips generated files', () {
        expect(analyzer.shouldSkipFile('/lib/my_widget.g.dart'), isTrue);
        expect(
            analyzer.shouldSkipFile('/lib/my_widget.freezed.dart'), isTrue);
      });

      test('does not skip screenshot test files', () {
        expect(
            analyzer.shouldSkipFile('/test/my_widget_screenshot_test.dart'),
            isFalse);
      });

      test('handles Windows-style paths', () {
        expect(
          analyzer.shouldSkipFile(
              r'test\my_widget_screenshot_test.dart'),
          isFalse,
        );
        expect(
          analyzer.shouldSkipFile(r'test\my_widget_test.dart'),
          isTrue,
        );
      });
    });

    group('rule metadata', () {
      test('rule name', () {
        expect(rule.code.name, equals('forbid_manual_screenshot_theme'));
      });

      test('problem message mentions screenshotThemeGroups', () {
        expect(
            rule.code.problemMessage, contains('screenshotThemeGroups'));
      });
    });

    group('direct analyze() call', () {
      test('analyze() returns empty list (path context guard)', () {
        const source = '''
        Future<void> pump(ThemeData? theme) async {}
        ''';
        final parseResult = parseString(content: source);
        final testUnit = parseResult.unit;

        final issues = rule.analyzer.analyze(testUnit);
        expect(
          issues,
          isEmpty,
          reason:
              'analyze() must return [] — path context is required to avoid false positives on non-screenshot files',
        );
      });
    });

    group('analyzer interface', () {
      test('analyzeWithResolver flags violations on screenshot test path',
          () {
        const source = '''
        void pump(ThemeData? theme) async {}
        ''';
        final parseResult = parseString(content: source);
        final testUnit = parseResult.unit;
        final resolver = TestCustomLintResolver(
          testUnit,
          path: '/test/my_widget_screenshot_test.dart',
        );

        final issues = rule.analyzer.analyzeWithResolver(testUnit, resolver);
        expect(issues, hasLength(1));
        expect(issues.first.ruleName,
            equals('forbid_manual_screenshot_theme'));
      });

      test('analyzeWithResolver returns empty for non-screenshot path', () {
        const source = '''
        void pump(ThemeData? theme) async {}
        ''';
        final parseResult = parseString(content: source);
        final testUnit = parseResult.unit;
        final resolver = TestCustomLintResolver(
          testUnit,
          path: '/test/my_widget_test.dart',
        );

        final issues = rule.analyzer.analyzeWithResolver(testUnit, resolver);
        expect(issues, isEmpty);
      });
    });
  });
}
