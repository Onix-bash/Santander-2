#!/bin/bash

git config --global --add safe.directory "*"
source_to_check_changes="origin/feature/deploy-test"

#github_actor="Kristy-user"
#ALLOWED_MODIFICATIONS='"sfdx-project.json","testFolder/","scripts/findChangedModules.sh"'
#DEV_OPS="kristina-klepik"

github_actor="${GITHUB_ACTOR}"
ALLOWED_MODIFICATIONS=$(echo "$ALLOWED_MODIFICATIONS" | sed 's/"//g')
DEV_OPS=$(echo "$DEV_OPS" | sed 's/"//g')
echo "$ALLOWED_MODIFICATIONS"

echo "Starting to look for changes"
git fetch origin
git_diff=$(git diff --name-only "$source_to_check_changes" | grep -v "^src/")
echo "Git_diff files: '$git_diff'"

# Check if the list of changed files is empty
if [[ -n "$DEV_OPS" && -n "$git_diff" ]]; then
  echo "Current username: '$github_actor'"
  echo "DEV_OPS team list: '$DEV_OPS'"

  IFS=',' read -r -a DEV_OPS_ARRAY <<< "$DEV_OPS"
  is_admin=false

  for member in "${DEV_OPS_ARRAY[@]}"; do
    if [[ "$member" == "$github_actor" ]]; then
      is_admin=true
      break
    fi
  done

  # Check if user NOT in DevOps team
  if [[ "$is_admin" == false ]]; then
    IFS=',' read -r -a ALLOWED_MODIFICATIONS_ARRAY <<< "$ALLOWED_MODIFICATIONS"
    allow_changes=true

    while IFS= read -r file; do
      echo "git_diff file: '$file'"
      is_allowed=false
      for allowed_modification in "${ALLOWED_MODIFICATIONS_ARRAY[@]}"; do
        if [[ "$file" == "$allowed_modification" || "$file" == "$allowed_modification"* ]]; then
          echo "Change in '$file' is allowed."
          is_allowed=true
          break
        fi
      done

      if [[ "$is_allowed" == false ]]; then
        echo "Change in '$file' is not allowed."
        exit 1
      fi
    done <<< "$git_diff"
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
