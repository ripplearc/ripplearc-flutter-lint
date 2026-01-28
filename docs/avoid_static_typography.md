# avoid_static_typography

Disallows static typography definitions (`CoreTypography.*` including static font-weight constants like `CoreTypography.semiBold`), raw `TextStyle` constructors, and direct `GoogleFonts.*` usage in production code. Typography must be accessed through `Theme.of(context).extension<TypographyExtension>()` so it participates in theming and dark mode.

## Bad ❌
```dart
// Static CoreTypography
Text(
  'Hello',
  style: CoreTypography.bodyLargeRegular(),
);

// Raw TextStyle
Text(
  'Welcome back',
  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
);

// GoogleFonts
Text(
  'Hello',
  style: GoogleFonts.roboto(fontSize: 16),
);
```

## Good ✅
```dart
final typography = Theme.of(context).extension<TypographyExtension>();

Text(
  'Hello',
  style: typography?.bodyLargeRegular,
);

Text(
  'Hello',
  style: typography?.bodyLargeMedium?.copyWith(
    color: colors.textHeadline,
  ),
);
```
