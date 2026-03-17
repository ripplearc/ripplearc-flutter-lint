# Wiki: Create a Custom Linter Rule Using the Cursor Agent

This guide explains how to add a new custom linter rule fully automatically using the Cursor agent. You provide a rule spec — the agent generates all required Dart files, runs the git workflow, and opens the PR. No manual steps required.

---

## How it works

Two files drive the automation:

| File | Role |
|------|------|
| `.cursor/rules/create-linter-rule.mdc` | Agent instructions — tells Cursor exactly what Dart files to generate and how |
| `scripts/create_linter_rule_from_spec.sh` | Git/PR automation — creates the branch, stages files, commits, pushes, and opens the PR |

The agent reads the Cursor Rule, generates the files, then runs the shell script itself. You don't touch the script.

---

## Prerequisites

- **Cursor** with agent/composer available and the `ripplearc-flutter-lint` repo open.
- **Git** installed and authenticated.
- **GitHub CLI** (`gh`) installed and authenticated — for automatic PR creation. If absent, the script prints a browser URL as fallback.

---

## 1. Rule spec format

Write a spec in Markdown (`.md`) describing what the rule enforces.

### Required

- **Rule name**: first heading, `snake_case`. Example: `# forbid_foo`
- **Description**: 1–2 sentences after the heading.
- **Bad**: a `## Bad` section with a Dart code block showing code that should be reported.
- **Good**: a `## Good` section with a Dart code block showing allowed code.

### Optional

- **Scope**: `**Scope**: include_tests` or `**Scope**: test_only`.
  - `test_only` → rule runs only in test files.
  - `include_tests` → rule runs in both lib and test.
  - Omit → rule runs only in production (lib) code.
- **Exceptions**: when to skip (e.g. "Skip in files ending with `_impl.dart`").

### Example spec

Save as `rule_specs/forbid_foo.md`:

~~~markdown
# forbid_foo

Short description: do not use Foo.bar() in production; use Baz.bar() instead for testability.

**Scope**: include_tests
**Exceptions**: Skip in `foo_impl.dart`

## Bad

```dart
void doSomething() {
  Foo.bar();  // should be reported
}
```

## Good

```dart
void doSomething(Baz baz) {
  baz.bar();  // OK
}
```
~~~

---

## 2. How to use the agent

Open Cursor's Composer (Agent mode) and say:

> Create a new linter rule from `rule_specs/forbid_foo.md`.

Or paste the spec inline:

> Create a new linter rule from this spec: [paste spec content]

The agent will:

1. Parse the spec (rule name, description, scope, exceptions, Bad/Good examples).
2. Create `lib/core/analyzers/<rule_name>_analyzer.dart`.
3. Create `lib/custom_lint_rules/<rule_name>.dart`.
4. Update `lib/ripplearc_linter.dart`.
5. Create `test/custom_lint_rules/<rule_name>_test.dart`.
6. Optionally add `example/` and `docs/` files.
7. Run `./scripts/create_linter_rule_from_spec.sh <rule_name>` itself — no input from you.

The PR is opened automatically.

---

## 3. Quick reference

| Step | Who | Action |
|------|-----|--------|
| 1 | You | Write or paste the rule spec. |
| 2 | You | Ask the Cursor agent to create the rule. |
| 3 | Agent | Generates all Dart files. |
| 4 | Agent | Runs `create_linter_rule_from_spec.sh` — creates branch, commits, pushes, opens PR. |

---

## 4. Where things live

- **Rule spec**: `rule_specs/<rule_name>.md` (recommended) or any path you reference.
- **Agent instructions**: `.cursor/rules/create-linter-rule.mdc`
- **Git/PR automation**: `scripts/create_linter_rule_from_spec.sh`
- **Generated files**:
  - `lib/core/analyzers/<rule_name>_analyzer.dart`
  - `lib/custom_lint_rules/<rule_name>.dart`
  - `lib/ripplearc_linter.dart` (updated)
  - `test/custom_lint_rules/<rule_name>_test.dart`
  - Optionally: `example/`, `docs/<rule_name>.md`

---

## 5. Troubleshooting

- **Agent didn't register the rule** — remind it to add the import and rule instance in `lib/ripplearc_linter.dart`.
- **Script says "no rule files staged"** — the agent may not have saved files to disk. Ask it to write the files and retry.
- **PR not created** — install and authenticate GitHub CLI: `gh auth login`.
- **Rule name with hyphens** — the script normalises `forbid-foo` → `forbid_foo` correctly.
- **Tests or analyzer don't match spec** — refine the Bad/Good examples and ask the agent to update accordingly.

---

## 6. Summary

1. Write a rule spec (`rule_specs/<rule_name>.md`).
2. Ask the Cursor agent: *"Create a new linter rule from `rule_specs/<rule_name>.md`"*.
3. The agent generates the files and opens the PR automatically — nothing else needed.
