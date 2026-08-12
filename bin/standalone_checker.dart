import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:ripplearc_linter/core/analyzers/avoid_static_typography_analyzer.dart';
import 'package:ripplearc_linter/core/analyzers/avoid_static_colors_analyzer.dart';
import 'package:ripplearc_linter/core/analyzers/base_analyzer.dart';
import 'package:ripplearc_linter/core/analyzers/direct_instantiation_helpers/config_parser.dart';
import 'package:ripplearc_linter/core/analyzers/forced_unwrapping_analyzer.dart';
import 'package:ripplearc_linter/core/analyzers/direct_instantiation_analyzer.dart';
import 'package:ripplearc_linter/core/analyzers/sealed_over_dynamic_analyzer.dart';
import 'package:ripplearc_linter/core/analyzers/private_subject_analyzer.dart';
import 'package:ripplearc_linter/core/analyzers/specific_exception_types_analyzer.dart';
import 'package:ripplearc_linter/core/analyzers/document_fake_parameters_analyzer.dart';
import 'package:ripplearc_linter/core/analyzers/document_interface_analyzer.dart';
import 'package:ripplearc_linter/core/analyzers/no_internal_method_docs_analyzer.dart';
import 'package:ripplearc_linter/core/analyzers/todo_with_story_links_analyzer.dart';
import 'package:ripplearc_linter/core/analyzers/no_optional_operators_in_tests_analyzer.dart';
import 'package:ripplearc_linter/core/analyzers/prefer_fake_over_mock_analyzer.dart';
import 'package:ripplearc_linter/core/analyzers/test_file_mutation_coverage_analyzer.dart';
import 'package:ripplearc_linter/core/analyzers/forbid_helper_util_naming_analyzer.dart';
import 'package:ripplearc_linter/core/analyzers/prevent_feature_module_dependencies_analyzer.dart';
import 'package:ripplearc_linter/core/analyzers/prevent_library_module_dependencies_analyzer.dart';
import 'package:ripplearc_linter/core/analyzers/forbid_modular_get_outside_module_analyzer.dart';
import 'package:ripplearc_linter/core/analyzers/forbid_raw_icon_and_image_usage_analyzer.dart';
import 'package:ripplearc_linter/core/analyzers/restrict_core_icon_data_analyzer.dart';
import 'package:ripplearc_linter/core/analyzers/forbid_manual_screenshot_theme_analyzer.dart';

import 'package:path/path.dart' as p;
import 'package:analyzer/dart/analysis/utilities.dart';

/// Simple resolver mock for TestFileMutationCoverageAnalyzer
class _SimpleResolver {
  final String path;
  _SimpleResolver(this.path);
}

/// A standalone lint checker that can analyze Dart files and directories
/// without requiring the full Flutter/Dart analysis context.
///
/// This class provides a lightweight alternative to the full custom lint package,
/// useful for:
/// - CI/CD pipelines where you want fast linting
/// - Command-line tools for developers
/// - Integration with other build systems
///
/// **Performance Characteristics:**
/// - Individual files are analyzed using fast parsing (parseString)
/// - Directories use the full analysis context for better accuracy
/// - Test files are only analyzed when the 'test_file_mutation_coverage' rule is enabled
///
/// **Usage Examples:**
/// ```dart
/// // Check all files in a directory with all rules
/// final checker = StandaloneLintChecker();
/// final issues = await checker.check(['lib/', 'test/']);
///
/// // Check with only specific rules enabled
/// final issues = await checker.check(
///   ['lib/'],
///   enabledRules: ['forbid_forced_unwrapping', 'no_direct_instantiation']
/// );
///
/// // Check test files (requires test_file_mutation_coverage rule)
/// final issues = await checker.check(
///   ['test/'],
///   enabledRules: ['test_file_mutation_coverage']
/// );
/// ```
class StandaloneLintChecker {
  StandaloneLintChecker({String? configFilePath}) {
    final linterConfig = LinterConfigParser.loadFromFile(configFilePath);
    
    _analyzers = [
      AvoidStaticTypographyAnalyzer(),
      AvoidStaticColorsAnalyzer(),
      ForcedUnwrappingAnalyzer(),
      ForbidHelperUtilNamingAnalyzer(),
      DirectInstantiationAnalyzer(config: linterConfig),
      SealedOverDynamicAnalyzer(),
      PrivateSubjectAnalyzer(),
      SpecificExceptionTypesAnalyzer(),
      DocumentFakeParametersAnalyzer(),
      DocumentInterfaceAnalyzer(),
      NoInternalMethodDocsAnalyzer(),
      TodoWithStoryLinksAnalyzer(),
      NoOptionalOperatorsInTestsAnalyzer(),
      PreferFakeOverMockAnalyzer(),
      TestFileMutationCoverageAnalyzer(),
      FeatureModuleIsolationAnalyzer(),
      LibraryModuleDependenciesAnalyzer(),
      ForbidModularGetOutsideModuleAnalyzer(),
      ForbidRawIconAndImageUsageAnalyzer(),
      RestrictCoreIconDataAnalyzer(),
      ForbidManualScreenshotThemeAnalyzer(),
    ];
  }

  late final List<BaseAnalyzer> _analyzers;
  
  List<BaseAnalyzer> get analyzers => _analyzers;

  static const Set<String> _testOnlyRuleNames = {
    'avoid_test_timeouts',
    'no_optional_operators_in_tests',
    'prefer_fake_over_mock',
    'document_fake_parameters',
    'test_file_mutation_coverage',
    'forbid_manual_screenshot_theme',
  };

  static const Set<String> _bothFilesRuleNames = {
    'avoid_static_colors',
    'avoid_static_typography',
    'no_direct_instantiation',
    'forbid_helper_util_naming',
    'forbid_raw_icon_and_image_usage',
    'restrict_core_icon_data',
  };

  /// Analyzes the given files and directories for linting issues.
  ///
  /// This method processes both individual files and directories, using different
  /// analysis strategies for optimal performance and accuracy.
  ///
  /// **Parameters:**
  /// - [filePaths]: List of file or directory paths to analyze. Can be a mix of
  ///   individual .dart files and directory paths.
  /// - [enabledRules]: Optional list of specific rules to run. If null, all rules are run.
  ///   Use this to limit analysis to specific concerns or improve performance.
  ///
  /// **Returns:** A list of issue strings in the format:
  /// `filepath:line:column • message • rule_name`
  ///
  /// **Analysis Strategy:**
  /// - **Individual files**: Uses fast parsing (parseString) for quick analysis
  /// - **Directories**: Uses full analysis context for better accuracy and symbol resolution
  /// - **Test files**: Only analyzed when 'test_file_mutation_coverage' is in enabledRules
  /// - **Performance**: Fast path is ~5-10x faster than full analysis context
  ///
  /// **Example Usage:**
  /// ```dart
  /// final checker = StandaloneLintChecker();
  ///
  /// // Check specific files with all rules
  /// final issues = await checker.check(['lib/main.dart', 'lib/utils.dart']);
  ///
  /// // Check directories with specific rules
  /// final issues = await checker.check(
  ///   ['lib/', 'test/'],
  ///   enabledRules: ['forbid_forced_unwrapping', 'no_direct_instantiation']
  /// );
  ///
  /// // Check only test mutation coverage
  /// final issues = await checker.check(
  ///   ['test/'],
  ///   enabledRules: ['test_file_mutation_coverage']
  /// );
  /// ```
  Future<List<String>> check(
    List<String> filePaths, {
    List<String>? enabledRules,
  }) async {
    final shouldCheckTestFiles = _shouldCheckTestFiles(enabledRules);
    final activeAnalyzers = _getActiveAnalyzers(enabledRules);
    final pathGroups = _categorizePaths(filePaths);

    final allIssues = <String>[];

    allIssues.addAll(
      _analyzeIndividualFiles(
        pathGroups.files,
        activeAnalyzers,
        shouldCheckTestFiles,
      ),
    );

    allIssues.addAll(
      await _analyzeDirectories(
        pathGroups.directories,
        activeAnalyzers,
        shouldCheckTestFiles,
      ),
    );

    return allIssues;
  }

  bool _shouldCheckTestFiles(List<String>? enabledRules) {
    if (enabledRules == null) return false;
    return enabledRules.any(
      (rule) =>
          _testOnlyRuleNames.contains(rule) ||
          _bothFilesRuleNames.contains(rule),
    );
  }

  List<BaseAnalyzer> _getActiveAnalyzers(List<String>? enabledRules) {
    return enabledRules != null
        ? analyzers.where((a) => enabledRules.contains(a.ruleName)).toList()
        : analyzers;
  }

  _PathGroups _categorizePaths(List<String> filePaths) {
    final absolutePaths = _normalizePaths(filePaths);
    final files = <String>[];
    final directories = <String>[];

    for (final path in absolutePaths) {
      if (FileSystemEntity.isDirectorySync(path)) {
        directories.add(path);
      } else if (path.endsWith('.dart')) {
        files.add(path);
      }
    }

    return _PathGroups(files: files, directories: directories);
  }

  List<String> _normalizePaths(List<String> filePaths) {
    return filePaths.map((path) {
      final absolute =
          FileSystemEntity.isDirectorySync(path)
              ? Directory(path).absolute.path
              : File(path).absolute.path;
      return p.normalize(p.canonicalize(absolute));
    }).toList();
  }

  List<String> _analyzeIndividualFiles(
    List<String> files,
    List<BaseAnalyzer> activeAnalyzers,
    bool shouldCheckTestFiles,
  ) {
    final issues = <String>[];

    for (final filePath in files) {
      if (!_shouldAnalyzeFile(filePath, shouldCheckTestFiles)) continue;

      final parseResult = parseString(
        path: filePath,
        content: File(filePath).readAsStringSync(),
      );

      issues.addAll(_analyzeUnit(parseResult.unit, filePath, activeAnalyzers));
    }

    return issues;
  }

  Future<List<String>> _analyzeDirectories(
    List<String> directories,
    List<BaseAnalyzer> activeAnalyzers,
    bool shouldCheckTestFiles,
  ) async {
    if (directories.isEmpty) return [];

    final issues = <String>[];
    final collection = AnalysisContextCollection(includedPaths: directories);

    for (final context in collection.contexts) {
      for (final filePath in context.contextRoot.analyzedFiles()) {
        if (!_shouldAnalyzeFile(filePath, shouldCheckTestFiles)) continue;

        final result = await context.currentSession.getResolvedUnit(filePath);
        if (result is ResolvedUnitResult) {
          issues.addAll(_analyzeUnit(result.unit, filePath, activeAnalyzers));
        }
      }
    }

    return issues;
  }

  bool _shouldAnalyzeFile(String filePath, bool shouldCheckTestFiles) {
    return filePath.endsWith('.dart') &&
        (shouldCheckTestFiles || !BaseAnalyzer.isTestFile(filePath));
  }

  List<String> _analyzeUnit(
    dynamic unit,
    String filePath,
    List<BaseAnalyzer> activeAnalyzers,
  ) {
    final issues = <String>[];
    final isTestFile = BaseAnalyzer.isTestFile(filePath);

    for (final analyzer in activeAnalyzers) {
      if (_isBothFilesRule(analyzer.ruleName)) {
        final analyzerIssues = _runAnalyzer(analyzer, unit, filePath);
        issues.addAll(_formatIssues(analyzerIssues, filePath));
        continue;
      }

      // Skip production analyzers on test files
      if (isTestFile && !_isTestOnlyRule(analyzer.ruleName)) continue;
      // Skip test-only analyzers on production files
      if (!isTestFile && _isTestOnlyRule(analyzer.ruleName)) continue;

      final analyzerIssues = _runAnalyzer(analyzer, unit, filePath);
      issues.addAll(_formatIssues(analyzerIssues, filePath));
    }

    return issues;
  }

  bool _isTestOnlyRule(String ruleName) {
    return _testOnlyRuleNames.contains(ruleName);
  }

  bool _isBothFilesRule(String ruleName) {
    return _bothFilesRuleNames.contains(ruleName);
  }

  List<dynamic> _runAnalyzer(
    BaseAnalyzer analyzer,
    dynamic unit,
    String filePath,
  ) {
    final resolver = _SimpleResolver(filePath);
    return analyzer.analyzeWithResolver(unit, resolver);
  }

  List<String> _formatIssues(List<dynamic> issues, String filePath) {
    return issues
        .map(
          (issue) =>
              '$filePath:${issue.line}:${issue.column} • ${issue.message} • ${issue.ruleName}',
        )
        .toList();
  }
}

class _PathGroups {
  final List<String> files;
  final List<String> directories;

  _PathGroups({required this.files, required this.directories});
}

String? _getConfigFilePathFromFiles(List<String> files) {
  return files.isNotEmpty ? files.first : null;
}

/// Main entry point for the standalone lint checker.
///
/// **Command Line Usage:**
/// ```bash
/// # Locally via package name
/// dart run ripplearc_linter:standalone_checker lib/
///
/// # Check with only specific rules enabled
/// dart run ripplearc_linter:standalone_checker --rules forbid_forced_unwrapping,no_direct_instantiation lib/
///
/// # Check test files (requires test_file_mutation_coverage rule)
/// dart run ripplearc_linter:standalone_checker --rules test_file_mutation_coverage test/
/// ```
void main(List<String> args) async {
  final stopwatch = Stopwatch()..start();

  final files = <String>[];
  final rules = <String>[];

  // Parse arguments
  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--rules' && i + 1 < args.length) {
      rules.addAll(args[i + 1].split(','));
      i++; // Skip next argument
    } else if (!args[i].startsWith('--')) {
      files.add(args[i]);
    }
  }

  if (files.isEmpty) {
    print('Usage:');
    print(
      'dart run ripplearc_linter:standalone_checker [--rules rule1,rule2] <files_or_directories>',
    );
    print(
      'standalone_checker [--rules rule1,rule2] <files_or_directories> (after global activate)',
    );
    print(
      'Available rules: avoid_static_typography, avoid_static_colors, forbid_forced_unwrapping, no_direct_instantiation, sealed_over_dynamic, private_subject, specific_exception_types, document_fake_parameters, document_interface, no_internal_method_docs, todo_with_story_links, no_optional_operators_in_tests, prefer_fake_over_mock, test_file_mutation_coverage, prevent_feature_module_dependencies, forbid_modular_get_outside_module, forbid_raw_icon_and_image_usage, restrict_core_icon_data, forbid_manual_screenshot_theme',
    );
    exit(1);
  }

  final configFilePath = _getConfigFilePathFromFiles(files);
  final checker = StandaloneLintChecker(configFilePath: configFilePath);
  final issues = await checker.check(
    files,
    enabledRules: rules.isEmpty ? null : rules,
  );

  if (issues.isNotEmpty) {
    print('Found ${issues.length} issue(s):');
    issues.forEach(print);
    stopwatch.stop();
    final elapsed = stopwatch.elapsed;
    print(
      'Execution time:  [${elapsed.inSeconds}s ${elapsed.inMilliseconds % 1000}ms]',
    );
    exit(1);
  } else {
    stopwatch.stop();
    final elapsed = stopwatch.elapsed;
    print('No issues found! ✅');
    print(
      'Execution time:  [${elapsed.inSeconds}s ${elapsed.inMilliseconds % 1000}ms]',
    );
  }
}
