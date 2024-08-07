#!/bin/bash

git config --global --add safe.directory "*"
source_to_check_changes="origin/$GITHUB_BASE_REF"
current_branch="origin/$GITHUB_HEAD_REF"

if [[ -n "$1" && "$1" != 'null' ]]; then
  source_to_check_changes=$1
fi

echo "1: $1"
echo "2: $2"
ES_PATH='^src/.*/expressionSetDefinition/'

git fetch origin
if [[ -n "$2" && "$2" == 'scratch' ]]; then
  echo "Condition: scratch"
  compared_branches="$source_to_check_changes..$current_branch"
elif [[ -n "$1" && "$1" != 'null' ]]; then
  echo "Condition: HEAD^"
  compared_branches="$source_to_check_changes"
else
  echo "Condition: default"
  compared_branches="$source_to_check_changes...$current_branch"
fi

changed_es_files=$(git diff --name-only compared_branches | grep -E $ES_PATH)
echo "$changed_es_files"
for file_path in $changed_es_files; do
  echo "!$file_path" >> .forceignore
done