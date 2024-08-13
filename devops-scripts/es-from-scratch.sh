#!/bin/bash
#sf project retrieve start --metadata ExpressionSetDefinition --output-dir scratch_es --ignore-conflicts

DIR1="scratch_es/main/default/expressionSetDefinition"
DIR2="src/decision-centre/main/default/expressionSetDefinition"

# Run the diff command and get the list of changed files
changed_files=$(diff -qr "$DIR1" "$DIR2" | grep -E '^Files ' | awk '{print $2}' | sed "s|^$DIR1/||")

# Check if any files are detected
if [ -z "$changed_files" ]; then
    echo "No differences found between CI-Org and develop."
    changed_files=""
else
    echo "Differences found in: $changed_files"
fi

# Format changed_files (e.g., replace newlines with spaces or commas)
formatted_changed_files=$(echo "$changed_files" | tr '\n' ' ')

# Set the GitHub Action output
echo "changed_files=$formatted_changed_files" >> $GITHUB_ENV
git status