import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// Enforces dependency injection for better testability of auth/sync components.
///
/// This rule flags all direct instantiations of classes, except:
///   - Classes whose names end with 'Factory' (e.g., FileProcessorFactory)
///   - Classes that extend 'Module'
///   - Any instantiation that occurs inside a class that extends 'Module'
///   - Classes annotated with @dataModel
///   - The DataModel annotation class itself
///   - Namespaced models from third-party libraries (e.g., supabase.User)
///   - Classes from dart: libraries (SDK types)
///   - Classes from supabase_flutter library
///   - Classes that extend Exception or Error
///
/// Example:
/// ```dart
/// // ❌ Not allowed:
/// fakeSupabaseWrapper = FakeSupabaseWrapper();
/// final service = AuthService();
///
/// // ✅ Allowed:
/// fakeSupabaseWrapper = Modular.get<FakeSupabaseWrapper>();
/// final service = Modular.get<AuthService>();
/// final factory = FileProcessorFactory();
/// final module = AppModule();
///
/// // ✅ Allowed: Instantiation inside a Module
/// class AppModule extends Module {
///   AppModule() {
///     final service = AuthService(); // Allowed here
///   }
/// }
///
/// // ✅ Allowed: Data model with @dataModel annotation
/// @dataModel
/// class User {
///   final int id;
///   final String name;
///   User({required this.id, required this.name});
/// }
/// final user = User(id: 1, name: 'Alice');
///
/// // ✅ Allowed: Instantiating the DataModel annotation class
/// final model = DataModel();
///
/// // ✅ Allowed: Instantiating a namespaced model (e.g., supabase.User)
/// final user = supabase.User(id: 1);
///
/// // ✅ Allowed: Exception classes
/// throw supabase.AuthSessionMissingException();
/// ```
class NoDirectInstantiation extends DartLintRule {
  const NoDirectInstantiation() : super(code: _code);

  static const _code = LintCode(
    name: 'no_direct_instantiation',
    problemMessage:
        'Direct instantiation is not allowed. Use dependency injection instead.',
    correctionMessage:
        'Replace direct instantiation with Modular.get<ClassName>().',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((node) {
      _checkForDirectInstantiation(node, reporter);
    });
  }

  void _checkForDirectInstantiation(
    CompilationUnit node,
    ErrorReporter reporter,
  ) {
    node.visitChildren(_DirectInstantiationVisitor(reporter));
  }
}

class _DirectInstantiationVisitor extends RecursiveAstVisitor<void> {
  final ErrorReporter reporter;
  _DirectInstantiationVisitor(this.reporter);

  // List of allowed namespaces for direct instantiation
  static const allowedNamespaces = {'supabase'};

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final namedType = node.constructorName.type;
    final className = namedType.name2.lexeme;
    
    // Check if this instantiation should be allowed
    if (!_isExcludedClass(className, node) && !_isInsideModule(node)) {
      reporter.atNode(node, NoDirectInstantiation._code);
    }
    
    super.visitInstanceCreationExpression(node);
  }

  bool _isExcludedClass(String className, InstanceCreationExpression node) {
    final namedType = node.constructorName.type;
    final element = node.staticType?.element;
    
    // Check for namespaced instantiation (e.g., supabase.AuthException)
    if (namedType.importPrefix != null) {
      final prefix = namedType.importPrefix!.name;
      if (allowedNamespaces.contains(prefix)) {
        return true;
      }
    }
    
    // Check element-based exclusions if static type is resolved
    if (element is ClassElement) {
      final source = element.librarySource;
      
      // Exclude all classes from dart: libraries (SDK types)
      if (source != null && source.uri.isScheme('dart')) {
        return true;
      }
      
      // Exclude classes from supabase_flutter library
      if (source != null && source.uri.toString().contains('supabase_flutter')) {
        return true;
      }
      
      // Exclude classes that extend Exception or Error (traverse full supertype chain)
      if (_extendsExceptionOrError(element)) {
        return true;
      }
      
      // Check for @dataModel or @freezed annotations
      if (_hasDataModelAnnotation(element)) {
        return true;
      }
      
      // Check if class extends Module
      if (_extendsModule(element)) {
        return true;
      }
    }
    
    // If the class name contains any forbidden keyword, never exclude
    final forbidden = [
      'impl', 'service', 'manager', 'bloc', 'repository', 'datasource', 'provider'
    ];
    final lower = className.toLowerCase();
    if (forbidden.any((word) => lower.contains(word))) {
      return false;
    }
    
    // Allow classes whose names end with 'Factory' or are the DataModel annotation itself
    if (className.endsWith('Factory') || className == 'DataModel') {
      return true;
    }
    
    return false;
  }

  bool _extendsExceptionOrError(ClassElement element) {
    InterfaceType? supertype = element.thisType;
    final visitedTypes = <String>{};
    
    while (supertype != null) {
      final name = supertype.element.name;
      
      // Prevent infinite loops
      if (visitedTypes.contains(name)) {
        break;
      }
      visitedTypes.add(name);
      
      if (name == 'Exception' || name == 'Error') {
        return true;
      }
      
      final next = supertype.superclass;
      if (next == null || next.element.name == 'Object') {
        break;
      }
      supertype = next;
    }
    
    return false;
  }

  bool _hasDataModelAnnotation(ClassElement element) {
    for (final meta in element.metadata) {
      final name = meta.element?.displayName;
      if (name == 'dataModel' || name == 'freezed') {
        return true;
      }
    }
    return false;
  }

  bool _extendsModule(ClassElement element) {
    final supertype = element.supertype;
    return supertype != null && supertype.element.name == 'Module';
  }

  bool _isInsideModule(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is ClassDeclaration) {
        final extendsClause = current.extendsClause;
        if (extendsClause != null &&
            extendsClause.superclass.name2.lexeme == 'Module') {
          return true;
        }
        break;
      }
      current = current.parent;
    }
    return false;
  }
}