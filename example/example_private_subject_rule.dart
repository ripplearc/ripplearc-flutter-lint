import 'package:rxdart/rxdart.dart';

/// Dummy base class to satisfy `no_direct_instantiation` rule
abstract class Module {}

enum AuthStatus { authenticated, unauthenticated }

class User {
  final String name;
  final String email;
  User({required this.name, required this.email});
}

// Wrap the example in a Module subclass to avoid no_direct_instantiation errors
class AuthServiceModule extends Module {
  // Bad: Public Subject variables
  final authStateController = BehaviorSubject<AuthStatus>(); // LINT
  final userController = ReplaySubject<User>(); // LINT
  final loginController = PublishSubject<void>(); // LINT

  // Good: Private Subject variables
  final _authStateController = BehaviorSubject<AuthStatus>(); // Good
  final _userController = ReplaySubject<User?>(); // Good
  final _loginController = PublishSubject<void>(); // Good

  // Good: Non-Subject variables are allowed to be public
  final user = User(name: 'John', email: 'john@example.com');
  final status = AuthStatus.authenticated;

  // Good: Private non-Subject variables
  final _internalData = 'private data';

  void login() {
    _authStateController.add(AuthStatus.authenticated);
    _userController.add(user);
    _loginController.add(null);
  }

  void logout() {
    _authStateController.add(AuthStatus.unauthenticated);
    _userController.add(null);
  }

  // Good: Public getters for streams
  Stream<AuthStatus> get authState => _authStateController.stream;
  Stream<User?> get userStream => _userController.stream;
  Stream<void> get loginEvents => _loginController.stream;
}
