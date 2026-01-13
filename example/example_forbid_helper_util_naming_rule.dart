// Example file demonstrating the forbid_helper_util_naming rule.
// This rule forbids class names containing "Helper" or "Util" substrings.

// ============================================================================
// BAD: Classes with "Helper" or "Util" in the name
// These will trigger lint errors
// ============================================================================

class AssetHelper {} // LINT: Use more descriptive name like AssetLoader

class StringUtil {} // LINT: Use more descriptive name like StringParser

class DateTimeHelper {} // LINT: Use more descriptive name like DateTimeFormatter

class NetworkUtils {} // LINT: Use more descriptive name like HttpClient

class FileHelper {} // LINT: Use more descriptive name like FileReader

class ValidationUtil {} // LINT: Use more descriptive name like InputValidator

class CacheHelper {} // LINT: Use more descriptive name like CacheManager

class FormattingUtils {} // LINT: Use more descriptive name like TextFormatter

// ============================================================================
// GOOD: Classes with descriptive, domain-specific names
// These will NOT trigger lint errors
// ============================================================================

class AssetLoader {}

class StringParser {}

class DateTimeFormatter {}

class HttpClient {}

class FileReader {}

class InputValidator {}

class CacheManager {}

class TextFormatter {}

class UserRepository {}

class PaymentProcessor {}

class ImageCompressor {}

class TokenRefresher {}

void main() {
  // Demonstration of instantiation
  final loader = AssetLoader();
  final parser = StringParser();
  final formatter = DateTimeFormatter();
  final client = HttpClient();
  
  print('Using descriptive class names: $loader, $parser, $formatter, $client');
}
