import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'custom_lint_rules/avoid_test_timeouts.dart';
import 'custom_lint_rules/forbid_forced_unwrapping.dart';
import 'custom_lint_rules/forbid_datetime_now.dart';
import 'custom_lint_rules/no_direct_instantiation.dart';
import 'custom_lint_rules/sealed_over_dynamic.dart';
import 'custom_lint_rules/private_subject.dart';
import 'custom_lint_rules/specific_exception_types.dart';
import 'custom_lint_rules/document_fake_parameters.dart';
import 'custom_lint_rules/document_interface.dart';
import 'custom_lint_rules/no_internal_method_docs.dart';
import 'custom_lint_rules/todo_with_story_links.dart';
import 'custom_lint_rules/no_optional_operators_in_tests.dart';
import 'custom_lint_rules/prefer_fake_over_mock_rule.dart';

PluginBase createPlugin() => _CustomLintPlugin();

class _CustomLintPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
    AvoidTestTimeouts(),
    ForbidForcedUnwrapping(),
    ForbidDateTimeNow(),
    NoDirectInstantiation(),
    SealedOverDynamic(),
    PrivateSubject(),
    SpecificExceptionTypes(),
    DocumentFakeParameters(),
    DocumentInterface(),
    NoInternalMethodDocs(),
    TodoWithStoryLinks(),
    NoOptionalOperatorsInTests(),
    PreferFakeOverMockRule(),
  ];
}
