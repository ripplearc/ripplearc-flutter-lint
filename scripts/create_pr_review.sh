#!/bin/bash

# PR Review File Generator for RippleArc Flutter Lint Project
# Usage examples:
# ./create_pr_review.sh feature-branch main
# ./create_pr_review.sh bugfix/rule-fix develop rule_fix_review.txt
# ./create_pr_review.sh feature/new-lint-rule master new_rule_review.txt
# ./create_pr_review.sh origin/feature-x upstream/main fork_review.txt

# Check if enough parameters are provided
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 pr_branch base_branch [output_file]"
    echo "Example: $0 feature-branch main pr_review.txt"
    exit 1
fi

# Set variables from parameters
PR_BRANCH="$1"      # Branch with your changes
BASE_BRANCH="$2"    # Branch you want to merge into (target)
OUTPUT_FILE="${3:-pr_review_for_claude.txt}"  # Default filename if not provided

# Verify branches exist
if ! git rev-parse --verify "$PR_BRANCH" >/dev/null 2>&1; then
    echo "Error: PR branch '$PR_BRANCH' does not exist"
    exit 1
fi

if ! git rev-parse --verify "$BASE_BRANCH" >/dev/null 2>&1; then
    echo "Error: Base branch '$BASE_BRANCH' does not exist"
    exit 1
fi

# Create header
echo "# PR Review Request: $PR_BRANCH → $BASE_BRANCH" > "$OUTPUT_FILE"
echo "**Project:** RippleArc Flutter Lint Library" >> "$OUTPUT_FILE"
echo "**PR Branch:** $PR_BRANCH (with changes)" >> "$OUTPUT_FILE"
echo "**Base Branch:** $BASE_BRANCH (target)" >> "$OUTPUT_FILE"
echo "**Date:** $(date)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Get list of changed files - show what's in PR_BRANCH that's not in BASE_BRANCH
CHANGED_FILES=$(git diff --name-only "$BASE_BRANCH".."$PR_BRANCH")

# Check if there are any changes
if [ -z "$CHANGED_FILES" ]; then
    echo "No changes found between PR branch $PR_BRANCH and base branch $BASE_BRANCH"
    exit 0
fi

# Generate overview table with Flutter Lint specific categorization
echo "## CHANGES OVERVIEW" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "| File | Changes | Type | Category |" >> "$OUTPUT_FILE"
echo "|------|---------|------|----------|" >> "$OUTPUT_FILE"

for FILE in $CHANGED_FILES; do
    # Get file status (modified, added, deleted)
    STATUS=$(git diff --name-status "$BASE_BRANCH".."$PR_BRANCH" -- "$FILE" | cut -f1)
    
    case $STATUS in
        M) STATUS_DESC="Modified" ;;
        A) STATUS_DESC="Added" ;;
        D) STATUS_DESC="Deleted" ;;
        R*) STATUS_DESC="Renamed" ;;
        C*) STATUS_DESC="Copied" ;;
        *) STATUS_DESC="Changed" ;;
    esac
    
    # Determine file category based on project structure
    if [[ "$FILE" == lib/core/analyzers/* ]]; then
        CATEGORY="Core Analyzer"
    elif [[ "$FILE" == lib/custom_lint_rules/* ]]; then
        CATEGORY="Lint Rule"
    elif [[ "$FILE" == test/custom_lint_rules/* ]]; then
        CATEGORY="Rule Tests"
    elif [[ "$FILE" == example/* ]]; then
        CATEGORY="Examples"
    elif [[ "$FILE" == lib/core/* ]]; then
        CATEGORY="Core Framework"
    elif [[ "$FILE" == test/utils/* ]]; then
        CATEGORY="Test Utils"
    elif [[ "$FILE" == scripts/* ]]; then
        CATEGORY="Scripts"
    elif [[ "$FILE" == *.yaml ]] || [[ "$FILE" == *.md ]]; then
        CATEGORY="Configuration/Docs"
    else
        CATEGORY="Other"
    fi
    
    # Get file type and stats
    if git show "$PR_BRANCH":"$FILE" &>/dev/null 2>&1; then
        if file --mime-type "$FILE" 2>/dev/null | grep -q "text/"; then
            FILE_TYPE="Text"
            # Count lines changed
            STATS=$(git diff --stat "$BASE_BRANCH".."$PR_BRANCH" -- "$FILE" | tail -n1)
            echo "| $FILE | $STATS | $FILE_TYPE | $CATEGORY |" >> "$OUTPUT_FILE"
        else
            FILE_TYPE="Binary"
            echo "| $FILE | $STATUS_DESC | $FILE_TYPE | $CATEGORY |" >> "$OUTPUT_FILE"
        fi
    else
        FILE_TYPE="Unknown"
        echo "| $FILE | $STATUS_DESC | $FILE_TYPE | $CATEGORY |" >> "$OUTPUT_FILE"
    fi
done

echo "" >> "$OUTPUT_FILE"

# Create GitHub-style diff with context
echo "## GITHUB-STYLE DIFF WITH CONTEXT" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

for FILE in $CHANGED_FILES; do
    # Skip binary files
    if git show "$PR_BRANCH":"$FILE" &>/dev/null 2>&1 && ! file --mime-type "$FILE" 2>/dev/null | grep -q "binary"; then
        # Get the file extension for syntax highlighting
        FILE_EXT="${FILE##*.}"
        
        # Determine if file is added, modified, or deleted
        STATUS=$(git diff --name-status "$BASE_BRANCH".."$PR_BRANCH" -- "$FILE" | cut -f1)
        
        case $STATUS in
            A) CHANGE_TYPE="Added" ;;
            M) CHANGE_TYPE="Modified" ;;
            D) CHANGE_TYPE="Deleted" ;;
            R*) CHANGE_TYPE="Renamed" ;;
            C*) CHANGE_TYPE="Copied" ;;
            *) CHANGE_TYPE="Changed" ;;
        esac
        
        echo "### $FILE ($CHANGE_TYPE)" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        
        # Generate GitHub-style diff with context
        # Using -U3 to show 3 lines of context before and after changes
        echo "\`\`\`$FILE_EXT" >> "$OUTPUT_FILE"
        
        # Use git diff directly with line numbers (simplified approach)
        git diff --no-prefix -U3 "$BASE_BRANCH".."$PR_BRANCH" -- "$FILE" >> "$OUTPUT_FILE"
        
        echo "\`\`\`" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        
        # Add Flutter Lint specific review prompts based on file category
        if [[ "$FILE" == lib/core/analyzers/* ]]; then
            echo "#### Analyzer Review Points for $FILE" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
            echo "**Key Review Areas:**" >> "$OUTPUT_FILE"
            echo "- ✅ Does the analyzer extend BaseAnalyzer?" >> "$OUTPUT_FILE"
            echo "- ✅ Is the ruleName unique and descriptive?" >> "$OUTPUT_FILE"
            echo "- ✅ Are error messages clear and actionable?" >> "$OUTPUT_FILE"
            echo "- ✅ Does the analysis logic cover edge cases?" >> "$OUTPUT_FILE"
            echo "- ✅ Is the performance optimized for large files?" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
        elif [[ "$FILE" == lib/custom_lint_rules/* ]]; then
            echo "#### Lint Rule Review Points for $FILE" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
            echo "**Key Review Areas:**" >> "$OUTPUT_FILE"
            echo "- ✅ Does the rule extend BaseLintRule?" >> "$OUTPUT_FILE"
            echo "- ✅ Is the analyzer properly instantiated?" >> "$OUTPUT_FILE"
            echo "- ✅ Is the rule properly registered in the main plugin?" >> "$OUTPUT_FILE"
            echo "- ✅ Does the rule follow naming conventions?" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
        elif [[ "$FILE" == test/custom_lint_rules/* ]]; then
            echo "#### Test Review Points for $FILE" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
            echo "**Key Review Areas:**" >> "$OUTPUT_FILE"
            echo "- ✅ Are both positive and negative test cases covered?" >> "$OUTPUT_FILE"
            echo "- ✅ Are edge cases and error conditions tested?" >> "$OUTPUT_FILE"
            echo "- ✅ Is the test code using proper test utilities?" >> "$OUTPUT_FILE"
            echo "- ✅ Are test descriptions clear and descriptive?" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
        elif [[ "$FILE" == example/* ]]; then
            echo "#### Example Review Points for $FILE" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
            echo "**Key Review Areas:**" >> "$OUTPUT_FILE"
            echo "- ✅ Does the example clearly show bad vs good usage?" >> "$OUTPUT_FILE"
            echo "- ✅ Are the examples realistic and practical?" >> "$OUTPUT_FILE"
            echo "- ✅ Is the LINT comment properly placed?" >> "$OUTPUT_FILE"
            echo "- ✅ Does the example demonstrate the rule's value?" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
        fi
        
        # Add placeholder for code review comments
        echo "#### Suggestions for $FILE" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "<!-- Example suggestion format below -->" >> "$OUTPUT_FILE"
        echo "<!--" >> "$OUTPUT_FILE"
        echo "**Line XX:** ✅/❌ Comment about the code" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "**Suggested Change:**" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "\`\`\`$FILE_EXT" >> "$OUTPUT_FILE"
        echo "// Suggested implementation" >> "$OUTPUT_FILE"
        echo "\`\`\`" >> "$OUTPUT_FILE"
        echo "-->" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    else
        echo "### $FILE (Binary or Deleted - diff not shown)" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    fi
done

# Add full file contents for context
echo "## COMPLETE FILE CONTENTS FOR CONTEXT" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

for FILE in $CHANGED_FILES; do
    # Check if file exists in PR branch
    if git show "$PR_BRANCH":"$FILE" &>/dev/null; then
        # Skip binary files
        if ! git cat-file -t "$PR_BRANCH":"$FILE" | grep -q "blob" || ! file --mime-type "$FILE" 2>/dev/null | grep -qv "binary"; then
            # Get the file extension for syntax highlighting
            FILE_EXT="${FILE##*.}"
            
            echo "### COMPLETE FILE: $FILE (PR branch version)" >> "$OUTPUT_FILE"
            echo "\`\`\`$FILE_EXT" >> "$OUTPUT_FILE"
            git show "$PR_BRANCH":"$FILE" 2>/dev/null >> "$OUTPUT_FILE"
            echo "\`\`\`" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
        else
            echo "### SKIPPED BINARY FILE: $FILE" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
        fi
    else
        # File was deleted in PR branch
        echo "### FILE DELETED IN PR BRANCH: $FILE" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    fi
done

# Add Flutter Lint specific review instructions
echo "## FLUTTER LINT PROJECT REVIEW INSTRUCTIONS" >> "$OUTPUT_FILE"
echo "Please review this PR with the following Flutter Lint specific considerations:" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "### 🎯 **Core Rule Quality**" >> "$OUTPUT_FILE"
echo "1. **Analyzer Implementation**: Does the analyzer extend BaseAnalyzer and follow established patterns?" >> "$OUTPUT_FILE"
echo "2. **Rule Registration**: Is the rule properly registered in ripplearc_linter_test.dart?" >> "$OUTPUT_FILE"
echo "3. **Error Messages**: Are lint messages clear, actionable, and consistent with other rules?" >> "$OUTPUT_FILE"
echo "4. **Performance**: Is the analyzer efficient for large files and complex code structures?" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### 🧪 **Testing & Coverage**" >> "$OUTPUT_FILE"
echo "1. **Test Coverage**: Are there comprehensive tests covering positive/negative cases and edge cases?" >> "$OUTPUT_FILE"
echo "2. **Test Utilities**: Is the code using TestErrorReporter and other test utilities properly?" >> "$OUTPUT_FILE"
echo "3. **Example Files**: Do the examples clearly demonstrate rule violations and correct usage?" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### 📚 **Documentation & Examples**" >> "$OUTPUT_FILE"
echo "1. **Example Files**: Do examples show realistic usage patterns and clear LINT comments?" >> "$OUTPUT_FILE"
echo "2. **Configuration**: Are configuration files updated if needed?" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### 🏗️ **Architecture & Code Quality**" >> "$OUTPUT_FILE"
echo "1. **Base Classes**: Does the code properly extend the established base classes?" >> "$OUTPUT_FILE"
echo "2. **Separation of Concerns**: Is there clear separation between analyzers and rules?" >> "$OUTPUT_FILE"
echo "3. **Dart Best Practices**: Does the code follow Dart/Flutter best practices and conventions?" >> "$OUTPUT_FILE"
echo "4. **Code Duplication**: Is there any unnecessary code duplication that could be refactored?" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### 🔧 **Integration & Configuration**" >> "$OUTPUT_FILE"
echo "1. **Plugin Registration**: Is the rule properly added to the plugin's rule list?" >> "$OUTPUT_FILE"
echo "2. **Dependencies**: Are any new dependencies necessary and properly constrained?" >> "$OUTPUT_FILE"
echo "3. **Backward Compatibility**: Do changes maintain backward compatibility?" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### 📝 **Code Review Format**" >> "$OUTPUT_FILE"
echo "Please format suggestions as:" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Line XX:** ✅/❌ Comment about the code" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Suggested Change:**" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "\`\`\`language" >> "$OUTPUT_FILE"
echo "// Code suggestion here" >> "$OUTPUT_FILE"
echo "\`\`\`" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### 🚀 **Release Considerations**" >> "$OUTPUT_FILE"
echo "1. **Version Bump**: Should the version be incremented in pubspec.yaml?" >> "$OUTPUT_FILE"
echo "2. **Changelog**: Are changes documented in CHANGELOG.md?" >> "$OUTPUT_FILE"
echo "3. **Breaking Changes**: Are there any breaking changes that need special attention?" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "Review file created: $OUTPUT_FILE"
echo ""
echo "💡 **Tip**: Focus on the Flutter Lint specific aspects above, especially rule quality, testing coverage, and proper integration with the existing framework."
