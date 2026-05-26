# forbid_raw_icon_and_image_usage

Forbids direct usage of raw Flutter `Icon(Icons.xxx)` and `Image.asset()` in application code. This rule enforces icon and image abstraction by requiring developers to use `CoreIcons` constants and coreui abstraction components, ensuring consistent visual styling and asset management across the codebase.

## Bad ❌
```dart
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Direct Icon instantiation
        Icon(Icons.home),  // LINT
        Icon(Icons.import_contacts),  // LINT

        // Direct Image.asset usage
        Image.asset('assets/images/logo.png'),  // LINT
      ],
    );
  }
}
```

## Good ✅
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Use CoreIcons constants via coreui abstractions
        CoreIcon(CoreIcons.home),
        CoreIcon(CoreIcons.contacts),

        // Use coreui abstraction components for images
        CoreImage.asset(CoreAssets.logo),
      ],
    );
  }
}
```

## What's Detected
- **Direct `Icon` instantiation**: `Icon(Icons.xxx)`
- **Direct `Image.asset` usage**: both `Image.asset(...)` constructor invocations and method-style calls

## Excluded Files
- Files under `coreui/lib/` (coreui package implementation)
- Files under `coreui/test/` (coreui package tests)

## Known Limitations
- `Icon()` detection is AST-name-only and does not filter by import source. The check `typeName == 'Icon'` flags any class named `Icon`, not strictly Flutter's `material.dart` `Icon`. This is a known limitation of unresolved-mode analysis shared by other rules in this repo (e.g., `restrict_core_icon_data`). In practice, collisions with non-Flutter `Icon` classes are rare in app code.
