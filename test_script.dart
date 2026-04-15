import 'package:ripplearc_linter/core/analyzers/forbid_modular_get_outside_module_analyzer.dart';
import 'package:analyzer/dart/analysis/utilities.dart';

class _SimpleResolver {
  final String path;
  _SimpleResolver(this.path);
}

void main() {
  final analyzer = ForbidModularGetOutsideModuleAnalyzer();
  final path = '/home/user/myproject/lib/foo.dart';
  final result = parseString(content: 'import "x.dart"; class B { B() { Modular.get<int>(); } }');
  final issues = analyzer.analyzeWithResolver(result.unit, _SimpleResolver(path));
  print("Found ${issues.length} issues.");
}
