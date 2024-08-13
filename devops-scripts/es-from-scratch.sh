#!/bin/bash

#sf project retrieve start --metadata ExpressionSetDefinition --output-dir scratch_es --ignore-conflicts

DIR1="scratch_es/main/default/expressionSetDefinition"
DIR2="src/decision-centre/main/default/expressionSetDefinition"

# Run the diff command and get the list of changed files
changed_files=$(diff -qr "$DIR1" "$DIR2" | grep -E '^Files ' | awk '{print $2}' | sed "s|^$DIR1/||")

# Check if any files are detected
if [ -z "$changed_files" ]; then
    echo "No differences found between CI-Org and develop."
else
    echo "Differences found in: $changed_files"

    # Add the changed files to .forceignore with "!" prefix
    for file in $changed_files; do
        # Check if the entry already exists in .forceignore
        if ! grep -qx "!$file" .forceignore; then
            echo "!$file" >> .forceignore
        fi
    done
fi

cat .forceignore