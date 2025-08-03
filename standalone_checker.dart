import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'lib/core/analyzers/base_analyzer.dart';
import 'lib/core/analyzers/forced_unwrapping_analyzer.dart';
import 'lib/core/analyzers/direct_instantiation_analyzer.dart';
import 'lib/core/analyzers/sealed_over_dynamic_analyzer.dart';
import 'lib/core/analyzers/private_subject_analyzer.dart';
import 'lib/core/analyzers/specific_exception_types_analyzer.dart';
import 'lib/core/analyzers/document_fake_parameters_analyzer.dart';
import 'lib/core/analyzers/document_interface_analyzer.dart';
import 'lib/core/analyzers/no_internal_method_docs_analyzer.dart';
import 'lib/core/analyzers/todo_with_story_links_analyzer.dart';
import 'lib/core/analyzers/no_optional_operators_in_tests_analyzer.dart';
import 'lib/core/analyzers/prefer_fake_over_mock_analyzer.dart';
import 'lib/core/analyzers/test_file_mutation_coverage_analyzer.dart';
import 'package:path/path.dart' as p;
import 'package:analyzer/dart/analysis/utilities.dart';

/// Simple resolver mock for TestFileMutationCoverageAnalyzer
class _SimpleResolver {
  final String path;
  _SimpleResolver(this.path);
}

class StandaloneLintChecker {
  final List<BaseAnalyzer> analyzers = [
    ForcedUnwrappingAnalyzer(),
    DirectInstantiationAnalyzer(),
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
    // Add other analyzers here as you refactor them
  ];

  Future<List<String>> check(
    List<String> filePaths, {
    List<String>? enabledRules,
  }) async {
    final shouldCheckTestFiles =
        enabledRules?.contains('test_file_mutation_coverage') ?? false;
    final allIssues = <String>[];
    final activeAnalyzers =
        enabledRules != null
            ? analyzers.where((a) => enabledRules.contains(a.ruleName)).toList()
            : analyzers;

    // Convert all input paths to absolute, normalized, canonicalized paths
    final absolutePaths =
        filePaths.map((p0) {
          final abs =
              FileSystemEntity.isDirectorySync(p0)
                  ? Directory(p0).absolute.path
                  : File(p0).absolute.path;
          return p.normalize(p.canonicalize(abs));
        }).toList();

    // Separate files and directories
    final files = <String>[];
    final directories = <String>[];
    for (final path in absolutePaths) {
      if (FileSystemEntity.isDirectorySync(path)) {
        directories.add(path);
      } else if (path.endsWith('.dart')) {
        files.add(path);
      }
    }

    // Analyze individual files directly (fast path)
    for (final filePath in files) {
      if (!filePath.endsWith('.dart') ||
          (!shouldCheckTestFiles && BaseAnalyzer.isTestFile(filePath)))
        continue;
      final parseResult = parseString(
        path: filePath,
        content: File(filePath).readAsStringSync(),
      );
      final unit = parseResult.unit;
      for (final analyzer in activeAnalyzers) {
        List<dynamic> issues;
        if (analyzer is TestFileMutationCoverageAnalyzer) {
          // Create a simple resolver mock for TestFileMutationCoverageAnalyzer
          final resolver = _SimpleResolver(filePath);
          issues = analyzer.analyzeWithResolver(unit, resolver);
        } else {
          issues = analyzer.analyze(unit);
        }
        for (final issue in issues) {
          allIssues.add(
            '$filePath:${issue.line}:${issue.column} • ${issue.message} • ${issue.ruleName}',
          );
        }
      }
    }

    // Analyze directories using AnalysisContextCollection (existing logic)
    if (directories.isNotEmpty) {
      final collection = AnalysisContextCollection(includedPaths: directories);
      for (final context in collection.contexts) {
        for (final filePath in context.contextRoot.analyzedFiles()) {
          if (!filePath.endsWith('.dart') ||
              (!shouldCheckTestFiles && BaseAnalyzer.isTestFile(filePath)))
            continue;
          final result = await context.currentSession.getResolvedUnit(filePath);
          if (result is ResolvedUnitResult) {
            for (final analyzer in activeAnalyzers) {
              List<dynamic> issues;
              if (analyzer is TestFileMutationCoverageAnalyzer) {
                // Create a simple resolver mock for TestFileMutationCoverageAnalyzer
                final resolver = _SimpleResolver(filePath);
                issues = analyzer.analyzeWithResolver(result.unit, resolver);
              } else {
                issues = analyzer.analyze(result.unit);
              }
              for (final issue in issues) {
                allIssues.add(
                  '$filePath:${issue.line}:${issue.column} • ${issue.message} • ${issue.ruleName}',
                );
              }
            }
          }
        }
      }
    }

    return allIssues;
  }
}

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
    print(
      'Usage: dart run standalone_checker.dart [--rules rule1,rule2] <files_or_directories>',
    );
    print(
      'Available rules: forbid_forced_unwrapping, no_direct_instantiation, sealed_over_dynamic, private_subject, specific_exception_types, document_fake_parameters, document_interface, no_internal_method_docs, todo_with_story_links, no_optional_operators_in_tests, prefer_fake_over_mock, test_file_mutation_coverage',
    );
    exit(1);
  }

  final checker = StandaloneLintChecker();
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
