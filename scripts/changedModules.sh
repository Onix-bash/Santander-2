#!/bin/bash

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
    if git diff --name-only "$source_to_check_changes" -- "$module" | grep -q "$module"; then
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
  echo "changed_modules=${changed_modules[*]}" >> "$GITHUB_OUTPUT"
fi
echo
