#!/bin/bash

git config --global --add safe.directory "*"
github_actor="${GITHUB_ACTOR}"
source_to_check_changes="origin/feature/deploy-test"
git fetch origin

echo "Starting to look for changed"
git_diff=$(git diff --name-only $source_to_check_changes | grep -v "^src/")

DEV_OPS=$1
# Check if the list of changed files is empty
if [[ -n $DEV_OPS && -n $git_diff ]]; then
  echo "There are changes outside 'src' folder."
  echo "Current username: '$github_actor'"
  echo "DEV_OPS team list: '$DEV_OPS'"

  IFS=',' read -r -a DEV_OPS_ARRAY <<< "$DEV_OPS"
  is_admin=false

  for member in "${DEV_OPS_ARRAY[@]}"; do
    if [[ "$member" == "$GITHUB_ACTOR" ]]; then
      is_admin=true
      break
    fi
  done
  # Check if user not in DevOps team
  if [[ "$is_admin" == "false" ]]; then
    echo "You can't make changes"
    exit 1
    else
      echo "You can make changes outside 'src' folder"
  fi
fi
#echo "Starting to look for changed modules against $source_to_check_changes..."
## Array of your module directories
#modules=( $( cd src/ ;ls -1p | grep / | sed 's/^\(.*\)/\1/') )
#
## externalize module names
## Base branch to compare against, adjust according to your workflow
#
#
## Loop through each module to check for changes
#for module in "${modules[@]}"; do
#    # Check if the module has changes compared to the base branch
#    if git diff --name-only "$source_to_check_changes" | grep -q "$module"; then
#        changed_modules+=("$module")
#        echo "changes detected in $module"
#    else
#        echo "No changes in $module"
#    fi
#done
#
#if (( ${#changed_modules[@]} == 0 )); then
#  echo "No changed modules detected, aborting deployment"
#  exit 0
#else
#  echo "--- Changes detected for modules ${changed_modules[*]}"
#  echo "changed_modules=${changed_modules[*]}" >> "$GITHUB_OUTPUT"
#fi
#echo
#
#
#
