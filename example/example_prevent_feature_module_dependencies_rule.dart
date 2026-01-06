// ============================================================================
// EXAMPLE: Prevent Feature Module Dependencies Rule
// ============================================================================
// This rule ensures feature modules remain independent and can be developed,
// tested, and deployed in isolation. Features should NOT depend on other features.

// ============================================================================
// ❌ BAD EXAMPLES: Feature modules depending on other feature modules
// ============================================================================

class BadCheckoutFeature {
  // Bad: Features in /lib/features/checkout/ importing from /lib/features/dashboard/
  // LINT: Feature modules cannot depend on other feature modules.
  void displayDashboard() {
    // Imagine this imports from: package:project/features/dashboard/...
    print('Displaying Dahsboard'); // ❌ LINT
  }

  // Bad: Importing from another feature
  // LINT: Feature modules cannot depend on other feature modules.
  void checkUserPermission() {
    print('Checking permission'); // ❌ LINT
  }

  // Bad: Cross-feature export
  // LINT: Feature modules cannot depend on other feature modules.
  void processProject() {
    print('Processing project'); // ❌ LINT
  }
}

// ============================================================================
// ✅ CORRECT EXAMPLES: Feature modules with proper dependencies
// ============================================================================

class CorrectCheckoutFeature {
  // ✅ GOOD: Imports from the same feature
  void loadEstimationData() {
    // These imports are allowed (same feature):
    // import 'package:project/features/checkout/domain/entities/order.dart';
    // import 'package:project/features/checkout/data/models/checkout_model.dart';
    // import '../domain/repositories/checkout_repository.dart'; // relative import

    print('Loading estimation data from same feature');
  }

  // ✅ GOOD: Imports from core layer (available to all features)
  void logActivity() {
    // These imports are allowed (core/shared layers):
    // import 'package:project/core/constants/app_constants.dart';
    // import 'package:project/core/services/logger_service.dart';
    // import 'package:project/shared/widgets/common_button.dart';

    print('Logging activity using core services');
  }

  // ✅ GOOD: Imports from external packages
  void buildUI() {
    // These imports are allowed (external packages):
    // import 'package:flutter/material.dart';
    // import 'package:provider/provider.dart';
    // import 'package:get_it/get_it.dart';

    print('Building UI with external packages');
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
//
//
// ============================================================================
