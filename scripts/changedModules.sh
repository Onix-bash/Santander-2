#!/bin/bash

nextStep() {
  source_paths_to_deploy=('src/')
  if [ -n "$1" ]; then
    source_paths_to_deploy=()
    for module in "$@"; do
        source_paths_to_deploy+=("../src/$module")
    done
  fi
  echo "--- Starting deployment for modules: ${source_paths_to_deploy[*]}"
  if [ "$SKIP_ORG_INTERACTION" = "true" ]; then
    echo "Org interaction has been skipped because of setup: SKIP_ORG_INTERACTION = true"
  else
    sf project generate manifest --source-dir "${source_paths_to_deploy[@]}" --name sourcePackage
    # Track "Deployment Id" allowing to Cancel the Job
    deployment_id=$(sf project deploy start --manifest sourcePackage.xml --post-destructive-changes "../src/destructiveChanges/destructiveChanges.xml" --test-level RunLocalTests -o target-org --ignore-conflicts --ignore-warnings --async --json | jq -r .result.id)
    echo "deployment_id=$deployment_id" >> "$GITHUB_OUTPUT"
    sf project deploy resume --job-id "$deployment_id"
  fi
}

git config --global --add safe.directory /__w/mortgagesfdc-homes-crm/mortgagesfdc-homes-crm #fix for dubious ownership issue TODO check more deeply for better solution

source_to_check_changes="origin/develop"

if [ -n "$1" ]; then
  source_to_check_changes=$1
fi


echo "Starting to look for changed modules against $source_to_check_changes..."
# Array of your module directories
modules=( $( cd ../src/ ;ls -1p | grep / | sed 's/^\(.*\)/\1/') )
 #externalize module names
# Base branch to compare against, adjust according to your workflow

 
# Loop through each module to check for changes
for module in "${modules[@]}"; do
  echo "$module"
    # Check if the module has changes compared to the base branch
    if git diff --name-only "$source_to_check_changes" | grep -q "$module"; then
        changed_modules+=("$module")
        echo "changes detected in $module"
    else
        echo "No changes in $module"
    fi
done

if (( ${#changed_modules[@]} == 0 )); then
  echo "No changed modules detected, aborting deployment"
  exit 0
else
  echo "--- Changes detected for modules ${changed_modules[*]}"
  echo "changed_modules=${changed_modules[*]}"
  nextStep "${changed_modules[*]}"
fi
echo

