// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';

class CoreIconData {
  final IconData? materialIcon;
  final String? svgPath;

  const CoreIconData.material(this.materialIcon) : svgPath = null;
  const CoreIconData.svg(this.svgPath) : materialIcon = null;

  bool get isSvg => svgPath != null;
}

class CoreMaterialIcons {
  static const arrowRight = CoreIconData.material(Icons.keyboard_arrow_right);
  static const arrowLeft = CoreIconData.material(Icons.keyboard_arrow_left);
}

class CoreIcons {
  static const arrowRight = CoreMaterialIcons.arrowRight;
  static const arrowLeft = CoreMaterialIcons.arrowLeft;
  static const microsoft =
      CoreIconData.svg('packages/coreui/assets/icons/microsoft.svg');
}

// ============================================================================
// ❌ VIOLATION EXAMPLES - These will trigger the linter
// ============================================================================

class ViolationExamples {
  void directCoreIconDataSvg() {
    // ❌ VIOLATION: Direct CoreIconData.svg() usage
    const icon = CoreIconData.svg('assets/icons/custom.svg'); // LINT
  }

  void directCoreIconDataMaterial() {
    // ❌ VIOLATION: Direct CoreIconData.material() usage
    const icon = CoreIconData.material(Icons.home); // LINT
  }

  void coreMaterialIconsUsage() {
    // ❌ VIOLATION: Direct CoreMaterialIcons access
    const icon = CoreMaterialIcons.arrowRight; // LINT
  }

  void coreMaterialIconsAnotherUsage() {
    // ❌ VIOLATION: Direct CoreMaterialIcons access
    const icon = CoreMaterialIcons.arrowLeft; // LINT
  }
}

// ============================================================================
// ✅ CORRECT EXAMPLES - These will NOT trigger the linter
// ============================================================================

class CorrectExamples {
  void useCoreIconsConstants() {
    // ✅ CORRECT: Using CoreIcons constants
    const icon1 = CoreIcons.arrowRight;
    const icon2 = CoreIcons.arrowLeft;
    const icon3 = CoreIcons.microsoft;
  }

  void useCoreIconsInWidget() {
    // ✅ CORRECT: Using CoreIcons in widget context
    final icons = [
      CoreIcons.arrowRight,
      CoreIcons.arrowLeft,
      CoreIcons.microsoft,
    ];
  }
}
