import 'package:analyzer/dart/ast/ast.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';

class PreferFakeOverMockAnalyzer extends BaseAnalyzer {
  @override
  String get ruleName => 'prefer_fake_over_mock';
  @override
  String get problemMessage =>
      'Prefer using Fake instead of Mock for test doubles. Fakes provide more realistic behavior and are easier to maintain.';
  @override
  String get correctionMessage => 'Replace "extends Mock" with "extends Fake"';

  @override
  List<LintIssue> analyze(CompilationUnit unit) {
    final issues = <LintIssue>[];
    for (final decl in unit.declarations) {
      if (decl is ClassDeclaration) {
        final extendsClause = decl.extendsClause;
        if (extendsClause == null) continue;
        final superclass = extendsClause.superclass;
        final superclassName = superclass.name2.lexeme;
        if (superclassName == 'Mock') {
          issues.add(createIssue(superclass));
        }
      }
    }
    return issues;
  }
}
