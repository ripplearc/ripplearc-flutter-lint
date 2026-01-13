import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'base_analyzer.dart';
import '../models/lint_issue.dart';

/// Analyzer that forbids class names containing 'Helper' or 'Util'.
///
/// This rule encourages developers to use more descriptive, domain-specific
/// names instead of generic 'Helper' or 'Util' suffixes. Classes with these
/// names often indicate unclear responsibilities or poor abstraction.
///
/// Example of code that triggers this rule:
/// ```dart
/// class AssetHelper {}      // LINT: Use more descriptive name like AssetLoader
/// class StringUtil {}       // LINT: Use more descriptive name like StringParser
/// class DateTimeHelper {}   // LINT: Use more descriptive name like DateTimeFormatter
/// class NetworkUtils {}     // LINT: Use more descriptive name like HttpClient
/// ```
///
/// Example of correct code:
/// ```dart
/// class AssetLoader {}
/// class StringParser {}
/// class DateTimeFormatter {}
/// class HttpClient {}
/// ```
class ForbidHelperUtilNamingAnalyzer extends BaseAnalyzer {
  static const _forbiddenPatterns = ['Helper', 'Util'];

  @override
  String get ruleName => 'forbid_helper_util_naming';

  @override
  String get problemMessage =>
      'Class names containing "Helper" or "Util" are discouraged. Use more descriptive, domain-specific names.';

  @override
  String get correctionMessage =>
      'Rename the class to better describe its responsibility (e.g., AssetHelper → AssetLoader, StringUtil → StringParser).';

  @override
  List<LintIssue> analyze(CompilationUnit unit) {
    final visitor = _HelperUtilNamingVisitor(this);
    unit.accept(visitor);
    return visitor.issues;
  }

  bool containsForbiddenPattern(String className) {
    return _forbiddenPatterns.any((pattern) => className.contains(pattern));
  }
}

class _HelperUtilNamingVisitor extends RecursiveAstVisitor<void> {
  final ForbidHelperUtilNamingAnalyzer analyzer;
  final List<LintIssue> issues = [];

  _HelperUtilNamingVisitor(this.analyzer);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final className = node.name.lexeme;
    if (analyzer.containsForbiddenPattern(className)) {
      // Use the whole class declaration node to report the issue
      issues.add(analyzer.createIssue(node));
    }
    super.visitClassDeclaration(node);
  }
}
