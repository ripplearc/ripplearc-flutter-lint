import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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
  }
}

class MyConstClass {
  final String name;
  const MyConstClass(this.name);
}

// Const list with const constructors
const myConstList = [
  MyConstClass('item1'), // ✅ Allowed: Const constructor in const list
  MyConstClass('item2'), // ✅ Allowed: Const constructor in const list
];

// Const map with const constructors
const myConstMap = {
  'key1': MyConstClass('value1'), // ✅ Allowed: Const constructor in const map
  'key2': MyConstClass('value2'), // ✅ Allowed: Const constructor in const map
};

// Const set with const constructors
const myConstSet = {
  MyConstClass('a'), // ✅ Allowed: Const constructor in const set
  MyConstClass('b'), // ✅ Allowed: Const constructor in const set
};

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
// ✅ ALLOWED: State classes (BLoC states that extend Equatable)
// ============================================================================

// Good: State classes that extend Equatable (or inherit from classes that extend Equatable) are allowed
// This includes BLoC states which typically extend Equatable for value equality
class Equatable {} // Mock Equatable class for examples

class State extends Equatable {} // ✅ Allowed: Base State class extending Equatable

class AuthState extends State {} // ✅ Allowed: Extends State (which extends Equatable)

class AuthInitial extends AuthState {} // ✅ Allowed: Inherits from class that extends Equatable

class AuthLoading extends AuthState {} // ✅ Allowed: Inherits from class that extends Equatable

void stateExample() {
  final state = AuthInitial(); // ✅ Allowed: State class
  final loading = AuthLoading(); // ✅ Allowed: State class
  final baseState = State(); // ✅ Allowed: State class
}

// ============================================================================
// ✅ ALLOWED: Event classes (BLoC events that extend Equatable)
// ============================================================================

// Good: Event classes that extend Equatable (or inherit from classes that extend Equatable) are allowed
// This includes BLoC events which typically extend Equatable for value equality
class Event extends Equatable {} // ✅ Allowed: Base Event class extending Equatable

class AuthEvent extends Event {} // ✅ Allowed: Extends Event (which extends Equatable)

class LoginEvent extends AuthEvent {} // ✅ Allowed: Inherits from class that extends Equatable

class LogoutEvent extends AuthEvent {} // ✅ Allowed: Inherits from class that extends Equatable

void eventExample() {
  final event = LoginEvent(); // ✅ Allowed: Event class
  final baseEvent = Event(); // ✅ Allowed: Event class
}

// ============================================================================
// ✅ ALLOWED: Exception and Error classes
// ============================================================================

// Good: Exception and Error classes are allowed
class CustomException implements Exception {
  final String message;
  CustomException(this.message);
} // ✅ Allowed: Exception class
class ValidationException implements Exception { // ✅ Allowed: Exception class
  final String message;
  ValidationException(this.message);
}
class NetworkError extends Error {} // ✅ Allowed: Error class
class CustomError extends Error {} // ✅ Allowed: Error class

void exceptionExample() {
  throw ValidationException('Invalid'); // ✅ Allowed: Exception instantiation
  throw CustomException('Invalid'); // ✅ Allowed: Exception instantiation
}

// ============================================================================
// ✅ ALLOWED: DTO, Entity, Model, Params classes (extend Equatable)
// ============================================================================

// Good: DTO, Entity, Model, and Params classes that extend Equatable are allowed
class UserDto extends Equatable {} // ✅ Allowed: Extends Equatable

class UserDTO extends Equatable {} // ✅ Allowed: Extends Equatable

class UserEntity extends Equatable {} // ✅ Allowed: Extends Equatable

class UserModel extends Equatable {} // ✅ Allowed: Extends Equatable

class RequestParams extends Equatable {
  @override
  List<Object?> get props => [];
} // ✅ Allowed: Params extends Equatable

class LoginParams extends Equatable {
  @override
  List<Object?> get props => [];
} // ✅ Allowed: Params extends Equatable

// Note: Attributes classes from package:supabase/ or package:supabase_flutter/
// are also allowed for direct instantiation, even without extending Equatable.
// This is a special case for Supabase's generated Attributes classes.

void dataExample() {
  final dto = UserDto(); // ✅ Allowed: Extends Equatable
  final entity = UserEntity(); // ✅ Allowed: Extends Equatable
  final model = UserModel(); // ✅ Allowed: Extends Equatable
  final params = RequestParams(); // ✅ Allowed: Params extends Equatable
  final loginParams = LoginParams(); // ✅ Allowed: Params extends Equatable
}

// ============================================================================
// ✅ ALLOWED: Classes in specific file paths
// ============================================================================

// Files in these paths are excluded:
// - testing/

// Example: lib/testing/fake_service.dart
class FakeService {} // ✅ Allowed: In testing directory

// ============================================================================
// ✅ ALLOWED: Classes from whitelisted packages
// ============================================================================

// Classes from these packages are allowed:
// - package:flutter/* (Widget, State, TextEditingController, FocusNode, etc.)
// - package:flutter_bloc/* (BLoC classes)
// - package:supabase/*, package:supabase_flutter/* (Attributes classes)
// - Specific utility classes from third-party packages:
//   * Uuid (package:uuid) - UUID generation
//   * DateFormat, NumberFormat (package:intl) - Internationalization
//   * Faker (package:faker) - Test data generation
//   * BehaviorSubject, PublishSubject, ReplaySubject (package:rxdart) - Reactive streams

// import 'package:flutter/material.dart';
// final controller = TextEditingController(); // ✅ Allowed: Flutter package

void whitelistedUtilityExamples() {
  // ✅ Allowed: UUID generation utility
  final uuid = Uuid();
  final id = uuid.v4();

  // ✅ Allowed: Internationalization utilities
  final dateFormat = DateFormat.yMd();
  final numberFormat = NumberFormat.currency();

  // ✅ Allowed: Test data generation utility
  final faker = Faker();

  // ✅ Allowed: Reactive stream utilities
  final behaviorSubject = BehaviorSubject<String>();
  final publishSubject = PublishSubject<int>();
  final replaySubject = ReplaySubject<bool>();
}

// ============================================================================
// ✅ ALLOWED: Private constructor calls inside the same class
// ============================================================================

// Private constructors can be called from within the same class.
// This supports builder/fluent API patterns where a class creates new instances of itself.
class AppLogger {
  final String _tag;
  
  AppLogger._private(this._tag);
  
  // ✅ Allowed: Private constructor called inside the same class
  AppLogger fresh() => AppLogger._private('default');
  
  // ✅ Allowed: Private constructor called inside the same class  
  AppLogger tag(String newTag) => AppLogger._private(newTag);
}



// ============================================================================
// ✅ ALLOWED: Sealed classes
// ============================================================================

sealed class Result<T> {
  final T value;
  Result(this.value);
}

final class Success<T> extends Result<T> {
  Success(super.value);
}

void sealedExample() {
  final result = Success<String>('data'); // ✅ Allowed: Sealed class hierarchy
}

// ============================================================================
// ✅ ALLOWED: Dart SDK & Flutter framework types
// ============================================================================

// All types from dart:core, dart:async, dart:ui, and package:flutter are allowed.
// These are fundamental types that don't need dependency injection.

// dart:core types
void dartCoreExamples() {
  final date = DateTime.now(); // ✅ Allowed: dart:core
  final duration = Duration(seconds: 5); // ✅ Allowed: dart:core
  final uri = Uri.parse('https://example.com'); // ✅ Allowed: dart:core
  final regex = RegExp(r'pattern'); // ✅ Allowed: dart:core
  final stopwatch = Stopwatch(); // ✅ Allowed: dart:core
  final buffer = StringBuffer(); // ✅ Allowed: dart:core
}

// dart:async types
void dartAsyncExamples() {
  final completer = Completer<String>(); // ✅ Allowed: dart:async
  final controller = StreamController<int>(); // ✅ Allowed: dart:async
  final broadcastController = StreamController<String>.broadcast(); // ✅ Allowed: dart:async
}

// dart:ui types (via Flutter)
void dartUiExamples() {
  const color = Color(0xFF000000); // ✅ Allowed: dart:ui
  const offset = Offset(10, 20); // ✅ Allowed: dart:ui
  const radius = Radius.circular(8); // ✅ Allowed: dart:ui
}

// package:flutter types
void flutterExamples() {
  const edgeInsets = EdgeInsets.all(16); // ✅ Allowed: package:flutter
  const borderRadius = BorderRadius.all(Radius.circular(8)); // ✅ Allowed: package:flutter
  const locale = Locale('en', 'US'); // ✅ Allowed: package:flutter
  final textController = TextEditingController(); // ✅ Allowed: package:flutter
  final focusNode = FocusNode(); // ✅ Allowed: package:flutter
  final scrollController = ScrollController(); // ✅ Allowed: package:flutter
  final pageController = PageController(); // ✅ Allowed: package:flutter
  final tabController = TabController(length: 3, vsync: _TickerProvider()); // ✅ Allowed: package:flutter
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

// Stubs for whitelisted third-party utility classes
class Uuid {
  String v4() => '';
}

class DateFormat {
  DateFormat.yMd();
}

class NumberFormat {
  NumberFormat.currency();
}

class Faker {}

class BehaviorSubject<T> {}

class PublishSubject<T> {}

class ReplaySubject<T> {}

// TickerProvider stub for TabController examples
class _TickerProvider implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

