#!/bin/bash

source_to_check_changes="origin/$GITHUB_BASE_REF"
current_branch="origin/$GITHUB_HEAD_REF"

if [[ -n "$1" && "$1" == "HEAD^" ]]; then
  source_to_check_changes=$1
  current_branch=""
elif [[ "$1" == "release" ]]; then
  current_branch="origin/$(git branch --show-current)"
  source_to_check_changes="origin/$(git remote show origin | grep 'HEAD branch' | sed 's/.*: //')"
fi
 echo "$source_to_check_changes"
 echo "$current_branch"

ES_PATH='^src/.*/expressionSetDefinition/'
git fetch origin
changed_es_files=$(git diff --name-only $source_to_check_changes...$current_branch | grep -E $ES_PATH)

for file_path in $changed_es_files; do
  echo "!$file_path" >> .forceignore
done