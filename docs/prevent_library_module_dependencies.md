# prevent_library_module_dependencies

Enforces library module independence by preventing library modules from importing feature modules. This rule ensures that libraries remain reusable and do not have feature-specific dependencies, enabling better code reuse and maintainability.

## Bad ❌
```dart
// lib/libraries/auth/auth_library_module.dart
import 'package:project/features/auth/presentation/pages/login_page.dart'; // LINT: Library importing a feature
import 'package:project/features/dashboard/domain/entities/dashboard.dart'; // LINT: Library importing a feature

class AuthLibraryModule {
  void initialize() {
    // Library code should not depend on feature implementations
  }
}
```

## Good ✅
```dart
// lib/libraries/auth/auth_library_module.dart

// Good: Imports from other libraries
import 'package:project/libraries/time/interfaces/clock.dart';
import 'package:project/libraries/supabase/interfaces/supabase_wrapper.dart';

// Good: External packages
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AuthLibraryModule {
  void initialize() {
    // Library code with proper dependencies
  }
}
```

## Allowed Patterns
- **Library-to-library imports**: Libraries can import from other libraries (`package:project/libraries/...`)
- **External packages**: All libraries can import from Flutter, Dart SDK, and pub.dev packages
- **Dart SDK**: All libraries can import Dart core libraries (`dart:async`, `dart:convert`, etc.)

## Library Structure
```
lib/
├── features/              # Feature modules (can import from libraries)
│   ├── auth/
│   ├── dashboard/
│   └── project/
└── libraries/             # Library modules (cannot import from features)
    ├── auth/              # Shared auth utilities
    ├── config/            # Configuration
    ├── either/            # Either pattern
    ├── project/           # Shared project utilities
    ├── router/            # Navigation
    ├── storage/           # Storage services
    ├── supabase/          # Supabase integration
    └── time/              # Time utilities
```
