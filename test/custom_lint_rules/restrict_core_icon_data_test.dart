import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:ripplearc_linter/custom_lint_rules/restrict_core_icon_data.dart';
import 'package:test/test.dart';
import '../utils/custom_lint_resolver.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('RestrictCoreIconData', () {
    late RestrictCoreIconData rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = RestrictCoreIconData();
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

    group('CoreIconData.svg() usage', () {
      test('should flag CoreIconData.svg() in app code', () async {
        const source = '''
        class MyWidget {
          void build() {
            final icon = CoreIconData.svg('assets/icon.svg');
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/widgets/my_widget.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag CoreIconData.svg() in test files', () async {
        const source = '''
        void main() {
          test('example', () {
            final icon = CoreIconData.svg('assets/icon.svg');
          });
        }
        ''';
        await analyzeCode(source, path: 'test/widgets/my_widget_test.dart');
        expect(reporter.errors, hasLength(1));
      });

      test(
        'should not flag CoreIconData.svg() in coreui package inside core_icon.dart',
        () async {
          const source = '''
        class CoreIcons {
          static const microsoft = CoreIconData.svg('packages/coreui/assets/microsoft.svg');
        }
        ''';
          await analyzeCode(
            source,
            path: 'packages/coreui/lib/src/components/core_icon.dart',
          );
          expect(reporter.errors, isEmpty);
        },
      );

      test('should not flag CoreIconData.svg() in coreui icons directory', () async {
        const source = '''
        class CoreIcons {
          static const microsoft = CoreIconData.svg('packages/coreui/assets/microsoft.svg');
        }
        ''';
        await analyzeCode(
          source,
          path: 'packages/coreui/lib/src/theme/icons/core_icons.dart',
        );
        expect(reporter.errors, isEmpty);
      });
    });

    group('CoreIconData.material() usage', () {
      test('should flag CoreIconData.material() in app code', () async {
        const source = '''
        class MyWidget {
          void build() {
            final icon = CoreIconData.material(Icons.home);
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/widgets/my_widget.dart');
        expect(reporter.errors, hasLength(1));
      });

      test(
        'should flag CoreIconData.material() in coreui package outside theme folder or core_icon',
        () async {
          const source = '''
        class CoreMaterialIcons {
          static const arrowRight = CoreIconData.material(Icons.keyboard_arrow_right);
        }
        ''';
          await analyzeCode(
            source,
            path: 'packages/coreui/lib/src/components/material_icons.dart',
          );
          expect(reporter.errors, hasLength(1));
        },
      );

      test(
        'should not flag CoreIconData.material() in coreui theme icons folder',
        () async {
          const source = '''
        class CoreMaterialIcons {
          static const arrowRight = CoreIconData.material(Icons.keyboard_arrow_right);
        }
        ''';
          await analyzeCode(
            source,
            path: 'packages/coreui/lib/src/theme/icons/material_icons.dart',
          );
          expect(reporter.errors, isEmpty);
        },
      );
    });

    group('CoreMaterialIcons usage', () {
      test('should flag CoreMaterialIcons usage in app code', () async {
        const source = '''
        class MyWidget {
          void build() {
            final icon = CoreMaterialIcons.arrowRight;
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/widgets/my_widget.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should flag CoreMaterialIcons in construculator app', () async {
        const source = '''
        class MyWidget {
          void build() {
            final icon = CoreMaterialIcons.arrowLeft;
          }
        }
        ''';
        await analyzeCode(
          source,
          path: 'lib/features/calculator/calculator_widget.dart',
        );
        expect(reporter.errors, hasLength(1));
      });

      test(
        'should flag CoreMaterialIcons in coreui test folder (not allowed path)',
        () async {
          const source = '''
        class CoreIcons {
          static const arrowRight = CoreMaterialIcons.arrowRight;
        }
        ''';
          await analyzeCode(
            source,
            path: 'packages/coreui/test/components/core_icon_test.dart',
          );
          expect(reporter.errors, hasLength(1));
        },
      );

      test(
        'should not flag CoreMaterialIcons in coreui icons directory',
        () async {
          const source = '''
        class CoreIcons {
          static const arrowRight = CoreMaterialIcons.arrowRight;
        }
        ''';
          await analyzeCode(
            source,
            path: 'packages/coreui/lib/src/theme/icons/core_icons.dart',
          );
          expect(reporter.errors, isEmpty);
        },
      );
    });

    group('CoreIcons usage (allowed)', () {
      test('should not flag CoreIcons usage in app code', () async {
        const source = '''
        class MyWidget {
          void build() {
            final icon = CoreIcons.arrowRight;
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/widgets/my_widget.dart');
        expect(reporter.errors, isEmpty);
      });

      test('should not flag CoreIcons usage in test files', () async {
        const source = '''
        void main() {
          test('example', () {
            final icon = CoreIcons.microsoft;
          });
        }
        ''';
        await analyzeCode(source, path: 'test/widgets/my_widget_test.dart');
        expect(reporter.errors, isEmpty);
      });
    });

    group('edge cases', () {
      test('should flag multiple CoreIconData usages', () async {
        const source = '''
        class MyWidget {
          void build() {
            final svg = CoreIconData.svg('assets/icon.svg');
            final material = CoreIconData.material(Icons.home);
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/widgets/my_widget.dart');
        expect(reporter.errors, hasLength(2));
      });

      test('should not flag CoreIconData type annotation', () async {
        const source = '''
        class MyWidget {
          CoreIconData getIcon() {
            return CoreIcons.arrowRight;
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/widgets/my_widget.dart');
        expect(reporter.errors, isEmpty);
      });

      test('should not flag unrelated classes', () async {
        const source = '''
        class MyWidget {
          void build() {
            final data = SomeOtherIconData.create();
            final icons = MaterialIcons.home;
          }
        }
        ''';
        await analyzeCode(source, path: 'lib/widgets/my_widget.dart');
        expect(reporter.errors, isEmpty);
      });

      test('should flag const CoreIconData.svg() usage', () async {
        const source = '''
        class MyWidget {
          static const icon = CoreIconData.svg('assets/icon.svg');
        }
        ''';
        await analyzeCode(source, path: 'lib/widgets/my_widget.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should not flag CoreIconData in generic type parameters', () async {
        const source = '''
        class MyWidget {
          List<CoreIconData> getIcons() => [];
        }
        ''';
        await analyzeCode(source, path: 'lib/widgets/my_widget.dart');
        expect(reporter.errors, isEmpty);
      });

      test('should not flag CoreIconData as function parameter type', () async {
        const source = '''
        class MyWidget {
          void setIcon(CoreIconData icon) {}
        }
        ''';
        await analyzeCode(source, path: 'lib/widgets/my_widget.dart');
        expect(reporter.errors, isEmpty);
      });
    });
  });
}
