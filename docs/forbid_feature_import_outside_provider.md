# forbid_feature_import_outside_provider

Part of the `feature_module_isolation` family (alongside `prevent_feature_module_dependencies` and `prevent_library_module_dependencies`). Forbids importing a feature's internals from anywhere outside that feature, except through the feature's own provider file: `{feature_name}_feature_module.dart` inside `lib/features/{feature_name}/`.

This is the file each feature exposes to the rest of the app to implement the `FeatureModule`/`TabEntry` contract used for per-flavor feature exclusion (see the "Per-Flavor Feature Module Exclusion" HLD, CA-923). Everything else inside a feature — its screens, blocs, repositories, entities — should stay reachable only from within that same feature.

## Bad ❌
```dart
// lib/app/enabled_features.dart
import 'package:project/features/estimation/domain/entities/estimate.dart'; // LINT: deep import, bypasses the provider file
import 'package:project/features/estimation/presentation/pages/estimation_page.dart'; // LINT: deep import
```

## Good ✅
```dart
// lib/app/enabled_features.dart
import 'package:project/features/estimation/estimation_feature_module.dart'; // OK: the feature's provider file

const enabledFeatures = <FeatureModule>[
  if (BuildFeatures.estimation) EstimationFeatureModule(),
];
```

```dart
// lib/features/estimation/estimation_feature_module.dart
// Code inside the feature can still import its own internals freely.
import 'package:project/features/estimation/domain/entities/estimate.dart'; // OK: same feature
```

## Allowed Patterns
- **The provider file itself**: `package:project/features/{feature_name}/{feature_name}_feature_module.dart` can be imported from anywhere.
- **Imports from within the same feature**: any file under `lib/features/{feature_name}/` can import other files in that same feature directly.
- **External packages**: Flutter, Dart SDK, and pub.dev packages are never in scope for this rule.

## Out of Scope
Feature-to-feature deep imports (one feature reaching directly into another feature's internals) are already caught by `prevent_feature_module_dependencies`. This rule only covers imports from code outside `lib/features/` altogether — the app/shell layer, core, or libraries — reaching into a feature.

## Not reported
- Code inside `lib/features/{feature_name}/` (covered by `feature_module_isolation`).
- A feature's own tests under `test/features/{feature_name}/`, which import that feature's internals on purpose.
- Other test files, such as `test/utils/`, are still checked.

## Relative imports
A relative import is checked the same way as a `package:` import, including a path that starts with `features/` and has no slash before it (for a file directly in `lib/`).
