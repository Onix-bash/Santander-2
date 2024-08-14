#!/bin/bash

#sf project retrieve start --metadata ExpressionSetDefinition --output-dir scratch_es --ignore-conflicts

DIR1="scratch_es/main/default/expressionSetDefinition"
DIR2="src/decision-centre/main/default/expressionSetDefinition"

# Check if the retrieval command was successful
if [ ! -d "$DIR1" ] || [ -z "$(ls -A "$DIR1")" ]; then
    echo "No data retrieved from Salesforce or directory is empty."
    echo "changed_files=" >> "$GITHUB_OUTPUT"
    exit 0
fi

# Run the diff command and get the list of changed files
changed_files=$(diff -qr "$DIR1" "$DIR2" | grep -E '^Files ' | awk '{print $2}' | sed "s|^$DIR1/||")

# Format the changed files to be space-separated on a single line
formatted_changed_files=$(echo "$changed_files" | tr '\n' ' ')
echo "$formatted_changed_files"
echo "changed_files=$formatted_changed_files" >> "$GITHUB_OUTPUT"