#!/bin/bash
#
# create_linter_rule_from_spec.sh
#
# Purpose:
#   Git automation for adding a new custom linter rule.
#   Creates the branch, stages rule files, commits, pushes, and opens a PR.
#
#   The Cursor agent runs this script automatically after generating the Dart files.
#   See .cursor/rules/create-linter-rule.mdc for the full agent workflow.
#
# Usage:
#   ./scripts/create_linter_rule_from_spec.sh <rule_name> [base_branch]
#
# Arguments:
#   rule_name   (required) Snake_case name of the rule, e.g. forbid_datetime_now
#   base_branch (optional) Branch to target for the PR. Default: main
#
# Requirements:
#   - Git repository with the new rule files already created.
#   - For PR creation: `gh` (GitHub CLI) installed and authenticated.
#

set -eo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_open_pr_in_browser() {
  local base="$1" head="$2" origin_url pr_url
  origin_url=$(git remote get-url origin 2>/dev/null | sed 's/\.git$//')
  [ -z "$origin_url" ] && return 1
  pr_url="${origin_url}/compare/${base}...${head}"
  echo "Open in browser to create the PR: $pr_url"
  command -v xdg-open >/dev/null 2>&1 && xdg-open "$pr_url" 2>/dev/null && return 0
  command -v open     >/dev/null 2>&1 && open     "$pr_url" 2>/dev/null && return 0
  command -v start    >/dev/null 2>&1 && start    "$pr_url" 2>/dev/null && return 0
  return 1
}

_create_pr() {
  local base="$1" head="$2" rule="$3"
  if command -v gh >/dev/null 2>&1; then
    if gh pr view --head "$head" >/dev/null 2>&1; then
      echo "A PR for branch $head already exists."
      gh pr view --web 2>/dev/null || true
    else
      echo "Creating pull request..."
      gh pr create \
        --base "$base" --head "$head" \
        --title "Add ${rule} linter rule" \
        --body "Adds the \`${rule}\` custom linter rule.

- Analyzer: \`lib/core/analyzers/${rule}_analyzer.dart\`
- Rule:     \`lib/custom_lint_rules/${rule}.dart\`
- Tests:    \`test/custom_lint_rules/${rule}_test.dart\`
- Registered in \`lib/ripplearc_linter.dart\`

Created via Cursor agent + \`scripts/create_linter_rule_from_spec.sh\`."
      echo "Done."
    fi
  else
    echo "GitHub CLI (gh) not found. Opening GitHub in browser..."
    _open_pr_in_browser "$base" "$head" || \
      echo "  Open: $(git remote get-url origin | sed 's/\.git$//')/compare/${base}...${head}"
  fi
}

# ---------------------------------------------------------------------------
# Validate arguments
# ---------------------------------------------------------------------------

RULE_NAME="${1:-}"
BASE_BRANCH="${2:-main}"

if [ -z "$RULE_NAME" ]; then
  echo "Usage: $0 <rule_name> [base_branch]"
  echo "Example: $0 forbid_foo"
  echo ""
  echo "Run this script after the Cursor agent has created the analyzer, rule class,"
  echo "and test files. See .cursor/rules/create-linter-rule.mdc for the full workflow."
  exit 1
fi

# Normalize: lowercase, spaces → underscores, hyphens → underscores
RULE_NAME=$(echo "$RULE_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr '-' '_')
BRANCH_NAME="rule/${RULE_NAME}"

# ---------------------------------------------------------------------------
# Navigate to repo root
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# ---------------------------------------------------------------------------
# Handle already-clean working tree (e.g. re-running to create a missed PR)
# ---------------------------------------------------------------------------

if [ -z "$(git status --porcelain)" ]; then
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
  if [ "$CURRENT_BRANCH" = "$BRANCH_NAME" ]; then
    git push -u origin "$BRANCH_NAME" 2>/dev/null || true
    _create_pr "$BASE_BRANCH" "$BRANCH_NAME" "$RULE_NAME"
    exit 0
  fi
  echo "No changes to commit. Expected rule files:"
  echo "  lib/core/analyzers/${RULE_NAME}_analyzer.dart"
  echo "  lib/custom_lint_rules/${RULE_NAME}.dart"
  echo "  lib/ripplearc_linter.dart (updated)"
  echo "  test/custom_lint_rules/${RULE_NAME}_test.dart"
  exit 1
fi

# ---------------------------------------------------------------------------
# Create or switch to the rule branch
# ---------------------------------------------------------------------------

if git rev-parse --verify "$BRANCH_NAME" >/dev/null 2>&1; then
  git checkout "$BRANCH_NAME"
else
  git checkout -b "$BRANCH_NAME"
fi

# ---------------------------------------------------------------------------
# Stage rule-related files
# ---------------------------------------------------------------------------

for f in \
  "lib/core/analyzers/${RULE_NAME}_analyzer.dart" \
  "lib/custom_lint_rules/${RULE_NAME}.dart" \
  "lib/ripplearc_linter.dart" \
  "test/custom_lint_rules/${RULE_NAME}_test.dart" \
  "example/example_${RULE_NAME}_rule.dart" \
  "docs/${RULE_NAME}.md"; do
  [ -f "$f" ] && git add "$f"
done

# Also catch any additional files the agent created under key dirs
git add -A lib/ test/custom_lint_rules/ example/ docs/ rule_specs/ 2>/dev/null || true

# ---------------------------------------------------------------------------
# Commit
# ---------------------------------------------------------------------------

git commit -m "Add ${RULE_NAME} linter rule"

# ---------------------------------------------------------------------------
# Push and open PR
# ---------------------------------------------------------------------------

echo "Pushing branch $BRANCH_NAME..."
git push -u origin "$BRANCH_NAME"

_create_pr "$BASE_BRANCH" "$BRANCH_NAME" "$RULE_NAME"
