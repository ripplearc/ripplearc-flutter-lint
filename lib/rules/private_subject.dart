import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that enforces Subject variables to be private.
///
/// This rule prevents external manipulation of Subject streams by ensuring
/// that all Subject variables (BehaviorSubject, ReplaySubject, PublishSubject)
/// are declared as private with an underscore prefix.
///
/// Example of code that triggers this rule:
/// ```dart
/// final authStateController = BehaviorSubject<AuthStatus>();  // LINT
/// final userController = ReplaySubject<User>();              // LINT
/// ```
///
/// Example of code that doesn't trigger this rule:
/// ```dart
/// final _authStateController = BehaviorSubject<AuthStatus>();  // Good
/// final _userController = ReplaySubject<User>();              // Good
/// ```
class PrivateSubject extends DartLintRule {
  const PrivateSubject() : super(code: _code);

  static const _code = LintCode(
    name: 'private_subject',
    problemMessage:
        'Subject variables must be private to prevent external manipulation.',
    correctionMessage: 'Add underscore prefix to make the variable private.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((node) {
      _checkForPublicSubjects(node, reporter);
    });
  }

  void _checkForPublicSubjects(CompilationUnit node, ErrorReporter reporter) {
    final visitor = _PrivateSubjectVisitor(reporter);
    node.accept(visitor);
  }
}

class _PrivateSubjectVisitor extends RecursiveAstVisitor<void> {
  _PrivateSubjectVisitor(this.reporter);

  final ErrorReporter reporter;

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final initializer = node.initializer;
    if (initializer != null) {
      final source = initializer.toSource();
      if (_isSubjectType(source)) {
        final name = node.name.lexeme;
        if (!name.startsWith('_')) {
          reporter.atNode(node, PrivateSubject._code);
        }
      }
    }
    super.visitVariableDeclaration(node);
  }

  bool _isSubjectType(String typeName) {
    final lower = typeName.toLowerCase();
    return lower.contains('behaviorsubject') ||
        lower.contains('replaysubject') ||
        lower.contains('publishsubject') ||
        lower.contains('subject');
  }
}
