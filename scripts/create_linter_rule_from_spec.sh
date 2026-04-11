#!/bin/bash
#
# create_linter_rule_from_spec.sh
#
# Purpose:
#   Git/PR automation for new linter rules. Creates the branch, stages rule files,
#   commits, pushes, and opens a PR.
#
#   Agent instructions for generating the rule files live in:
#     .cursor/rules/create-linter-rule.mdc
#
# Usage:
#   ./scripts/create_linter_rule_from_spec.sh <rule_name> [base_branch]
#
# Arguments:
#   rule_name   (required) snake_case name of the rule, e.g. forbid_datetime_now
#   base_branch (optional) branch to open PR against. Default: main
#
# Requirements:
#   - Git repository with the new rule files already present (agent has created them).
#   - For PR creation: gh (GitHub CLI) installed and authenticated.
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_open_pr_in_browser() {
  local base="$1" head="$2" origin_url pr_url
  origin_url=$(git remote get-url origin 2>/dev/null | sed 's/\.git$//')
  [ -z "$origin_url" ] && return 1
  pr_url="${origin_url}/compare/${base}...${head}"
  echo "Open in browser to create the PR: $pr_url"
  if command -v xdg-open >/dev/null 2>&1; then xdg-open "$pr_url" 2>/dev/null && return 0; fi
  if command -v open      >/dev/null 2>&1; then open      "$pr_url" 2>/dev/null && return 0; fi
  if command -v start     >/dev/null 2>&1; then start     "$pr_url" 2>/dev/null && return 0; fi
  return 1
}

# ---------------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------------

RULE_NAME="${1:-}"
BASE_BRANCH="${2:-main}"

if [ -z "$RULE_NAME" ]; then
  echo "Usage: $0 <rule_name> [base_branch]"
  echo "Example: $0 forbid_foo main"
  echo ""
  echo "Rule name must be snake_case (e.g. forbid_datetime_now)."
  echo "Run this script after the Cursor agent has generated the rule files."
  exit 1
fi

# Normalize to snake_case: lowercase, spaces→underscore, hyphens→underscore
RULE_NAME=$(echo "$RULE_NAME" | tr '[:upper:]' '[:lower:]' | tr -s ' ' '_' | tr '-' '_')
BRANCH_NAME="rule/${RULE_NAME}"

PR_BODY="Adds the \`${RULE_NAME}\` custom linter rule.

- Analyzer: \`lib/core/analyzers/${RULE_NAME}_analyzer.dart\`
- Rule: \`lib/custom_lint_rules/${RULE_NAME}.dart\`
- Registered in \`lib/ripplearc_linter.dart\`

Created via Cursor agent + \`scripts/create_linter_rule_from_spec.sh\`."

# ---------------------------------------------------------------------------
# Repo root
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# ---------------------------------------------------------------------------
# Already on rule branch and clean → just push + create PR
# ---------------------------------------------------------------------------

if [ -z "$(git status --porcelain)" ]; then
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
  if [ "$CURRENT_BRANCH" = "$BRANCH_NAME" ]; then
    git push -u origin "$BRANCH_NAME"
    if command -v gh >/dev/null 2>&1; then
      if gh pr view --head "$BRANCH_NAME" >/dev/null 2>&1; then
        echo "A PR for branch $BRANCH_NAME already exists."
        gh pr view --web 2>/dev/null || true
      else
        gh pr create --base "$BASE_BRANCH" --head "$BRANCH_NAME" \
          --title "Add ${RULE_NAME} linter rule" \
          --body "$PR_BODY"
      fi
    else
      _open_pr_in_browser "$BASE_BRANCH" "$BRANCH_NAME" || true
    fi
    exit 0
  fi
  echo "Error: no changes to commit and not on branch $BRANCH_NAME."
  echo "Expected rule files:"
  echo "  lib/core/analyzers/${RULE_NAME}_analyzer.dart"
  echo "  lib/custom_lint_rules/${RULE_NAME}.dart"
  echo "  lib/ripplearc_linter.dart (updated)"
  exit 1
fi

# ---------------------------------------------------------------------------
# Create branch, stage, commit, push, open PR
# ---------------------------------------------------------------------------

if git rev-parse --verify "$BRANCH_NAME" >/dev/null 2>&1; then
  git checkout "$BRANCH_NAME"
else
  git checkout -b "$BRANCH_NAME"
fi

# Stage only generated rule artifacts (not rule_specs/*.md — spec is user input, not committed)
for f in \
  "lib/core/analyzers/${RULE_NAME}_analyzer.dart" \
  "lib/custom_lint_rules/${RULE_NAME}.dart" \
  "lib/ripplearc_linter.dart" \
  "test/custom_lint_rules/${RULE_NAME}_test.dart" \
  "example/example_${RULE_NAME}_rule.dart" \
  "docs/${RULE_NAME}.md"; do
  [ -f "$f" ] && git add "$f"
done

if [ -z "$(git diff --cached --name-only)" ]; then
  echo "Error: no rule files staged. Check that the agent created the expected files."
  exit 1
fi

# ---------------------------------------------------------------------------
# Validate before committing
# ---------------------------------------------------------------------------

echo "Running dart analyze..."
if ! dart analyze lib/ test/; then
  echo "Error: dart analyze failed. Fix the issues above before committing."
  exit 1
fi

echo "Running dart test..."
if ! dart test "test/custom_lint_rules/${RULE_NAME}_test.dart"; then
  echo "Error: dart test failed. Fix the failures above before committing."
  exit 1
fi

git commit -m "Add ${RULE_NAME} linter rule"

echo "Pushing branch $BRANCH_NAME..."
git push -u origin "$BRANCH_NAME"

if command -v gh >/dev/null 2>&1; then
  gh pr create --base "$BASE_BRANCH" --head "$BRANCH_NAME" \
    --title "Add ${RULE_NAME} linter rule" \
    --body "$PR_BODY"
else
  _open_pr_in_browser "$BASE_BRANCH" "$BRANCH_NAME" || true
fi

echo "Done."
