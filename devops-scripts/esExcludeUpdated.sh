#!/bin/bash

# Default branches to compare
source_to_check_changes="origin/$GITHUB_BASE_REF"
current_branch="$GITHUB_HEAD_REF"

# Override if an argument is passed
if [ -n "$1" ]; then
  source_to_check_changes="origin/$1"
fi

ES_PATH='^src/.*/expressionSetDefinition/'

# Fetch both branches
git fetch origin $source_to_check_changes
git fetch origin $current_branch

# Get the list of changed files matching the pattern
changed_es_files=$(git diff --name-only $source_to_check_changes...$current_branch | grep -E $ES_PATH)

# Append changes to .forceignore
for file_path in $changed_es_files; do
  echo "!$file_path" >> .forceignore
  echo "changed: $file_path"
done