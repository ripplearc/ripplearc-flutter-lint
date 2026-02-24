import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// BAD: Static CoreUI tokens
class BadCoreUITokens extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'Hello',
      // LINT: Static color token "CoreTextColors.headline" detected
      style: TextStyle(color: CoreTextColors.headline),
    );
  }
}

// BAD: Flutter Colors class
class BadFlutterColors extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // LINT: Flutter Colors class usage "Colors.white" detected
        Container(color: Colors.white),
        // LINT: Flutter Colors class index access "Colors.grey[...]" detected
        Container(color: Colors.grey[700]),
      ],
    );
  }
}

// BAD: CupertinoColors
class BadCupertinoColors extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // LINT: Flutter CupertinoColors class usage "CupertinoColors.systemRed" detected
    return Container(color: CupertinoColors.systemRed);
  }
}

// BAD: Direct Color definitions
class BadDirectColors extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // LINT: Direct color definition "Color(0xFF015B7C)" detected
        Container(color: Color(0xFF015B7C)),
        // LINT: Direct color definition "Color.fromARGB(...)" detected
        Container(color: Color.fromARGB(255, 0, 0, 0)),
      ],
    );
  }
}

// BAD: Prefixed imports
import 'package:flutter/material.dart' as material;

class BadPrefixedImports extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // LINT: Flutter Colors class usage (via prefixed import) detected
    return Container(color: material.Colors.red);
  }
}

// GOOD: Theme-based color access
class GoodThemeColors extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // OK: Using theme extension for color access
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    
    return Column(
      children: [
        // OK: Color from theme extension
        Text(
          'Hello',
          style: TextStyle(color: colors.textHeadline),
        ),
        // OK: Color from theme extension
        Container(color: colors.pageBackground),
        // OK: Color from theme extension
        Container(color: colors.lineLight),
      ],
    );
  }
}

// Example CoreUI color classes (for demonstration)
class CoreTextColors {
  static const headline = Color(0xFF000000);
  static const body = Color(0xFF333333);
}

class CoreBackgroundColors {
  static const pageBackground = Color(0xFFFFFFFF);
}

// Example theme extension (for demonstration)
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
  ThemeExtension<AppColorsExtension> copyWith({
    Color? textHeadline,
    Color? pageBackground,
    Color? lineLight,
  }) {
    return AppColorsExtension(
      textHeadline: textHeadline ?? this.textHeadline,
      pageBackground: pageBackground ?? this.pageBackground,
      lineLight: lineLight ?? this.lineLight,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(
    ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      textHeadline: Color.lerp(textHeadline, other.textHeadline, t)!,
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      lineLight: Color.lerp(lineLight, other.lineLight, t)!,
    );
  }
}
