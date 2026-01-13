// ============================================================================
// EXAMPLE: Prevent Library Module Dependencies Rule
// ============================================================================
// This rule ensures library modules remain reusable and do not depend on
// feature-specific code. Libraries should be independent and shared across features.

// ============================================================================
// ❌ BAD EXAMPLES: Library modules importing from feature modules
// ============================================================================

class BadLibraryModule {
  // Bad: Files in /lib/libraries/ importing from /lib/features/
  // LINT: Library modules cannot import from feature modules.
  void loadFeatureData() {
    // These imports are NOT allowed (library depending on feature):
    // import 'package:construculator/features/auth/data/models/auth_user.dart';
    // import 'package:construculator/features/dashboard/presentation/pages/dashboard_page.dart';
    // import 'package:construculator/features/estimation/domain/entities/estimation.dart';
    // import '../features/project/data/models/project_model.dart'; // relative import
  }
}

// ============================================================================
// ✅ CORRECT EXAMPLES: Library modules with proper dependencies
// ============================================================================

class CorrectLibraryModule {
  // ✅ GOOD: Library imports from another library
  void loadLibraryData() {
    // These imports are allowed (library to library):
    // import 'package:construculator/libraries/time/interfaces/clock.dart';
    // import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
    // import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
    // import '../either/interfaces/either.dart'; // relative import within libraries
  }

  // ✅ GOOD: Library imports from external packages
  void buildUI() {
    // These imports are allowed (external packages):
    // import 'package:flutter/material.dart';
    // import 'package:flutter_modular/flutter_modular.dart';
    // import 'package:freezed_annotation/freezed_annotation.dart';
  }

  // ✅ GOOD: Dart SDK imports
  void useCore() {
    // These imports are allowed (Dart SDK):
    // import 'dart:async';
    // import 'dart:convert';
  }
}

// ============================================================================
// ARCHITECTURAL GUIDELINES
// ============================================================================
//
// FOLDER STRUCTURE (construculator-app):
//   lib/
//   ├── features/
//   │   ├── auth/               # Feature module
//   │   ├── dashboard/          # Feature module
//   │   ├── estimation/         # Feature module
//   │   └── project/            # Feature module
//   └── libraries/
//       ├── auth/               # Library module (shared auth utilities)
//       ├── config/             # Library module (configuration)
//       ├── either/             # Library module (Either pattern)
//       ├── project/            # Library module (shared project utilities)
//       ├── router/             # Library module (navigation)
//       ├── storage/            # Library module (storage services)
//       ├── supabase/           # Library module (Supabase integration)
//       └── time/               # Library module (time utilities)
//
// DEPENDENCY RULES:
//
// ❌ FORBIDDEN: Library → Feature dependencies
//    libraries/auth CANNOT import from features/auth
//    libraries/project CANNOT import from features/dashboard
//    Any file in /libraries/ CANNOT have imports containing /features/
//
// ✅ ALLOWED: Library → Library dependencies
//    libraries/auth CAN import from libraries/time
//    libraries/project CAN import from libraries/either
//
// ✅ ALLOWED: Library → External Package dependencies
//    Any library CAN import from external packages
//    (package:flutter/...)
//    (package:flutter_modular/...)
//
// ✅ ALLOWED: Feature → Library dependencies
//    features/auth CAN import from libraries/auth
//    features/dashboard CAN import from libraries/project
//
// RATIONALE:
// - Libraries are meant to be reusable across multiple features
// - Features are specific implementations that may change frequently
// - Libraries should not be coupled to specific feature implementations
// - This enables better code reuse and maintainability
