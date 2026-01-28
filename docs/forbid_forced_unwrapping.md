# forbid_forced_unwrapping

Forbids the use of forced unwrapping (`!`) in production code. This rule encourages the use of null-safe alternatives to prevent runtime null errors.

## Bad ❌
```dart
final name = user.name!;  // Will crash if name is null
print('User: $name');
```

## Good ✅
```dart
final name = user.name ?? 'Unknown';  // Safe with default value
print('User: $name');
```
