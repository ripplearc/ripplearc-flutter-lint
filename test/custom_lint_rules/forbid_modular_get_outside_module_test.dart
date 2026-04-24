import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:ripplearc_linter/custom_lint_rules/forbid_modular_get_outside_module.dart';
import 'package:test/test.dart';
import '../utils/custom_lint_resolver.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('ForbidModularGetOutsideModule', () {
    late ForbidModularGetOutsideModule rule;
    late TestErrorReporter reporter;
    late CompilationUnit unit;
    final tempDirectories = <Directory>[];

    setUp(() {
      rule = ForbidModularGetOutsideModule();
    });

    tearDown(() async {
      for (final directory in tempDirectories) {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      }
      tempDirectories.clear();
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

    group('Modular.get in production files', () {
      test('flags Modular.get in a bloc', () async {
        const source = r'''
        class Modular {
          static T get<T>() => throw UnimplementedError();
        }
        class ProjectRepository {}
        class ProjectDropdownBloc {
          ProjectDropdownBloc() {
            final repo = Modular.get<ProjectRepository>();
          }
        }
        ''';
        await analyzeCode(
          source,
          path: '/lib/features/project_dropdown_bloc.dart',
        );
        expect(reporter.errors, hasLength(1));
      });

      test('flags Modular.get in a non-bloc lib file', () async {
        const source = r'''
        class Modular {
          static T get<T>() => throw UnimplementedError();
        }
        class Foo {}
        void main() {
          Modular.get<Foo>();
        }
        ''';
        await analyzeCode(source, path: '/lib/some_widget.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('does not flag Modular.get<AppRouter>() outside a module', () async {
        const source = r'''
        class Modular {
          static T get<T>() => throw UnimplementedError();
        }
        class AppRouter {}
        class NavigationService {
          NavigationService() {
            final router = Modular.get<AppRouter>();
          }
        }
        ''';
        await analyzeCode(source, path: '/lib/navigation_service.dart');
        expect(reporter.errors, isEmpty);
      });

      test('flags import-prefixed Modular.get', () async {
        await analyzeCode(r'''
import 'no_such_lib.dart' as fm;

class R {}
class S {}
class MyService {
  MyService() {
    fm.Modular.get<R>();
  }
}
''', path: '/lib/prefixed_service.dart');
        expect(reporter.errors, hasLength(1));
      });

      test('flags Modular.get in a fake file inside lib', () async {
        const source = r'''
        class Modular {
          static T get<T>() => throw UnimplementedError();
        }
        class FakeService {
          void doSomething() {
            Modular.get<int>();
          }
        }
        ''';
        await analyzeCode(source, path: '/lib/testing/fake_service.dart');
        expect(reporter.errors, hasLength(1));
      });
    });

    group('allowed locations', () {
      test(
        'does not flag Modular.get inside StatelessWidget classes',
        () async {
          const source = r'''
        class Modular {
          static T get<T>() => throw UnimplementedError();
        }
        class StatelessWidget {}
        class BuildContext {}
        class FeatureController {}
        class LoginPage extends StatelessWidget {
          Object build(BuildContext context) {
            return Modular.get<FeatureController>();
          }
        }
        ''';
          await analyzeCode(source, path: '/lib/login_page.dart');
          expect(reporter.errors, isEmpty);
        },
      );

      test('does not flag Modular.get inside StatefulWidget classes', () async {
        const source = r'''
        class Modular {
          static T get<T>() => throw UnimplementedError();
        }
        class StatefulWidget {}
        class FeatureController {}
        class LoginFlow extends StatefulWidget {
          void open() {
            Modular.get<FeatureController>();
          }
        }
        ''';
        await analyzeCode(source, path: '/lib/login_flow.dart');
        expect(reporter.errors, isEmpty);
      });

      test('does not flag Modular.get inside classes named *Page', () async {
        const source = r'''
        class Modular {
          static T get<T>() => throw UnimplementedError();
        }
        class FeatureController {}
        class CheckoutPage {
          void open() {
            Modular.get<FeatureController>();
          }
        }
        ''';
        await analyzeCode(source, path: '/lib/checkout_page.dart');
        expect(reporter.errors, isEmpty);
      });

      test('does not flag Modular.get in *_module.dart', () async {
        const source = r'''
        class Modular {
          static T get<T>() => throw UnimplementedError();
        }
        class ProjectRepository {}
        class ProjectDropdownBloc {
          ProjectDropdownBloc({required ProjectRepository repo});
        }
        class Module {
          void binds(dynamic i) {}
        }
        class ProjectModule extends Module {
          @override
          void binds(i) {
            i.addFactory<ProjectDropdownBloc>(
              () => ProjectDropdownBloc(repo: Modular.get<ProjectRepository>()),
            );
          }
        }
        ''';
        await analyzeCode(source, path: '/lib/project_module.dart');
        expect(reporter.errors, isEmpty);
      });

      test('does not flag Modular.get in top-level test files', () async {
        const source = r'''
        class Modular {
          static T get<T>() => throw UnimplementedError();
        }
        void main() {
          Modular.get<int>();
        }
        ''';
        await analyzeCode(source, path: '/test/some_test.dart');
        expect(reporter.errors, isEmpty);
      });

      test('does not flag Modular.get in absolute path test files', () async {
        const source = r'''
        class Modular {
          static T get<T>() => throw UnimplementedError();
        }
        void main() {
          Modular.get<int>();
        }
        ''';
        await analyzeCode(
          source,
          path: '/home/user/myproject/test/some_test.dart',
        );
        expect(reporter.errors, isEmpty);
      });

      test('does not flag Modular.get in generated files', () async {
        const source = r'''
        class Modular {
          static T get<T>() => throw UnimplementedError();
        }
        void generatedLogic() {
          Modular.get<int>();
        }
        ''';
        await analyzeCode(source, path: '/lib/some_file.g.dart');
        expect(reporter.errors, isEmpty);

        await analyzeCode(source, path: '/lib/some_file.freezed.dart');
        expect(reporter.errors, isEmpty);
      });

      test('does not flag other get() calls on Modular-shaped types', () async {
        const source = r'''
        class NotModular {
          void get() {}
        }
        class B {
          B() {
            NotModular().get();
          }
        }
        ''';
        await analyzeCode(source, path: '/lib/wrong_target.dart');
        expect(reporter.errors, isEmpty);
      });

      test('supports allow_list from analysis_options.yaml', () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'forbid_modular_get_config_test_',
        );
        tempDirectories.add(tempDir);

        final analysisOptions = File('${tempDir.path}/analysis_options.yaml');
        await analysisOptions.writeAsString('''
custom_lint:
  rules:
    forbid_modular_get_outside_module:
      allow_list:
        - GlobalAnalytics
''');

        const source = r'''
        class Modular {
          static T get<T>() => throw UnimplementedError();
        }
        class GlobalAnalytics {}
        class AnalyticsConsumer {
          AnalyticsConsumer() {
            Modular.get<GlobalAnalytics>();
          }
        }
        ''';

        await analyzeCode(
          source,
          path: '${tempDir.path}/lib/analytics_consumer.dart',
        );
        expect(reporter.errors, isEmpty);
      });
    });

    group('rule metadata', () {
      test('rule name', () {
        expect(rule.code.name, equals('forbid_modular_get_outside_module'));
      });

      test('problem message mentions constructor and module files', () {
        expect(rule.code.problemMessage, contains('Modular.get'));
        expect(rule.code.problemMessage, contains('_module.dart'));
      });
    });

    group('direct analyze() call', () {
      test('analyze() returns empty list (bypass check)', () {
        const source =
            'class Modular { static T get<T>() => throw ""; } void f() { Modular.get<int>(); }';
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
    });
  });
}
