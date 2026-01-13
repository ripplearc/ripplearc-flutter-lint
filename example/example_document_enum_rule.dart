// Bad: Enum without documentation
enum Status {
  active, // LINT: Missing value documentation
  inactive, // LINT: Missing value documentation
}

// Bad: Enum with only enum documentation, missing value documentation
/// Represents the current status of an authentication request.
enum AuthStatus {
  authenticated, // LINT: Missing value documentation
  unauthenticated, // LINT: Missing value documentation
  connectionError, // LINT: Missing value documentation
}

// Bad: Enum with only value documentation, missing enum documentation
enum ProjectStatus {
  /// The project is currently active.
  active,

  /// The project has been archived.
  archived,
}

// Good: Enum with proper documentation for both enum and values
/// Defines the type of toast notification and its visual styling.
///
/// This enum determines the appearance and icon used for toast messages
/// throughout the application.
enum ToastType {
  /// Error toast with red background and icon for critical issues.
  error,

  /// Warning toast with orange background and icon for cautionary messages.
  warning,

  /// Information toast with blue background and icon for general notifications.
  info,

  /// Success toast with green background and icon for positive confirmations.
  success,
}

// Good: Another properly documented enum
/// Storage providers supported for project export functionality.
///
/// These enums represent the different cloud storage services that users
/// can choose from when exporting their construction project data.
enum StorageProvider {
  /// Google Drive cloud storage service.
  googleDrive,

  /// Microsoft OneDrive cloud storage service.
  oneDrive,

  /// Dropbox cloud storage service.
  dropbox,
}

// Good: Properly documented enum with extensions
/// Defines the types of digits and symbols available on the keyboard.
///
/// These values represent the numeric input options displayed on
/// the calculator keyboard interface.
enum DigitType {
  /// Numeric digit 0.
  zero,

  /// Numeric digit 1.
  one,

  /// Numeric digit 2.
  two,

  /// Decimal point symbol.
  decimal,
}

// Good: Complex enum with enhanced values (Dart 2.17+)
/// Defines the strategy for applying markups to cost estimates.
///
/// This enum determines whether markups are applied uniformly across
/// all cost components or separately to different categories.
enum MarkupType {
  /// Apply a single markup to the entire project cost.
  overall,

  /// Apply separate markups to different cost categories.
  granular,
}
