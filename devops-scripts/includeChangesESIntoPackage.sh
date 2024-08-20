#!/bin/bash
# $1 - PR was merged into <base> branch OR <release> branch was executed to be validated/deployed manually
echo "This script was triggered by the $GITHUB_WORKFLOW workflow."
echo "MANUAL_WORKFLOWS $MANUAL_WORKFLOWS"
if [ -n "$MANUAL_WORKFLOWS" ]; then
  IFS=$'\n' read -r -d '' -a MANUAL_WORKFLOW_ARRAY <<< "$(echo "$MANUAL_WORKFLOWS" | sed '/^\s*$/d' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  is_manual=false

  for workflow in "${MANUAL_WORKFLOW_ARRAY[@]}"; do
    if [[ "$workflow" == "$GITHUB_WORKFLOW" ]]; then
       echo "$workflow == $GITHUB_WORKFLOW"
      is_manual=true
      break
    fi
  done

  current_branch="origin/$GITHUB_HEAD_REF"
  source_to_check_changes="origin/$GITHUB_BASE_REF"

 if $is_manual; then
    # PR was merged into <base> branch
    current_branch=""
    source_to_check_changes="HEAD^"
 else
   # <release> branch was executed
   current_branch="origin/$(git branch --show-current)"
   source_to_check_changes="origin/$(git remote show origin | grep 'HEAD branch' | sed 's/.*: //')"
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


fi
