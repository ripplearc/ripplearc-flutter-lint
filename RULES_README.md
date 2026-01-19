## Rules

### avoid_static_colors

Enforces theme-context-based color access for proper light/dark mode support. This rule flags static color usage that breaks theme switching.

#### Bad ❌
```dart
// Static CoreUI tokens
Text(style: TextStyle(color: CoreTextColors.headline));

// Flutter Colors class
Container(color: Colors.white);
Container(color: Colors.grey[700]);

// CupertinoColors
Container(color: CupertinoColors.systemRed);

// Direct Color definitions
Container(color: Color(0xFF015B7C));
Container(color: Color.fromARGB(255, 0, 0, 0));

// Prefixed imports
Container(color: material.Colors.red);
```

#### Good ✅
```dart
final colors = Theme.of(context).extension<AppColorsExtension>()!;

Text(style: TextStyle(color: colors.textHeadline));
Container(color: colors.pageBackground);
Container(color: colors.lineLight);
```

#### What's Detected
- **CoreUI tokens**: `CoreTextColors`, `CoreBackgroundColors`, `CoreBorderColors`, `CoreIconColors`, `CoreButtonColors`, `CoreStatusColors`, `CoreChipColors`, `CoreAlertColors`, `CoreKeyboardColors`, `CoreShadowColors`, `CoreBrandColors`
- **Flutter colors**: `Colors.white`, `Colors.grey[700]`, etc.
- **Cupertino colors**: `CupertinoColors.systemRed`, etc.
- **Direct definitions**: `Color(0xFF...)`, `Color.fromARGB(...)`, `Color.fromRGBO(...)`
- **Prefixed imports**: `material.Colors.red`, `m.Color(0xFF...)`


### avoid_static_typography

Disallows static typography definitions (`CoreTypography.*` including static font-weight constants like `CoreTypography.semiBold`), raw `TextStyle` constructors, and direct `GoogleFonts.*` usage in production code. Typography must be accessed through `Theme.of(context).extension<TypographyExtension>()` so it participates in theming and dark mode.

#### Bad ❌
```dart
// Static CoreTypography
Text(
  'Hello',
  style: CoreTypography.bodyLargeRegular(),
);

// Raw TextStyle
Text(
  'Welcome back',
  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
);

// GoogleFonts
Text(
  'Hello',
  style: GoogleFonts.roboto(fontSize: 16),
);
```

#### Good ✅
```dart
final typography = Theme.of(context).extension<TypographyExtension>();

Text(
  'Hello',
  style: typography?.bodyLargeRegular,
);

Text(
  'Hello',
  style: typography?.bodyLargeMedium?.copyWith(
    color: colors.textHeadline,
  ),
);
```


### prefer_fake_over_mock

Recommends using `Fake` instead of `Mock` for test doubles. Fakes provide more realistic behavior and are easier to maintain than mocks.

#### Bad ❌
```dart
class MockUserRepository extends Mock implements UserRepository {}
```

#### Good ✅
```dart
class FakeUserRepository extends Fake implements UserRepository {
  @override
  Future<User> getUser(String id) async => User(id: id, name: 'Test User');
}
```

### forbid_forced_unwrapping

Forbids the use of forced unwrapping (`!`) in production code. This rule encourages the use of null-safe alternatives to prevent runtime null errors.

#### Bad ❌
```dart
final name = user.name!;  // Will crash if name is null
print('User: $name');
```

#### Good ✅
```dart
final name = user.name ?? 'Unknown';  // Safe with default value
print('User: $name');
```

### no_optional_operators_in_tests

Forbids the use of optional operators (`?.`, `??`, `??=`, `?[]`) in test files. Tests should fail explicitly at the point of failure rather than silently handling null values. This rule is enforced as an error to ensure test reliability.

#### Bad ❌
```dart
test('example', () {
  final result = someObject?.someProperty;  // ERROR
  final value = someValue ?? defaultValue;  // ERROR
  someValue ??= defaultValue;  // ERROR
  final item = someList?[0];  // ERROR
});
```

#### Good ✅
```dart
test('example', () {
  final result = someObject.someProperty;  // Will fail explicitly if null
  expect(result, equals(expected));
});
```

### avoid_test_timeouts

Forbids using `.timeout()` and `Future.delayed()` in test blocks to prevent flaky tests. These patterns can cause non-deterministic test failures. Applies to `test`, `group`, `testWidgets`, and lifecycle methods (`setUp`, `tearDown`, `setUpAll`, `tearDownAll`).

#### Bad ❌
```dart
test('example', () async {
  await future.timeout(Duration(seconds: 1));  // ERROR
  await Future.delayed(Duration(milliseconds: 10));  // ERROR
});

testWidgets('widget test', (tester) async {
  await Future.delayed(Duration(milliseconds: 100));  // ERROR
});
```

#### Good ✅
```dart
test('example', () async {
  await expectLater(stream, emits(expectedValue));
});

testWidgets('widget test', (tester) async {
  await tester.pumpAndSettle();  // Proper widget testing
});
```

### no_direct_instantiation

Enforces dependency injection by forbidding direct class instantiation. This rule flags direct instantiations of classes to ensure proper dependency injection is used, improving testability and maintainability. Classes that extend `Module`, have names ending with "Factory", or any instantiation that occurs inside a class that extends `Module` are excluded.

#### Bad ❌
```dart
// Bad: Direct instantiation of classes
class BadService {
  void doSomething() {
    final service = AuthService(); // LINT: Direct instantiation not allowed
    final wrapper = FakeSupabaseWrapper(); // LINT: Direct instantiation not allowed
  }
}
```

#### Good ✅
```dart
// Good: Using dependency injection
class GoodService {
  void doSomething() {
    final service = Modular.get<AuthService>(); // Good: Using DI
    final wrapper = Modular.get<FakeSupabaseWrapper>(); // Good: Using DI
  }
}

// Good: Factory classes can be instantiated directly
class FactoryExample {
  void createFactory() {
    final factory = FileProcessorFactory(); // Good: Factory class
  }
}

// Good: Module classes can be instantiated directly
class ModuleExample {
  void createModule() {
    final module = AppModule(); // Good: Module class
  }
}

// Good: Instantiation inside Module class
class AppModule extends Module {
  AppModule() {
    final service = AuthService(); // ✅ Allowed: Inside Module class
    final wrapper = FakeSupabaseWrapper(); // ✅ Allowed: Inside Module class
  }
}
```

#### Excluded Classes/Contexts
- **Module classes**: Classes that extend `Module`
- **Factory classes**: Classes whose names end with "Factory" (e.g., `DatabaseFactory`, `HttpClientFactory`)
- **Inside Module**: Any direct instantiation inside a class that extends `Module`

### document_fake_parameters

Enforces documentation on Fake classes and their non-private members. This rule ensures that test helper methods and variables in Fake classes are properly documented for better test maintainability and team collaboration. Only applies to classes that extend `Fake` and implement interfaces.

#### Bad ❌
```dart
class FakeAuthService extends Fake implements AuthService {
  void setAuthDelay(Duration delay) {} // Missing documentation
  void triggerAuthFailure() {} // Missing documentation

  @override
  Future<void> authenticate() async {}
}

/// Fake implementation of UserRepository for testing.
class FakeUserRepository extends Fake implements UserRepository {
  void setUserData(User user) {} // Missing documentation
  void triggerNetworkError() {} // Missing documentation

  @override
  Future<User?> getUser(String id) async => null;
  
### todo_with_story_links

Ensures TODO comments include YouTrack story links for proper project management and technical debt tracking. This rule flags TODO comments that don't include a valid YouTrack URL, ensuring technical debt is properly linked to product backlog items.

#### Bad ❌
```dart
//TODO: Fix this later  // LINT: Missing YouTrack URL
// TODO: Refactor this method  // LINT: Missing YouTrack URL
//TODO: Add error handling  // LINT: Missing YouTrack URL
### no_internal_method_docs

Forbids documentation on private methods to reduce documentation noise. This rule flags private methods that have documentation comments, as these are internal implementation details that don't need to be documented for external consumers. Getters, setters, and fields are ignored.

#### Bad ❌
```dart
class AuthService {
  /// Handles internal auth state
  void _handleAuthState() {} // LINT: Private method should not be documented

  // Validates user input
  void _validateInput(String input) {} // LINT: Private method should not be documented

  /// Processes user data internally
  void _processUserData() {} // LINT: Private method should not be documented

### document_interface

Enforces documentation on abstract classes and their public methods. This rule ensures clear API contracts for modular architecture by requiring `///` documentation for both the class and its public methods. Private methods and concrete classes are ignored.

#### Bad ❌
```dart
abstract class SyncRepository {
  Future<void> syncData();  // Missing method documentation
  Future<void> clearData(); // Missing method documentation
}

/// Repository interface for data synchronization operations.
abstract class UserRepository {
  Future<String> getUser(String id);  // Missing method documentation
}

```

#### Good ✅
```dart

// Good: Using dependency injection
final authService = Modular.get<AuthService>();
final userService = Modular.get<UserService>();

// Good: Module instantiation - should not be flagged
final module = AppModule();

// Good: Factory class instantiation - should not be flagged
final databaseFactory = DatabaseFactory();
final httpClientFactory = HttpClientFactory();
final fileProcessorFactory = FileProcessorFactory();

// Good: Static factory method - should not be flagged
final staticFactory = AuthService.create();
```

#### Excluded Classes
- **Module classes**: Classes that extend `Module`
- **Factory classes**: Classes whose names end with "Factory" (e.g., `DatabaseFactory`, `HttpClientFactory`)

/// Fake implementation of AuthService for testing authentication scenarios.
class FakeAuthService extends Fake implements AuthService {
  /// Sets authentication delay for testing timing scenarios.
  /// Useful for testing timeout handling and loading states.
  void setAuthDelay(Duration delay) {}

  /// Simulates authentication failure for error handling tests.
  /// Triggers the same error conditions as the real service.
  void triggerAuthFailure() {}

  @override
  Future<void> authenticate() async {} // Override - no documentation needed
}

/// Fake implementation of UserRepository for testing.
class FakeUserRepository extends Fake implements UserRepository {
  /// Sets user data for testing scenarios.
  void setUserData(User user) {}

  void _validateUser(User user) {} // Private method - no documentation needed

  @override
  Future<User?> getUser(String id) async => null; // Override - no documentation needed
  
//TODO: https://ripplearc.youtrack.cloud/issue/CA-123
// TODO: https://ripplearc.youtrack.cloud/issue/UI-456
//TODO: https://ripplearc.youtrack.cloud/issue/BE-789 - Fix authentication timeout
```

#### Valid YouTrack URL Format
- **Domain**: `https://ripplearc.youtrack.cloud/issue/`
- **Project code**: Any uppercase letters (e.g., `CA`, `UI`, `BE`, `API`, `PERF`)
- **Issue number**: Any digits (e.g., `123`, `456`, `789`)

#### Excluded Files
- **Test files**: Files with `_test.dart` or in `/test/` directories are ignored
- **Regular comments**: Comments not starting with `TODO:` are ignored
- **Block comments**: `/* TODO: */` and `/** TODO: */` are ignored

class AuthService {
  void _handleAuthState() {} // Good: No documentation needed
  void _validateInput(String input) {} // Good: No documentation needed
  void _processUserData() {} // Good: No documentation needed

  /// Authenticates the user with provided credentials
  void authenticate() {} // Good: Public method should be documented
}

class DataService {
  /// Internal configuration data
  Map<String, dynamic> _config = {}; // Good: Fields can have documentation

  /// Internal state getter
  bool get _isInitialized => true; // Good: Getters can have documentation

  void _loadConfig() {} // Good: No documentation needed

  /// Loads configuration from external source
  Future<void> loadConfiguration() async {}

/// Repository interface for data synchronization operations.
abstract class DataRepository {
  /// Synchronizes local data with remote Supabase instance.
  /// Returns true if synchronization was successful.
  Future<bool> syncData();

  /// Clears all local data from the repository.
  /// This operation cannot be undone.
  Future<void> clearData();

  /// Retrieves data by its unique identifier.
  /// Returns null if no data is found for the given id.
  Future<String?> getData(String id);
}

// Private methods are ignored (no documentation required)
/// Repository interface for data synchronization operations.
abstract class SecureRepository {
  /// Synchronizes local data with remote Supabase instance.
  Future<bool> syncData();

  Future<void> _validateData(); // Private method - no documentation needed
}
```

### prevent_feature_module_dependencies

Enforces feature module independence by preventing feature modules from depending on other feature modules. This rule ensures that each feature can be developed, tested, and deployed in isolation, reducing coupling and improving modularity.

#### Bad ❌
```dart
// lib/features/estimation/presentation/pages/estimation_page.dart
import 'package:project/features/estimation/data/models/estimation.dart'; // LINT: Feature importing another feature
import 'package:project/features/estimation/domain/entities/estimation.dart'; // LINT: Feature importing another feature

class DashboardPage {
  void displayDate(Dashboard dashboard) {
    print('Date: ${dashboard.date}');
  }

  void display(ResentAction recentAction) {
    print('Recent Action: ${recentAction.last}');
  }
}
```

#### Good ✅
```dart
// lib/features/dashboard/presentation/pages/dashboard_page.dart

// Good: Imports from the same feature
import 'package:project/features/dashboard/domain/entities/order.dart';
import 'package:project/features/dashboard/data/models/dashboard_model.dart';
import '../presentation/widgets/dashboard_form.dart'; // Relative imports are OK


// Good: External packages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CheckoutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Column(
        children: [
          AppButton(label: 'Continue', onPressed: () {}),
          const DashboardForm(),
        ],
      ),
    );
  }
}
```

#### Allowed Patterns
- **Same feature imports**: Features can import from their own feature (`package:project/features/{same_feature}/...`)
- **Relative imports**: Features can use relative imports within the same feature
- **External packages**: All features can import from Flutter, Dart SDK, and pub.dev packages
- **Non-feature files**: Files outside the features directory (like `main.dart`, `app.dart`) can import features for initialization

#### Feature Structure
```
lib/
├── features/
│   ├── auth/              # Independent feature
│   ├── dashboard/         # Independent feature
│   ├── estimation/        # Independent feature
│   └── project/           # Independent feature
├── libraries/                  

```
### prevent_library_module_dependencies

Enforces library module independence by preventing library modules from importing feature modules. This rule ensures that libraries remain reusable and do not have feature-specific dependencies, enabling better code reuse and maintainability.

#### Bad ❌
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

#### Good ✅
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

#### Allowed Patterns
- **Library-to-library imports**: Libraries can import from other libraries (`package:project/libraries/...`)
- **External packages**: All libraries can import from Flutter, Dart SDK, and pub.dev packages
- **Dart SDK**: All libraries can import Dart core libraries (`dart:async`, `dart:convert`, etc.)

#### Library Structure
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
### forbid_helper_util_naming

Forbids class names that include generic substrings like `Helper` or `Util`.
This rule encourages more descriptive, domain-specific names (e.g.,
`AssetLoader` instead of `AssetHelper`) to improve clarity and reduce
catch-all utility classes.

#### Bad ❌
```dart
class AssetHelper {}        // LINT: prefer AssetLoader or AssetAdapter
class StringUtil {}         // LINT: prefer StringParser or StringSanitizer
class FormattingUtils {}    // LINT: prefer TextFormatter
```

#### Good ✅
```dart
class AssetLoader {}
class StringParser {}
class TextFormatter {}
```

#### What's Detected
- Class names containing the substrings: `Helper`, `Helpers`, `Util`, `Utils`
- Typical PascalCase class names that include those substrings


### restrict_core_icon_data

Restricts `CoreIconData` and `CoreMaterialIcons` usage to the coreui package icons directory. This rule enforces icon abstraction by requiring developers to use `CoreIcons` constants instead of directly instantiating icon data classes, ensuring consistent icon management across the codebase.

#### Bad ❌
```dart
class MyWidget {
  void build() {
    // Direct CoreIconData instantiation
    final svgIcon = CoreIconData.svg('assets/icons/custom.svg');  // LINT
    final materialIcon = CoreIconData.material(Icons.home);  // LINT
    
    // Direct CoreMaterialIcons access
    final arrow = CoreMaterialIcons.arrowRight;  // LINT
  }
  
  // Type annotations are also flagged
  CoreIconData getIcon() => CoreIcons.arrowRight;  // LINT
  void setIcon(CoreIconData icon) {}  // LINT
}
```

#### Good ✅
```dart
class MyWidget {
  void build() {
    // Use CoreIcons constants
    final icon1 = CoreIcons.arrowRight;
    final icon2 = CoreIcons.arrowLeft;
    final icon3 = CoreIcons.microsoft;
    
    // Lists of icons
    final icons = [
      CoreIcons.arrowRight,
      CoreIcons.arrowLeft,
    ];
  }
}
```

#### What's Detected
- **Direct instantiation**: `CoreIconData.svg()`, `CoreIconData.material()`
- **Static access**: `CoreMaterialIcons.arrowRight`, `CoreMaterialIcons.arrowLeft`
- **Type annotations**: `CoreIconData` used as return type, parameter type, or in generics

#### Excluded Files
- Files under `/lib/src/theme/icons/` directory (coreui icon definitions)
