import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:ripplearc_linter/custom_lint_rules/prevent_feature_module_dependencies.dart';
import 'package:test/test.dart';
import '../utils/custom_lint_resolver.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('PreventFeatureModuleDependencies', () {
    late PreventFeatureModuleDependencies rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = PreventFeatureModuleDependencies();
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

    group('feature module violations', () {
      test(
        'should flag when auth feature imports from dashboard feature',
        () async {
          const source = '''
        import 'package:project/features/dashboard/data/models/dashboard.dart';
        
        void main() {
          print('Hello');
        }
        ''';
          await analyzeCode(
            source,
            path: '/project/lib/features/auth/presentation/screens/login.dart',
          );
          expect(reporter.errors, hasLength(1));
          expect(
            reporter.errors.first.message.toString(),
            equals(
              'Avoid importing from other feature modules; extract shared code to core/shared layers or a common package.',
            ),
          );
        },
      );

      test(
        'should flag when dashboard feature imports from auth feature',
        () async {
          const source = '''
        import 'package:project/features/auth/data/models/user.dart';
        
        void main() {
          print('Hello');
        }
        ''';
          await analyzeCode(
            source,
            path:
                '/project/lib/features/product/presentation/screens/product_list.dart',
          );
          expect(reporter.errors, hasLength(1));
        },
      );

      test('should flag export directive from another feature', () async {
        const source = '''
        export 'package:project/features/payment/domain/entities/payment.dart';
        ''';
        await analyzeCode(
          source,
          path:
              '/project/lib/features/checkout/presentation/pages/checkout_page.dart',
        );
        expect(reporter.errors, hasLength(1));
      });

      test('should flag multiple imports from different features', () async {
        const source = '''
        import 'package:project/features/auth/data/models/user.dart';
        import 'package:project/features/product/domain/entities/product.dart';
        import 'package:project/features/payment/data/models/transaction.dart';
        
        void main() {}
        ''';
        await analyzeCode(
          source,
          path:
              '/project/lib/features/order/presentation/pages/order_page.dart',
        );
        expect(reporter.errors, hasLength(3));
      });
    });

    group('allowed imports - same feature', () {
      test('should not flag when feature imports from itself', () async {
        const source = '''
        import 'package:project/features/auth/data/models/user.dart';
        import 'package:project/features/auth/presentation/widgets/login_form.dart';
        import 'package:project/features/auth/domain/entities/auth_entity.dart';
        
        void main() {
          print('Hello');
        }
        ''';
        await analyzeCode(
          source,
          path: '/project/lib/features/auth/presentation/screens/login.dart',
        );
        expect(reporter.errors, isEmpty);
      });

      test('should not flag relative imports within same feature', () async {
        const source = '''
        import '../data/models/user.dart';
        import '../domain/repositories/auth_repo.dart';
        
        void main() {
          print('Hello');
        }
        ''';
        await analyzeCode(
          source,
          path: '/project/lib/features/auth/presentation/screens/login.dart',
        );
        expect(reporter.errors, isEmpty);
      });
    });

    group('allowed imports - core and shared layers', () {
      test('should not flag imports from core layer', () async {
        const source = '''
        import 'package:project/core/constants/app_constants.dart';
        import 'package:project/core/utils/validators.dart';
        
        void main() {
          print('Hello');
        }
        ''';
        await analyzeCode(
          source,
          path: '/project/lib/features/auth/presentation/screens/login.dart',
        );
        expect(reporter.errors, isEmpty);
      });

      test('should not flag imports from shared layer', () async {
        const source = '''
        import 'package:project/shared/widgets/app_button.dart';
        import 'package:project/shared/themes/app_theme.dart';
        
        void main() {
          print('Hello');
        }
        ''';
        await analyzeCode(
          source,
          path: '/project/lib/features/auth/presentation/screens/login.dart',
        );
        expect(reporter.errors, isEmpty);
      });

      test('should not flag imports from utilities layer', () async {
        const source = '''
        import 'package:project/utils/helpers/string_helper.dart';
        
        void main() {
          print('Hello');
        }
        ''';
        await analyzeCode(
          source,
          path: '/project/lib/features/auth/presentation/screens/login.dart',
        );
        expect(reporter.errors, isEmpty);
      });
    });

    group('allowed imports - external packages', () {
      test('should not flag Flutter SDK imports', () async {
        const source = '''
        import 'package:flutter/material.dart';
        import 'package:flutter/cupertino.dart';
        
        void main() {
          print('Hello');
        }
        ''';
        await analyzeCode(
          source,
          path: '/project/lib/features/auth/presentation/screens/login.dart',
        );
        expect(reporter.errors, isEmpty);
      });

      test('should not flag third-party package imports', () async {
        const source = '''
        import 'package:provider/provider.dart';
        import 'package:get_it/get_it.dart';
        import 'package:dio/dio.dart';
        
        void main() {
          print('Hello');
        }
        ''';
        await analyzeCode(
          source,
          path: '/project/lib/features/auth/presentation/screens/login.dart',
        );
        expect(reporter.errors, isEmpty);
      });

      test('should not flag dev_dependencies', () async {
        const source = '''
        import 'package:test/test.dart';
        import 'package:mocktail/mocktail.dart';
        
        void main() {
          print('Hello');
        }
        ''';
        await analyzeCode(
          source,
          path: '/project/lib/features/auth/presentation/screens/login.dart',
        );
        expect(reporter.errors, isEmpty);
      });
    });

    group('non-feature files', () {
      test(
        'should not apply rule to files outside features directory',
        () async {
          const source = '''
        import 'package:project/features/auth/data/models/user.dart';
        import 'package:project/features/product/data/models/product.dart';
        
        void main() {
          print('Hello');
        }
        ''';
          // This is in the root lib directory, not in features
          await analyzeCode(source, path: '/project/lib/main.dart');
          expect(reporter.errors, isEmpty);
        },
      );

      test('should not apply rule to files in app layer', () async {
        const source = '''
        import 'package:project/features/auth/data/models/user.dart';
        import 'package:project/features/product/data/models/product.dart';
        
        void main() {
          print('Hello');
        }
        ''';
        await analyzeCode(source, path: '/project/lib/app/app.dart');
        expect(reporter.errors, isEmpty);
      });

      test('should not apply rule to core layer files', () async {
        const source = '''
        import 'package:project/features/auth/data/models/user.dart';
        
        void main() {
          print('Hello');
        }
        ''';
        await analyzeCode(
          source,
          path: '/project/lib/core/di/service_locator.dart',
        );
        expect(reporter.errors, isEmpty);
      });

      test('should not apply rule to shared layer files', () async {
        const source = '''
        import 'package:project/features/auth/data/models/user.dart';
        import 'package:project/features/product/domain/entities/product.dart';
        
        void main() {
          print('Hello');
        }
        ''';
        await analyzeCode(
          source,
          path: '/project/lib/shared/widgets/app_button.dart',
        );
        expect(reporter.errors, isEmpty);
      });
    });

    group('edge cases', () {
      test('should handle deeply nested feature directories', () async {
        const source = '''
        import 'package:project/features/product/data/models/product.dart';
        
        void main() {}
        ''';
        await analyzeCode(
          source,
          path:
              '/project/lib/features/auth/presentation/pages/screens/login/widgets/email_field.dart',
        );
        expect(reporter.errors, hasLength(1));
      });

      test('should handle feature names with underscores', () async {
        const source = '''
        import 'package:project/features/user_profile/data/models/profile.dart';
        
        void main() {}
        ''';
        await analyzeCode(
          source,
          path:
              '/project/lib/features/auth_service/presentation/screens/login.dart',
        );
        expect(reporter.errors, hasLength(1));
      });

      test(
        'should not flag if feature name appears in package name but not in path',
        () async {
          const source = '''
        import 'package:auth_provider/models/auth.dart'; // This is external package, not a feature
        
        void main() {}
        ''';
          await analyzeCode(
            source,
            path: '/project/lib/features/auth/presentation/screens/login.dart',
          );
          expect(reporter.errors, isEmpty);
        },
      );

      test('should handle mixed valid and invalid imports', () async {
        const source = '''
        import 'package:flutter/material.dart';
        import 'package:project/core/constants/constants.dart';
        import 'package:project/features/product/data/models/product.dart';
        import 'package:project/shared/widgets/button.dart';
        import 'package:project/features/payment/models/payment.dart';
        import 'package:provider/provider.dart';
        
        void main() {}
        ''';
        await analyzeCode(
          source,
          path: '/project/lib/features/auth/presentation/screens/login.dart',
        );
        expect(
          reporter.errors,
          hasLength(2),
        ); // Only the feature imports should be flagged
      });

      test('should work in test files within features', () async {
        const source = '''
        import 'package:test/test.dart';
        import 'package:project/features/product/data/models/product.dart';
        
        void main() {
          test('should work', () {});
        }
        ''';
        await analyzeCode(
          source,
          path:
              '/project/lib/features/auth/presentation/screens/login_test.dart',
        );
        expect(reporter.errors, hasLength(1));
      });

      test('should not flag star imports without feature path', () async {
        const source = '''
        import 'package:project/core/constants/constants.dart' as constants;
        
        void main() {}
        ''';
        await analyzeCode(
          source,
          path: '/project/lib/features/auth/presentation/screens/login.dart',
        );
        expect(reporter.errors, isEmpty);
      });

      test('should handle Windows-style paths', () async {
        const source = '''
        import 'package:project/features/product/data/models/product.dart';
        
        void main() {}
        ''';
        // Windows path with backslashes
        await analyzeCode(
          source,
          path: r'C:\project\lib\features\auth\presentation\screens\login.dart',
        );
        expect(reporter.errors, hasLength(1));
      });
    });

    group('error message quality', () {
      test('error message should be clear and actionable', () async {
        const source = '''
        import 'package:project/features/payment/models/payment.dart';
        
        void main() {}
        ''';
        await analyzeCode(
          source,
          path:
              '/project/lib/features/checkout/presentation/pages/checkout.dart',
        );

        expect(reporter.errors, hasLength(1));
        final message = reporter.errors.first.message.toString();
        expect(
          message,
          equals(
            'Avoid importing from other feature modules; extract shared code to core/shared layers or a common package.',
          ),
        );
      });
    });
  });
}
