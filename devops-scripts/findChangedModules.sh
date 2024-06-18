#!/bin/bash

git config --global --add safe.directory /__w/Santander-2/Santander-2
source_to_check_changes="feature/pr-scan-v2"

if [ -n "$1" ]; then
  source_to_check_changes=$1
fi

git fetch origin
git_diff=$(git diff --name-only $source_to_check_changes | grep -v "^src/")

# Check changes outside src folder
if [[ -n $DEVOPS_TEAM && -n $git_diff ]]; then

  IFS=$'\n' read -r -d '' -a DEVOPS_ARRAY <<< "$(echo "$DEVOPS_TEAM" | sed '/^\s*$/d' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  is_admin=false

  for member in "${DEVOPS_ARRAY[@]}"; do
    if [[ "$member" == "$GITHUB_ACTOR" ]]; then
      is_admin=true
      break
    fi
  done

  # Check if user is NOT in DevOps team
  if ! $is_admin; then
    IFS=$'\n' read -r -d '' -a ALLOWED_DEV_MODIFICATIONS_ARRAY <<< "$(echo "$ALLOWED_DEV_MODIFICATIONS" | sed '/^\s*$/d' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

    while IFS= read -r file; do
      is_allowed=false
      for allowed_modification in "${ALLOWED_DEV_MODIFICATIONS_ARRAY[@]}"; do
        if [[ "$file" == "$allowed_modification"* ]]; then
          is_allowed=true
          break
        fi
      done

      if ! $is_allowed; then
        echo "Only DevOps team members can change '$file'."
        exit 1
      fi
    done <<< "$git_diff"
  fi
fi

echo "Starting to look for changed modules against $source_to_check_changes..."
# Array of your module directories
modules=( $( cd src/ ;ls -1p | grep / | sed 's/^\(.*\)/\1/') )

 #externalize module names
# Base branch to compare against, adjust according to your workflow


# Loop through each module to check for changes
for module in "${modules[@]}"; do
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
  echo "changed_modules=${changed_modules[*]}" >> "$GITHUB_OUTPUT"
fi
echo
