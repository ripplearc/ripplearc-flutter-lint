class User {
  final String? name;
  final int? age;
  User({this.name, this.age});
}

void main() {
  final user = User(name: null, age: null);
  
  // Bad: Using forced unwrapping
  final name = user.name!;  // LINT
  final age = user.age!;    // LINT
  print('User: $name, Age: $age');  // Will crash at runtime
  
  // Good: Using null-safe alternatives
  final safeName = user.name ?? 'Unknown';
  final safeAge = user.age ?? 0;
  print('User: $safeName, Age: $safeAge');  // Safe, will print "User: Unknown, Age: 0"
  
  // Good: Using explicit null checks
  if (user.name != null) {
    final checkedName = user.name;  // Safe after null check
    print('User name is: $checkedName');
  } else {
    print('User name is not set');
  }
} 