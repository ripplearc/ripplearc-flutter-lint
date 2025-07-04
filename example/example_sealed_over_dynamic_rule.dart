// ❌ Bad: Using dynamic for sync result
void bad() async {
  dynamic syncResult =
      await powersync.execute('query'); // LINT: Use a sealed class instead
}

// ✅ Good: Using a sealed class for sync result
sealed class SyncResult {}

void good() async {
  SyncResult result = await powersync.execute('query');
}

// Mock powersync object for demonstration
final powersync = _PowerSync();

class _PowerSync {
  Future<dynamic> execute(String query) async => SyncResultImpl();
}

class SyncResultImpl extends SyncResult {}
