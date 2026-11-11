# forbid_direct_storage_access

Bans direct use of `shared_preferences`, `path_provider` and `flutter_secure_storage` outside the storage library. Everything an app keeps on the device goes through one library, so sign-out can find it and delete it (CA-14, design "Keep or delete local-only data on sign-out, per account").

The rule checks `import` and `export` directives, including every URI of a conditional import. It runs on every Dart file that is analysed, in `lib/`, `test/` and anywhere else. Generated files (`.g.dart`, `.freezed.dart`) are skipped.

## Where the packages are allowed

- Any file inside `lib/libraries/storage/` or `test/libraries/storage/`.
- Any file whose exact path is listed in `allowed_files`.

Paths are relative to the folder that holds `analysis_options.yaml`, written with `/`. A file is never allowed because of how its name ends, and a folder never allows a neighbour that only shares its name start (`lib/libraries/storage_other/` is not `lib/libraries/storage/`).

## Configuration

```yaml
custom_lint:
  rules:
    - forbid_direct_storage_access
  forbid_direct_storage_access:
    allowed_files:
      - lib/libraries/secure_storage/secure_storage_wrapper_impl.dart
```

The options may sit next to `rules:` (as above) or inside a `rules:` map under the rule name. A single path instead of a list counts as a list of one. Any other value fails with `allowed_files must be a list of file paths`.

## Bad ❌
```dart
// lib/features/estimation/data/last_unit.dart
import 'package:shared_preferences/shared_preferences.dart'; // LINT
```

## Good ✅
```dart
// lib/features/estimation/data/last_unit.dart
import 'package:project/libraries/storage/interfaces/storage_service.dart'; // OK
```

## Known limits

- `// ignore: forbid_direct_storage_access` and `// ignore_for_file:` bypass the rule, like any lint. Reviewers look for them.
- Only the three packages are banned. Their companion packages, such as `shared_preferences_platform_interface` or `path_provider_platform_interface`, are not.
- Only the nearest `analysis_options.yaml` is read. A nested one that only has `include:` does not inherit the parent's `allowed_files`, so list the files in the nested file too.
- `standalone_checker` turns every path into lower case on Windows, so a listed path with capital letters would not match there. Dart file names are lower case by convention.
- The options are read once per analysis session. After editing `allowed_files`, restart analysis or rerun `dart run custom_lint`.
