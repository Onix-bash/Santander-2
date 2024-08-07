#!/bin/bash

source_to_check_changes="$GITHUB_BASE_REF"
current_branch="$GITHUB_HEAD_REF"

if [ -n "$1" ]; then
  source_to_check_changes=$1
  current_branch=""
fi
echo "$source_to_check_changes"
echo "$current_branch"
ES_PATH='^src/.*/expressionSetDefinition/'

changed_es_files=$(git diff --name-only $source_to_check_changes..$current_branch | grep -E $ES_PATH)

changed_all=$(git diff --name-only "$source_to_check_changes" | grep -E $ES_PATH)
echo "all: $changed_all"

for file_path in $changed_es_files; do
  echo "!$file_path" >> .forceignore
  echo "changed: $file_path"
done
