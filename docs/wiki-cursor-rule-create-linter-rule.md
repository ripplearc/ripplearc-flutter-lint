# Wiki: Automated linter rule creation with the Cursor agent

This project uses a Cursor rule to create new custom linter rules fully autonomously — no manual script execution required. You provide a rule spec; the Cursor agent generates all files and opens the PR itself.

---

## How it works

```mermaid
flowchart LR
    A[You: provide rule spec] --> B[Cursor agent reads\n.cursor/rules/create-linter-rule.mdc]
    B --> C[Generates Dart files\nanalyzer · rule · registration · tests]
    C --> D[Runs script autonomously\ncreate_linter_rule_from_spec.sh]
    D --> E[PR opened on GitHub]
```

The agent instructions live in `.cursor/rules/create-linter-rule.mdc`. The shell script `scripts/create_linter_rule_from_spec.sh` handles only git/PR automation — no agent instructions embedded inside it.

---

## Prerequisites

- **Cursor** with Agent (Composer) mode enabled.
- `ripplearc-flutter-lint` open in Cursor.
- **GitHub CLI** (`gh`) installed and authenticated (`gh auth login`) — required for automatic PR creation. If unavailable, the script prints a GitHub compare URL instead.

---

## Usage

### Step 1 — Write a rule spec

Create a file under `rule_specs/<rule_name>.md` (or paste content directly in Cursor):

```markdown
# forbid_foo

Do not use Foo.bar() in production; use Baz.bar() instead for testability.

**Scope**: include_tests
**Exceptions**: Skip in files ending with `_impl.dart`

## Bad
```dart
void doSomething() {
  Foo.bar(); // flagged
}
```

## Good
```dart
void doSomething(Baz baz) {
  baz.bar(); // OK
}
```
```

### Step 2 — Ask the Cursor agent

Open Cursor's Composer (Agent mode) and say:

> *Create a new linter rule from `rule_specs/forbid_foo.md`.*

The agent reads `.cursor/rules/create-linter-rule.mdc`, generates all required files, and runs `scripts/create_linter_rule_from_spec.sh` autonomously. A PR is opened when done.

---

## Generated files

| File | Description |
|------|-------------|
| `lib/core/analyzers/<rule_name>_analyzer.dart` | AST visitor implementation |
| `lib/custom_lint_rules/<rule_name>.dart` | Rule class wiring the analyzer |
| `lib/ripplearc_linter.dart` | Updated to register the new rule |
| `test/custom_lint_rules/<rule_name>_test.dart` | Violation and no-violation tests |
| `example/example_<rule_name>_rule.dart` | Bad/Good annotated example *(optional)* |
| `docs/<rule_name>.md` | Rule documentation *(optional)* |

---

## Spec format reference

| Field | Required | Description |
|-------|----------|-------------|
| `# <rule_name>` | ✅ | First heading, snake_case |
| Description | ✅ | 1–2 sentences after heading |
| `**Scope**` | ❌ | `test_only` \| `include_tests` \| omit (production only) |
| `**Exceptions**` | ❌ | When to skip the rule |
| `## Bad` | ✅ | Dart code that should trigger the rule |
| `## Good` | ✅ | Dart code that should not trigger the rule |

---

## Troubleshooting

**Agent didn't register the rule** — remind it to add the import and the rule instance in `lib/ripplearc_linter.dart`.

**Script exits with "Nothing staged to commit"** — ensure the new Dart files are saved and you're in the repo root.

**PR not created** — install and authenticate GitHub CLI: `gh auth login`. Or use the compare URL the script prints.

**Rule name normalisation** — spaces and hyphens are converted to underscores automatically (e.g. `forbid-foo` → `forbid_foo`).
