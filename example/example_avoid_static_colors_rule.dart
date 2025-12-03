// ignore_for_file: unused_local_variable, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// Mock classes to simulate CoreUI color tokens
class CoreTextColors {
  static const Color headline = Color(0xFF101828);
  static const Color dark = Color(0xFF1D2939);
  static const Color body = Color(0xFF475467);
  static const Color disable = Color(0xFF98A2B3);
  static const Color inverse = Color(0xFFFFFFFF);
}

class CoreBackgroundColors {
  static const Color pageBackground = Color(0xFFFFFFFF);
  static const Color backgroundGrayLight = Color(0xFFF9FAFB);
}

class CoreBorderColors {
  static const Color lineLight = Color(0xFFE4E7EC);
}

class CoreIconColors {
  static const Color dark = Color(0xFF101828);
}

class CoreButtonColors {
  static const Color surface = Color(0xFF015B7C);
}

// Mock AppColorsExtension for correct usage example
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color textHeadline;
  final Color pageBackground;
  final Color lineLight;
  final Color iconDark;
  final Color buttonSurface;

  const AppColorsExtension({
    required this.textHeadline,
    required this.pageBackground,
    required this.lineLight,
    required this.iconDark,
    required this.buttonSurface,
  });

  @override
  ThemeExtension<AppColorsExtension> copyWith() => this;

  @override
  ThemeExtension<AppColorsExtension> lerp(
    covariant ThemeExtension<AppColorsExtension>? other,
    double t,
  ) =>
      this;
}

// ============================================================================
// ❌ VIOLATION EXAMPLES - These will trigger the linter
// ============================================================================

class ViolationExamples extends StatelessWidget {
  const ViolationExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ❌ VIOLATION: CoreTextColors static token
        Text(
          'Hello',
          style: TextStyle(color: CoreTextColors.headline), // LINT
        ),

        // ❌ VIOLATION: CoreBackgroundColors static token
        Scaffold(
          backgroundColor: CoreBackgroundColors.pageBackground, // LINT
        ),

        // ❌ VIOLATION: CoreBorderColors static token
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: CoreBorderColors.lineLight), // LINT
          ),
        ),

        // ❌ VIOLATION: CoreIconColors static token
        Icon(Icons.home, color: CoreIconColors.dark), // LINT

        // ❌ VIOLATION: CoreButtonColors static token
        Container(color: CoreButtonColors.surface), // LINT

        // ❌ VIOLATION: Flutter Colors class
        Container(color: Colors.white), // LINT

        // ❌ VIOLATION: Flutter Colors class
        Container(color: Colors.black), // LINT
        
        // ❌ VIOLATION: Flutter Colors class
        Container(color:Colors.orange), // LINT

        // ❌ VIOLATION: Flutter Colors with index access
        Container(color: Colors.grey[700]), // LINT

        // ❌ VIOLATION: CupertinoColors - iOS system colors
        Container(color: CupertinoColors.systemRed), // LINT

        // ❌ VIOLATION: CupertinoColors - active colors
        Container(color: CupertinoColors.activeBlue), // LINT

        // ❌ VIOLATION: CupertinoColors - background colors
        Container(color: CupertinoColors.systemBackground), // LINT

        // ❌ VIOLATION: CupertinoColors - label colors
        Container(
          child: Text(
            'Label',
            style: TextStyle(color: CupertinoColors.label), // LINT
          ),
        ),

        // ❌ VIOLATION: CupertinoColors - destructive action
        CupertinoButton(
          color: CupertinoColors.destructiveRed, // LINT
          onPressed: () {},
          child: Text('Delete'),
        ),

        // ❌ VIOLATION: Direct hex color
        Container(color: Color(0xFF015B7C)), // LINT

        // ❌ VIOLATION: Color.fromARGB
        Container(color: Color.fromARGB(255, 0, 0, 0)), // LINT

        // ❌ VIOLATION: Color.fromRGBO
        Container(color: Color.fromRGBO(255, 255, 255, 1.0)), // LINT

        // ❌ VIOLATION: Multiple violations in one widget
        Container(
          color: CoreBackgroundColors.backgroundGrayLight, // LINT
          child: Text(
            'Multiple violations',
            style: TextStyle(color: CoreTextColors.dark), // LINT
          ),
        ),

        // ❌ VIOLATION: Ternary with static colors
        Container(
          color: true
              ? CoreTextColors.body // LINT
              : CoreTextColors.inverse, // LINT
        ),
      ],
    );
  }
}

// ============================================================================
// ✅ CORRECT EXAMPLES - These will NOT trigger the linter
// ============================================================================

class CorrectExamples extends StatelessWidget {
  const CorrectExamples({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ CORRECT: Get colors from theme extension
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return Column(
      children: [
        // ✅ CORRECT: Using theme extension for text color
        Text(
          'Hello',
          style: TextStyle(color: colors.textHeadline),
        ),

        // ✅ CORRECT: Using theme extension for background color
        Scaffold(
          backgroundColor: colors.pageBackground,
        ),

        // ✅ CORRECT: Using theme extension for border color
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: colors.lineLight),
          ),
        ),

        // ✅ CORRECT: Using theme extension for icon color
        Icon(Icons.home, color: colors.iconDark),

        // ✅ CORRECT: Using theme extension for button color
        Container(color: colors.buttonSurface),

        // ✅ CORRECT: Ternary with theme colors
        Container(
          color: true ? colors.textHeadline : colors.pageBackground,
        ),
      ],
    );
  }
}

// ============================================================================
// Alternative: Context extension for cleaner access
// ============================================================================

extension AppColorsContext on BuildContext {
  AppColorsExtension get colors =>
      Theme.of(this).extension<AppColorsExtension>()!;
}

class CorrectWithExtension extends StatelessWidget {
  const CorrectWithExtension({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ CORRECT: Using context extension for even cleaner access
    return Container(
      color: context.colors.pageBackground,
      child: Text(
        'Clean access',
        style: TextStyle(color: context.colors.textHeadline),
      ),
    );
  }
}


