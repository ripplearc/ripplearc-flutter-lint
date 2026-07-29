// ignore_for_file: unused_element, unused_local_variable

// Simulated stubs so the example compiles standalone.
class ThemeData {
  const ThemeData();
  static ThemeData light() => const ThemeData();
  static ThemeData dark() => const ThemeData();
}

class WidgetTester {}

class MyWidget {}

dynamic get finder => null;

dynamic matchesGoldenFile(String path) => null;

// ─── BAD: manual dual-theme pattern ──────────────────────────────────────────

// LINT — ThemeData? nullable parameter in a screenshot test helper
Future<void> _pumpMyWidget(WidgetTester tester, ThemeData? theme) async {}

void badExamples() {
  // LINT — hard-coded _dark.png suffix passed directly to matchesGoldenFile
  matchesGoldenFile('goldens/my_widget_dark.png');
}

// ─── GOOD: use screenshotThemeGroups ─────────────────────────────────────────

// OK — no ThemeData? parameter
Future<void> _pumpMyWidgetCorrect(WidgetTester tester) async {}

void goodExamples(String goldenSuffix) {
  // OK — suffix comes from the goldenSuffix parameter supplied by screenshotThemeGroups
  matchesGoldenFile('goldens/my_widget$goldenSuffix');

  // OK — non-dark suffix literal
  matchesGoldenFile('goldens/my_widget_light.png');
}
