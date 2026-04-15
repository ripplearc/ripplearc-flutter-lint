---
name: lint-review
description: >
  Use this skill when reviewing PRs in the ripplearc-flutter-lint repository, or
  when answering questions about how analyzers work, why analyze() vs analyzeWithResolver()
  is used, how rules are wired, or how the standalone checker dispatches. Triggers on
  any PR review for ripplearc-flutter-lint, or questions about analyzer architecture,
  BaseAnalyzer, BaseLintRule, StandaloneLintChecker, shouldSkipFile, or any custom
  lint rule internals. Also use when a contributor asks "why does X not produce
  violations?" or "is this wiring correct?" for any analyzer in this repo.
---

# Lint Review Skill — ripplearc-flutter-lint

Read this before reviewing any PR or answering any architecture question for the
`ripplearc/ripplearc-flutter-lint` repository.

---

## 1 · Architecture Overview

Every lint rule in this repo is composed of three layers:

```
BaseLintRule (custom_lint plugin integration)
    └── BaseAnalyzer (AST analysis logic)
            └── RecursiveAstVisitor (node traversal)
```

### Key files

| File | Role |
|------|------|
| `lib/core/analyzers/base_analyzer.dart` | Abstract base: declares `analyze()`, `analyzeWithResolver()`, `shouldSkipFile()` |
| `lib/core/base_lint_rule.dart` | Plugin glue: wires `CustomLintResolver` → `analyzeWithResolver()` |
| `bin/standalone_checker.dart` | CLI tool: calls `analyzeWithResolver()` via `_SimpleResolver(filePath)` |
| `lib/ripplearc_linter.dart` | Registration: lists every `BaseLintRule` subclass |

---

## 2 · The Two Analysis Paths

### Path A — custom_lint plugin (IDE / `dart run custom_lint`)

`BaseLintRule.run()` is invoked by the custom_lint framework:

```dart
// base_lint_rule.dart
context.registry.addCompilationUnit((node) {
  final issues = analyzer.analyzeWithResolver(node, resolver);
  ...
});
```

The `resolver` here is a real `CustomLintResolver` with a `.path` property.

### Path B — standalone checker (`bin/standalone_checker.dart`)

```dart
List<dynamic> _runAnalyzer(BaseAnalyzer analyzer, dynamic unit, String filePath) {
  final resolver = _SimpleResolver(filePath);
  return analyzer.analyzeWithResolver(unit, resolver);
}
```

A lightweight `_SimpleResolver` carrying only the file path is constructed and
passed to `analyzeWithResolver`. **Both paths call `analyzeWithResolver`, not
`analyze()` directly.**

### Default delegation in BaseAnalyzer

```dart
// base_analyzer.dart
List<LintIssue> analyzeWithResolver(CompilationUnit unit, dynamic resolver) {
  return analyze(unit);   // ← default fallback for path-agnostic analyzers
}
```

Most analyzers don't need the path, so they only implement `analyze()` and the
default delegation handles everything. Path-aware analyzers override
`analyzeWithResolver()` to extract the path first.

---

## 3 · Path-Aware Analyzers (analyzeWithResolver override pattern)

Some rules need the **file path** to decide whether to skip a file (e.g. allow
the rule only outside `*_module.dart`, or skip `test/` and generated files).
These analyzers follow this pattern:

```dart
@override
List<LintIssue> analyzeWithResolver(CompilationUnit unit, dynamic resolver) {
  final path = resolver.path as String?;
  if (path == null || shouldSkipFile(path)) return [];
  return _analyzeInternally(unit);  // real visitor logic
}

@override
List<LintIssue> analyze(CompilationUnit unit) {
  // Intentionally returns [] — path context is required.
  // This is a safety guard, not dead code.
  // Any caller that bypasses analyzeWithResolver gets no violations
  // rather than false positives on module/test/generated files.
  return [];
}
```

**Current path-aware analyzers:** `ForbidModularGetOutsideModuleAnalyzer`

**Review implication:** When you see `analyze()` returning `[]` with a comment
about "path context required", do **not** flag it as a bug. It is intentional
defence-in-depth. The live analysis path goes through `analyzeWithResolver`.

---

## 4 · shouldSkipFile Convention

`BaseAnalyzer.shouldSkipFile(String path)` returns `false` by default.
Analyzers override it to exclude paths. Common patterns:

```dart
@override
bool shouldSkipFile(String path) {
  if (BaseAnalyzer.isTestFile(path)) return true;              // skip test/
  final normalized = path.replaceAll('\\', '/');
  final basename = normalized.split('/').last;
  if (basename.endsWith('.g.dart')) return true;               // skip generated
  if (basename.endsWith('.freezed.dart')) return true;         // skip generated
  if (basename.endsWith('_module.dart')) return true;          // rule-specific
  return false;
}
```

`BaseAnalyzer.isTestFile(path)` normalises path separators and checks for
`_test.dart` or `/test/` in the path.

---

## 5 · Adding a New Analyzer — Checklist

When reviewing a PR that adds a new analyzer:

- [ ] Extends `BaseAnalyzer`
- [ ] Implements `ruleName`, `problemMessage`, `correctionMessage`
- [ ] If path-aware: overrides `analyzeWithResolver` AND overrides `analyze()` to
      return `[]` with an explanatory comment
- [ ] If path-agnostic: only implements `analyze()`; does NOT need to touch
      `analyzeWithResolver`
- [ ] `shouldSkipFile` implemented if the rule has file-level exclusions
- [ ] Rule class in `lib/custom_lint_rules/` extends `BaseLintRule`
- [ ] Registered in `lib/ripplearc_linter.dart`
- [ ] If standalone checker support claimed: added to `StandaloneLintChecker._createAnalyzers()` in `bin/standalone_checker.dart` AND listed in the help text `print()`
- [ ] Analyzer count in `standalone_checker_test.dart` updated
- [ ] Test file covers: at least one violation case, at least one allowed case, and the `shouldSkipFile` paths (module file, test file, generated file)
- [ ] `docs/<rule_name>.md` added
- [ ] `example/example_<rule_name>_rule.dart` added with `// LINT` / `// OK` markers
- [ ] CHANGELOG updated with correct version bump (patch for fixes, minor for new rules)
- [ ] `pubspec.yaml` version matches CHANGELOG

---

## 6 · Common False Findings to Avoid

| Apparent issue | Reality |
|----------------|---------|
| `analyze()` returns `[]` with no logic | Intentional for path-aware analyzers — check if `analyzeWithResolver` is overridden |
| Standalone checker calls `analyzeWithResolver`, not `analyze()` | This is correct — `_SimpleResolver` carries the path |
| Rule registered in standalone checker but uses `analyzeWithResolver` | Fine — standalone checker always calls `analyzeWithResolver` |
| `BaseLintRule.run()` calls `analyzeWithResolver` | Correct — it passes the real `CustomLintResolver` from the plugin framework |

---

## 7 · Test Patterns for Analyzers

Tests use `parseString` (unresolved mode) plus test utilities:

```dart
rule.run(
  TestCustomLintResolver(unit, path: '/lib/some_file.dart'),
  reporter,
  TestCustomLintContext(unit),
);
```

The `path` parameter on `TestCustomLintResolver` is what feeds `resolver.path`
inside `analyzeWithResolver`. Tests for path-aware rules **must** vary the path
to cover: production file (should flag), module file (should skip), test file
(should skip), generated file (should skip).

**Unresolved mode caveat:** `parseString` does not resolve types. Analyzers that
rely on `node.staticElement` or type resolution will only work partially in tests.
Most analyzers in this repo use import-based or AST-shape-based detection
specifically to work in unresolved mode.

---

## 8 · Severity Tiers for Lint-Repo PRs

| Finding | Severity |
|---------|----------|
| `analyze()` returning `[]` without `analyzeWithResolver` override (rule never fires) | 🔴 blocking |
| New path-aware rule missing `shouldSkipFile` test cases | 🔴 blocking |
| Analyzer count in `standalone_checker_test.dart` not updated | 🔴 blocking |
| Rule registered in standalone checker but missing from help text `print()` | 🟡 non-blocking |
| Missing `docs/` or `example/` file | 🟡 non-blocking |
| CHANGELOG version bump inconsistency | 🟡 non-blocking |
