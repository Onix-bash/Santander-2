#!/bin/bash

git config --global --add safe.directory "*"
source_to_check_changes="origin/$GITHUB_BASE_REF"
current_branch="origin/$GITHUB_HEAD_REF"

if [ -n "$1" ]; then
  source_to_check_changes=$1
fi

ES_PATH='^src/.*/expressionSetDefinition/'

git fetch origin
changed_es_files=$(git diff --name-only $source_to_check_changes...$current_branch | grep -E $ES_PATH)

for file_path in $changed_es_files; do
  echo "!$file_path" >> .forceignore
done