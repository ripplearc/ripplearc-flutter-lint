# document_enum

Enforces documentation on enums and their values. This rule ensures that every enum type and each enum value has a `///` documentation comment, providing clear descriptions of the enum's purpose and the meaning of each value.

## Bad ❌
```dart
// Missing enum documentation
enum Status {
  active,    // LINT: Missing value documentation
  inactive,  // LINT: Missing value documentation
}

// Enum with only class documentation
/// Represents the authentication status.
enum AuthStatus {
  authenticated,    // LINT: Missing value documentation
  unauthenticated,  // LINT: Missing value documentation
}

// Enum with only value documentation
enum ProjectStatus {
  /// The project is active.
  active,
  /// The project is archived.
  archived,
}
```

## Good ✅
```dart
/// Defines the type of toast notification and its visual styling.
enum ToastType {
  /// Error toast with red background for critical issues.
  error,

  /// Warning toast with orange background for cautionary messages.
  warning,

  /// Info toast with blue background for general notifications.
  info,

  /// Success toast with green background for positive confirmations.
  success,
}

/// Storage providers supported for project export functionality.
enum StorageProvider {
  /// Google Drive cloud storage service.
  googleDrive,

  /// Microsoft OneDrive cloud storage service.
  oneDrive,

  /// Dropbox cloud storage service.
  dropbox,
}
```
