# avoid_static_colors_agent_test

**Type**: Linter Rule  
**Severity**: Warning  
**Category**: Design / Theme  
**Scope**: Production and Test files

## Overview

Enforces theme-context-based color access for proper light/dark mode support. This rule flags static color usage that breaks theme switching (e.g. `Colors.white`, `CoreTextColors.headline`, `Color(0xFF...)`). Use `Theme.of(context).extension<AppColorsExtension>()` instead.

## Why This Rule Exists

Static color references break proper theme support in Flutter applications because:

1. **Theme switching fails**: Hard-coded colors don't change when the user switches between light and dark modes
2. **Accessibility issues**: Users with accessibility needs (high contrast, color blindness) can't customize colors
3. **Maintenance burden**: Changing colors requires finding and updating every hard-coded reference
4. **Inconsistent UI**: Different parts of the app may use slightly different color values for the "same" color

By accessing colors through `Theme.of(context).extension<AppColorsExtension>()`, your app:
- Automatically supports light/dark mode
- Respects user accessibility preferences
- Maintains consistent colors across the entire application
- Makes global color changes trivial (just update the theme)

## Bad Examples

```dart
// Static CoreUI tokens
Text(style: TextStyle(color: CoreTextColors.headline));

// Flutter Colors class
Container(color: Colors.white);
Container(color: Colors.grey[700]);

// CupertinoColors
Container(color: CupertinoColors.systemRed);

// Direct Color definitions
Container(color: Color(0xFF015B7C));
Container(color: Color.fromARGB(255, 0, 0, 0));

// Prefixed imports
Container(color: material.Colors.red);
```

## Good Examples

```dart
final colors = Theme.of(context).extension<AppColorsExtension>()!;

Text(style: TextStyle(color: colors.textHeadline));
Container(color: colors.pageBackground);
Container(color: colors.lineLight);
```

## Exceptions

This rule automatically skips files in the following locations:
- `/lib/src/theme/` - Theme definition files
- `/test/theme/` - Theme-related test files

These directories are excluded because they typically define the theme colors themselves and need to reference static color values.

## How to Fix

1. **Define your colors in a theme extension**:

```dart
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color textHeadline;
  final Color pageBackground;
  final Color lineLight;

  AppColorsExtension({
    required this.textHeadline,
    required this.pageBackground,
    required this.lineLight,
  });

  @override
  ThemeExtension<AppColorsExtension> copyWith({...}) { ... }

  @override
  ThemeExtension<AppColorsExtension> lerp(...) { ... }
}
```

2. **Register the extension with your themes**:

```dart
final lightTheme = ThemeData.light().copyWith(
  extensions: [
    AppColorsExtension(
      textHeadline: Color(0xFF000000),
      pageBackground: Color(0xFFFFFFFF),
      lineLight: Color(0xFFE0E0E0),
    ),
  ],
);

final darkTheme = ThemeData.dark().copyWith(
  extensions: [
    AppColorsExtension(
      textHeadline: Color(0xFFFFFFFF),
      pageBackground: Color(0xFF121212),
      lineLight: Color(0xFF2C2C2C),
    ),
  ],
);
```

3. **Access colors via the theme**:

```dart
@override
Widget build(BuildContext context) {
  final colors = Theme.of(context).extension<AppColorsExtension>()!;
  
  return Text(
    'Hello',
    style: TextStyle(color: colors.textHeadline),
  );
}
```

## Related Rules

- `avoid_static_typography` - Enforces theme-based typography access
- `avoid_static_colors` - The production version of this rule

## Additional Resources

- [Flutter Theming Documentation](https://docs.flutter.dev/cookbook/design/themes)
- [Theme Extensions Guide](https://api.flutter.dev/flutter/material/ThemeExtension-class.html)
