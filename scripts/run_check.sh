#!/bin/bash
# run_check_new.sh
# Runs the exact_dependency_version.sh script and passes through its exit code

set -euo pipefail

scripts/exact_dependency_version.sh
status=$?
if [[ $status -ne 0 ]]; then
  echo "One or more pubspec.yaml files have non-exact dependency versions. See above for details."
fi
exit $status 