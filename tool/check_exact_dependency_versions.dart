import 'dart:io';
import 'package:ripplearc_flutter_lint/rules/exact_dependency_versions.dart';

Future<void> main(List<String> args) async {
  final rule = ExactDependencyVersions();
  final pubspecFiles = await _findPubspecFiles(Directory.current);
  var totalIssues = 0;

  for (final file in pubspecFiles) {
    final content = await file.readAsString();
    final errors = <String>[];
    final reporter = _SimpleReporter(errors);
    rule.checkSourceForVersionRanges(content, reporter);
    if (errors.isNotEmpty) {
      print('❌ ${file.path}:');
      for (final error in errors) {
        print('  - $error');
      }
      totalIssues += errors.length;
    }
  }

  if (totalIssues == 0) {
    print('✅ All pubspec.yaml files use exact dependency versions.');
    exit(0);
  } else {
    print('\n$totalIssues version range issues found.');
    exit(1);
  }
}

Future<List<File>> _findPubspecFiles(Directory dir) async {
  final files = <File>[];
  await for (final entity in dir.list(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('pubspec.yaml')) {
      files.add(entity);
    }
  }
  return files;
}

class _SimpleReporter {
  final List<String> errors;
  _SimpleReporter(this.errors);
  void atOffset({
    required int offset,
    required int length,
    required errorCode,
  }) {
    errors.add('${errorCode.name}: ${errorCode.problemMessage}');
  }

  void atNode(node, errorCode, {List<Object>? arguments}) {}
}
