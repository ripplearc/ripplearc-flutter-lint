import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:ripplearc_linter/custom_lint_rules/forbid_raw_icon_and_image_usage.dart';
import 'package:ripplearc_linter/core/analyzers/forbid_raw_icon_and_image_usage_analyzer.dart';
import 'package:test/test.dart';
import '../utils/custom_lint_resolver.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('ForbidRawIconAndImageUsage', () {
    late ForbidRawIconAndImageUsage rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = ForbidRawIconAndImageUsage();
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

    group('Icon() usage', () {
      test('should flag Icon() constructor in app code', () async {
        const source = '''
        class Icons {
          static const home = 1;
        }
        class Icon {
          const Icon(dynamic iconData);
        }
        class MyWidget {
          void build() {
            final icon = new Icon(Icons.home);
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/widgets/my_widget.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag Icon() constructor in test files', () async {
        const source = '''
        class Icons {
          static const home = 1;
        }
        class Icon {
          const Icon(dynamic iconData);
        }
        void main() {
          test('example', () {
            final icon = new Icon(Icons.home);
          });
        }
        ''';
        await analyzeCode(source, path: 'test/widgets/my_widget_test.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag const Icon() usage', () async {
        const source = '''
        class Icons {
          static const star = 1;
        }
        class Icon {
          const Icon(dynamic iconData);
        }
        class MyWidget {
          static const icon = const Icon(Icons.star);
        }
        ''';
        await analyzeCode(source, path: 'lib/widgets/my_widget.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag multiple Icon() usages', () async {
        const source = '''
        class Icons {
          static const home = 1;
          static const star = 2;
        }
        class Icon {
          const Icon(dynamic iconData);
        }
        class MyWidget {
          void build() {
            final icon1 = new Icon(Icons.home);
            final icon2 = new Icon(Icons.star);
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/widgets/my_widget.dart');
        expect(reporter.errors, hasLength(2));
      });

      test('should not flag Icon() in coreui/lib path', () async {
        const source = '''
        class Icons {
          static const home = 1;
        }
        class Icon {
          const Icon(dynamic iconData);
        }
        class CoreIconWidget {
          void build() {
            final icon = new Icon(Icons.home);
          }
        }
        ''';
        await analyzeCode(
          source,
          path: 'packages/coreui/lib/src/components/core_icon.dart',
        );
        expect(reporter.errors, isEmpty);
      });

      test('should not flag Icon() in coreui/test path', () async {
        const source = '''
        class Icons {
          static const home = 1;
        }
        class Icon {
          const Icon(dynamic iconData);
        }
        void main() {
          test('example', () {
            final icon = new Icon(Icons.home);
          });
        }
        ''';
        await analyzeCode(
          source,
          path: 'packages/coreui/test/components/core_icon_test.dart',
        );
        expect(reporter.errors, isEmpty);
      });
    });

    group('Image.asset() usage', () {
      test('should flag Image.asset() in app code', () async {
        const source = '''
        class Image {
          Image.asset(String name);
        }
        class MyWidget {
          void build() {
            final image = new Image.asset('assets/image.png');
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/widgets/my_widget.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag Image.asset() in test files', () async {
        const source = '''
        class Image {
          Image.asset(String name);
        }
        void main() {
          test('example', () {
            final image = new Image.asset('assets/logo.png');
          });
        }
        ''';
        await analyzeCode(source, path: 'test/widgets/my_widget_test.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag multiple Image.asset() usages', () async {
        const source = '''
        class Image {
          Image.asset(String name);
        }
        class MyWidget {
          void build() {
            final img1 = new Image.asset('assets/image1.png');
            final img2 = new Image.asset('assets/image2.png');
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/widgets/my_widget.dart');
        expect(reporter.errors, hasLength(2));
      });

      test('should not flag Image.network() (only Image.asset is restricted)',
          () async {
        const source = '''
        class Image {
          Image.network(String url);
        }
        class MyWidget {
          void build() {
            final image = new Image.network('https://example.com/img.png');
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/widgets/my_widget.dart');
        expect(reporter.errors, isEmpty);
      });

      test('should not flag plain Image() default constructor', () async {
        const source = '''
        class Image {
          Image();
        }
        class MyWidget {
          void build() {
            final image = new Image();
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/widgets/my_widget.dart');
        expect(reporter.errors, isEmpty);
      });

      test('should flag both Icon() and Image.asset() in same file', () async {
        const source = '''
        class Icons {
          static const home = 1;
        }
        class Icon {
          const Icon(dynamic iconData);
        }
        class Image {
          Image.asset(String name);
        }
        class MyWidget {
          void build() {
            final icon = new Icon(Icons.home);
            final image = new Image.asset('assets/image.png');
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/widgets/my_widget.dart');
        expect(reporter.errors, hasLength(2));
      });

      test('should not flag Image constructors in coreui/lib path', () async {
        const source = '''
        class Image {
          Image.asset(String name);
          Image.network(String url);
        }
        class CoreImageWidget {
          void build() {
            final image = new Image.asset('assets/image.png');
            final network = new Image.network('https://example.com');
          }
        }
        ''';
        await analyzeCode(
          source,
          path: 'packages/coreui/lib/src/components/core_image.dart',
        );
        expect(reporter.errors, isEmpty);
      });

      test('should not flag Image constructors in coreui/test path', () async {
        const source = '''
        class Image {
          Image.asset(String name);
        }
        void main() {
          test('example', () {
            final image = new Image.asset('assets/image.png');
          });
        }
        ''';
        await analyzeCode(
          source,
          path: 'packages/coreui/test/components/core_image_test.dart',
        );
        expect(reporter.errors, isEmpty);
      });
    });

    group('shouldSkipFile', () {
      late ForbidRawIconAndImageUsageAnalyzer analyzer;

      setUp(() {
        analyzer = ForbidRawIconAndImageUsageAnalyzer();
      });

      test('should skip files in coreui/lib/', () {
        expect(
          analyzer.shouldSkipFile(
            'packages/coreui/lib/src/components/core_icon.dart',
          ),
          isTrue,
        );
      });

      test('should skip files in coreui/test/', () {
        expect(
          analyzer.shouldSkipFile(
            'packages/coreui/test/components/core_icon_test.dart',
          ),
          isTrue,
        );
      });

      test('should not skip app lib files', () {
        expect(analyzer.shouldSkipFile('lib/widgets/my_widget.dart'), isFalse);
      });

      test('should not skip app test files', () {
        expect(
          analyzer.shouldSkipFile('test/widgets/my_widget_test.dart'),
          isFalse,
        );
      });

      test('should handle Windows-style paths', () {
        expect(
          analyzer.shouldSkipFile(
            r'packages\coreui\lib\src\components\core_icon.dart',
          ),
          isTrue,
        );
        expect(
          analyzer.shouldSkipFile(
            r'packages\coreui\test\components\core_icon_test.dart',
          ),
          isTrue,
        );
      });
    });

    group('edge cases', () {
      test('should not flag unrelated classes', () async {
        const source = '''
        class CustomIcon {
          const CustomIcon(dynamic data);
        }
        class MyWidget {
          void build() {
            final icon = new CustomIcon('data');
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/widgets/my_widget.dart');
        expect(reporter.errors, isEmpty);
      });

      test(
        'should not flag CoreIcons usage (the approved replacement)',
        () async {
          const source = '''
        class CoreIcons {
          static const arrowRight = 'icon_data';
        }
        class MyWidget {
          void build() {
            final icon = CoreIcons.arrowRight;
          }
        }
        ''';
          await analyzeCode(source, path: 'lib/widgets/my_widget.dart');
          expect(reporter.errors, isEmpty);
        },
      );

      test('should handle empty source code', () async {
        const source = '';
        await analyzeCode(source, path: 'lib/widgets/empty.dart');
        expect(reporter.errors, isEmpty);
      });

      test('should handle source with no violations', () async {
        const source = '''
        class MyWidget {
          void build() {
            print('no icons here');
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/widgets/my_widget.dart');
        expect(reporter.errors, isEmpty);
      });
    });

    group('rule metadata', () {
      test('rule name', () {
        expect(rule.code.name, equals('forbid_raw_icon_and_image_usage'));
      });

      test('problem message mentions raw icons and Image.asset', () {
        expect(rule.code.problemMessage, contains('Raw Flutter icons'));
        expect(rule.code.problemMessage, contains('Image.asset'));
      });

      test('rule includes test files', () {
        expect(
          ForbidRawIconAndImageUsageAnalyzer().shouldSkipFile(
            'test/my_test.dart',
          ),
          isFalse,
        );
      });
    });

    group('analyzer interface', () {
      test('analyze() returns empty list (bypass check)', () {
        const source = '''
        class Icon {
          const Icon(dynamic iconData);
        }
        class Icons {
          static const home = 1;
        }
        void f() { new Icon(Icons.home); }
        ''';
        final parseResult = parseString(content: source);
        final unit = parseResult.unit;

        final issues = rule.analyzer.analyze(unit);
        expect(
          issues,
          isEmpty,
          reason:
              'analyze() should return an empty list to prevent path-unaware analysis',
        );
      });

      test(
        'analyzeWithResolver returns issues for Icon() on non-excluded path',
        () {
          const source = '''
        class Icon {
          const Icon(dynamic iconData);
        }
        class Icons {
          static const home = 1;
        }
        void f() { new Icon(Icons.home); }
        ''';
          final parseResult = parseString(content: source);
          final unit = parseResult.unit;
          final resolver = TestCustomLintResolver(unit, path: 'lib/main.dart');

          final issues = rule.analyzer.analyzeWithResolver(unit, resolver);
          expect(issues, hasLength(1));
          expect(
            issues.first.ruleName,
            equals('forbid_raw_icon_and_image_usage'),
          );
          expect(issues.first.message, contains('Icon()'));
        },
      );

      test('analyzeWithResolver returns empty for excluded coreui path', () {
        const source = '''
        class Icon {
          const Icon(dynamic iconData);
        }
        class Icons {
          static const home = 1;
        }
        void f() { new Icon(Icons.home); }
        ''';
        final parseResult = parseString(content: source);
        final unit = parseResult.unit;
        final resolver = TestCustomLintResolver(
          unit,
          path: 'packages/coreui/lib/src/core_icon.dart',
        );

        final issues = rule.analyzer.analyzeWithResolver(unit, resolver);
        expect(issues, isEmpty);
      });

      test('analyzer exposes correct rule name', () {
        expect(
          rule.analyzer.ruleName,
          equals('forbid_raw_icon_and_image_usage'),
        );
      });

      test('analyzer exposes problem message', () {
        expect(rule.analyzer.problemMessage, isNotEmpty);
        expect(rule.analyzer.problemMessage, contains('Raw Flutter icons'));
      });

      test('analyzer exposes correction message', () {
        expect(rule.analyzer.correctionMessage, isNotEmpty);
        expect(rule.analyzer.correctionMessage, contains('CoreIcons'));
      });
    });
  });
}
