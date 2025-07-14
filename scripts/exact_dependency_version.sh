#!/bin/bash
# exact_dependency_version.sh
# Checks all pubspec.yaml files for non-exact dependency versions (no ^, ~, >=, <=, <, > allowed)
# Exits nonzero if any violations are found.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

found_issues=0

for file in $(find . -type f -name 'pubspec.yaml'); do
  in_deps=0
  lineno=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    lineno=$((lineno+1))
    # Check for start of dependencies/dev_dependencies section
    if [[ "$line" =~ ^(dependencies|dev_dependencies):[[:space:]]*$ ]]; then
      in_deps=1
      continue
    fi
    # End of section: blank line or new section
    if [[ $in_deps -eq 1 && ( -z "${line// /}" || ! "$line" =~ ^[[:space:]] ) ]]; then
      in_deps=0
    fi
    # If in dependencies section, check for version range
    if [[ $in_deps -eq 1 ]]; then
      # Match lines like '  foo: ^1.2.3' or '  bar: >=2.0.0'
      if [[ "$line" =~ ^[[:space:]]+([a-zA-Z0-9_\-]+):[[:space:]]*([^#[:space:]]+) ]]; then
        dep_name="${BASH_REMATCH[1]}"
        version="${BASH_REMATCH[2]}"
        # Ignore sdk dependencies
        if [[ "$dep_name" == "sdk" ]]; then
          continue
        fi
        # Check if version starts with ^, ~, >=, <=, <, or >
        if [[ "$version" =~ ^(\^|~|>=|<=|<|>) ]]; then
          echo -e "${RED}❌ $file:$lineno: $dep_name: $version (should use exact version)${NC}"
          found_issues=1
        fi
      fi
    fi
  done < "$file"
done

if [[ $found_issues -eq 0 ]]; then
  echo -e "${GREEN}✅ All pubspec.yaml files use exact dependency versions.${NC}"
  exit 0
else
  exit 1
fi 