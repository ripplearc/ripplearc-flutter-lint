/// Configuration for the `forbid_direct_storage_access` rule.
class ForbidDirectStorageAccessConfig {
  /// Creates a config. [allowedFiles] are paths relative to the project root,
  /// with `/` separators and no leading `./`.
  const ForbidDirectStorageAccessConfig({required this.allowedFiles});

  /// Folders that belong to the storage library, so their files may use the
  /// storage packages directly.
  static const libraryFolders = {
    'lib/libraries/storage',
    'test/libraries/storage',
  };

  /// Exact files outside [libraryFolders] that may use the storage packages
  /// directly.
  final Set<String> allowedFiles;

  /// The config with no extra files.
  factory ForbidDirectStorageAccessConfig.defaults() {
    return const ForbidDirectStorageAccessConfig(allowedFiles: {});
  }

  /// Returns true when [relativePath] is a listed file or sits inside a
  /// library folder. A folder never matches a sibling that only shares its
  /// name prefix, and a file never matches by its ending.
  bool allows(String relativePath) {
    if (allowedFiles.contains(relativePath)) return true;
    return libraryFolders.any((folder) => relativePath.startsWith('$folder/'));
  }
}
