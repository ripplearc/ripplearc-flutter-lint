import '../core/analyzers/base_analyzer.dart';
import '../core/analyzers/forbid_direct_storage_access_analyzer.dart';
import '../core/base_lint_rule.dart';

/// Lint rule that bans direct use of `shared_preferences`, `path_provider` and
/// `flutter_secure_storage` outside the storage library.
///
/// Files in `lib/libraries/storage/` and `test/libraries/storage/` may use
/// them. Any other file needs its exact path in `allowed_files`:
/// ```yaml
/// custom_lint:
///   rules:
///     - forbid_direct_storage_access
///   forbid_direct_storage_access:
///     allowed_files:
///       - lib/libraries/secure_storage/secure_storage_wrapper_impl.dart
/// ```
class ForbidDirectStorageAccess extends BaseLintRule {
  ForbidDirectStorageAccess()
    : super(BaseLintRule.createLintCode(_analyzer), includeTests: true);

  static final _analyzer = ForbidDirectStorageAccessAnalyzer();

  @override
  BaseAnalyzer get analyzer => _analyzer;
}
