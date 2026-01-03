// ============================================================================
// EXAMPLE: Prevent Feature Module Dependencies Rule
// ============================================================================
// This rule ensures feature modules remain independent and can be developed,
// tested, and deployed in isolation. Features should NOT depend on other features.

// ============================================================================
// ❌ BAD EXAMPLES: Feature modules depending on other feature modules
// ============================================================================

class BadCheckoutFeature {
  // Bad: Features in /lib/features/checkout/ importing from /lib/features/product/
  // LINT: Feature modules cannot depend on other feature modules.
  void displayProduct() {
    // Imagine this imports from: package:project/features/product/...
    print('Displaying product'); // ❌ LINT
  }

  // Bad: Importing from another feature
  // LINT: Feature modules cannot depend on other feature modules.
  void checkUserPermission() {
    // Imagine this imports from: package:project/features/auth/...
    print('Checking permission'); // ❌ LINT
  }

  // Bad: Cross-feature export
  // LINT: Feature modules cannot depend on other feature modules.
  void processPayment() {
    // Imagine this exports from: package:project/features/payment/...
    print('Processing payment'); // ❌ LINT
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
//   │   ├── product/            # Feature module (independent)
//   │   ├── checkout/           # Feature module (independent)
//   │   └── payment/            # Feature module (independent)
//   ├── core/                   # Shared utilities (all features depend on this)
//   ├── shared/                 # Shared widgets (all features depend on this)
//   └── utils/                  # Helper utilities (all features depend on this)
//
// DEPENDENCY RULES:
//
// ❌ FORBIDDEN: Feature → Feature dependencies
//    auth CANNOT import from dashboard, checkout, payment, etc.
//    dashboard CANNOT import from auth, checkout, payment, etc.
//
// ✅ ALLOWED: Feature → Same Feature dependencies
//    auth CAN import from auth/
//    dashboard CAN import from dashboard/
//    (Absolute: package:project/features/auth/...)
//    (Relative: ../domain/..., ../data/...)
//
// ✅ ALLOWED: Feature → Core/Shared/Utils dependencies
//    Any feature CAN import from core/, shared/, utils/
//    (package:project/core/...)
//    (package:project/shared/...)
//    (package:project/utils/...)
//
// ✅ ALLOWED: Feature → External Package dependencies
//    Any feature CAN import from external packages
//    (package:flutter/...)
//    (package:provider/...)
//    (Any pub.dev package)
//
// ✅ ALLOWED: Non-Feature → Feature dependencies
//    lib/main.dart CAN import features (initialization context)
//    lib/app/app.dart CAN import features (DI setup)
//    This is allowed because these are bootstrap files, not feature modules.
//
// ============================================================================
