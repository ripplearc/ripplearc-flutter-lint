# forbid_helper_util_naming

Forbids class names that include generic substrings like `Helper` or `Util`.
This rule encourages more descriptive, domain-specific names (e.g.,
`AssetLoader` instead of `AssetHelper`) to improve clarity and reduce
catch-all utility classes.

## Bad ❌
```dart
class AssetHelper {}        // LINT: prefer AssetLoader or AssetAdapter
class StringUtil {}         // LINT: prefer StringParser or StringSanitizer
class FormattingUtils {}    // LINT: prefer TextFormatter
```

## Good ✅
```dart
class AssetLoader {}
class StringParser {}
class TextFormatter {}
```

## What's Detected
- Class names containing the substrings: `Helper`, `Helpers`, `Util`, `Utils`
- Typical PascalCase class names that include those substrings
