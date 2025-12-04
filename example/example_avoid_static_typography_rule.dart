// ignore_for_file: unused_local_variable, prefer_const_constructors

import 'package:flutter/material.dart';

// Mock classes for demonstration (these would be imported from actual packages)
class CoreTypography {
  static TextStyle headlineLargeSemiBold() => const TextStyle();
  static TextStyle bodyLargeRegular() => const TextStyle();
  static TextStyle titleLargeMedium() => const TextStyle();
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
}

class GoogleFonts {
  static TextStyle roboto({double? fontSize}) => const TextStyle();
  static TextStyle lato({double? fontSize}) => const TextStyle();
}

class TypographyExtension extends ThemeExtension<TypographyExtension> {
  final TextStyle? bodyLargeRegular;
  final TextStyle? bodyLargeMedium;
  final TextStyle? headlineLargeSemiBold;

  const TypographyExtension({
    this.bodyLargeRegular,
    this.bodyLargeMedium,
    this.headlineLargeSemiBold,
  });

  @override
  TypographyExtension copyWith({
    TextStyle? bodyLargeRegular,
    TextStyle? bodyLargeMedium,
    TextStyle? headlineLargeSemiBold,
  }) {
    return TypographyExtension(
      bodyLargeRegular: bodyLargeRegular ?? this.bodyLargeRegular,
      bodyLargeMedium: bodyLargeMedium ?? this.bodyLargeMedium,
      headlineLargeSemiBold:
          headlineLargeSemiBold ?? this.headlineLargeSemiBold,
    );
  }

  @override
  TypographyExtension lerp(TypographyExtension? other, double t) {
    return this;
  }
}

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color? textDark;
  final Color? textHeadline;

  const AppColorsExtension({this.textDark, this.textHeadline});

  @override
  AppColorsExtension copyWith({
    Color? textDark,
    Color? textHeadline,
  }) {
    return AppColorsExtension(
      textDark: textDark ?? this.textDark,
      textHeadline: textHeadline ?? this.textHeadline,
    );
  }

  @override
  AppColorsExtension lerp(AppColorsExtension? other, double t) {
    return this;
  }
}

// ============================================================================
// BAD EXAMPLES - These trigger the avoid_static_typography rule
// ============================================================================

class BadExample1StaticTypographyMethod extends StatelessWidget {
  final String title;

  const BadExample1StaticTypographyMethod({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    // ❌ BAD: Static method call bypasses theme
    return Text(
      title,
      style: CoreTypography.headlineLargeSemiBold(), // LINT
    );
  }
}

class BadExample2RawTextStyle extends StatelessWidget {
  const BadExample2RawTextStyle({super.key});

  @override
  Widget build(BuildContext context) {
    // ❌ BAD: Completely bypasses design system
    return Text(
      'Welcome back',
      style: TextStyle(
        // LINT
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class BadExample3GoogleFonts extends StatelessWidget {
  const BadExample3GoogleFonts({super.key});

  @override
  Widget build(BuildContext context) {
    // ❌ BAD: Font family should be defined in app_theme.dart
    return Text(
      'Hello',
      style: GoogleFonts.roboto(fontSize: 16), // LINT
    );
  }
}

class BadExample4StaticFontWeight extends StatelessWidget {
  const BadExample4StaticFontWeight({super.key});

  @override
  Widget build(BuildContext context) {
    // ❌ BAD: Using static font weight constant
    final weight = CoreTypography.semiBold; // LINT
    return Text('Example', style: TextStyle(fontWeight: weight));
  }
}

// ============================================================================
// GOOD EXAMPLES - These are the correct patterns
// ============================================================================

class GoodExample1ThemeExtension extends StatelessWidget {
  const GoodExample1ThemeExtension({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ GOOD: Access typography via Theme Extension
    final typography = Theme.of(context).extension<TypographyExtension>();

    return Text(
      'Hello World',
      style: typography?.bodyLargeRegular,
    );
  }
}

class GoodExample2WithColorOverride extends StatelessWidget {
  const GoodExample2WithColorOverride({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ GOOD: Typography with color override via copyWith
    final typography = Theme.of(context).extension<TypographyExtension>();
    final appColors = Theme.of(context).extension<AppColorsExtension>();

    return Text(
      'Custom colored text',
      style: typography?.bodyLargeMedium?.copyWith(
        color: appColors?.textDark,
      ),
    );
  }
}

class GoodExample3InlineAccess extends StatelessWidget {
  final String message;

  const GoodExample3InlineAccess({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    // ✅ GOOD: Inline access for single use
    return Text(
      message,
      style: Theme.of(context)
          .extension<TypographyExtension>()
          ?.bodyLargeRegular
          ?.copyWith(
            color:
                Theme.of(context).extension<AppColorsExtension>()?.textHeadline,
          ),
    );
  }
}

void main() {
  // Examples showing both bad and good patterns
}

