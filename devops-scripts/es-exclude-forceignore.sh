#!/bin/bash

git config --global --add safe.directory "*"
source_to_check_changes="origin/$GITHUB_BASE_REF"
current_branch="origin/$GITHUB_HEAD_REF"
echo "$source_to_check_changes"
echo "$current_branch"
if [ -n "$1" ]; then
  source_to_check_changes=$1
  current_branch=""
fi

if [ -n "$2" ]; then
  current_branch=$2
fi

ES_PATH='src/decision-centre/main/default/expressionSetDefinition'

git fetch origin
changed_es_files=$(git diff --name-only $source_to_check_changes...$current_branch $ES_PATH)
echo "changed_es_files: $changed_es_files"

for file_path in $changed_es_files; do
  echo "!$file_path" >> .forceignore
done
cat .forceignore