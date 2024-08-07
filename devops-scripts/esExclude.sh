#!/bin/bash

git config --global --add safe.directory "*"
source_to_check_changes="origin/$GITHUB_BASE_REF"
current_branch="origin/$GITHUB_HEAD_REF"

if [[ -n "$1" && "$1" != null ]]; then
  echo "merge to develop"
  source_to_check_changes=$1
  current_branch=""
fi
echo "1: $1"
echo "2: $2"
ES_PATH='^src/.*/expressionSetDefinition/'

git fetch origin
if [[ -n "$2" && "$2" == 'scratch' ]]; then
  echo "if scratch"
  echo "branch $source_to_check_changes"
  changed_es_files=$(git diff --name-only $source_to_check_changes | grep -E $ES_PATH)
  else
  echo "not scratch"
  changed_es_files=$(git diff --name-only $source_to_check_changes...$current_branch | grep -E $ES_PATH)
  echo "branch $source_to_check_changes"
  echo "changed $changed_es_files"
fi

echo "$changed_es_files"
for file_path in $changed_es_files; do
  echo "!$file_path" >> .forceignore
done