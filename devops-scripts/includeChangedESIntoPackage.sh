#!/bin/bash
# $1 - PR was merged into <base> branch OR <release> branch was executed to be validated/deployed manually

current_branch="origin/$GITHUB_HEAD_REF"
source_to_check_changes="origin/$GITHUB_BASE_REF"

if [[ -n "$1" && "$1" == "HEAD^" ]]; then
  # PR was merged into <base> branch
  current_branch=""
  source_to_check_changes=$1
elif [[ "$1" == "release" ]]; then
  # <release> branch was executed
  current_branch="origin/$(git branch --show-current)"
  source_to_check_changes="origin/$(git remote show origin | grep 'HEAD branch' | sed 's/.*: //')"
fi

ES_PATH='^src/.*/expressionSetDefinition/'

git fetch origin
changed_es_files=$(git diff --name-only $source_to_check_changes...$current_branch | grep -E $ES_PATH)

for file_path in $changed_es_files; do
  echo "!$file_path" >> .forceignore
done
