import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that encourages using [Fake] instead of [Mock] for test doubles.
///
/// This rule flags classes that extend [Mock] from the mockito package and
/// suggests using [Fake] instead. Fakes provide more realistic behavior and
/// are easier to maintain than mocks.
///
/// Example of code that triggers this rule:
/// ```dart
/// class MyRepository extends Mock implements Repository {}
/// ```
///
/// Example of code that doesn't trigger this rule:
/// ```dart
/// class MyRepository extends Fake implements Repository {
///   @override
///   Future<String> getData() async => 'fake data';
/// }
/// ```
class PreferFakeOverMockRule extends DartLintRule {
  const PreferFakeOverMockRule() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_fake_over_mock',
    problemMessage: 'Prefer using Fake instead of Mock for test doubles. '
        'Fakes provide more realistic behavior and are easier to maintain.',
    correctionMessage: 'Replace "extends Mock" with "extends Fake"',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      checkForMockSuperclass(node, reporter);
    });
  }

  /// Checks if a class declaration extends [Mock] and reports an error if it does.
  ///
  /// This method is called for each class declaration in the analyzed code.
  /// It checks if the class extends [Mock] and reports an error if found.
  void checkForMockSuperclass(ClassDeclaration node, ErrorReporter reporter) {
    final extendsClause = node.extendsClause;
    if (extendsClause == null) return;

    final superclass = extendsClause.superclass;
    final superclassName = superclass.name2.lexeme;

    if (superclassName == 'Mock') {
      reporter.atNode(superclass, _code);
    }
  }
} 