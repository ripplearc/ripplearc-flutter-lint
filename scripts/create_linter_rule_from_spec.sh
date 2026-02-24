#!/bin/bash
#
# create_linter_rule_from_spec.sh
#
# Purpose:
#   1. Provides instructions for the Cursor agent to create a new linter rule from a spec file.
#   2. After the agent has created the files, this script creates the branch, commits, pushes,
#      and opens a PR.
#
# Usage (by user/agent):
#   Step A: In Cursor, ask the agent to follow the AGENT INSTRUCTIONS below and use your rule spec.
#   Step B: After the agent has created/updated all files, run:
#     ./scripts/create_linter_rule_from_spec.sh <rule_name> [base_branch]
#   Example:
#     ./scripts/create_linter_rule_from_spec.sh forbid_foo
#     ./scripts/create_linter_rule_from_spec.sh my_new_rule main
#
# Arguments:
#   rule_name   (required) Snake_case name of the rule, e.g. forbid_datetime_now
#   base_branch (optional) Branch to create PR against. Default: main
#
# Requirements:
#   - Git repository clean or with only the new rule files changed.
#   - For PR creation: `gh` (GitHub CLI) installed and authenticated.
#
# =============================================================================
# AGENT INSTRUCTIONS (read and follow when the user asks you to create a rule)
# =============================================================================
#
# When the user asks you to create a custom linter rule and mentions this script
# (or points you to scripts/create_linter_rule_from_spec.sh), do the following.
#
# --- INPUT ---
# The user will provide:
#   - A rule spec: either a path to a .md or .txt file (e.g. rule_specs/my_rule.md),
#     or the spec content pasted in the chat.
#
# Spec format (structured Markdown):
#   - First heading: rule name in snake_case, e.g. "# forbid_foo"
#   - Short description (1–2 sentences) after the heading
#   - Optional: **Scope**: one of "test_only" | "include_tests" | (omit = production only)
#   - Optional: **Exceptions**: when to skip (e.g. "Skip in path ending with x.dart")
#   - ## Bad — code block(s) showing code that should trigger the rule
#   - ## Good — code block(s) showing correct code
#
# --- STEPS TO PERFORM (in order) ---
#
# 1. PARSE THE SPEC
#    - rule_name: from first # heading, normalized to snake_case
#    - description: paragraph after heading (for problemMessage and doc comments)
#    - scope: test_only → testOnly: true; include_tests → includeTests: true; else default
#    - exceptions: use for shouldSkipFile or visitor logic in the analyzer
#    - bad_examples / good_examples: use to implement and test the analyzer
#
# 2. CREATE THE ANALYZER
#    File: lib/core/analyzers/<rule_name>_analyzer.dart
#    - Extend BaseAnalyzer
#    - Implement: ruleName, problemMessage, correctionMessage
#    - Implement analyze(CompilationUnit) and optionally analyzeWithResolver(CompilationUnit, resolver)
#    - Use a RecursiveAstVisitor (or similar) to find nodes matching the "Bad" examples
#    - For each violation call createIssue(node) or createIssue(node, customMessage: ...)
#    - If exceptions were specified, implement shouldSkipFile(String path) or equivalent
#    Reference: lib/core/analyzers/forbid_datetime_now_analyzer.dart
#
# 3. CREATE THE RULE CLASS
#    File: lib/custom_lint_rules/<rule_name>.dart
#    - Extend BaseLintRule
#    - Constructor: super(BaseLintRule.createLintCode(_analyzer), testOnly: ... | includeTests: ...)
#      Use testOnly: true if scope is test_only; includeTests: true if scope is include_tests; else omit
#    - static final _analyzer = <PascalCaseRuleName>Analyzer();
#    - @override BaseAnalyzer get analyzer => _analyzer;
#    - Add doc comment from spec description
#    Reference: lib/custom_lint_rules/forbid_datetime_now.dart
#
# 4. REGISTER THE RULE
#    File: lib/ripplearc_linter.dart
#    - Add: import 'custom_lint_rules/<rule_name>.dart';
#    - In getLintRules(...), add <PascalCaseRuleClass>() to the returned list (alphabetical order optional)
#
# 5. (RECOMMENDED) ADD TESTS
#    File: test/custom_lint_rules/<rule_name>_test.dart
#    - Use parseString, TestCustomLintResolver, TestErrorReporter, TestCustomLintContext
#    - At least one test that expects a violation (from Bad example) and one that expects no violation (from Good example)
#    Reference: test/custom_lint_rules/forbid_datetime_now_test.dart
#
# 6. (OPTIONAL) ADD EXAMPLE AND DOCS
#    - example/example_<rule_name>_rule.dart — Bad/Good code with // LINT and // OK comments
#    - docs/<rule_name>.md — same structure as docs/forbid_datetime_now.md
#
# 7. AFTER CREATING ALL FILES
#    Tell the user to run this script to create the branch and PR:
#      ./scripts/create_linter_rule_from_spec.sh <rule_name> [base_branch]
#    Or run it yourself if you have terminal access.
#
# =============================================================================
# END AGENT INSTRUCTIONS
# =============================================================================

set -e

RULE_NAME="${1:-}"
BASE_BRANCH="${2:-main}"

if [ -z "$RULE_NAME" ]; then
  echo "Usage: $0 <rule_name> [base_branch]"
  echo "Example: $0 forbid_foo main"
  echo ""
  echo "Rule name must be snake_case (e.g. forbid_datetime_now)."
  echo "After the Cursor agent has created the analyzer, rule, and registration,"
  echo "run this script to create the branch, commit, push, and open a PR."
  exit 1
fi

# Normalize to snake_case (no spaces, lowercase)
RULE_NAME=$(echo "$RULE_NAME" | tr '[:upper:]' '[:lower:]' | tr -s ' ' '_' | tr -d '-')
BRANCH_NAME="rule/${RULE_NAME}"

# Ensure we're in repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
  echo "Creating branch and committing current changes..."
else
  echo "No changes to commit. Have you created the analyzer and rule files?"
  echo "Expected files (at least):"
  echo "  lib/core/analyzers/${RULE_NAME}_analyzer.dart"
  echo "  lib/custom_lint_rules/${RULE_NAME}.dart"
  echo "  lib/ripplearc_linter.dart (updated)"
  exit 1
fi

# Create a new branch from current HEAD (keeps all new/edited files in working tree)
if git rev-parse --verify "$BRANCH_NAME" >/dev/null 2>&1; then
  git checkout "$BRANCH_NAME"
else
  git checkout -b "$BRANCH_NAME"
fi

# Stage the expected rule-related files (if they exist)
for f in \
  "lib/core/analyzers/${RULE_NAME}_analyzer.dart" \
  "lib/custom_lint_rules/${RULE_NAME}.dart" \
  "lib/ripplearc_linter.dart" \
  "test/custom_lint_rules/${RULE_NAME}_test.dart" \
  "example/example_${RULE_NAME}_rule.dart" \
  "docs/${RULE_NAME}.md"; do
  if [ -f "$f" ]; then
    git add "$f"
  fi
done

# Also stage any other modified files (e.g. custom_lint_package, standalone_checker)
git add -u lib/ bin/ test/custom_lint_rules/ example/ docs/ 2>/dev/null || true

# Commit
git status
echo ""
read -p "Commit with message 'Add ${RULE_NAME} linter rule'? [Y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
  git commit -m "Add ${RULE_NAME} linter rule"
else
  echo "Aborted. You can commit manually."
  exit 0
fi

# Push
echo "Pushing branch $BRANCH_NAME..."
git push -u origin "$BRANCH_NAME"

# Open PR with gh if available
if command -v gh >/dev/null 2>&1; then
  echo "Creating pull request..."
  gh pr create --base "$BASE_BRANCH" --head "$BRANCH_NAME" \
    --title "Add ${RULE_NAME} linter rule" \
    --body "Adds the \`${RULE_NAME}\` custom linter rule.

- Analyzer: \`lib/core/analyzers/${RULE_NAME}_analyzer.dart\`
- Rule: \`lib/custom_lint_rules/${RULE_NAME}.dart\`
- Registered in \`lib/ripplearc_linter.dart\`

Created via \`scripts/create_linter_rule_from_spec.sh\`."
else
  echo "GitHub CLI (gh) not found. Create the PR manually:"
  echo "  Open: $(git remote get-url origin | sed 's/\.git$//')/compare/${BASE_BRANCH}...${BRANCH_NAME}"
fi

echo "Done."
