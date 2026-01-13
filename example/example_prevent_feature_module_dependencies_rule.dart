// ============================================================================
// EXAMPLE: Prevent Feature Module Dependencies Rule
// ============================================================================
// This rule ensures feature modules remain independent and can be developed,
// tested, and deployed in isolation. Features should NOT depend on other features.

// ============================================================================
// ❌ BAD EXAMPLES: Feature modules depending on other feature modules
// ============================================================================

class BadEstimationFeature {
  // Bad: Features in /lib/features/estimation/ importing from /lib/features/dashboard/
  // LINT: Feature modules cannot depend on other feature modules.
  void loadDashboardData() {
    // These imports are NOT allowed (cross-feature dependencies):
    // import 'package:project/features/dashboard/domain/entities/dashboard.dart';
    // import 'package:project/features/dashboard/data/models/dashboard_model.dart';
    // import '../domain/repositories/dashboard_repository.dart'; // relative import
  }
}

// ============================================================================
// ✅ CORRECT EXAMPLES: Feature modules with proper dependencies
// ============================================================================

class CorrectEstimationFeature {
  // ✅ GOOD: Imports from the same feature
  void loadEstimationData() {
    // These imports are allowed (same feature):
    // import 'package:project/features/estimation/domain/entities/order.dart';
    // import 'package:project/features/estimation/data/models/estimation_model.dart';
    // import '../domain/repositories/estimation_repository.dart'; // relative import
  }

  // ✅ GOOD: Imports from external packages
  void buildUI() {
    // These imports are allowed (external packages):
    // import 'package:flutter/material.dart';
    // import 'package:provider/provider.dart';
    // import 'package:get_it/get_it.dart';
  }
}

// ============================================================================
// ARCHITECTURAL GUIDELINES
// ============================================================================
//
// FEATURE STRUCTURE:
//   lib/
//   ├── features/
//   │   ├── auth/               # Feature module (independent)
//   │   ├── dashboard/          # Feature module (independent)
//   │   ├── estimation/         # Feature module (independent)
//   │   └── project/            # Feature module (independent)
//   ├── libraries/
//
// DEPENDENCY RULES:
//
// ❌ FORBIDDEN: Feature → Feature dependencies
//    auth CANNOT import from dashboard, estimation, project, etc.
//    dashboard CANNOT import from auth, estimation, project, etc.
//
// ✅ ALLOWED: Feature → Same Feature dependencies
//    auth CAN import from auth/
//    dashboard CAN import from dashboard/
//    (Absolute: package:project/features/auth/...)
//    (Relative: ../domain/..., ../data/...)
//
// ✅ ALLOWED: Feature → External Package dependencies
//    Any feature CAN import from external packages
//    (package:flutter/...)
//    (package:provider/...)
//    (Any pub.dev package)
