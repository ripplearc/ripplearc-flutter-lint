import 'package:test/test.dart';

void main() {
  // ❌ Bad: Missing mutation test configuration
  // This file: auth_repository_test.dart
  // Missing: auth_repository_test.mutation.yaml or mutation.yaml
  test('should authenticate user', () {
    // test implementation
    expect(result, equals(expected));
  });

  // ✅ Good: Has mutation test configuration
  // This file: user_service_test.dart
  // Has: user_service_test.mutation.yaml or mutation.yaml
  test('should create user', () {
    // test implementation
    expect(result, equals(expected));
  });
}

// Mock objects for demonstration
final result = 'success';
final expected = 'success';
