// Example file demonstrating the no_direct_instantiation rule
// This file shows both correct and incorrect usage patterns

// Good: Module class - should not be flagged
class Module {
  // Base module class
}

class AppModule extends Module {
  // Module implementation
}

// Good: Factory class - should not be flagged
class AuthService {
  factory AuthService() {
    return AuthService._internal();
  }

  AuthService._internal();

  void authenticate() {
    // Authentication logic
  }

  // Good: Static factory method - should not be flagged
  static AuthService create() {
    return AuthService._internal();
  }
}

// Good: Factory class with parameters - should not be flagged
class UserService {
  factory UserService(String apiKey) {
    return UserService._internal(apiKey);
  }

  UserService._internal(this.apiKey);

  final String apiKey;

  void getUser() {
    // Get user logic
  }
}

// Bad: Regular class - will be flagged when instantiated directly
class SyncService {
  SyncService();

  void sync() {
    // Sync logic
  }
}

// Bad: Regular class with parameters - will be flagged when instantiated directly
class NotificationService {
  NotificationService(String token);

  void sendNotification() {
    // Notification logic
  }
}

// Mock dependency injection container for example purposes
class Modular {
  static T get<T>() {
    // Mock implementation
    return null as T;
  }
}

void main() {
  // Good: Using dependency injection
  final authService = Modular.get<AuthService>();
  final userService = Modular.get<UserService>();

  // Bad: Direct instantiation - will be flagged
  final syncService = SyncService(); // LINT: Direct instantiation not allowed

  // Bad: Direct instantiation with parameters - will be flagged
  final notificationService =
      NotificationService('token'); // LINT: Direct instantiation not allowed

  // Bad: Using new keyword - will be flagged
  final anotherService =
      new SyncService(); // LINT: Direct instantiation not allowed

  // Good: Module instantiation - should not be flagged
  final module = AppModule();

  // Good: Factory class instantiation - should not be flagged
  final factoryService = AuthService();
  final factoryServiceWithParams = UserService('api-key');

  // Good: Static factory method - should not be flagged
  final staticFactory = AuthService.create();
}
