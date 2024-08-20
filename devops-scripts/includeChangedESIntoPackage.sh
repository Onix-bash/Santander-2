#!/bin/bash
# $1 - PR was merged into <base> branch OR <release> branch was executed to be validated/deployed manually

GITHUB_EVENT_NAME=$GITHUB_EVENT_NAME
echo "$GITHUB_EVENT_NAME"
# Conditional logic based on the event
if [ "$GITHUB_EVENT_NAME" = "push" ]; then
    current_branch=""
    source_to_check_changes="HEAD^"
elif [ "$GITHUB_EVENT_NAME" = "workflow_dispatch" ]; then
    current_branch="origin/$(git branch --show-current)"
    source_to_check_changes="origin/$(git remote show origin | grep 'HEAD branch' | sed 's/.*: //')"
else
    current_branch="origin/$GITHUB_HEAD_REF"
    source_to_check_changes="origin/$GITHUB_BASE_REF"
fi


echo "current_branch= $current_branch"
echo "source_to_check_changes= $source_to_check_changes"
ES_PATH='^src/.*/expressionSetDefinition/'

git fetch origin
changed_es_files=$(git diff --name-only $source_to_check_changes...$current_branch | grep -E $ES_PATH)
echo "changed_es_files $changed_es_files"
for file_path in $changed_es_files; do
  echo "!$file_path" >> .forceignore
done

