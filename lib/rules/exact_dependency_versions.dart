import 'dart:io';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that enforces exact dependency versions in pubspec.yaml files.
///
/// This rule prevents unexpected breaking changes in PowerSync/Supabase integrations
/// by ensuring all dependencies use exact versions instead of version ranges.
///
/// Example of code that triggers this rule:
/// ```yaml
/// dependencies:
///   flutter_launcher_icons: ^0.14.3  # LINT: Should use exact version
///   http: ^1.1.0  # LINT: Should use exact version
/// ```
///
/// Example of code that doesn't trigger this rule:
/// ```yaml
/// dependencies:
///   flutter_launcher_icons: 0.14.3  # Good: Exact version
///   http: 1.1.0  # Good: Exact version
/// ```
class ExactDependencyVersions extends DartLintRule {
  const ExactDependencyVersions() : super(code: _code);

  static const _code = LintCode(
    name: 'exact_dependency_versions',
    problemMessage:
        'Dependencies must use exact versions to prevent unexpected breaking changes.',
    correctionMessage:
        'Remove the version range operator (^, ~, >=, etc.) and use exact version.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) async {
    // Only check pubspec.yaml files
    if (!_isPubspecFile(resolver.path)) return;

    String source;
    try {
      final file = File(resolver.path);
      if (await file.exists()) {
        source = await file.readAsString();
      } else {
        // For test environments where file doesn't exist on disk
        return;
      }
    } catch (e) {
      // If file reading fails, skip this file
      return;
    }

    checkSourceForVersionRanges(source, reporter);
  }

  /// Check source code for dependency version ranges.
  /// This method is exposed for testing purposes.
  void checkSourceForVersionRanges(String source, dynamic reporter) {
    final lines = source.split('\n');
    final dependencySectionPattern = RegExp(
      r'^(dependencies|dev_dependencies):\s*$',
    );
    final dependencyLinePattern = RegExp(
      r'^\s{1,}(\w+):\s*([^#\s]+)',
    ); // At least one space
    final versionRangePattern = RegExp(r'^[\^~>=<]');

    bool inDependencySection = false;
    int offset = 0;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      // Check if we're entering a dependency section
      if (dependencySectionPattern.hasMatch(line)) {
        inDependencySection = true;
      }
      // Check if we're leaving a dependency section (empty line or new section)
      else if (inDependencySection &&
          (line.trim().isEmpty || !line.startsWith(' '))) {
        inDependencySection = false;
      }

      // Check dependency lines within dependency sections
      if (inDependencySection) {
        final match = dependencyLinePattern.firstMatch(line);
        if (match != null) {
          final depName = match.group(1);
          final version = match.group(2);
          // Ignore sdk dependencies
          if (depName == 'sdk') continue;
          if (version != null && versionRangePattern.hasMatch(version)) {
            // Report at the version part of the line
            final versionStart = line.indexOf(version);
            if (versionStart != -1) {
              reporter.atOffset(
                offset: offset + versionStart,
                length: version.length,
                errorCode: _code,
              );
            }
          }
        }
      }

      offset += line.length + 1; // +1 for the newline
    }
  }

  bool _isPubspecFile(String path) {
    return path.endsWith('pubspec.yaml');
  }
}
