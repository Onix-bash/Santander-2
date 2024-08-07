#!/bin/bash

source_to_check_changes="origin/$GITHUB_BASE_REF"
current_branch="origin/$GITHUB_HEAD_REF"

if [ -n "$1" ]; then
  source_to_check_changes=$1
  current_branch=""
fi

ES_PATH='^src/.*/expressionSetDefinition/'

git fetch origin
changed_es_files=$(git diff --name-only $source_to_check_changes..$current_branch | grep -E $ES_PATH)
echo "$source_to_check_changes..$current_branch"

for file_path in $changed_es_files; do
  echo "!$file_path" >> .forceignore
  echo "changed: $file_path"
done
