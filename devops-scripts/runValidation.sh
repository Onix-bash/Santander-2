#!/bin/bash

# script gets as parameter an array of module names
# if there is no any module name provided then script validates all sources under /src folder
source_paths_to_validate=('src/')
if [ -n "$1" ]; then
  source_paths_to_validate=()
  for module in "$@"; do
      source_paths_to_validate+=("src/$module")
  done
fi

unit_tests_params='--test-level NoTestRun'

# Ensure TEST_LEVEL and SPECIFIED_TESTS environment variables are set
# Check if TEST_LEVEL is "RunSpecifiedTests" and SPECIFIED_TESTS is provided
if [ "$TEST_LEVEL" == "RunSpecifiedTests" ] && [ -n "$SPECIFIED_TESTS" ]; then
  unit_tests_params="--test-level RunSpecifiedTests --tests $SPECIFIED_TESTS"
elif [ -n "$TEST_LEVEL" ]; then
  unit_tests_params="--test-level $TEST_LEVEL"
fi

echo "--- Starting validation for modules: ${source_paths_to_validate[*]}"
#if [ "$SKIP_ORG_INTERACTION" = "true" ]; then
#  echo "Org interaction has been skipped because of setup: SKIP_ORG_INTERACTION = true"
#else
#  # chmod +x ./devops-scripts/getTestClasses.sh
#  # IFS=' ' read -r -a testClasses <<< "$(./devops-scripts/getTestClasses.sh)"  # I dont know why this is not working, I tried several different approaches with string concat and arrays
#                                                                       # but only thi IFS approach works, I love bash scripting but we should look into JS actions asap ;_;
#
#  command_result=$(sf project generate manifest --source-dir "${source_paths_to_validate[@]}" --name sourcePackage)
#  echo "Package generated: $command_result"

  # Track "Deployment Id" allowing to Cancel the Job
  echo "sf project deploy start --manifest sourcePackage.xml --post-destructive-changes src/destructiveChanges/destructiveChanges.xml --ignore-warnings --ignore-conflicts --verbose $unit_tests_params --dry-run --async --json"
#  validate_command_result=$(sf project deploy start --manifest sourcePackage.xml --post-destructive-changes "src/destructiveChanges/destructiveChanges.xml" --ignore-warnings --ignore-conflicts --verbose $test_level --dry-run --async --json)
#
#  echo "Validation job details: $validate_command_result"
#  deployment_id=$(echo "$validate_command_result" | jq -r .result.id)
#  echo "deployment_id=$deployment_id" >> "$GITHUB_OUTPUT"
#  sf project deploy resume --job-id $deployment_id
#fi