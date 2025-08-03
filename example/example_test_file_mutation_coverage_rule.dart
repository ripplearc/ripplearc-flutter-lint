// Example demonstrating the test_file_mutation_coverage rule
//
// This rule ensures that every test file in test/units directory has a corresponding
// mutation file in test/mutations directory with the same name but .xml extension.
//
// File structure that should exist:
// test/
//   units/
//     user_test.dart          -> test/mutations/user_test.xml
//     auth/
//       login_test.dart       -> test/mutations/auth/login_test.xml
//     services/
//       api_test.dart         -> test/mutations/services/api_test.xml
//
// If any test file in test/units is missing its corresponding mutation file,
// this rule will report an error.

import 'package:test/test.dart';

void main() {
  group('User Tests', () {
    test('should create user successfully', () {
      // This test file should have a corresponding mutation file:
      // test/mutations/user_test.xml
      expect(true, isTrue);
    });
  });
}

// Example of what the mutation file (test/mutations/user_test.xml) should contain:
// <?xml version="1.0" encoding="UTF-8"?>
// <mutations>
//   <mutation>
//     <description>Change user creation logic</description>
//     <original>User(name: 'John')</original>
//     <mutated>User(name: 'Jane')</mutated>
//   </mutation>
// </mutations>
