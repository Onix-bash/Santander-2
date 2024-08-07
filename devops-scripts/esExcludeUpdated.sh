#!/bin/bash

source_to_check_changes="origin/$GITHUB_BASE_REF"
current_branch="origin/$GITHUB_HEAD_REF"

if [ -n "$1" ]; then
  source_to_check_changes=$1
  current_branch=""
fi
echo "source_to_check_changes $source_to_check_changes"
echo "current_branch $current_branch"
ES_PATH='^src/.*/expressionSetDefinition/'

git fetch origin
# Get the list of changed files that match the pattern
changed_es_files=$(git diff --name-only $source_to_check_changes...$current_branch | grep -E $ES_PATH)
echo "Changed files matching pattern: $changed_es_files"

# Get the list of all changed files from the source branch
changed_all=$(git diff --name-only $source_to_check_changes..$current_branch)
echo "All changed files: $changed_all"

# Get the list of changed files in the latest commit that match the pattern
changed_head=$(git diff --name-only  | grep -E $ES_PATH)
echo "Changed files in HEAD matching pattern: $changed_head"

for file_path in $changed_es_files; do
  echo "!$file_path" >> .forceignore
  echo "changed: $file_path"
done
