#!/bin/bash

source_to_check_changes="origin/$GITHUB_BASE_REF"
ES_PATH='src/decision-centre/main/default/expressionSetDefinition'

git fetch origin
changed_es_files=$(git diff --name-only $source_to_check_changes $ES_PATH)

for file_path in $changed_es_files; do
  echo "!$file_path" >> .forceignore
done

cat .forceignore