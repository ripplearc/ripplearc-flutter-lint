// ============================================================================
// ❌ BAD: Direct instantiation of classes (VIOLATIONS)
// ============================================================================

// Bad: Direct instantiation of regular service classes
class BadService {
  void doSomething() {
    final service = AuthService(); // LINT: Direct instantiation not allowed
    final wrapper = FakeSupabaseWrapper(); // LINT: Direct instantiation not allowed
    final repository = UserRepository(); // LINT: Direct instantiation not allowed
  }
}

// ============================================================================
// ✅ GOOD: Using dependency injection (CORRECT APPROACH)
// ============================================================================

// Good: Using dependency injection
class GoodService {
  void doSomething() {
    final service = Modular.get<AuthService>(); // Good: Using DI
    final wrapper = Modular.get<FakeSupabaseWrapper>(); // Good: Using DI
    final repository = Modular.get<UserRepository>(); // Good: Using DI
  }
}

// ============================================================================
// ✅ ALLOWED: Factory classes (ending with "Factory")
// ============================================================================

// Good: Factory classes can be instantiated directly
class FactoryExample {
  void createFactory() {
    final fileProcessorFactory = FileProcessorFactory(); // ✅ Allowed: Factory class
    final databaseFactory = DatabaseFactory(); // ✅ Allowed: Factory class
    final httpClientFactory = HttpClientFactory(); // ✅ Allowed: Factory class
  }
}

// ============================================================================
// ✅ ALLOWED: Module classes (extending Module)
// ============================================================================

// Good: Module classes can be instantiated directly
class ModuleExample {
  void createModule() {
    final module = AppModule(); // ✅ Allowed: Module class
    final featureModule = FeatureModule(); // ✅ Allowed: Module class
  }
}

// ============================================================================
// ✅ ALLOWED: Instantiation inside Module class
// ============================================================================

// Good: Instantiation inside Module class (anywhere in the class)
class AppModule extends Module {
  AppModule() {
    final service = AuthService(); // ✅ Allowed: Inside Module class
    final wrapper = FakeSupabaseWrapper(); // ✅ Allowed: Inside Module class
  }
  
  void someMethod() {
    final another = AnotherService(); // ✅ Allowed: Inside Module class
  }
}

// ============================================================================
// ✅ ALLOWED: Instantiation inside Module's binds/exportedBinds methods
// ============================================================================

class FeatureModule extends Module {
  @override
  void binds(Binder binder) {
    binder.singleton<AuthService>(() => AuthService()); // ✅ Allowed: In binds method
    binder.factory<UserRepository>(() => UserRepository()); // ✅ Allowed: In binds method
  }
  
  @override
  void exportedBinds(Binder binder) {
    binder.singleton<SharedService>(() => SharedService()); // ✅ Allowed: In exportedBinds method
  }
}

// ============================================================================
// ✅ ALLOWED: Const constructors and const contexts
// ============================================================================

// Good: Const constructors are allowed
class ConstExample {
  void example() {
    const value = String.fromEnvironment('KEY'); // ✅ Allowed: Const constructor
    // Note: const list/map examples require const constructors
    // In real code, const [MyConstClass()] would be allowed if MyConstClass has const constructor
  }
}

class MyConstClass {
  const MyConstClass(); // Const constructor
}

// ============================================================================
// ✅ ALLOWED: Factory constructors
// ============================================================================

// Good: Factory constructors are allowed
class MyClass {
  factory MyClass() => MyClass._(); // ✅ Allowed: Factory constructor
  MyClass._();
  
  factory MyClass.named() => MyClass._(); // ✅ Allowed: Named factory constructor
}

void example() {
  final instance = MyClass(); // ✅ Allowed: Calling factory constructor
  final named = MyClass.named(); // ✅ Allowed: Calling named factory constructor
}

// ============================================================================
// ✅ ALLOWED: Flutter Widget classes
// ============================================================================

// Good: Widget classes are allowed
class BuildContext {} // Mock for examples

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(); // ✅ Allowed: Widget instantiation
  }
}

class CustomButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ✅ Allowed: Widget instantiation
    return Container(); // Simplified for example
  }
}

// ============================================================================
// ✅ ALLOWED: State classes (BLoC states, Flutter State, etc.)
// ============================================================================

// Good: State classes ending with "State" pattern are allowed
class AuthState {} // ✅ Allowed: Ends with State
class AuthInitial extends AuthState {} // ✅ Allowed: Initial state
class AuthLoading extends AuthState {} // ✅ Allowed: Loading state
class AuthSuccess extends AuthState {} // ✅ Allowed: Success state
class AuthFailure extends AuthState {} // ✅ Allowed: Failure state
class AuthInProgress extends AuthState {} // ✅ Allowed: InProgress state
class AuthValidated extends AuthState {} // ✅ Allowed: Validated state

void stateExample() {
  final state = AuthInitial(); // ✅ Allowed: State class
  final loading = AuthLoading(); // ✅ Allowed: State class
}

// ============================================================================
// ✅ ALLOWED: Event classes (BLoC events)
// ============================================================================

// Good: Event classes ending with "Event" are allowed
class AuthEvent {} // ✅ Allowed: Ends with Event
class LoginEvent extends AuthEvent {} // ✅ Allowed: Event class
class LogoutEvent extends AuthEvent {} // ✅ Allowed: Event class

void eventExample() {
  final event = LoginEvent(); // ✅ Allowed: Event class
}

// ============================================================================
// ✅ ALLOWED: Exception and Error classes
// ============================================================================

// Good: Exception and Error classes are allowed
class CustomException implements Exception {} // ✅ Allowed: Exception class
class ValidationException implements Exception { // ✅ Allowed: Exception class
  final String message;
  ValidationException(this.message);
}
class NetworkError extends Error {} // ✅ Allowed: Error class
class CustomError extends Error {} // ✅ Allowed: Error class

void exceptionExample() {
  throw CustomException(); // ✅ Allowed: Exception instantiation
  throw ValidationException('Invalid'); // ✅ Allowed: Exception instantiation
}

// ============================================================================
// ✅ ALLOWED: DTO, Entity, Model classes (by name pattern)
// ============================================================================

// Good: Classes ending with DTO, Entity, Model are allowed
class UserDto {} // ✅ Allowed: Ends with Dto
class UserDTO {} // ✅ Allowed: Ends with DTO
class UserEntity {} // ✅ Allowed: Ends with Entity
class UserModel {} // ✅ Allowed: Ends with Model
class ProductValue {} // ✅ Allowed: Ends with Value
class RequestParams {} // ✅ Allowed: Ends with Params
class UserAttributes {} // ✅ Allowed: Ends with Attributes

void dataExample() {
  final dto = UserDto(); // ✅ Allowed: DTO class
  final entity = UserEntity(); // ✅ Allowed: Entity class
  final model = UserModel(); // ✅ Allowed: Model class
}

// ============================================================================
// ✅ ALLOWED: Classes in specific file paths
// ============================================================================

// Files in these paths are excluded:
// - *_dto.dart, *_model.dart
// - testing/, test/ directories
// - main.dart
// - data/models/
// - domain/entities/
// - params/, usecases/params/

// Example: lib/data/models/product_model.dart
class ProductModel {} // ✅ Allowed: In model file

// Example: lib/domain/entities/product_entity.dart
class ProductEntity {} // ✅ Allowed: In entity file

// Example: lib/testing/fake_service.dart
class FakeService {} // ✅ Allowed: In testing directory

// ============================================================================
// ✅ ALLOWED: Classes imported from domain entities or models
// ============================================================================

// If a class is imported from a domain entity or model path, it's allowed
// import 'package:app/domain/entities/user_entity.dart';
// final user = UserEntity(); // ✅ Allowed: Imported from domain entity

// import 'package:app/data/models/user_model.dart';
// final model = UserModel(); // ✅ Allowed: Imported from model

// ============================================================================
// ✅ ALLOWED: Classes from whitelisted packages
// ============================================================================

// Classes from these packages are allowed:
// - package:flutter/* (Widget, State, TextEditingController, FocusNode, etc.)
// - package:flutter_bloc/* (BLoC classes)
// - package:supabase/*, package:supabase_flutter/*
// - package:intl/* (NumberFormat, DateFormat)
// - package:uuid/* (Uuid)

// import 'package:flutter/material.dart';
// final controller = TextEditingController(); // ✅ Allowed: Flutter package

// import 'package:intl/intl.dart';
// final formatter = NumberFormat(); // ✅ Allowed: intl package

// ============================================================================
// ✅ ALLOWED: Private named constructors
// ============================================================================

class MyService {
  MyService._private(); // ✅ Allowed: Private constructor
  factory MyService() => MyService._private();
}

void privateExample() {
  final service = MyService._private(); // ✅ Allowed: Private named constructor
}

// ============================================================================
// ✅ ALLOWED: Sealed classes
// ============================================================================

sealed class Result<T> {} // ✅ Allowed: Sealed class
class Success<T> extends Result<T> {}
class Failure<T> extends Result<T> {}

void sealedExample() {
  final result = Success<String>(); // ✅ Allowed: Sealed class
}

// ============================================================================
// ✅ ALLOWED: Special classes (by name)
// ============================================================================

// These specific classes are whitelisted:
// - Trace
// - DateTime
// - Uri
// - Uuid
// - Completer
// - RegExp
// - Locale
// - StreamController

void specialExample() {
  final date = DateTime.now(); // ✅ Allowed: DateTime
  final uri = Uri.parse('https://example.com'); // ✅ Allowed: Uri
  final regex = RegExp(r'pattern'); // ✅ Allowed: RegExp
}

// ============================================================================
// Supporting classes for examples
// ============================================================================

class Module {}

class AuthService {}

class FakeSupabaseWrapper {}

class FileProcessorFactory {}

class DatabaseFactory {}

class HttpClientFactory {}

class UserRepository {}

class SharedService {}

class AnotherService {}

// Mock Modular for examples
class Modular {
  static T get<T>() => throw UnimplementedError();
}

// Mock Binder for examples
class Binder {
  void singleton<T>(T Function() factory) {}
  void factory<T>(T Function() factory) {}
}

// Flutter imports (mock)
class StatelessWidget {}
class Widget {}
class Container extends Widget {}
class ElevatedButton extends Widget {}
class Text extends Widget {}
