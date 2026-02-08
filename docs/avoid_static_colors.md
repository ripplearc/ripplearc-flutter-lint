# avoid_static_colors

Enforces theme-context-based color access for proper light/dark mode support. This rule flags static color usage that breaks theme switching.

## Bad ❌
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

## Good ✅
```dart
final colors = Theme.of(context).extension<AppColorsExtension>()!;

Text(style: TextStyle(color: colors.textHeadline));
Container(color: colors.pageBackground);
Container(color: colors.lineLight);
```

## What's Detected
- **CoreUI tokens**: `CoreTextColors`, `CoreBackgroundColors`, `CoreBorderColors`, `CoreIconColors`, `CoreButtonColors`, `CoreStatusColors`, `CoreChipColors`, `CoreAlertColors`, `CoreKeyboardColors`, `CoreShadowColors`, `CoreBrandColors`
- **Flutter colors**: `Colors.white`, `Colors.grey[700]`, etc.
- **Cupertino colors**: `CupertinoColors.systemRed`, etc.
- **Direct definitions**: `Color(0xFF...)`, `Color.fromARGB(...)`, `Color.fromRGBO(...)`
- **Prefixed imports**: `material.Colors.red`, `m.Color(0xFF...)`
