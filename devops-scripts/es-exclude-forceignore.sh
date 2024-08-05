#!/bin/bash
echo "GITHUB_BASE_BRANCH: $GITHUB_BASE_BRANCH"
echo "GITHUB_CURRENT_BRANCH: $GITHUB_CURRENT_BRANCH"

if [ -n "$GITHUB_BASE_REF" ]; then
  source_to_check_changes="origin/$GITHUB_BASE_REF"
  else
  source_to_check_changes="HEAD^"
fi

if [ -n "$GITHUBa_HEAD_REF" ]; then
  current_branch="origin/$GITHUB_HEAD_REF"
  else
  current_branch=""
fi
echo "source_to_check_changes: $source_to_check_changes"
echo "current_branch: $current_branch"

ES_PATH='src/decision-centre/main/default/expressionSetDefinition'

git fetch origin
changed_es_files=$(git diff --name-only $source_to_check_changes...$current_branch $ES_PATH)
echo "changed_es_files: $changed_es_files"
for file_path in $changed_es_files; do
  echo "!$file_path" >> .forceignore
done

cat .forceignore


