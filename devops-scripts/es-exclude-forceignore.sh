#!/bin/bash

source_to_check_changes="origin/$GITHUB_BASE_REF"
current_branch="origin/$GITHUB_HEAD_REF"

if [ -n "$1" ]; then
  source_to_check_changes=$1
  current_branch=""
fi

ES_PATH='src/decision-centre/main/default/expressionSetDefinition'

git fetch origin
changed_es_files=$(git diff --name-only $source_to_check_changes $ES_PATH)
echo "changed_es_files: $changed_es_files"

for file_path in $changed_es_files; do
  echo "!$file_path" >> .forceignore
done