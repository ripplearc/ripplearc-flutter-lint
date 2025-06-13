import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'rules/prefer_fake_over_mock_rule.dart';

PluginBase createPlugin() => _RipplearcFlutterLint();

class _RipplearcFlutterLint extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        const PreferFakeOverMockRule(),
      ];
} 