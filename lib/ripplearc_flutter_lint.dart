import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'rules/prefer_fake_over_mock_rule.dart';
import 'rules/forbid_forced_unwrapping.dart';
import 'rules/no_optional_operators_in_tests.dart';

PluginBase createPlugin() => _RipplearcFlutterLint();

class _RipplearcFlutterLint extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        const ForbidForcedUnwrapping(),
        const NoOptionalOperatorsInTests(),
        const PreferFakeOverMockRule(),
      ];
} 