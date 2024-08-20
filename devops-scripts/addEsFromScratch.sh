#!/bin/bash

if [ -n "$1" ]; then
    # Add the changed files to .forceignore with "!" prefix
    for file in $1; do
        # Check if the entry already exists in .forceignore
        if ! grep -qx "!$file" .forceignore; then
            echo "!$file" >> .forceignore
        fi
    done
fi

cat .forceignore