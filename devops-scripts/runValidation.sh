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
echo "--- Starting validation for modules: ${source_paths_to_validate[*]}"
if [ "$SKIP_ORG_INTERACTION" = "true" ]; then
  echo "Org interaction has been skipped because of setup: SKIP_ORG_INTERACTION = true"
else
  chmod +x ./devops-scripts/getTestClasses.sh
  IFS=' ' read -r -a testClasses <<< "$(./devops-scripts/getTestClasses.sh)"  # I dont know why this is not working, I tried several different approaches with string concat and arrays
                                                                       # but only thi IFS approach works, I love bash scripting but we should look into JS actions asap ;_;

  command_result=$(sf project generate manifest --source-dir "${source_paths_to_validate[@]}" --name sourcePackage)
  echo "Package generated: $command_result"
  # Track "Deployment Id" allowing to Cancel the Job
  validate_command_result=$(sf project deploy validate --manifest sourcePackage.xml --post-destructive-changes "src/destructiveChanges/destructiveChanges.xml" --test-level RunSpecifiedTests --tests "${testClasses[@]}" --ignore-warnings --async --json)
  echo "Validation job details: $validate_command_result"
  deployment_id=$(echo "$validate_command_result" | jq -r .result.id)
  echo "deployment_id=$deployment_id" >> "$GITHUB_OUTPUT"
  sf project deploy resume --job-id $deployment_id
fi