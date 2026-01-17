import '../core/base_lint_rule.dart';
import '../core/analyzers/forbid_datetime_now_analyzer.dart';
import '../core/analyzers/base_analyzer.dart';

/// Lint rule that forbids using `DateTime.now()` in production code.
///
/// This rule enforces the use of the custom `Clock` interface from
/// `libraries/time/interfaces/clock.dart` instead of direct `DateTime.now()` calls.
/// This is essential for:
/// - Deterministic testing: Tests can control the current time
/// - Widget testing: Time-dependent widgets can be tested reliably
/// - Mocking: Time can be easily mocked in unit and integration tests
///
/// Exception: `DateTime.now()` is allowed in `system_clock_impl.dart` where the
/// Clock implementation is defined.
///
/// Example of code that triggers this rule:
/// ```dart
/// final currentTime = DateTime.now();  // LINT: Use clock.now() instead
/// ```
///
/// Example of correct usage:
/// ```dart
/// import 'libraries/time/interfaces/clock.dart';
///
/// // Inject clock via constructor or use dependency injection
/// final Clock clock;
/// final currentTime = clock.now();  // OK - testable
/// ```
class ForbidDateTimeNow extends BaseLintRule {
  ForbidDateTimeNow() : super(BaseLintRule.createLintCode(_analyzer));

  static final _analyzer = ForbidDateTimeNowAnalyzer();

  @override
  BaseAnalyzer get analyzer => _analyzer;
}
