# forbid_manual_screenshot_theme

Forbids the manual dual-theme pattern in `*_screenshot_test.dart` files.

CA-847 introduced `screenshotThemeGroups` to replace two fragile patterns that
had to be repeated manually across screenshot tests:

1. A nullable `ThemeData?` pump-helper parameter — it collides with the
   `no_optional_operators_in_tests` lint rule and forces an `if/else` workaround.
2. A hand-typed `_dark.png` suffix in every `matchesGoldenFile` call — easy to
   forget or mistype.

Use `screenshotThemeGroups` instead; it handles both automatically.

**Scope:** only fires in files whose name ends with `_screenshot_test.dart`.
Existing files that intentionally use the old pattern can suppress with
`// ignore_for_file: forbid_manual_screenshot_theme`.

## Bad ❌

```dart
// my_widget_screenshot_test.dart

// ThemeData? parameter — manual theme switching
Future<void> _pumpMyWidget(
  WidgetTester tester,
  ThemeData? theme,       // LINT
) async {
  await tester.pumpWidget(
    Theme(data: theme ?? ThemeData.light(), child: const MyWidget()),
  );
}

// Hard-coded _dark.png suffix — manual golden naming
void main() {
  testWidgets('dark theme golden', (tester) async {
    await _pumpMyWidget(tester, ThemeData.dark());
    await expectLater(
      find.byType(MyWidget),
      matchesGoldenFile('goldens/my_widget_dark.png'), // LINT
    );
  });
}
```

## Good ✅

```dart
// my_widget_screenshot_test.dart

// Use screenshotThemeGroups — no ThemeData? param, no _dark.png suffix
Future<void> _pumpMyWidget(WidgetTester tester) async {
  await tester.pumpWidget(const MyWidget());
}

void main() {
  screenshotThemeGroups('MyWidget', (tester, goldenSuffix) async {
    await _pumpMyWidget(tester);
    await expectLater(
      find.byType(MyWidget),
      matchesGoldenFile('goldens/my_widget$goldenSuffix'),
    );
  });
}
```
