// Bad: Abstract class without documentation
abstract class SyncRepository {
  Future<void> syncData(); // LINT: Missing method documentation
  Future<void> clearData(); // LINT: Missing method documentation
}

// Bad: Abstract class with only class documentation
/// Repository interface for data synchronization operations.
abstract class UserRepository {
  Future<String> getUser(String id); // LINT: Missing method documentation
  Future<void> updateUser(
      String id, String name); // LINT: Missing method documentation
}

// Good: Abstract class with proper documentation
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

// Good: Private methods are ignored (no documentation required)
/// Repository interface for data synchronization operations.
abstract class SecureRepository {
  /// Synchronizes local data with remote Supabase instance.
  Future<bool> syncData();

  Future<void> _validateData(); // Private method - no documentation needed
  Future<void> _encryptData(); // Private method - no documentation needed
}

// Good: Concrete classes are ignored (no documentation required)
class LocalRepository {
  Future<void> syncData() async {
    // Implementation
  }

  Future<void> clearData() async {
    // Implementation
  }
}
