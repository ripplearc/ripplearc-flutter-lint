import 'package:rxdart/rxdart.dart';

enum AuthStatus { authenticated, unauthenticated }

class User {
  final String name;
  final String email;
  User({required this.name, required this.email});
}

class AuthService {
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

void main() {
  final authService = AuthService();

  // Good: Using public getters instead of direct access
  authService.authState.listen((status) {
    print('Auth status: $status');
  });

  authService.userStream.listen((user) {
    if (user != null) {
      print('User: ${user.name}');
    }
  });

  authService.login();
}
