import '../core/base_lint_rule.dart';
import '../core/analyzers/forbid_feature_import_outside_provider_analyzer.dart';
import '../core/analyzers/base_analyzer.dart';

/// Lint rule that forbids importing a feature's internals from outside the
/// feature except through that feature's own provider file.
///
/// Each feature is expected to expose exactly one public door,
/// `{feature_name}_feature_module.dart`, so code outside `lib/features/` can
/// only ever depend on that feature's `FeatureModule`/`TabEntry` contract and
/// never reach into its screens, blocs, or entities directly.
class ForbidFeatureImportOutsideProvider extends BaseLintRule {
  ForbidFeatureImportOutsideProvider()
    : super(BaseLintRule.createLintCode(_analyzer), includeTests: true);

  static final _analyzer = ForbidFeatureImportOutsideProviderAnalyzer();

  @override
  BaseAnalyzer get analyzer => _analyzer;
}
