import 'package:analyzer/error/listener.dart';
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
    return NoDirectInstantiation._(DirectInstantiationAnalyzer(config: config));
  }

  NoDirectInstantiation._(this._analyzer)
    : super(BaseLintRule.createLintCode(_analyzer), includeTests: true);

  final DirectInstantiationAnalyzer _analyzer;
  static DirectInstantiationAnalyzer? _cachedAnalyzer;

  @override
  BaseAnalyzer get analyzer => _cachedAnalyzer ?? _analyzer;

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    _cachedAnalyzer ??= DirectInstantiationAnalyzer(
      config: LinterConfigParser.loadFromFile(resolver.path) ?? LinterConfig.defaults(),
    );
    super.run(resolver, reporter, context);
  }
}
