import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:ripplearc_linter_test/custom_lint_rules/avoid_static_colors.dart';
import 'package:test/test.dart';
import '../utils/custom_lint_resolver.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('AvoidStaticColors', () {
    late AvoidStaticColors rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = AvoidStaticColors();
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

    group('CoreUI color token classes', () {
      test('should flag CoreTextColors usage', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        class MyWidget extends StatelessWidget {
          @override
          Widget build(BuildContext context) {
            return Text(
              'Hello',
              style: TextStyle(color: CoreTextColors.headline),
            );
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag CoreBackgroundColors usage', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        class MyWidget extends StatelessWidget {
          @override
          Widget build(BuildContext context) {
            return Scaffold(
              backgroundColor: CoreBackgroundColors.pageBackground,
            );
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag CoreBorderColors usage', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        class MyWidget extends StatelessWidget {
          @override
          Widget build(BuildContext context) {
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: CoreBorderColors.lineLight),
              ),
            );
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag CoreIconColors usage', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        class MyWidget extends StatelessWidget {
          @override
          Widget build(BuildContext context) {
            return Icon(Icons.home, color: CoreIconColors.dark);
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag CoreButtonColors usage', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        class MyWidget extends StatelessWidget {
          @override
          Widget build(BuildContext context) {
            return Container(color: CoreButtonColors.surface);
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag CoreStatusColors usage', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        class MyWidget extends StatelessWidget {
          @override
          Widget build(BuildContext context) {
            return Icon(Icons.error, color: CoreStatusColors.error);
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag CoreChipColors usage', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        class MyWidget extends StatelessWidget {
          @override
          Widget build(BuildContext context) {
            return Container(color: CoreChipColors.primary);
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag CoreAlertColors usage', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        class MyWidget extends StatelessWidget {
          @override
          Widget build(BuildContext context) {
            return Container(color: CoreAlertColors.red);
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag CoreKeyboardColors usage', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        class MyWidget extends StatelessWidget {
          @override
          Widget build(BuildContext context) {
            return Container(color: CoreKeyboardColors.numbers);
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag CoreShadowColors usage', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        class MyWidget extends StatelessWidget {
          @override
          Widget build(BuildContext context) {
            return Container(
              decoration: BoxDecoration(
                boxShadow: [BoxShadow(color: CoreShadowColors.shadowGrey5)],
              ),
            );
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag CoreBrandColors usage', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        class MyWidget extends StatelessWidget {
          @override
          Widget build(BuildContext context) {
            return Container(color: CoreBrandColors.orient);
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag multiple CoreUI color usages', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        class MyWidget extends StatelessWidget {
          @override
          Widget build(BuildContext context) {
            return Container(
              color: CoreBackgroundColors.pageBackground,
              child: Text(
                'Hello',
                style: TextStyle(color: CoreTextColors.headline),
              ),
            );
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(2));
      });
    });

    group('Flutter Colors class', () {
      test('should flag Colors.white usage', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        class MyWidget extends StatelessWidget {
          @override
          Widget build(BuildContext context) {
            return Container(color: Colors.white);
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag Colors.black usage', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        class MyWidget extends StatelessWidget {
          @override
          Widget build(BuildContext context) {
            return Container(color: Colors.black);
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag Colors.transparent usage', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        class MyWidget extends StatelessWidget {
          @override
          Widget build(BuildContext context) {
            return Container(color: Colors.transparent);
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag Colors.grey usage', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        class MyWidget extends StatelessWidget {
          @override
          Widget build(BuildContext context) {
            return Container(color: Colors.grey);
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag Colors.grey[700] index access', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        class MyWidget extends StatelessWidget {
          @override
          Widget build(BuildContext context) {
            return Container(color: Colors.grey[700]);
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        // Should flag both the PrefixedIdentifier (Colors.grey) and IndexExpression
        expect(reporter.errors, hasLength(2));
      });

      test('should flag Colors.red usage', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        class MyWidget extends StatelessWidget {
          @override
          Widget build(BuildContext context) {
            return Container(color: Colors.red);
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag Colors.blue usage', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        class MyWidget extends StatelessWidget {
          @override
          Widget build(BuildContext context) {
            return Container(color: Colors.blue);
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
      });
    });

    group('Direct hex Color definitions', () {
      test('should flag Color(0xFF...) hex definition', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        class MyWidget extends StatelessWidget {
          @override
          Widget build(BuildContext context) {
            return Container(color: Color(0xFF015B7C));
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag Color(0xFFFFFFFF) white hex definition', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        class MyWidget extends StatelessWidget {
          @override
          Widget build(BuildContext context) {
            return Container(color: Color(0xFFFFFFFF));
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag Color.fromARGB usage', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        class MyWidget extends StatelessWidget {
          @override
          Widget build(BuildContext context) {
            return Container(color: Color.fromARGB(255, 0, 0, 0));
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag Color.fromRGBO usage', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        class MyWidget extends StatelessWidget {
          @override
          Widget build(BuildContext context) {
            return Container(color: Color.fromRGBO(255, 255, 255, 1.0));
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, hasLength(1));
      });
    });

    group('Test file exclusion', () {
      test('should not flag violations in test files', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        void main() {
          testWidgets('my test', (tester) async {
            await tester.pumpWidget(
              Container(
                color: Colors.white,
                child: Text(
                  'Test',
                  style: TextStyle(color: CoreTextColors.headline),
                ),
              ),
            );
          });
        }
        ''';
        await analyzeCode(source, path: 'test/my_widget_test.dart');
        expect(reporter.errors, isEmpty);
      });
    });

    group('Correct usage - no violations', () {
      test('should not flag Theme.of(context).extension usage', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        class MyWidget extends StatelessWidget {
          @override
          Widget build(BuildContext context) {
            final colors = Theme.of(context).extension<AppColorsExtension>()!;
            return Container(
              color: colors.pageBackground,
              child: Text(
                'Hello',
                style: TextStyle(color: colors.textHeadline),
              ),
            );
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, isEmpty);
      });

      test('should not flag non-color class prefixed identifiers', () async {
        const source = '''
        import 'package:flutter/material.dart';
        
        class MyWidget extends StatelessWidget {
          @override
          Widget build(BuildContext context) {
            return Text(MyStrings.hello);
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/my_widget.dart');
        expect(reporter.errors, isEmpty);
      });
    });
  });
}



