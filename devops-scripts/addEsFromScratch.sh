#!/bin/bash

# Check if any files are detected
echo "$1"
if [ -z "$1" ]; then
    echo "No differences found between CI-Org and develop."
else
    echo "Differences found in: $1"

    # Add the changed files to .forceignore with "!" prefix
    for file in $1; do
        # Check if the entry already exists in .forceignore
        if ! grep -qx "!$file" .forceignore; then
            echo "!$file" >> .forceignore
            echo "Added !$file to .forceignore"
        fi
    done
fi

cat .forceignore