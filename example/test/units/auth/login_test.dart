import 'package:test/test.dart';

void main() {
  group('Login Tests', () {
    test('should validate email format', () {
      expect(isValidEmail('test@example.com'), isTrue);
      expect(isValidEmail('invalid-email'), isFalse);
    });

    test('should validate password strength', () {
      expect(isStrongPassword('Password123!'), isTrue);
      expect(isStrongPassword('weak'), isFalse);
    });
  });
}

bool isValidEmail(String email) {
  return email.contains('@') && email.contains('.');
}

bool isStrongPassword(String password) {
  return password.length >= 8 &&
      password.contains(RegExp(r'[A-Z]')) &&
      password.contains(RegExp(r'[a-z]')) &&
      password.contains(RegExp(r'[0-9]'));
}
