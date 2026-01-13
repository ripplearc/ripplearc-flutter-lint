import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'custom_lint_rules/avoid_static_colors.dart';
import 'custom_lint_rules/avoid_static_typography.dart';
import 'custom_lint_rules/avoid_test_timeouts.dart';
import 'custom_lint_rules/no_direct_instantiation.dart';
import 'custom_lint_rules/document_fake_parameters.dart';
import 'custom_lint_rules/document_enum.dart';
import 'custom_lint_rules/sealed_over_dynamic.dart';
import 'custom_lint_rules/todo_with_story_links.dart';
import 'custom_lint_rules/no_internal_method_docs.dart';
import 'custom_lint_rules/prefer_fake_over_mock_rule.dart';
import 'custom_lint_rules/forbid_forced_unwrapping.dart';
import 'custom_lint_rules/forbid_helper_util_naming.dart';
import 'custom_lint_rules/no_optional_operators_in_tests.dart';
import 'custom_lint_rules/document_interface.dart';
import 'custom_lint_rules/private_subject.dart';
import 'custom_lint_rules/specific_exception_types.dart';
import 'custom_lint_rules/test_file_mutation_coverage.dart';
import 'custom_lint_rules/prevent_feature_module_dependencies.dart';
import 'custom_lint_rules/prevent_library_module_dependencies.dart';
import 'custom_lint_rules/restrict_core_icon_data.dart';

PluginBase createPlugin() => _RipplearcLintRules();

class _RipplearcLintRules extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
    AvoidStaticColors(),
    AvoidStaticTypography(),
    ForbidForcedUnwrapping(),
    ForbidHelperUtilNaming(),
    NoOptionalOperatorsInTests(),
    PreferFakeOverMockRule(),
    NoDirectInstantiation(),
    DocumentFakeParameters(),
    DocumentEnum(),
    TodoWithStoryLinks(),
    NoInternalMethodDocs(),
    DocumentInterface(),
    AvoidTestTimeouts(),
    PrivateSubject(),
    SealedOverDynamic(),
    SpecificExceptionTypes(),
    TestFileMutationCoverage(),
    PreventFeatureModuleDependencies(),
    PreventLibraryModuleDependencies(),
    RestrictCoreIconData(),
  ];
}
