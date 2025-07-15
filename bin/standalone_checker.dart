import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import '../lib/core/analyzers/base_analyzer.dart';
import '../lib/core/analyzers/forced_unwrapping_analyzer.dart';
import '../lib/core/analyzers/direct_instantiation_analyzer.dart';
import '../lib/core/analyzers/sealed_over_dynamic_analyzer.dart';
import '../lib/core/analyzers/private_subject_analyzer.dart';
import '../lib/core/analyzers/specific_exception_types_analyzer.dart';
import '../lib/core/analyzers/document_fake_parameters_analyzer.dart';
import '../lib/core/analyzers/document_interface_analyzer.dart';
import '../lib/core/analyzers/no_internal_method_docs_analyzer.dart';
import '../lib/core/analyzers/todo_with_story_links_analyzer.dart';
import '../lib/core/analyzers/no_optional_operators_in_tests_analyzer.dart';
import '../lib/core/analyzers/prefer_fake_over_mock_analyzer.dart';
import '../lib/core/models/lint_issue.dart';
import 'package:path/path.dart' as p;

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
    // Add other analyzers here as you refactor them
  ];

  Future<List<String>> check(
    List<String> filePaths, {
    List<String>? enabledRules,
  }) async {
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

    final collection = AnalysisContextCollection(includedPaths: absolutePaths);

    for (final context in collection.contexts) {
      for (final filePath in context.contextRoot.analyzedFiles()) {
        if (!filePath.endsWith('.dart') || BaseAnalyzer.isTestFile(filePath))
          continue;

        final result = await context.currentSession.getResolvedUnit(filePath);
        if (result is ResolvedUnitResult) {
          for (final analyzer in activeAnalyzers) {
            final issues = analyzer.analyze(result.unit);

            for (final issue in issues) {
              allIssues.add(
                '$filePath:${issue.line}:${issue.column} • ${issue.message} • ${issue.ruleName}',
              );
            }
          }
        }
      }
    }

    return allIssues;
  }
}

void main(List<String> args) async {
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
      'Usage: dart run bin/standalone_checker.dart [--rules rule1,rule2] <files_or_directories>',
    );
    print(
      'Available rules: forbid_forced_unwrapping, no_direct_instantiation, sealed_over_dynamic, private_subject, specific_exception_types, document_fake_parameters, document_interface, no_internal_method_docs, todo_with_story_links, no_optional_operators_in_tests, prefer_fake_over_mock',
    );
    exit(1);
  }

  final checker = StandaloneLintChecker();
  final issues = await checker.check(
    files,
    enabledRules: rules.isEmpty ? null : rules,
  );

  if (issues.isNotEmpty) {
    print('Found  [31m${issues.length} [0m issue(s):');
    issues.forEach(print);
    exit(1);
  } else {
    print('No issues found! ✅');
  }
}
