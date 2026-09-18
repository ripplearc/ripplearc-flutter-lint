import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:ripplearc_linter/custom_lint_rules/forbid_feature_import_outside_provider.dart';
import 'package:test/test.dart';
import '../utils/custom_lint_resolver.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('ForbidFeatureImportOutsideProvider', () {
    late ForbidFeatureImportOutsideProvider rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = ForbidFeatureImportOutsideProvider();
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

    group('violations - deep import from outside the feature', () {
      test(
        'should flag a shell file importing a feature entity directly',
        () async {
          const source = '''
        import 'package:project/features/estimation/domain/entities/estimate.dart';

        void main() {}
        ''';
          await analyzeCode(source, path: '/project/lib/app/enabled_features.dart');
          expect(reporter.errors, hasLength(1));
          expect(
            reporter.errors.first.message.toString(),
            equals(
              'A feature can only be imported from outside through its own provider file.',
            ),
          );
        },
      );

      test('should flag export directive reaching into a feature', () async {
        const source = '''
        export 'package:project/features/estimation/presentation/screens/estimation_page.dart';
        ''';
        await analyzeCode(source, path: '/project/lib/app/shell/tab_module_manager.dart');
        expect(reporter.errors, hasLength(1));
      });

      test(
        'should leave feature-to-feature imports to feature_module_isolation',
        () async {
          // Cross-feature imports are already caught by
          // PreventFeatureModuleDependencies; this rule only polices imports
          // from outside lib/features/ altogether, so it stays silent here.
          const source = '''
        import 'package:project/features/dashboard/data/models/dashboard.dart';

        void main() {}
        ''';
          await analyzeCode(
            source,
            path: '/project/lib/features/auth/presentation/screens/login.dart',
          );
          expect(reporter.errors, isEmpty);
        },
      );

      test('should flag multiple deep imports from different features', () async {
        const source = '''
        import 'package:project/features/auth/data/models/user.dart';
        import 'package:project/features/product/domain/entities/product.dart';

        void main() {}
        ''';
        await analyzeCode(source, path: '/project/lib/app/enabled_features.dart');
        expect(reporter.errors, hasLength(2));
      });
    });

    group('allowed imports - provider file', () {
      test(
        'should not flag importing the feature provider file itself',
        () async {
          const source = '''
        import 'package:project/features/estimation/estimation_feature_module.dart';

        void main() {}
        ''';
          await analyzeCode(source, path: '/project/lib/app/enabled_features.dart');
          expect(reporter.errors, isEmpty);
        },
      );

      test(
        'should not flag a different feature importing another feature\'s provider file',
        () async {
          const source = '''
        import 'package:project/features/dashboard/dashboard_feature_module.dart';

        void main() {}
        ''';
          await analyzeCode(
            source,
            path: '/project/lib/features/auth/presentation/screens/login.dart',
          );
          expect(reporter.errors, isEmpty);
        },
      );

      test(
        'should not confuse another feature\'s file that merely ends with the right suffix pattern for the wrong feature',
        () async {
          const source = '''
        import 'package:project/features/estimation/legacy_estimation_feature_module.dart';

        void main() {}
        ''';
          await analyzeCode(source, path: '/project/lib/app/enabled_features.dart');
          expect(reporter.errors, hasLength(1));
        },
      );
    });

    group('allowed imports - inside the feature itself', () {
      test('should not apply the rule to files inside the feature', () async {
        const source = '''
        import 'package:project/features/estimation/domain/entities/estimate.dart';
        import 'package:project/features/estimation/data/repositories/estimation_repo.dart';

        void main() {}
        ''';
        await analyzeCode(
          source,
          path: '/project/lib/features/estimation/estimation_feature_module.dart',
        );
        expect(reporter.errors, isEmpty);
      });

      test('should not flag relative imports within the same feature', () async {
        const source = '''
        import '../domain/entities/estimate.dart';

        void main() {}
        ''';
        await analyzeCode(
          source,
          path: '/project/lib/features/estimation/presentation/screens/estimation_page.dart',
        );
        expect(reporter.errors, isEmpty);
      });
    });

    group('allowed imports - external packages', () {
      test('should not flag Flutter SDK or third-party imports', () async {
        const source = '''
        import 'package:flutter/material.dart';
        import 'package:provider/provider.dart';

        void main() {}
        ''';
        await analyzeCode(source, path: '/project/lib/app/enabled_features.dart');
        expect(reporter.errors, isEmpty);
      });

      test(
        'should not flag a package whose name contains "features" but has no such path segment',
        () async {
          const source = '''
        import 'package:featurestore/featurestore.dart';

        void main() {}
        ''';
          await analyzeCode(source, path: '/project/lib/app/enabled_features.dart');
          expect(reporter.errors, isEmpty);
        },
      );
    });

    group('edge cases', () {
      test('should handle feature names with underscores', () async {
        const source = '''
        import 'package:project/features/global_search/data/models/result.dart';

        void main() {}
        ''';
        await analyzeCode(source, path: '/project/lib/app/enabled_features.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('should not flag star imports without a feature path', () async {
        const source = '''
        import 'package:project/core/constants/constants.dart' as constants;

        void main() {}
        ''';
        await analyzeCode(source, path: '/project/lib/app/enabled_features.dart');
        expect(reporter.errors, isEmpty);
      });

      test('should handle Windows-style paths for the provider file itself', () async {
        const source = '''
        import 'package:project/features/estimation/estimation_feature_module.dart';

        void main() {}
        ''';
        await analyzeCode(source, path: r'C:\project\lib\app\enabled_features.dart');
        expect(reporter.errors, isEmpty);
      });
    });
  });
}
