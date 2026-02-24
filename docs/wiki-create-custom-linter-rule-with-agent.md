# Wiki: Create a Custom Linter Rule Using the Cursor Agent

This guide explains how to add a new custom linter rule to this project by giving the Cursor agent a rule spec and having it follow the instructions in `scripts/create_linter_rule_from_spec.sh`. The agent will generate the analyzer, rule class, registration, and optional tests; then you (or the agent) run the script to create the branch and open a PR.

---

## Prerequisites

- **Cursor** with agent/composer available.
- This repo open in Cursor (`ripplearc-flutter-lint`).
- A **rule spec** in Markdown (or text) describing what the rule should do (see below).
- For opening the PR from the script: **Git** and optionally **GitHub CLI** (`gh`) installed and authenticated.

---

## 1. Rule spec format

The agent expects a **structured spec** so it can generate correct code. Use this format (`.md` or `.txt`).

### Required

- **Rule name**: First heading, snake_case.  
  Example: `# forbid_foo`
- **Description**: One or two sentences after the heading (what the rule forbids or enforces).
- **Bad**: A `## Bad` section with a Dart code block showing code that **should** be reported.
- **Good**: A `## Good` section with a Dart code block showing code that is **allowed**.

### Optional

- **Scope**: Line like `**Scope**: include_tests` or `**Scope**: test_only`.  
  - `test_only` → rule runs only in test files.  
  - `include_tests` → rule runs in both lib and test.  
  - Omit → rule runs only in production (lib) code.
- **Exceptions**: When to skip the rule (e.g. “Skip in files ending with `_impl.dart`”).

### Example spec

Save this as `rule_specs/forbid_foo.md` (or paste it in chat):

```markdown
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
```

You can put spec files under a `rule_specs/` folder or any path; just tell the agent where it is or paste the content.

---

## 2. How to use the agent

### Step 1: Tell the agent what to do

In Cursor, open the agent (Composer or Chat) and say something like:

- *“Follow the instructions in `scripts/create_linter_rule_from_spec.sh` and create a new linter rule from this spec.”*
- Then either:
  - **Attach or reference the spec file**, e.g. `rule_specs/my_rule.md`, or  
  - **Paste the spec** (rule name, description, Bad/Good, optional Scope and Exceptions) in the message.

Example:

> Follow the instructions in **scripts/create_linter_rule_from_spec.sh** and create a new linter rule. The rule spec is in **rule_specs/forbid_foo.md** (or see below).
>
> [Optional: paste spec content if not using a file]

### Step 2: What the agent will do

The agent will read the **AGENT INSTRUCTIONS** inside `scripts/create_linter_rule_from_spec.sh` and:

1. Parse the spec (rule name, description, scope, exceptions, Bad/Good examples).
2. Create **lib/core/analyzers/<rule_name>_analyzer.dart** (AST visitor, `createIssue`, etc.).
3. Create **lib/custom_lint_rules/<rule_name>.dart** (extends `BaseLintRule`, wires the analyzer).
4. Update **lib/ripplearc_linter.dart** (import and add the rule to `getLintRules`).
5. Optionally add **test/custom_lint_rules/<rule_name>_test.dart** and/or **example/** and **docs/**.

It will use existing rules (e.g. `forbid_datetime_now`) as references.

### Step 3: Create the branch and PR

After the agent has created or updated the files:

1. Open a terminal in the repo root.
2. Run the script with the **rule name** (snake_case) and optionally the base branch:

   ```bash
   ./scripts/create_linter_rule_from_spec.sh <rule_name> [base_branch]
   ```

   Examples:

   ```bash
   ./scripts/create_linter_rule_from_spec.sh forbid_foo
   ./scripts/create_linter_rule_from_spec.sh my_new_rule main
   ```

3. The script will:
   - Create branch `rule/<rule_name>` from your current branch (keeping all new changes).
   - Stage the new/updated rule files.
   - Ask for confirmation, then commit with message `Add <rule_name> linter rule`.
   - Push the branch.
   - If `gh` is installed, create a PR against `base_branch` (default: `main`).

If you prefer, you can ask the agent to run this script for you (e.g. “run create_linter_rule_from_spec.sh with rule name forbid_foo”) after it has generated the files.

---

## 3. Quick reference

| Step | Who | Action |
|------|-----|--------|
| 1 | You | Write or paste the rule spec (name, description, Bad, Good, optional Scope/Exceptions). |
| 2 | You | In Cursor, ask the agent to follow `scripts/create_linter_rule_from_spec.sh` and use that spec. |
| 3 | Agent | Creates analyzer, rule class, registration, and optionally tests/example/docs. |
| 4 | You or Agent | Run `./scripts/create_linter_rule_from_spec.sh <rule_name> [base_branch]` to create branch, commit, push, and open PR. |

---

## 4. Where things live

- **Rule spec**: e.g. `rule_specs/<rule_name>.md` (or any path you give the agent).
- **Instructions for the agent**: Inside `scripts/create_linter_rule_from_spec.sh` (AGENT INSTRUCTIONS block).
- **Generated files**:
  - `lib/core/analyzers/<rule_name>_analyzer.dart`
  - `lib/custom_lint_rules/<rule_name>.dart`
  - `lib/ripplearc_linter.dart` (updated)
  - Optionally: `test/...`, `example/...`, `docs/<rule_name>.md`
- **Full plan**: `docs/agent-rule-from-spec-plan.md`.

---

## 5. Troubleshooting

- **Agent didn’t register the rule**  
  Remind it to add the import and the rule instance in `lib/ripplearc_linter.dart` (step 4 in the script instructions).

- **Script says “No changes to commit”**  
  Ensure the new Dart files and changes to `ripplearc_linter.dart` are saved and that you’re in the repo root when running the script.

- **PR not created**  
  Install and log in to GitHub CLI: `gh auth login`. Then run the script again, or create the PR manually from the link the script prints.

- **Rule name with dashes or spaces**  
  The script normalizes the first argument to snake_case (e.g. `forbid-foo` → `forbid_foo`). Use the same name the agent used in file paths.

- **Tests or analyzer don’t match spec**  
  Refine the spec (clearer Bad/Good examples) and ask the agent to update the analyzer and tests accordingly.

---

## 6. Summary

1. Write a rule spec (Markdown with rule name, description, Bad, Good, optional Scope/Exceptions).
2. In Cursor, ask the agent to follow **scripts/create_linter_rule_from_spec.sh** and use that spec.
3. After the agent creates the files, run **./scripts/create_linter_rule_from_spec.sh \<rule_name>** to create the branch and PR.

The script is the single place for both **what the agent should do** (instructions inside it) and **how to create the PR** (running the script after the agent is done).
