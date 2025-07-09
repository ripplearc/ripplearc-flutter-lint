import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:ripplearc_flutter_lint/rules/no_direct_instantiation.dart';
import 'package:ripplearc_flutter_lint/rules/document_fake_parameters.dart';
import 'package:ripplearc_flutter_lint/rules/todo_with_story_links.dart';
import 'package:ripplearc_flutter_lint/rules/no_internal_method_docs.dart';
import 'rules/prefer_fake_over_mock_rule.dart';
import 'rules/forbid_forced_unwrapping.dart';
import 'rules/no_optional_operators_in_tests.dart';
import 'rules/document_interface.dart';
import 'rules/specific_exception_types.dart';

PluginBase createPlugin() => _RipplearcFlutterLint();

class _RipplearcFlutterLint extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
    const ForbidForcedUnwrapping(),
    const NoOptionalOperatorsInTests(),
    const PreferFakeOverMockRule(),
    const NoDirectInstantiation(),
    const DocumentFakeParameters(),
    const TodoWithStoryLinks(),
    const NoInternalMethodDocs(),
    const DocumentInterface(),
    const SpecificExceptionTypes(),
  ];
}
