import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:ripplearc_linter/custom_lint_rules/avoid_static_colors_agent_test.dart';
import 'package:test/test.dart';
import '../utils/custom_lint_resolver.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('AvoidStaticColorsAgentTest', () {
    late AvoidStaticColorsAgentTest rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = AvoidStaticColorsAgentTest();
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

    group('CoreUI static color tokens - Bad examples', () {
      test('should flag CoreTextColors usage', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        void main() {
          final style = TextStyle(color: CoreTextColors.headline);
        }
        
        class CoreTextColors {
          static const headline = Color(0xFF000000);
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
        expect(reporter.errors.first.message, contains('CoreTextColors'));
      });

      test('should flag CoreBackgroundColors usage', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        void main() {
          final color = CoreBackgroundColors.pageBackground;
        }
        
        class CoreBackgroundColors {
          static const pageBackground = Color(0xFFFFFFFF);
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
        expect(reporter.errors.first.message, contains('CoreBackgroundColors'));
      });

      test('should flag CoreBorderColors usage', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        void main() {
          final color = CoreBorderColors.divider;
        }
        
        class CoreBorderColors {
          static const divider = Color(0xFFE0E0E0);
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
        expect(reporter.errors.first.message, contains('CoreBorderColors'));
      });
    });

    group('Flutter Colors class - Bad examples', () {
      test('should flag Colors.white usage', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        void main() {
          final widget = Container(color: Colors.white);
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
        expect(reporter.errors.first.message, contains('Colors'));
      });

      test('should flag Colors with index access', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        void main() {
          final widget = Container(color: Colors.grey[700]);
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
        expect(reporter.errors.first.message, contains('Colors'));
      });

      test('should flag multiple Colors usage', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        void main() {
          final widget1 = Container(color: Colors.white);
          final widget2 = Container(color: Colors.black);
          final widget3 = Container(color: Colors.red);
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(3));
      });
    });

    group('CupertinoColors - Bad examples', () {
      test('should flag CupertinoColors.systemRed usage', () async {
        const source = '''
        import 'package:flutter/cupertino.dart';
        
        void main() {
          final widget = Container(color: CupertinoColors.systemRed);
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
        expect(reporter.errors.first.message, contains('CupertinoColors'));
      });
    });

    group('Direct Color definitions - Bad examples', () {
      test('should flag Color(0xFF...) usage', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        void main() {
          final widget = Container(color: Color(0xFF015B7C));
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
        expect(reporter.errors.first.message, contains('Direct color definition'));
      });

      test('should flag Color.fromARGB usage', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        void main() {
          final widget = Container(color: Color.fromARGB(255, 0, 0, 0));
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
        expect(reporter.errors.first.message, contains('Direct color definition'));
      });

      test('should flag multiple direct color definitions', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        void main() {
          final color1 = Color(0xFF015B7C);
          final color2 = Color.fromARGB(255, 0, 0, 0);
          final color3 = Color.fromRGBO(255, 255, 255, 1.0);
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(3));
      });
    });

    group('Prefixed imports - Bad examples', () {
      test('should flag prefixed Colors usage', () async {
        const source = '''
        import 'package:flutter/material.dart' as material;
        
        void main() {
          final widget = Container(color: material.Colors.red);
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
        expect(reporter.errors.first.message, contains('prefixed import'));
      });
    });

    group('Good examples - should not flag', () {
      test('should not flag Theme.of(context).extension usage', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        void main(BuildContext context) {
          final colors = Theme.of(context).extension<AppColorsExtension>()!;
          final widget = Text(
            'Hello',
            style: TextStyle(color: colors.textHeadline),
          );
        }
        
        class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
          final Color textHeadline;
          AppColorsExtension({required this.textHeadline});
          
          @override
          ThemeExtension<AppColorsExtension> copyWith() => this;
          
          @override
          ThemeExtension<AppColorsExtension> lerp(ThemeExtension<AppColorsExtension>? other, double t) => this;
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, isEmpty);
      });

      test('should not flag colors accessed from theme extension', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        void main(BuildContext context) {
          final colors = Theme.of(context).extension<AppColorsExtension>()!;
          final widget1 = Container(color: colors.pageBackground);
          final widget2 = Container(color: colors.lineLight);
          final style = TextStyle(color: colors.textHeadline);
        }
        
        class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
          final Color pageBackground;
          final Color lineLight;
          final Color textHeadline;
          AppColorsExtension({
            required this.pageBackground,
            required this.lineLight,
            required this.textHeadline,
          });
          
          @override
          ThemeExtension<AppColorsExtension> copyWith() => this;
          
          @override
          ThemeExtension<AppColorsExtension> lerp(ThemeExtension<AppColorsExtension>? other, double t) => this;
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, isEmpty);
      });

      test('should not flag non-color related classes', () async {
        const source = '''
        void main() {
          final text = MyTextColors.headline;
          final number = Numbers.one;
        }
        
        class MyTextColors {
          static const headline = 'headline';
        }
        
        class Numbers {
          static const one = 1;
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, isEmpty);
      });
    });

    group('File scoping', () {
      test('should flag violations in test files (includeTests: true)', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        void main() {
          final widget = Container(color: Colors.white);
        }
        ''';
        await analyzeCode(source, path: 'test/my_widget_test.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should skip violations in theme directory', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        class AppColors {
          static const primary = Colors.blue;
          static const secondary = Color(0xFF015B7C);
        }
        ''';
        await analyzeCode(source, path: 'lib/src/theme/app_colors.dart');
        expect(reporter.errors, isEmpty);
      });

      test('should skip violations in test/theme directory', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        void main() {
          final color = Colors.white;
        }
        ''';
        await analyzeCode(source, path: 'test/theme/theme_test.dart');
        expect(reporter.errors, isEmpty);
      });
    });

    group('Rule metadata', () {
      test('should have correct rule name', () {
        expect(rule.code.name, equals('avoid_static_colors_agent_test'));
      });

      test('should have problem message mentioning AppColorsExtension', () {
        expect(rule.code.problemMessage, contains('Theme.of(context).extension<AppColorsExtension>()'));
      });

      test('should have correction message with guidance', () {
        expect(rule.code.correctionMessage, contains('Theme.of(context).extension<AppColorsExtension>()'));
        expect(rule.code.correctionMessage, contains('light/dark mode'));
      });
    });

    group('Edge cases', () {
      test('should flag Colors in nested expressions', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        void main() {
          final color = someCondition ? Colors.white : Colors.black;
        }
        
        final someCondition = true;
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(2));
      });

      test('should flag Colors in lambda expressions', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        void main() {
          final getColor = () => Colors.white;
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag CoreTextColors in constructor initializer', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        class MyWidget {
          final Color textColor;
          MyWidget() : textColor = CoreTextColors.headline;
        }
        
        class CoreTextColors {
          static const headline = Color(0xFF000000);
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
      });
    });
  });
}
