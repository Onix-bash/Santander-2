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
echo "--- Starting deployment for modules: ${source_paths_to_deploy[*]}"
if [ "$SKIP_ORG_INTERACTION" = "true" ]; then
  echo "Org interaction has been skipped because of setup: SKIP_ORG_INTERACTION = true"
else
  sf project generate manifest --source-dir "${source_paths_to_deploy[@]}" --name sourcePackage
  # Track "Deployment Id" allowing to Cancel the Job
  deployment_id=$(sf project deploy start --manifest sourcePackage.xml --post-destructive-changes "src/destructiveChanges/destructiveChanges.xml" --test-level RunLocalTests -o target-org --ignore-conflicts --ignore-warnings --async --json | jq -r .result.id)
  echo "deployment_id=$deployment_id" >> "$GITHUB_OUTPUT"
  sf project deploy resume --job-id $deployment_id
fi
