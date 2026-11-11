import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:ripplearc_linter/core/analyzers/forbid_direct_storage_access_config.dart';
import 'package:ripplearc_linter/core/analyzers/forbid_direct_storage_access_config_parser.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('ForbidDirectStorageAccessConfig', () {
    const config = ForbidDirectStorageAccessConfig(
      allowedFiles: {'lib/b.dart', 'lib/x/c.dart'},
    );

    test('allows the files of the library folders', () {
      expect(config.allows('lib/libraries/storage/a.dart'), isTrue);
      expect(config.allows('lib/libraries/storage/deep/a.dart'), isTrue);
      expect(config.allows('test/libraries/storage/units/a_test.dart'), isTrue);
    });

    test('does not allow a folder that only shares the name start', () {
      expect(config.allows('lib/libraries/storage_other/a.dart'), isFalse);
      expect(config.allows('lib/libraries/storage'), isFalse);
      expect(config.allows('lib/libraries/storage.dart'), isFalse);
      expect(config.allows('lib/features/libraries/storage/a.dart'), isFalse);
    });

    test('allows a listed file by its exact path', () {
      expect(config.allows('lib/b.dart'), isTrue);
    });

    test('does not allow a path that only ends like a listed file', () {
      expect(config.allows('vendor/lib/b.dart'), isFalse);
      expect(config.allows('lib/b.dart.bak'), isFalse);
      expect(config.allows('lib/my_b.dart'), isFalse);
    });

    test('a listed file does not allow its folder', () {
      expect(config.allows('lib/x/other.dart'), isFalse);
    });

    test('defaults list no files', () {
      final defaults = ForbidDirectStorageAccessConfig.defaults();
      expect(defaults.allowedFiles, isEmpty);
      expect(defaults.allows('lib/libraries/storage/a.dart'), isTrue);
      expect(defaults.allows('lib/a.dart'), isFalse);
    });
  });

  group('ForbidDirectStorageAccessConfigParser', () {
    late Directory project;

    setUp(() {
      project = Directory.systemTemp.createTempSync('storage_config_');
    });

    tearDown(() => project.deleteSync(recursive: true));

    ForbidDirectStorageAccessConfig load(String yaml) {
      File(
        p.join(project.path, 'analysis_options.yaml'),
      ).writeAsStringSync(yaml);
      return ForbidDirectStorageAccessConfigParser.loadFromFile(
        p.join(project.path, 'lib', 'a.dart'),
      );
    }

    test('returns the defaults when there is no project root', () {
      final file = p.join(project.path, 'lib', 'a.dart');
      expect(ForbidDirectStorageAccessConfigParser.projectRootOf(file), isNull);

      final config = ForbidDirectStorageAccessConfigParser.loadFromFile(file);

      expect(config.allowedFiles, isEmpty);
    });

    test('finds the nearest folder that holds analysis_options.yaml', () {
      load('');
      expect(
        ForbidDirectStorageAccessConfigParser.projectRootOf(
          p.join(project.path, 'lib', 'deep', 'a.dart'),
        ),
        project.path,
      );
    });

    test('reads the files listed next to rules', () {
      final config = load('''
custom_lint:
  rules:
    - forbid_direct_storage_access
  forbid_direct_storage_access:
    allowed_files:
      - lib/a.dart
      - ./lib/b.dart
''');
      expect(config.allowedFiles, {'lib/a.dart', 'lib/b.dart'});
    });

    test('reads the files listed inside a rules map', () {
      final config = load('''
custom_lint:
  rules:
    forbid_direct_storage_access:
      allowed_files:
        - lib/a.dart
''');
      expect(config.allowedFiles, {'lib/a.dart'});
    });

    test('reads a single path as a list of one', () {
      final config = load('''
custom_lint:
  forbid_direct_storage_access:
    allowed_files: lib/a.dart
''');
      expect(config.allowedFiles, {'lib/a.dart'});
    });

    test('fails with a clear message when allowed_files is not a list', () {
      expect(
        () => load('''
custom_lint:
  forbid_direct_storage_access:
    allowed_files:
      lib/a.dart: true
'''),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('allowed_files must be a list of file paths'),
          ),
        ),
      );
    });

    test('keeps the defaults when the rule has no options', () {
      final config = load('''
custom_lint:
  rules:
    - forbid_direct_storage_access
''');
      expect(config.allowedFiles, isEmpty);
    });

    test('keeps the defaults when custom_lint is missing or not a map', () {
      expect(load('analyzer: {}').allowedFiles, isEmpty);
      expect(load('custom_lint: none').allowedFiles, isEmpty);
      expect(load('').allowedFiles, isEmpty);
    });

    test('ignores empty entries and an empty option', () {
      final config = load('''
custom_lint:
  forbid_direct_storage_access:
    allowed_files:
      - ""
      - lib/a.dart
''');
      expect(config.allowedFiles, {'lib/a.dart'});
      expect(
        load('''
custom_lint:
  forbid_direct_storage_access:
    allowed_files:
''').allowedFiles,
        isEmpty,
      );
    });

    test('fails loudly when the options file is not valid YAML', () {
      expect(
        () => load('custom_lint: [unclosed'),
        throwsA(isA<YamlException>()),
      );
    });

    test('normalize handles windows separators and a dot prefix', () {
      expect(
        ForbidDirectStorageAccessConfigParser.normalize(r' .\lib\a.dart '),
        'lib/a.dart',
      );
      expect(
        ForbidDirectStorageAccessConfigParser.normalize('./././lib/a.dart'),
        'lib/a.dart',
      );
    });
  });
}
