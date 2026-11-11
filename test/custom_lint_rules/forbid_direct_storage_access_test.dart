import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:ripplearc_linter/core/analyzers/forbid_direct_storage_access_analyzer.dart';
import 'package:ripplearc_linter/core/analyzers/forbid_direct_storage_access_config.dart';
import 'package:ripplearc_linter/custom_lint_rules/forbid_direct_storage_access.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../utils/custom_lint_resolver.dart';
import '../utils/test_error_reporter.dart';

void main() {
  group('ForbidDirectStorageAccess', () {
    late Directory project;

    setUp(() {
      project = Directory.systemTemp.createTempSync('storage_access_');
    });

    tearDown(() => project.deleteSync(recursive: true));

    void writeOptions(String yaml) =>
        File('${project.path}/analysis_options.yaml').writeAsStringSync(yaml);

    int errorsFor(String source, String relativePath) {
      final rule = ForbidDirectStorageAccess();
      final reporter = TestErrorReporter();
      final unit = parseString(content: source).unit;
      rule.run(
        TestCustomLintResolver(unit, path: '${project.path}/$relativePath'),
        reporter,
        TestCustomLintContext(unit),
      );
      return reporter.errors.length;
    }

    const sharedPreferences =
        "import 'package:shared_preferences/shared_preferences.dart';";

    group('imports', () {
      for (final package in [
        'shared_preferences',
        'path_provider',
        'flutter_secure_storage',
      ]) {
        test('flags $package in lib', () {
          writeOptions('');
          expect(
            errorsFor("import 'package:$package/$package.dart';", 'lib/a.dart'),
            1,
          );
        });
      }

      test('flags an export', () {
        writeOptions('');
        expect(
          errorsFor(
            "export 'package:path_provider/path_provider.dart';",
            'lib/a.dart',
          ),
          1,
        );
      });

      test('flags a forbidden package in a conditional import URI', () {
        writeOptions('');
        expect(
          errorsFor(
            "import 'none.dart' if (dart.library.io) 'package:shared_preferences/shared_preferences.dart';",
            'lib/a.dart',
          ),
          1,
        );
      });

      test('reports a directive once even when several URIs match', () {
        writeOptions('');
        expect(
          errorsFor(
            "import 'package:path_provider/a.dart' if (dart.library.io) 'package:shared_preferences/b.dart';",
            'lib/a.dart',
          ),
          1,
        );
      });

      test('flags each forbidden directive', () {
        writeOptions('');
        expect(
          errorsFor(
            "$sharedPreferences\nimport 'package:path_provider/path_provider.dart';",
            'lib/a.dart',
          ),
          2,
        );
      });

      test('flags test files too', () {
        writeOptions('');
        expect(errorsFor(sharedPreferences, 'test/a_test.dart'), 1);
      });

      test('ignores other packages and look-alike package names', () {
        writeOptions('');
        expect(
          errorsFor(
            "import 'package:path/path.dart';\n"
                "import 'package:shared_preferences_android/a.dart';\n"
                "import 'package:my_path_provider/a.dart';\n"
                "import 'shared_preferences.dart';",
            'lib/a.dart',
          ),
          0,
        );
      });

      test(
        'ignores a URI that only has a forbidden name after 8 characters',
        () {
          writeOptions('');
          expect(
            errorsFor(
              "import 'pkg:xyz/shared_preferences/a.dart';",
              'lib/a.dart',
            ),
            0,
          );
        },
      );

      test('skips generated files', () {
        writeOptions('');
        expect(errorsFor(sharedPreferences, 'lib/a.g.dart'), 0);
        expect(errorsFor(sharedPreferences, 'lib/a.freezed.dart'), 0);
      });

      test('skips a generated file whose path has windows separators', () {
        final analyzer = ForbidDirectStorageAccessAnalyzer();
        expect(analyzer.shouldSkipFile(r'lib\a.g.dart'), isTrue);
        expect(analyzer.shouldSkipFile(r'lib\a.freezed.dart'), isTrue);
        expect(analyzer.shouldSkipFile(r'lib\a.dart'), isFalse);
      });

      test('reports nothing when the resolver has no path', () {
        final unit = parseString(content: sharedPreferences).unit;
        expect(
          ForbidDirectStorageAccessAnalyzer().analyzeWithResolver(
            unit,
            _PathlessResolver(),
          ),
          isEmpty,
        );
      });

      test('ignores a directive whose URI is not a plain string', () {
        final unit =
            parseString(
              content: r"import '${'package:shared_preferences/a.dart'}';",
              throwIfDiagnostics: false,
            ).unit;
        final analyzer = ForbidDirectStorageAccessAnalyzer(
          config: ForbidDirectStorageAccessConfig.defaults(),
        );
        expect(
          analyzer.analyzeWithResolver(
            unit,
            TestCustomLintResolver(unit, path: '/lib/a.dart'),
          ),
          isEmpty,
        );
      });
    });

    group('allowed places', () {
      test('allows the storage library folder and its tests', () {
        writeOptions('');
        expect(errorsFor(sharedPreferences, 'lib/libraries/storage/a.dart'), 0);
        expect(
          errorsFor(sharedPreferences, 'lib/libraries/storage/x/y/a.dart'),
          0,
        );
        expect(
          errorsFor(
            sharedPreferences,
            'test/libraries/storage/units/a_test.dart',
          ),
          0,
        );
      });

      test('does not allow a folder that only shares the name start', () {
        writeOptions('');
        expect(
          errorsFor(sharedPreferences, 'lib/libraries/storage_other/a.dart'),
          1,
        );
        expect(errorsFor(sharedPreferences, 'lib/libraries/storage.dart'), 1);
      });

      test('does not allow the library folder name deeper in the path', () {
        writeOptions('');
        expect(
          errorsFor(sharedPreferences, 'lib/features/libraries/storage/a.dart'),
          1,
        );
      });

      test('allows a listed file by its exact path', () {
        writeOptions('''
custom_lint:
  forbid_direct_storage_access:
    allowed_files:
      - lib/libraries/secure_storage/wrapper.dart
''');
        expect(
          errorsFor(
            sharedPreferences,
            'lib/libraries/secure_storage/wrapper.dart',
          ),
          0,
        );
      });

      test(
        'does not allow a file that only shares the ending or the start',
        () {
          writeOptions('''
custom_lint:
  forbid_direct_storage_access:
    allowed_files:
      - lib/libraries/secure_storage/wrapper.dart
''');
          expect(
            errorsFor(
              sharedPreferences,
              'lib/other/secure_storage/wrapper.dart',
            ),
            1,
          );
          expect(
            errorsFor(
              sharedPreferences,
              'lib/libraries/secure_storage/my_wrapper.dart',
            ),
            1,
          );
          expect(
            errorsFor(
              sharedPreferences,
              'lib/libraries/secure_storage/wrapper.dart.bak',
            ),
            1,
          );
        },
      );

      test('does not allow a path that ends with a listed file path', () {
        writeOptions('''
custom_lint:
  forbid_direct_storage_access:
    allowed_files:
      - lib/libraries/secure_storage/wrapper.dart
''');
        expect(
          errorsFor(
            sharedPreferences,
            'vendor/lib/libraries/secure_storage/wrapper.dart',
          ),
          1,
        );
      });

      test('a listed file does not allow its folder', () {
        writeOptions('''
custom_lint:
  forbid_direct_storage_access:
    allowed_files:
      - lib/libraries/secure_storage/wrapper.dart
''');
        expect(
          errorsFor(
            sharedPreferences,
            'lib/libraries/secure_storage/other.dart',
          ),
          1,
        );
      });

      test('reads the options from a rules map', () {
        writeOptions('''
custom_lint:
  rules:
    forbid_direct_storage_access:
      allowed_files:
        - lib/a.dart
''');
        expect(errorsFor(sharedPreferences, 'lib/a.dart'), 0);
      });

      test('reads the options in the direct custom_lint form', () {
        writeOptions('''
custom_lint:
  forbid_direct_storage_access:
    allowed_files:
      - ./lib/a.dart
''');
        expect(errorsFor(sharedPreferences, 'lib/a.dart'), 0);
      });

      test('treats a config without the rule as the defaults', () {
        writeOptions('''
custom_lint:
  rules:
    - forbid_forced_unwrapping
''');
        expect(errorsFor(sharedPreferences, 'lib/a.dart'), 1);
        expect(errorsFor(sharedPreferences, 'lib/libraries/storage/a.dart'), 0);
      });

      test('allows a file given as a single path', () {
        writeOptions('''
custom_lint:
  forbid_direct_storage_access:
    allowed_files: lib/a.dart
''');
        expect(errorsFor(sharedPreferences, 'lib/a.dart'), 0);
        expect(errorsFor(sharedPreferences, 'lib/b.dart'), 1);
      });

      test('fails loudly when the options file is not valid YAML', () {
        writeOptions('custom_lint: [unclosed');
        expect(
          () => errorsFor(sharedPreferences, 'lib/a.dart'),
          throwsA(isA<YamlException>()),
        );
      });
    });

    test('uses the config it was given instead of the one on disk', () {
      final analyzer = ForbidDirectStorageAccessAnalyzer(
        config: const ForbidDirectStorageAccessConfig(
          allowedFiles: {'lib/x.dart'},
        ),
      );
      final unit = parseString(content: sharedPreferences).unit;
      expect(
        analyzer.analyzeWithResolver(
          unit,
          TestCustomLintResolver(unit, path: '/lib/x.dart'),
        ),
        isEmpty,
      );
    });

    group('config cache', () {
      test('reads the options once for every file of a project', () {
        writeOptions('''
custom_lint:
  forbid_direct_storage_access:
    allowed_files:
      - lib/a.dart
''');
        expect(errorsFor(sharedPreferences, 'lib/a.dart'), 0);

        writeOptions('');
        expect(errorsFor(sharedPreferences, 'lib/a.dart'), 0);
        expect(errorsFor(sharedPreferences, 'lib/b.dart'), 1);
      });
    });

    group('without a project root', () {
      test('matches the path as given, without its leading slash', () {
        final analyzer = ForbidDirectStorageAccessAnalyzer(
          config: ForbidDirectStorageAccessConfig.defaults(),
        );
        final unit = parseString(content: sharedPreferences).unit;
        expect(
          analyzer.analyzeWithResolver(
            unit,
            TestCustomLintResolver(unit, path: '/lib/libraries/storage/a.dart'),
          ),
          isEmpty,
        );
        expect(
          analyzer.analyzeWithResolver(
            unit,
            TestCustomLintResolver(unit, path: '/lib/features/a.dart'),
          ),
          hasLength(1),
        );
      });
    });
  });
}

class _PathlessResolver {
  final String? path = null;
}
