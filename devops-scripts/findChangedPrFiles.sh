#!/bin/bash

fileNames=""
if [ "$GITHUB_EVENT_NAME" = "pull_request" ]; then
  base_branch=$(jq --raw-output .pull_request.base.ref "$GITHUB_EVENT_PATH")
  head_branch=$(jq --raw-output .pull_request.head.ref "$GITHUB_EVENT_PATH")
  git fetch origin $base_branch $head_branch

  # Get the list of modified files in the PR
  modified_files=$(git diff --name-only --diff-filter=AM origin/$base_branch...origin/$head_branch | grep '^src/.*/\(classes\|lwc\)/' | tr '\n' ' ')
  fileNames=$modified_files
fi

echo "files=$fileNames" >> "$GITHUB_OUTPUT"