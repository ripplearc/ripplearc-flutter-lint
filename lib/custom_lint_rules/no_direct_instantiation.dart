import 'package:custom_lint_builder/custom_lint_builder.dart';
import '../core/base_lint_rule.dart';
import '../core/analyzers/direct_instantiation_analyzer.dart';
import '../core/analyzers/base_analyzer.dart';
import '../core/analyzers/direct_instantiation_helpers/linter_config.dart';
import '../core/analyzers/direct_instantiation_helpers/config_parser.dart';

class NoDirectInstantiation extends BaseLintRule {
  factory NoDirectInstantiation({
    LinterConfig? config,
    CustomLintConfigs? configs,
  }) {
    final resolvedConfig = config ?? _parseConfig(configs);
    final analyzer = DirectInstantiationAnalyzer(config: resolvedConfig);
    return NoDirectInstantiation._(analyzer);
  }

  NoDirectInstantiation._(this._analyzer)
    : super(BaseLintRule.createLintCode(_analyzer), includeTests: true);

  final DirectInstantiationAnalyzer _analyzer;

  @override
  BaseAnalyzer get analyzer => _analyzer;
  static LinterConfig _parseConfig(CustomLintConfigs? configs) {
    if (configs == null) return LinterConfig.defaults();

    return LinterConfigParser.parseFromRules(configs.rules) ??
        LinterConfig.defaults();
  }
}
