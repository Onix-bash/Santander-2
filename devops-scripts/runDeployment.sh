#!/bin/bash

set -e
# script gets as parameter an array of module names
# if there is no any module name provided then script deploys all sources under /src folder
source_paths_to_deploy=('src/')
if [ -n "$1" ]; then
  source_paths_to_deploy=()
  for module in "$@"; do
      source_paths_to_deploy+=("src/$module")
  done
fi
echo "--- Starting deployment for modules: ${source_paths_to_deploy[*]}"
if [ "$SKIP_ORG_INTERACTION" = "true" ]; then
  echo "Org interaction has been skipped because of setup: SKIP_ORG_INTERACTION = true"
else
  command_result=$(sf project generate manifest --source-dir "${source_paths_to_deploy[@]}" --name sourcePackage)
  echo "Package generated: $command_result"

  chmod +x ./devops-scripts/getTestClasses.sh
  IFS=' ' read -r -a testClasses <<< "$(./devops-scripts/getTestClasses.sh)"
  # Set manifest package for Decision Centre module
  # npm ci line has to be moved outside this script into better place - to be refactored during impl of MAXSF-5321
  npm ci
  node devops-scripts/addChangedDecisionCenterMetadata.js
  set_decision_centre_status=$?
  if [ $set_decision_centre_status -ne 0 ]; then
   exit 1
  fi

  # Track "Deployment Id" allowing to Cancel the Job
  deploy_command_result=$(sf project deploy start --manifest sourcePackage.xml --post-destructive-changes "src/destructiveChanges/destructiveChanges.xml" --test-level RunSpecifiedTests --tests "${testClasses[@]}" --ignore-conflicts --ignore-warnings --async --json)
  echo "Deployment job details: $deploy_command_result"
  deployment_id=$(echo "$deploy_command_result" | jq -r .result.id)
  echo "deployment_id=$deployment_id" >> "$GITHUB_OUTPUT"
  sf project deploy resume --job-id $deployment_id
fi