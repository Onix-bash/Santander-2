#!/bin/bash

if [ -n "$GITHUB_BASE_REF" ]; then
  source_to_check_changes="origin/$GITHUB_BASE_REF"
  else
  source_to_check_changes="HEAD^"
fi

if [ -n "$GITHUBa_HEAD_REF" ]; then
  source_to_check_changes="origin/$GITHUB_HEAD_REF"
  else
  source_to_check_changes=""
fi

ES_PATH='src/decision-centre/main/default/expressionSetDefinition'

git fetch origin
changed_es_files=$(git diff --name-only $source_to_check_changes...$current_branch $ES_PATH)

for file_path in $changed_es_files; do
  echo "!$file_path" >> .forceignore
done