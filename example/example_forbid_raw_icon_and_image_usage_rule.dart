// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';

class CoreIcons {
  static const home = 0;
  static const contacts = 1;
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
        // ❌ VIOLATION: Direct Icon() usage with Icons.xxx
        const Icon(Icons.home), // LINT

        // ❌ VIOLATION: Direct Icon() with a different material icon
        Icon(Icons.import_contacts), // LINT

        // ❌ VIOLATION: Direct Image.asset() usage
        Image.asset('assets/images/logo.png'), // LINT
      ],
    );
  }
}

// ============================================================================
// ✅ CORRECT EXAMPLES - These will NOT trigger the linter
// ============================================================================

class CoreIcon extends StatelessWidget {
  final int icon;
  const CoreIcon(this.icon, {super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class CoreImage extends StatelessWidget {
  const CoreImage.asset(String path, {super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class CorrectExamples extends StatelessWidget {
  const CorrectExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        // ✅ CORRECT: Use CoreIcons constants via coreui abstractions
        CoreIcon(CoreIcons.home),
        CoreIcon(CoreIcons.contacts),

        // ✅ CORRECT: Use coreui abstraction components for images
        CoreImage.asset('assets/images/logo.png'),
      ],
    );
  }
}
