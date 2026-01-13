import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:ripplearc_linter/custom_lint_rules/prevent_library_module_dependencies.dart';
import 'package:test/test.dart';
import '../utils/custom_lint_resolver.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('PreventLibraryModuleDependencies', () {
    late PreventLibraryModuleDependencies rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;

    setUp(() {
      rule = PreventLibraryModuleDependencies();
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

    group('library module violations', () {
      test('should flag when library imports from auth feature', () async {
        const source = '''
        import 'package:project/features/auth/data/models/auth_user.dart';
        
        void main() {
          print('Hello');
        }
        ''';
        await analyzeCode(
          source,
          path: '/project/lib/libraries/config/data/config_impl.dart',
        );
        expect(reporter.errors, hasLength(1));
        expect(
          reporter.errors.first.message.toString(),
          equals('Library modules must not import feature modules.'),
        );
      });

      test('should flag when library imports from dashboard feature', () async {
        const source = '''
        import 'package:project/features/dashboard/presentation/pages/dashboard_page.dart';
        
        void main() {
          print('Hello');
        }
        ''';
        await analyzeCode(
          source,
          path: '/project/lib/libraries/router/router_impl.dart',
        );
        expect(reporter.errors, hasLength(1));
      });

      test('should flag export directive from a feature module', () async {
        const source = '''
        export 'package:project/features/estimation/domain/entities/estimation.dart';
        ''';
        await analyzeCode(
          source,
          path: '/project/lib/libraries/project/project_library.dart',
        );
        expect(reporter.errors, hasLength(1));
      });

      test('should flag multiple imports from different features', () async {
        const source = '''
        import 'package:project/features/auth/data/models/user.dart';
        import 'package:project/features/dashboard/domain/entities/dashboard.dart';
        import 'package:project/features/estimation/data/models/estimation.dart';
        
        void main() {}
        ''';
        await analyzeCode(
          source,
          path: '/project/lib/libraries/storage/storage_impl.dart',
        );
        expect(reporter.errors, hasLength(3));
      });

      test('should flag relative import containing features path', () async {
        const source = '''
        import '../features/auth/data/models/user.dart';
        
        void main() {}
        ''';
        await analyzeCode(
          source,
          path: '/project/lib/libraries/auth/auth_manager.dart',
        );
        expect(reporter.errors, hasLength(1));
      });
    });

    group('allowed imports - other libraries', () {
      test(
        'should not flag when library imports from another library',
        () async {
          const source = '''
        import 'package:project/libraries/time/interfaces/clock.dart';
        import 'package:project/libraries/either/interfaces/either.dart';
        import 'package:project/libraries/config/interfaces/config.dart';
        
        void main() {
          print('Hello');
        }
        ''';
          await analyzeCode(
            source,
            path: '/project/lib/libraries/auth/auth_manager.dart',
          );
          expect(reporter.errors, isEmpty);
        },
      );

      test('should not flag relative imports within libraries', () async {
        const source = '''
        import '../interfaces/auth_repository.dart';
        import '../data/models/auth_user.dart';
        
        void main() {
          print('Hello');
        }
        ''';
        await analyzeCode(
          source,
          path: '/project/lib/libraries/auth/repositories/supabase_impl.dart',
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
          path: '/project/lib/libraries/router/router_impl.dart',
        );
        expect(reporter.errors, isEmpty);
      });

      test('should not flag third-party package imports', () async {
        const source = '''
        import 'package:flutter_modular/flutter_modular.dart';
        import 'package:freezed_annotation/freezed_annotation.dart';
        import 'package:supabase/supabase.dart';
        
        void main() {
          print('Hello');
        }
        ''';
        await analyzeCode(
          source,
          path: '/project/lib/libraries/supabase/supabase_wrapper.dart',
        );
        expect(reporter.errors, isEmpty);
      });

      test('should not flag Dart SDK imports', () async {
        const source = '''
        import 'dart:async';
        import 'dart:convert';
        
        void main() {
          print('Hello');
        }
        ''';
        await analyzeCode(
          source,
          path: '/project/lib/libraries/storage/storage_service.dart',
        );
        expect(reporter.errors, isEmpty);
      });
    });

    group('non-library files', () {
      test(
        'should not apply rule to files outside libraries directory',
        () async {
          const source = '''
        import 'package:project/features/auth/data/models/user.dart';
        import 'package:project/features/dashboard/domain/entities/dashboard.dart';
        
        void main() {
          print('Hello');
        }
        ''';
          await analyzeCode(source, path: '/project/lib/main.dart');
          expect(reporter.errors, isEmpty);
        },
      );

      test('should not apply rule to files in features directory', () async {
        const source = '''
        import 'package:project/features/auth/data/models/user.dart';
        
        void main() {
          print('Hello');
        }
        ''';
        await analyzeCode(
          source,
          path:
              '/project/lib/features/dashboard/presentation/pages/dashboard.dart',
        );
        expect(reporter.errors, isEmpty);
      });

      test('should not apply rule to files in app layer', () async {
        const source = '''
        import 'package:project/features/auth/data/models/user.dart';
        
        void main() {
          print('Hello');
        }
        ''';
        await analyzeCode(source, path: '/project/lib/app/app.dart');
        expect(reporter.errors, isEmpty);
      });
    });

    group('edge cases', () {
      test('should handle deeply nested library directories', () async {
        const source = '''
        import 'package:project/features/auth/data/models/user.dart';
        
        void main() {}
        ''';
        await analyzeCode(
          source,
          path:
              '/project/lib/libraries/auth/data/models/credentials/auth_credential.dart',
        );
        expect(reporter.errors, hasLength(1));
      });

      test('should handle library names with underscores', () async {
        const source = '''
        import 'package:project/features/user_profile/data/models/profile.dart';
        
        void main() {}
        ''';
        await analyzeCode(
          source,
          path: '/project/lib/libraries/user_auth/auth_manager.dart',
        );
        expect(reporter.errors, hasLength(1));
      });

      test(
        'should not flag if features appears in package name but not in path',
        () async {
          const source = '''
        import 'package:auth_features/models/auth.dart'; // External package with 'features' in name
        
        void main() {}
        ''';
          await analyzeCode(
            source,
            path: '/project/lib/libraries/auth/auth_manager.dart',
          );
          expect(reporter.errors, isEmpty);
        },
      );

      test('should handle mixed valid and invalid imports', () async {
        const source = '''
        import 'package:flutter/material.dart';
        import 'package:project/libraries/time/interfaces/clock.dart';
        import 'package:project/features/auth/data/models/user.dart';
        import 'package:project/libraries/config/config.dart';
        import 'package:project/features/dashboard/domain/entities/dashboard.dart';
        import 'package:supabase/supabase.dart';
        
        void main() {}
        ''';
        await analyzeCode(
          source,
          path: '/project/lib/libraries/auth/auth_manager.dart',
        );
        expect(reporter.errors, hasLength(2));
      });

      test('should handle Windows-style paths', () async {
        const source = '''
        import 'package:project/features/auth/data/models/user.dart';
        
        void main() {}
        ''';
        await analyzeCode(
          source,
          path: r'C:\project\lib\libraries\config\config_impl.dart',
        );
        expect(reporter.errors, hasLength(1));
      });

      test('should apply to test files in libraries', () async {
        const source = '''
        import 'package:project/features/auth/data/models/user.dart';
        
        void main() {}
        ''';
        await analyzeCode(
          source,
          path: '/project/test/libraries/auth/auth_manager_test.dart',
        );
        expect(reporter.errors, hasLength(1));
      });
    });

    group('error message quality', () {
      test('error message should be clear and actionable', () async {
        const source = '''
        import 'package:project/features/auth/data/models/user.dart';
        
        void main() {}
        ''';
        await analyzeCode(
          source,
          path: '/project/lib/libraries/config/config_impl.dart',
        );

        expect(reporter.errors, hasLength(1));
        final message = reporter.errors.first.message.toString();
        expect(
          message,
          equals('Library modules must not import feature modules.'),
        );
      });
    });

    group('construculator-app specific scenarios', () {
      test('should flag auth library importing from auth feature', () async {
        const source = '''
        import 'package:construculator/features/auth/presentation/pages/login_page.dart';
        
        void main() {}
        ''';
        await analyzeCode(
          source,
          path: '/construculator/lib/libraries/auth/auth_library_module.dart',
        );
        expect(reporter.errors, hasLength(1));
      });

      test(
        'should flag project library importing from project feature',
        () async {
          const source = '''
        import 'package:construculator/features/project/presentation/widgets/project_header_app_bar.dart';
        
        void main() {}
        ''';
          await analyzeCode(
            source,
            path:
                '/construculator/lib/libraries/project/project_library_module.dart',
          );
          expect(reporter.errors, hasLength(1));
        },
      );

      test('should allow project library importing from time library', () async {
        const source = '''
        import 'package:construculator/libraries/time/interfaces/clock.dart';
        
        void main() {}
        ''';
        await analyzeCode(
          source,
          path:
              '/construculator/lib/libraries/project/data/repositories/project_repository_impl.dart',
        );
        expect(reporter.errors, isEmpty);
      });

      test('should allow auth library importing from supabase library', () async {
        const source = '''
        import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
        
        void main() {}
        ''';
        await analyzeCode(
          source,
          path:
              '/construculator/lib/libraries/auth/repositories/supabase_repository_impl.dart',
        );
        expect(reporter.errors, isEmpty);
      });
    });
  });
}
