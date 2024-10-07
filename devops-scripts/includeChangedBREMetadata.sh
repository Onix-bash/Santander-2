#!/bin/bash

GITHUB_EVENT_NAME=$GITHUB_EVENT_NAME

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
echo "current_branch $current_branch"
echo "source_to_check_changes $source_to_check_changes"
# BRE - Business Rules Engine Metadata
BRE_PATH='^src/.*/(expressionSetDefinition|decisionMatrixDefinition)/'

git fetch origin
changed_bre_files=$(git diff --name-only --diff-filter=d $source_to_check_changes...$current_branch | grep -E $BRE_PATH)
          
changed_decision_matrix_files=()
for file_path in $changed_bre_files; do
  # Exclude changed BRE files from .forceignore
  echo "!$file_path" >> .forceignore

  # Find changed files from decisionMatrixDefinition folder
  if [[ $file_path =~ ^src/.*/decisionMatrixDefinition/ ]]; then
    changed_decision_matrix_files+=("$file_path")
  fi
done

# Changed Decision Matrixes for future Calculation Matrix Rows creation
echo "decision_matrix_files=${changed_decision_matrix_files[*]}" >> "$GITHUB_OUTPUT"