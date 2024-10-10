#!/bin/bash

# script gets as parameter an array of module names
# if there is no any module name provided then script deploys all sources under /src folder
source_paths_to_deploy=('src/')
if [ -n "$1" ]; then
  source_paths_to_deploy=()
  for module in "$@"; do
      source_paths_to_deploy+=("src/$module")
  done
fi

unit_tests_params='--test-level NoTestRun'

# Check and apply Apex Unit Tests params from inputs if they exist
if [ "$TEST_LEVEL" == "RunSpecifiedTests" ] && [ -n "$SPECIFIED_TESTS" ]; then
  unit_tests_params="--test-level $TEST_LEVEL --tests $SPECIFIED_TESTS"
elif [ -n "$TEST_LEVEL" ]; then
  unit_tests_params="--test-level $TEST_LEVEL"
fi

echo "--- Starting deployment for modules: ${source_paths_to_deploy[*]}"
if [ "$SKIP_ORG_INTERACTION" = "true" ]; then
  echo "Org interaction has been skipped because of setup: SKIP_ORG_INTERACTION = true"
else
  command_result=$(sf project generate manifest --source-dir "${source_paths_to_deploy[@]}" --name sourcePackage)
  echo "Package generated: $command_result"

  # chmod +x ./devops-scripts/getTestClasses.sh
  # IFS=' ' read -r -a testClasses <<< "$(./devops-scripts/getTestClasses.sh)"
  # Set manifest package for Decision Centre module
  
  echo "Destructive changes:"
  cat src/destructiveChanges/destructiveChanges.xml

  # Track "Deployment Id" allowing to Cancel the Job
  deploy_command_result=$(sf project deploy start --manifest sourcePackage.xml --post-destructive-changes "src/destructiveChanges/destructiveChanges.xml" $unit_tests_params --ignore-conflicts --ignore-warnings --async --json)
  echo "Deployment job details: $deploy_command_result"
  deployment_id=$(echo "$deploy_command_result" | jq -r .result.id)
  echo "deployment_id=$deployment_id" >> "$GITHUB_OUTPUT"
  sf project deploy resume --job-id $deployment_id
fi